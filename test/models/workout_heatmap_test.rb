require "test_helper"

class WorkoutHeatmapTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(email: "heatmap@example.com")
    @today = Date.new(2026, 5, 7) # a Thursday
  end

  test "produces 12 weeks of 7 days" do
    heatmap = WorkoutHeatmap.new(@user, today: @today)
    assert_equal 12, heatmap.weeks.length
    heatmap.weeks.each { |week| assert_equal 7, week.length }
  end

  test "the last cell is today's date" do
    heatmap = WorkoutHeatmap.new(@user, today: @today)
    last_week = heatmap.weeks.last
    monday_indexed_wday = (@today.wday == 0) ? 6 : @today.wday - 1
    assert_equal @today, last_week[monday_indexed_wday].date
    assert last_week.find { |cell| cell.date == @today }.today
  end

  test "empty days use the empty color" do
    heatmap = WorkoutHeatmap.new(@user, today: @today)
    assert_equal WorkoutHeatmap::EMPTY_COLOR, heatmap.weeks.first.first.color
    assert_nil heatmap.weeks.first.first.workout
  end

  test "cycles palette colors by program creation order" do
    travel_to Time.utc(2026, 1, 1) do
      11.times { |i| @user.programs.create!(title: "P#{i}") }
    end

    heatmap = WorkoutHeatmap.new(@user, today: @today)

    first_program = @user.programs.order(:created_at).first
    eleventh_program = @user.programs.order(:created_at).last

    # Palette is 10 colors, so program 11 wraps back to color 0
    assert_equal WorkoutHeatmap::PALETTE[0], heatmap.send(:color_for_program_id, first_program.id)
    assert_equal WorkoutHeatmap::PALETTE[0], heatmap.send(:color_for_program_id, eleventh_program.id)
  end

  test "completed workout shows program color" do
    program = @user.programs.create!(title: "Rehab v1")
    completed_at = Time.utc(2026, 5, 5, 12, 0)
    @user.workouts.create!(
      program: program,
      program_title: program.title,
      exercises_data: [],
      completed_at: completed_at
    )

    heatmap = WorkoutHeatmap.new(@user, today: @today)
    cell = heatmap.weeks.flatten.find { |c| c.date == Date.new(2026, 5, 5) }

    assert_not_nil cell.workout
    assert_equal WorkoutHeatmap::PALETTE[0], cell.color
    assert_equal "Rehab v1", cell.program_title
  end

  test "orphan workouts (deleted program) get the orphan color" do
    program = @user.programs.create!(title: "Old")
    @user.workouts.create!(
      program: program,
      program_title: program.title,
      exercises_data: [],
      completed_at: Time.utc(2026, 5, 5, 12, 0)
    )
    program.destroy! # workouts.program_id becomes nil via FK on_delete: :nullify

    heatmap = WorkoutHeatmap.new(@user, today: @today)
    cell = heatmap.weeks.flatten.find { |c| c.date == Date.new(2026, 5, 5) }

    assert_not_nil cell.workout
    assert_equal WorkoutHeatmap::ORPHAN_COLOR, cell.color
  end

  test "ignores workouts without completed_at" do
    program = @user.programs.create!(title: "P")
    @user.workouts.create!(
      program: program,
      program_title: program.title,
      exercises_data: [],
      completed_at: nil
    )

    heatmap = WorkoutHeatmap.new(@user, today: @today)
    assert_equal false, heatmap.any_workouts?
  end

  test "ignores workouts outside the visible window" do
    program = @user.programs.create!(title: "P")
    @user.workouts.create!(
      program: program,
      program_title: program.title,
      exercises_data: [],
      completed_at: Time.utc(2025, 1, 1, 12, 0) # well over 12 weeks ago
    )

    heatmap = WorkoutHeatmap.new(@user, today: @today)
    assert_equal false, heatmap.any_workouts?
  end

  test "when multiple workouts on same day, latest completed_at wins" do
    program_a = @user.programs.create!(title: "A")
    program_b = @user.programs.create!(title: "B")

    @user.workouts.create!(
      program: program_a,
      program_title: "A",
      exercises_data: [],
      completed_at: Time.utc(2026, 5, 5, 8, 0)
    )
    @user.workouts.create!(
      program: program_b,
      program_title: "B",
      exercises_data: [],
      completed_at: Time.utc(2026, 5, 5, 18, 0)
    )

    heatmap = WorkoutHeatmap.new(@user, today: @today)
    cell = heatmap.weeks.flatten.find { |c| c.date == Date.new(2026, 5, 5) }

    assert_equal "B", cell.program_title
    assert_equal WorkoutHeatmap::PALETTE[1], cell.color # second program by creation order
  end

  test "respects user timezone when bucketing workouts to a date" do
    @user.update!(timezone: "Australia/Sydney")
    program = @user.programs.create!(title: "P")

    # 2026-05-05 23:30 Sydney = 2026-05-05 13:30 UTC (Sydney is UTC+10)
    # Should land on 2026-05-05 in Sydney, not 2026-05-06.
    @user.workouts.create!(
      program: program,
      program_title: "P",
      exercises_data: [],
      completed_at: Time.utc(2026, 5, 5, 13, 30)
    )

    heatmap = WorkoutHeatmap.new(@user, today: @today)
    cell = heatmap.weeks.flatten.find { |c| c.date == Date.new(2026, 5, 5) }
    assert_not_nil cell.workout
  end

  test "legend lists only programs visible in window, in creation order" do
    older_program = @user.programs.create!(title: "First")
    newer_program = @user.programs.create!(title: "Second")
    @user.programs.create!(title: "Unused")

    @user.workouts.create!(
      program: newer_program,
      program_title: "Second",
      exercises_data: [],
      completed_at: Time.utc(2026, 5, 5, 12, 0)
    )
    @user.workouts.create!(
      program: older_program,
      program_title: "First",
      exercises_data: [],
      completed_at: Time.utc(2026, 5, 4, 12, 0)
    )

    heatmap = WorkoutHeatmap.new(@user, today: @today)
    titles = heatmap.legend.map { |e| e[:program].title }

    assert_equal ["First", "Second"], titles
    refute_includes titles, "Unused"
  end
end
