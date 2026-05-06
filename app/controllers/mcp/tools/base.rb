module Mcp
  module Tools
    class Base < ::MCP::Tool
      LIBRARY_NOTE = "Exercises created or modified by this tool live inside the program only and are never added to the user's exercise library."

      SETS_AND_REPS_NOTE = <<~TXT.strip
        SETS, REPS, AND DURATION:
          - `repeat_count` is the number of SETS — how many times the user performs the exercise within the program.
          - `reps` is the number of REPETITIONS PER SET — how many times the movement is performed in a single set. Defaults to 1.
          - `duration_seconds` is an alternative to `reps` for time-based exercises (e.g. a 45-second plank). Set EITHER `reps` OR `duration_seconds`, never both.
          Examples:
            - "3 sets of 10 push-ups" → repeat_count: 3, reps: 10
            - "5 rounds of 1 pull-up each" → repeat_count: 5, reps: 1
            - "4 × 5 deadlifts" → repeat_count: 4, reps: 5
            - "3 × 45-second plank" → repeat_count: 3, duration_seconds: 45
            - "Hold a hollow body for 30 seconds, twice" → repeat_count: 2, duration_seconds: 30
          When in doubt, set `reps: 1` and use `repeat_count` for the round/set count — that matches how single-movement exercises are modeled today. Use `duration_seconds` only when the exercise is fundamentally time-based (holds, carries, timed conditioning intervals) rather than counted.
      TXT
      REPEAT_COUNT_DESC = "Number of SETS (how many times the user performs this exercise in the program). Must be at least 1. See the tool description for sets vs reps guidance."
      REPS_DESC = "Number of REPETITIONS PER SET (how many times the movement is performed in a single set). Optional; defaults to 1 — set explicitly when the exercise has a meaningful per-set rep count. Mutually exclusive with `duration_seconds`. See the tool description for sets vs reps guidance."
      DURATION_SECONDS_DESC = "DURATION PER SET in seconds for time-based exercises (e.g. 45 for a 45-second plank). Mutually exclusive with `reps` — set one or the other, not both. Maximum 86400 (24h)."

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
            reps: exercise.reps,
            duration_seconds: exercise.duration_seconds,
            description: exercise.description,
            video_url: exercise.video_url
          }.compact
        end

        # If the caller passed duration_seconds but didn't pass reps, clear reps so
        # the column default doesn't trip the model's "exactly one of reps /
        # duration_seconds" validation.
        def normalize_effort!(attrs)
          if attrs[:duration_seconds].present? && !attrs.key?(:reps)
            attrs[:reps] = nil
          end
          attrs
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
