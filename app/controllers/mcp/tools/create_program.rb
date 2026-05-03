module Mcp
  module Tools
    class CreateProgram < Base
      tool_name "create_program"
      description <<~TXT
        Create a new workout program for the user, optionally with an initial set of exercises. The exercises are created in the order given, with positions assigned starting at 1.

        #{LIBRARY_NOTE}

        Returns the created program with its uuid (use this in later tool calls).
      TXT

      input_schema(
        properties: {
          title: {type: "string", description: "Name of the program (required)."},
          description: {type: "string", description: "Optional longer description."},
          exercises: {
            type: "array",
            description: "Optional initial list of exercises, in the order they should appear.",
            items: {
              type: "object",
              properties: {
                name: {type: "string"},
                repeat_count: {type: "integer", minimum: 1, description: "How many sets/reps/rounds of this exercise."},
                description: {type: "string"},
                video_url: {type: "string"}
              },
              required: ["name", "repeat_count"]
            }
          }
        },
        required: ["title"]
      )

      def self.call(title:, server_context:, description: nil, exercises: [])
        safely do
          user = current_user(server_context)
          program = user.programs.new(title: title, description: description)

          ::Program.transaction do
            program.save!
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
