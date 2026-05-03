class McpController < ActionController::API
  include McpAuthentication

  before_action :authenticate_mcp!

  def handle
    server = MCP::Server.new(
      name: "wombat-workouts",
      title: "Wombat Workouts",
      version: "0.1.0",
      instructions: <<~TXT,
        Tools for managing the user's workout programs in Wombat Workouts.

        A program is a named sequence of exercises that the user works through during a workout. Each exercise belongs to a single program; exercises created or modified through these tools are NOT added to the user's separate exercise library.

        Always summarize destructive changes (delete_program, remove_exercise, replace_exercises) to the user before calling them.
      TXT
      tools: [
        Mcp::Tools::ListPrograms,
        Mcp::Tools::GetProgram,
        Mcp::Tools::CreateProgram,
        Mcp::Tools::UpdateProgram,
        Mcp::Tools::DeleteProgram,
        Mcp::Tools::AddExercise,
        Mcp::Tools::UpdateExercise,
        Mcp::Tools::RemoveExercise,
        Mcp::Tools::ReplaceExercises
      ],
      server_context: {current_user: current_user}
    )

    response_json = server.handle_json(request.raw_post)

    if response_json
      render body: response_json, content_type: "application/json"
    else
      head :accepted
    end
  end
end
