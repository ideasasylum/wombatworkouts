module Mcp
  module Tools
    class GetProgram < Base
      tool_name "get_program"
      description "Fetch one of the user's programs by uuid, including all exercises with their ids and positions. Use the returned exercise ids when calling update_exercise or remove_exercise."

      input_schema(
        properties: {uuid: {type: "string", description: "The program's uuid."}},
        required: ["uuid"]
      )

      def self.call(uuid:, server_context:)
        safely do
          user = current_user(server_context)
          program = find_program!(user, uuid)
          text_response(JSON.pretty_generate(program_summary(program)))
        end
      end
    end
  end
end
