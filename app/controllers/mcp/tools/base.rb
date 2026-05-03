module Mcp
  module Tools
    class Base < ::MCP::Tool
      LIBRARY_NOTE = "Exercises created or modified by this tool live inside the program only and are never added to the user's exercise library."

      class << self
        def text_response(text)
          ::MCP::Tool::Response.new([{type: "text", text: text}])
        end

        def error_response(text)
          ::MCP::Tool::Response.new([{type: "text", text: "Error: #{text}"}], error: true)
        end

        def current_user(server_context)
          server_context[:current_user] || raise("missing current_user in MCP server_context")
        end

        def find_program!(user, uuid)
          user.programs.find_by!(uuid: uuid)
        end

        def find_exercise!(user, exercise_id)
          ::Exercise.joins(:program).where(programs: {user_id: user.id}).find(exercise_id)
        end

        def program_summary(program)
          {
            uuid: program.uuid,
            title: program.title,
            description: program.description,
            exercises: program.exercises.order(:position).map { |e| exercise_summary(e) }
          }
        end

        def exercise_summary(exercise)
          {
            id: exercise.id,
            position: exercise.position,
            name: exercise.name,
            repeat_count: exercise.repeat_count,
            description: exercise.description,
            video_url: exercise.video_url
          }.compact
        end

        # Wraps the tool body so any expected failure (RecordNotFound, RecordInvalid)
        # becomes a normal error_response rather than a 500.
        def safely
          yield
        rescue ActiveRecord::RecordNotFound
          error_response("not found")
        rescue ActiveRecord::RecordInvalid => e
          error_response(e.record.errors.full_messages.join("; "))
        rescue ArgumentError => e
          error_response(e.message)
        end
      end
    end
  end
end
