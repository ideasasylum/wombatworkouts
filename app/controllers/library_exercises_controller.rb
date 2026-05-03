class LibraryExercisesController < ApplicationController
  before_action :require_authentication
  before_action :set_library_exercise, only: [:edit, :update, :destroy]

  def index
    @library_exercises = current_user.library_exercises.alphabetical
  end

  def edit
  end

  def update
    if @library_exercise.update(library_exercise_params)
      redirect_to library_exercises_path, notice: "Exercise updated"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @library_exercise.destroy
    redirect_to library_exercises_path, notice: "Exercise removed from library"
  end

  private

  def set_library_exercise
    @library_exercise = current_user.library_exercises.find(params[:id])
  end

  def library_exercise_params
    params.require(:library_exercise).permit(:name, :video_url, :description)
  end
end
