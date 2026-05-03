module Mcp
  module Tools
    class DeleteProgram < Base
      tool_name "delete_program"
      description "DESTRUCTIVE. Permanently delete a program and all of its exercises. Past workouts started from this program are preserved (program reference is nullified). Always confirm with the user before calling this."

      input_schema(
        properties: {uuid: {type: "string"}},
        required: ["uuid"]
      )

      def self.call(uuid:, server_context:)
        safely do
          user = current_user(server_context)
          program = find_program!(user, uuid)
          program.destroy!
          text_response("Deleted program '#{program.title}' (#{uuid}).")
        end
      end
    end
  end
end
