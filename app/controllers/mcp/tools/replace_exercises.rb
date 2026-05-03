module Mcp
  module Tools
    class ReplaceExercises < Base
      tool_name "replace_exercises"
      description <<~TXT
        DESTRUCTIVE. Atomically replace ALL exercises in a program with a new list. Existing exercises are deleted and the supplied ones are created in order with positions starting at 1. Past workouts that referenced the old exercises are unaffected (they keep their own snapshot).

        Use this when restructuring a program rather than diffing it manually. Always confirm with the user first.

        #{LIBRARY_NOTE}
      TXT

      input_schema(
        properties: {
          program_uuid: {type: "string"},
          exercises: {
            type: "array",
            items: {
              type: "object",
              properties: {
                name: {type: "string"},
                repeat_count: {type: "integer", minimum: 1},
                description: {type: "string"},
                video_url: {type: "string"}
              },
              required: ["name", "repeat_count"]
            }
          }
        },
        required: ["program_uuid", "exercises"]
      )

      def self.call(program_uuid:, exercises:, server_context:)
        safely do
          user = current_user(server_context)
          program = find_program!(user, program_uuid)

          ::Program.transaction do
            program.exercises.destroy_all
            Array(exercises).each_with_index do |attrs, idx|
              attrs = attrs.transform_keys(&:to_sym)
              program.exercises.create!(
                name: attrs[:name],
                repeat_count: attrs[:repeat_count],
                description: attrs[:description],
                video_url: attrs[:video_url],
                position: idx + 1
              )
            end
          end

          text_response(JSON.pretty_generate(program_summary(program.reload)))
        end
      end
    end
  end
end
