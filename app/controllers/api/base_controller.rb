module Api
  class BaseController < ActionController::API
    include PersonalAccessTokenAuthentication

    before_action :authenticate_personal_access_token!

    rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
    rescue_from ActiveRecord::RecordInvalid, with: :render_invalid
    rescue_from ActionController::ParameterMissing, with: :render_bad_request

    private

    def render_not_found(*)
      render json: {error: "not_found"}, status: :not_found
    end

    def render_invalid(e)
      render json: {error: "validation_failed", details: e.record.errors.full_messages}, status: :unprocessable_entity
    end

    def render_bad_request(e)
      render json: {error: "bad_request", message: e.message}, status: :bad_request
    end

    def program_json(program)
      {
        uuid: program.uuid,
        title: program.title,
        description: program.description,
        created_at: program.created_at.iso8601,
        updated_at: program.updated_at.iso8601,
        exercises: program.exercises.order(:position).map { |e| exercise_json(e) }
      }
    end

    # If the caller passed duration_seconds but not reps, clear reps so the
    # column default doesn't trip the model's exactly-one validation.
    def normalize_effort(attrs)
      h = attrs.to_h.symbolize_keys
      h[:reps] = nil if h[:duration_seconds].present? && !h.key?(:reps)
      h
    end

    def exercise_json(exercise)
      {
        id: exercise.id,
        name: exercise.name,
        repeat_count: exercise.repeat_count,
        reps: exercise.reps,
        duration_seconds: exercise.duration_seconds,
        description: exercise.description,
        video_url: exercise.video_url,
        position: exercise.position
      }
    end
  end
end
