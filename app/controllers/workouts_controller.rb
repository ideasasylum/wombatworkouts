class WorkoutsController < ApplicationController
  before_action :require_authentication
  before_action :set_workout, only: [:show, :destroy, :mark_complete, :skip]

  # GET /workouts
  def index
    @workouts = current_user.workouts.includes(:program).order(updated_at: :desc)
  end

  # GET /workouts/new?program_id=:uuid
  def new
    program = Program.find_by!(uuid: params[:program_id])

    # Task Group 3.2: Auto-duplicate if user doesn't own the program
    if program.user_id != current_user.id
      program = program.duplicate(current_user.id)
    end

    @workout = Workout.new(user: current_user, program: program)
    @workout.initialize_from_program(program)
  end

  # POST /workouts
  def create
    program = Program.find_by!(uuid: params[:program_id])

    # Task Group 3.3: Auto-duplicate if user doesn't own the program
    if program.user_id != current_user.id
      program = program.duplicate(current_user.id)
    end

    @workout = Workout.new(user: current_user, program: program)
    @workout.initialize_from_program(program)

    if @workout.save
      redirect_to workout_path(@workout), notice: "Workout started successfully"
    else
      render :new, status: :unprocessable_entity
    end
  end

  # GET /workouts/:id
  def show
    # Allow viewing a specific exercise via exercise_index parameter
    if params[:exercise_index].present?
      index = params[:exercise_index].to_i
      @current_exercise = @workout.find_exercise_by_index(index)
    else
      @current_exercise = @workout.current_exercise
    end

    @stats = @workout.completion_stats
  end

  # DELETE /workouts/:id
  def destroy
    @workout.destroy
    redirect_to workouts_path, notice: "Workout deleted successfully"
  end

  # PATCH /workouts/:id/mark_complete
  def mark_complete
    exercise_id = params[:exercise_id]
    was_complete_before = @workout.complete?

    if @workout.mark_exercise_complete(exercise_id)
      if @workout.complete? && !was_complete_before
        redirect_to workout_path(@workout), notice: "Workout Complete! 🎉"
      else
        redirect_to workout_path(@workout), notice: "Exercise marked complete"
      end
    else
      redirect_to workout_path(@workout), alert: "Could not mark exercise complete"
    end
  end

  # PATCH /workouts/:id/skip
  def skip
    exercise_id = params[:exercise_id]
    was_complete_before = @workout.complete?

    if @workout.skip_exercise(exercise_id)
      if @workout.complete? && !was_complete_before
        redirect_to workout_path(@workout), notice: "Workout Complete! 🎉"
      else
        redirect_to workout_path(@workout), notice: "Exercise skipped"
      end
    else
      redirect_to workout_path(@workout), alert: "Could not skip exercise"
    end
  end

  private

  def set_workout
    @workout = current_user.workouts.find(params[:id])
  end
end
