module Mcp
  module Tools
    class RemoveExercise < Base
      tool_name "remove_exercise"
      description "DESTRUCTIVE. Remove a single exercise from a program. Trailing exercises shift up to fill the gap. Confirm with the user before calling."

      input_schema(
        properties: {exercise_id: {type: "integer"}},
        required: ["exercise_id"]
      )

      def self.call(exercise_id:, server_context:)
        safely do
          user = current_user(server_context)
          exercise = find_exercise!(user, exercise_id)
          program = exercise.program
          position = exercise.position

          ::Exercise.transaction do
            exercise.destroy!
            program.exercises.where("position > ?", position).update_all("position = position - 1")
          end

          text_response(JSON.pretty_generate(program_summary(program.reload)))
        end
      end
    end
  end
end
