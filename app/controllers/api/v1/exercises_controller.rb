module Api
  module V1
    class ExercisesController < Api::BaseController
      before_action :set_program, only: [:create]
      before_action :set_exercise, only: [:update, :destroy]

      def create
        attrs = exercise_params
        requested_position = attrs.delete(:position)&.to_i
        max_position = @program.exercises.maximum(:position) || 0

        @program.with_lock do
          if requested_position && requested_position.between?(1, max_position)
            @program.exercises.where("position >= ?", requested_position).update_all("position = position + 1")
            position = requested_position
          else
            position = max_position + 1
          end

          @exercise = @program.exercises.create!(attrs.merge(position: position))
        end

        render json: exercise_json(@exercise), status: :created
      end

      def update
        attrs = update_params
        new_position = attrs.delete(:position)&.to_i

        Exercise.transaction do
          @exercise.update!(attrs) if attrs.to_h.any?
          reposition!(new_position) if new_position
        end

        render json: exercise_json(@exercise.reload)
      end

      def destroy
        position = @exercise.position
        program = @exercise.program

        Exercise.transaction do
          @exercise.destroy!
          program.exercises.where("position > ?", position).update_all("position = position - 1")
        end

        head :no_content
      end

      private

      def set_program
        @program = current_user.programs.find_by!(uuid: params[:program_uuid])
      end

      def set_exercise
        @exercise = Exercise.joins(:program).where(programs: {user_id: current_user.id}).find(params[:id])
      end

      def exercise_params
        params.permit(:name, :repeat_count, :description, :video_url, :position)
      end

      def update_params
        params.permit(:name, :repeat_count, :description, :video_url, :position)
      end

      def reposition!(new_position)
        program = @exercise.program
        max = program.exercises.maximum(:position) || 1
        new_position = new_position.clamp(1, max)
        old_position = @exercise.position
        return if new_position == old_position

        if new_position > old_position
          program.exercises.where("position > ? AND position <= ?", old_position, new_position).update_all("position = position - 1")
        else
          program.exercises.where("position >= ? AND position < ?", new_position, old_position).update_all("position = position + 1")
        end

        @exercise.update!(position: new_position)
      end
    end
  end
end
