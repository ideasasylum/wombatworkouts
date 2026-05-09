class WorkoutHeatmap
  # Curated 10-color palette for cycling through programs in user's program-creation
  # order. Roughly progresses light → warm → deep so the heatmap reads as a rough
  # intensity ramp as a user cycles through new rehab programs.
  PALETTE = [
    "#f3e7d3", # warm cream
    "#e3c9a5", # wheat
    "#d4a574", # sand
    "#c08552", # light caramel
    "#b58863", # brand brown
    "#9c6644", # sienna
    "#7d5238", # chestnut
    "#5e3d24", # chocolate
    "#3f2817", # bistre
    "#261810"  # dark umber
  ].freeze

  EMPTY_COLOR = "#ebedf0".freeze
  ORPHAN_COLOR = "#9ca3af".freeze
  WEEKS = 12
  DAYS_PER_WEEK = 7

  Cell = Struct.new(:date, :workout, :color, :program_title, :today, :future, keyword_init: true) do
    def workout?
      !workout.nil?
    end
  end

  attr_reader :today, :start_date, :end_date

  def initialize(user, today: nil)
    @user = user
    @zone = ActiveSupport::TimeZone[user.timezone.presence || "UTC"] || Time.zone
    @today = today || Time.now.in_time_zone(@zone).to_date
    @end_date = @today.end_of_week(:monday)
    @start_date = @end_date - (WEEKS * DAYS_PER_WEEK - 1).days
  end

  # 12-element array of weeks, each a 7-element array of Cells (Mon → Sun).
  def weeks
    @weeks ||= Array.new(WEEKS) do |week_idx|
      Array.new(DAYS_PER_WEEK) do |day_idx|
        date = @start_date + (week_idx * DAYS_PER_WEEK + day_idx).days
        workout = workouts_by_date[date]
        Cell.new(
          date: date,
          workout: workout,
          color: cell_color(workout),
          program_title: workout&.program_title,
          today: date == @today,
          future: date > @today
        )
      end
    end
  end

  def any_workouts?
    workouts_by_date.any?
  end

  # Returns [{program:, color:}, ...] for programs with at least one workout in the
  # visible range, ordered by program creation date (i.e. the order the colors
  # cycle through the palette).
  def legend
    visible_program_ids = workouts_by_date.values.map(&:program_id).compact.uniq
    return [] if visible_program_ids.empty?

    @user.programs
      .where(id: visible_program_ids)
      .order(:created_at)
      .map { |program| {program: program, color: color_for_program_id(program.id)} }
  end

  private

  def cell_color(workout)
    return EMPTY_COLOR if workout.nil?
    return ORPHAN_COLOR if workout.program_id.nil?
    color_for_program_id(workout.program_id) || ORPHAN_COLOR
  end

  def color_for_program_id(program_id)
    index = program_color_index[program_id]
    return nil if index.nil?
    PALETTE[index % PALETTE.size]
  end

  def program_color_index
    @program_color_index ||= @user.programs.order(:created_at).pluck(:id).each_with_index.to_h
  end

  def workouts_by_date
    @workouts_by_date ||= begin
      range_start = @zone.local(@start_date.year, @start_date.month, @start_date.day)
      range_end = @zone.local(@end_date.year, @end_date.month, @end_date.day) + 1.day

      by_date = {}
      @user.workouts
        .where.not(completed_at: nil)
        .where(completed_at: range_start...range_end)
        .order(completed_at: :asc)
        .each do |workout|
          date = workout.completed_at.in_time_zone(@zone).to_date
          by_date[date] = workout # later completed_at overwrites earlier
        end
      by_date
    end
  end
end
