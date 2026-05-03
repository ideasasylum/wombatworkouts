module Api
  module V1
    class ProgramsController < Api::BaseController
      before_action :set_program, only: [:show, :update, :destroy]

      def index
        programs = current_user.programs.order(created_at: :desc)
        render json: {
          programs: programs.map do |p|
            {
              uuid: p.uuid,
              title: p.title,
              description: p.description,
              exercise_count: p.exercises.count,
              created_at: p.created_at.iso8601,
              updated_at: p.updated_at.iso8601
            }
          end
        }
      end

      def show
        render json: program_json(@program)
      end

      def create
        attrs = create_params
        exercise_attrs = Array(attrs[:exercises])

        program = current_user.programs.new(attrs.except(:exercises))

        Program.transaction do
          program.save!
          exercise_attrs.each_with_index do |e, i|
            program.exercises.create!(e.to_h.merge(position: i + 1))
          end
        end

        render json: program_json(program.reload), status: :created
      end

      def update
        @program.update!(update_params)
        render json: program_json(@program)
      end

      def destroy
        @program.destroy!
        head :no_content
      end

      private

      def set_program
        @program = current_user.programs.find_by!(uuid: params[:uuid])
      end

      def create_params
        params.permit(:title, :description, exercises: [:name, :repeat_count, :reps, :description, :video_url])
      end

      def update_params
        params.permit(:title, :description)
      end
    end
  end
end
