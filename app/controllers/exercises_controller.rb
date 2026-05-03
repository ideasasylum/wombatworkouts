class ExercisesController < ApplicationController
  before_action :require_authentication
  before_action :set_program_and_authorize, only: [:new, :create]
  before_action :set_exercise_and_authorize, only: [:show, :edit, :update, :destroy, :move]

  def new
    @library_exercises = current_user.library_exercises.alphabetical

    if params[:library_exercise_id].present?
      library_exercise = current_user.library_exercises.find_by(id: params[:library_exercise_id])
      @exercise = @program.exercises.build(library_exercise&.attributes_for_exercise || {})
      @from_library = library_exercise.present?
    else
      @exercise = @program.exercises.build
      @from_library = false
    end
  end

  def show
    # @exercise and @program are set by before_action
  end

  def edit
    # @exercise and @program are set by before_action
  end

  def create
    @exercise = @program.exercises.build(exercise_params)
    @exercise.position = (@program.exercises.maximum(:position) || 0) + 1
    from_library = params[:from_library] == "1"

    if @exercise.save
      save_to_library(@exercise) unless from_library

      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to @program, notice: "Exercise added successfully" }
      end
    else
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("exercise-form-frame", partial: "exercises/new", locals: {program: @program, exercise: @exercise}) }
        format.html { redirect_to @program, alert: "Failed to add exercise" }
      end
    end
  end

  def update
    if @exercise.update(exercise_params)
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to @exercise.program, notice: "Exercise updated successfully" }
      end
    else
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("exercise-#{@exercise.id}", partial: "exercises/form", locals: {program: @exercise.program, exercise: @exercise}) }
        format.html { redirect_to @exercise.program, alert: "Failed to update exercise" }
      end
    end
  end

  def destroy
    @program = @exercise.program
    @exercise.destroy

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @program, notice: "Exercise deleted successfully" }
    end
  end

  def move
    new_position = params[:position].to_i
    return head :bad_request if new_position < 1

    @program = @exercise.program
    old_position = @exercise.position

    if new_position != old_position
      # Update positions for affected exercises
      if new_position > old_position
        # Moving down: shift exercises between old and new position up
        @program.exercises.where("position > ? AND position <= ?", old_position, new_position).update_all("position = position - 1")
      else
        # Moving up: shift exercises between new and old position down
        @program.exercises.where("position >= ? AND position < ?", new_position, old_position).update_all("position = position + 1")
      end

      @exercise.update(position: new_position)
    end

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.replace("exercises-list", partial: "exercises/list", locals: {program: @program}) }
      format.json { head :ok }
    end
  end

  private

  def set_program_and_authorize
    @program = current_user.programs.find_by!(uuid: params[:program_id])
  end

  def set_exercise_and_authorize
    @exercise = Exercise.find(params[:id])
    @program = @exercise.program

    unless @program.user_id == current_user.id
      redirect_to programs_path, alert: "You don't have permission to access this exercise"
    end
  end

  def exercise_params
    params.require(:exercise).permit(:name, :repeat_count, :video_url, :description, :position)
  end

  def save_to_library(exercise)
    current_user.library_exercises.create(
      name: exercise.name,
      video_url: exercise.video_url,
      description: exercise.description
    )
  end
end
