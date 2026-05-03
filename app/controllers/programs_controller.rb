class ProgramsController < ApplicationController
  # Task 1.2: Allow public access to show action
  before_action :require_authentication, except: [:show]
  before_action :set_program, only: [:show, :edit, :update, :destroy, :duplicate, :export_garmin]

  def index
    @programs = current_user.programs.order(created_at: :desc)
  end

  def show
    # Task 1.4: Add owner detection logic
    @is_owner = logged_in? && current_user.id == @program.user_id
  end

  def new
    @program = current_user.programs.build
  end

  def create
    @program = current_user.programs.build(program_params)

    if @program.save
      redirect_to program_path(@program), notice: "Program created successfully"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @program.update(program_params)
      redirect_to program_path(@program), notice: "Program updated successfully"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @program.destroy
    redirect_to programs_path, notice: "Program deleted successfully"
  end

  # Task Group 2.2: Manual "Save to My Programs" action
  def duplicate
    @duplicated_program = @program.duplicate(current_user.id)
    redirect_to @duplicated_program, notice: "Program saved to your library"
  rescue
    redirect_to @program, alert: "Unable to save program. Please try again."
  end

  def export_garmin
    unless @program.user_id == current_user.id
      redirect_to programs_path, alert: "You don't have permission to export this program"
      return
    end

    if @program.exercises.empty?
      redirect_to program_path(@program), alert: "Add at least one exercise before exporting"
      return
    end

    data = Garmin::FitEncoder.encode_program(@program)
    send_data data,
      filename: "#{@program.title.parameterize.presence || "workout"}.fit",
      type: "application/vnd.ant.fit",
      disposition: "attachment"
  rescue Garmin::FitEncoder::TooManyStepsError => e
    redirect_to program_path(@program),
      alert: "Garmin Connect supports max #{Garmin::FitEncoder::MAX_STEPS} steps per workout. This program has #{e.step_count}."
  end

  private

  def set_program
    # Task 1.3: Update for public access and eager load exercises
    @program = Program.includes(:exercises).find_by!(uuid: params[:id])
  end

  def program_params
    params.require(:program).permit(:title, :description)
  end
end
