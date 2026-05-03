module Mcp
  module Tools
    class AddExercise < Base
      tool_name "add_exercise"
      description <<~TXT
        Add a single exercise to an existing program. By default the exercise is appended to the end. Pass `position` (1-indexed) to insert it earlier; existing exercises at and after that position will shift down by one.

        #{LIBRARY_NOTE}
      TXT

      input_schema(
        properties: {
          program_uuid: {type: "string"},
          name: {type: "string"},
          repeat_count: {type: "integer", minimum: 1},
          description: {type: "string"},
          video_url: {type: "string"},
          position: {type: "integer", minimum: 1, description: "Optional 1-indexed position to insert at. Defaults to the end."}
        },
        required: ["program_uuid", "name", "repeat_count"]
      )

      def self.call(program_uuid:, name:, repeat_count:, description: nil, video_url: nil, position: nil, server_context:)
        safely do
          user = current_user(server_context)
          program = find_program!(user, program_uuid)

          exercise = nil
          program.with_lock do
            max_position = program.exercises.maximum(:position) || 0
            target = if position && position.between?(1, max_position)
              program.exercises.where("position >= ?", position).update_all("position = position + 1")
              position
            else
              max_position + 1
            end

            exercise = program.exercises.create!(
              name: name,
              repeat_count: repeat_count,
              description: description,
              video_url: video_url,
              position: target
            )
          end

          text_response(JSON.pretty_generate(program_summary(program.reload)))
        end
      end
    end
  end
end
