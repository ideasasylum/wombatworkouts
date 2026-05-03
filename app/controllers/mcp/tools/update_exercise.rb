module Mcp
  module Tools
    class UpdateExercise < Base
      tool_name "update_exercise"
      description "Update one exercise's fields. Pass only the fields you want to change. Changing `position` resequences the other exercises in the program automatically."

      input_schema(
        properties: {
          exercise_id: {type: "integer"},
          name: {type: "string"},
          repeat_count: {type: "integer", minimum: 1},
          description: {type: "string"},
          video_url: {type: "string"},
          position: {type: "integer", minimum: 1}
        },
        required: ["exercise_id"]
      )

      def self.call(exercise_id:, server_context:, name: nil, repeat_count: nil, description: nil, video_url: nil, position: nil)
        safely do
          user = current_user(server_context)
          exercise = find_exercise!(user, exercise_id)
          program = exercise.program

          attrs = {}
          attrs[:name] = name unless name.nil?
          attrs[:repeat_count] = repeat_count unless repeat_count.nil?
          attrs[:description] = description unless description.nil?
          attrs[:video_url] = video_url unless video_url.nil?

          ::Exercise.transaction do
            exercise.update!(attrs) if attrs.any?
            reposition!(program, exercise, position) if position
          end

          text_response(JSON.pretty_generate(program_summary(program.reload)))
        end
      end

      def self.reposition!(program, exercise, new_position)
        max = program.exercises.maximum(:position) || 1
        new_position = new_position.clamp(1, max)
        old_position = exercise.position
        return if new_position == old_position

        if new_position > old_position
          program.exercises.where("position > ? AND position <= ?", old_position, new_position).update_all("position = position - 1")
        else
          program.exercises.where("position >= ? AND position < ?", new_position, old_position).update_all("position = position + 1")
        end
        exercise.update!(position: new_position)
      end
    end
  end
end
