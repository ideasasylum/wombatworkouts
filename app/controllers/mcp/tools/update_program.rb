module Mcp
  module Tools
    class UpdateProgram < Base
      tool_name "update_program"
      description "Rename a program or change its description. Pass only the fields you want to change."

      input_schema(
        properties: {
          uuid: {type: "string"},
          title: {type: "string"},
          description: {type: "string"}
        },
        required: ["uuid"]
      )

      def self.call(uuid:, title: nil, description: nil, server_context:)
        safely do
          user = current_user(server_context)
          program = find_program!(user, uuid)

          attrs = {}
          attrs[:title] = title unless title.nil?
          attrs[:description] = description unless description.nil?
          program.update!(attrs) if attrs.any?

          text_response(JSON.pretty_generate(program_summary(program.reload)))
        end
      end
    end
  end
end
