module Mcp
  module Tools
    class ListPrograms < Base
      tool_name "list_programs"
      description "List all of the user's workout programs (uuid, title, description, exercise count). Returns programs ordered by most recently created."

      input_schema(properties: {})

      def self.call(server_context:)
        safely do
          user = current_user(server_context)
          rows = user.programs.order(created_at: :desc).map do |p|
            {uuid: p.uuid, title: p.title, description: p.description, exercise_count: p.exercises.count}
          end
          text_response(JSON.pretty_generate(rows))
        end
      end
    end
  end
end
