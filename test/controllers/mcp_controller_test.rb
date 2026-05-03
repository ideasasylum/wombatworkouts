require "test_helper"

class McpControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @other_user = users(:two)
    @pat = @user.personal_access_tokens.create!(name: "test")
    @raw_token = @pat.token
    @program = @user.programs.create!(title: "Push", description: "upper")
    @e1 = @program.exercises.create!(name: "Bench", repeat_count: 5, position: 1)
    @e2 = @program.exercises.create!(name: "OHP", repeat_count: 5, position: 2)
  end

  def auth_headers(token = @raw_token)
    {"Authorization" => "Bearer #{token}", "Content-Type" => "application/json"}
  end

  def jsonrpc(method, params = {}, id: SecureRandom.hex(4))
    {jsonrpc: "2.0", id: id, method: method, params: params}.to_json
  end

  def post_mcp(body, headers: auth_headers)
    post "/mcp", params: body, headers: headers
  end

  # Returns the parsed `result` from a tools/call response, asserting it succeeded.
  def call_tool(name, args = {})
    post_mcp jsonrpc("tools/call", {name: name, arguments: args})
    assert_response :ok
    body = JSON.parse(response.body)
    refute body.key?("error"), "JSON-RPC error: #{body["error"]}"
    body["result"]
  end

  def text_from(result)
    result.dig("content", 0, "text")
  end

  test "rejects calls without bearer token" do
    post_mcp jsonrpc("tools/list"), headers: {"Content-Type" => "application/json"}
    assert_response :unauthorized
  end

  test "401 challenge advertises the protected-resource-metadata URL so claude.ai can discover OAuth" do
    post_mcp jsonrpc("tools/list"), headers: {"Content-Type" => "application/json"}
    assert_response :unauthorized
    challenge = response.headers["WWW-Authenticate"]
    assert_match(/Bearer/, challenge)
    assert_includes challenge, %(resource_metadata="#{request.base_url}/.well-known/oauth-protected-resource")
  end

  test "rejects calls with revoked PAT" do
    @pat.revoke!
    post_mcp jsonrpc("tools/list")
    assert_response :unauthorized
  end

  test "rejects garbage token that doesn't match either auth path" do
    post_mcp jsonrpc("tools/list"), headers: auth_headers("not-a-real-token")
    assert_response :unauthorized
  end

  test "OAuth access token with mcp scope and matching audience works" do
    application = Doorkeeper::Application.create!(
      name: "Test client", redirect_uri: "https://example.com/cb",
      scopes: "mcp", confidential: false, created_via_dcr: true
    )
    token = Doorkeeper::AccessToken.create!(
      application: application,
      resource_owner_id: @user.id,
      scopes: "mcp",
      resource: "http://www.example.com/mcp",
      expires_in: 3600
    )

    post_mcp jsonrpc("tools/list"), headers: auth_headers(token.token)
    assert_response :ok
  end

  test "OAuth token with mismatched resource is rejected" do
    application = Doorkeeper::Application.create!(
      name: "Test client", redirect_uri: "https://example.com/cb",
      scopes: "mcp", confidential: false, created_via_dcr: true
    )
    token = Doorkeeper::AccessToken.create!(
      application: application,
      resource_owner_id: @user.id,
      scopes: "mcp",
      resource: "https://attacker.example/mcp",
      expires_in: 3600
    )

    post_mcp jsonrpc("tools/list"), headers: auth_headers(token.token)
    assert_response :unauthorized
  end

  test "OAuth token without mcp scope is rejected with insufficient_scope" do
    application = Doorkeeper::Application.create!(
      name: "Test client", redirect_uri: "https://example.com/cb",
      scopes: "mcp", confidential: false, created_via_dcr: true
    )
    token = Doorkeeper::AccessToken.create!(
      application: application,
      resource_owner_id: @user.id,
      scopes: "other",
      resource: "http://www.example.com/mcp",
      expires_in: 3600
    )

    post_mcp jsonrpc("tools/list"), headers: auth_headers(token.token)
    assert_response :unauthorized
    assert_match(/insufficient_scope/, response.headers["WWW-Authenticate"])
  end

  test "tools/list returns all 9 tools" do
    post_mcp jsonrpc("tools/list")
    assert_response :ok
    body = JSON.parse(response.body)
    names = body.dig("result", "tools").map { |t| t["name"] }.sort
    assert_equal %w[
      add_exercise create_program delete_program get_program
      list_programs remove_exercise replace_exercises update_exercise update_program
    ], names
  end

  test "list_programs returns the user's programs" do
    text = text_from(call_tool("list_programs"))
    parsed = JSON.parse(text)
    assert_equal ["Push"], parsed.map { |p| p["title"] }
  end

  test "list_programs does not include another user's programs" do
    @other_user.programs.create!(title: "Theirs")
    text = text_from(call_tool("list_programs"))
    titles = JSON.parse(text).map { |p| p["title"] }
    assert_equal ["Push"], titles
  end

  test "get_program returns exercises with ids and positions" do
    text = text_from(call_tool("get_program", uuid: @program.uuid))
    parsed = JSON.parse(text)
    assert_equal 2, parsed["exercises"].size
    assert_equal [@e1.id, @e2.id], parsed["exercises"].map { |e| e["id"] }
  end

  test "get_program for another user's uuid returns an error response" do
    other = @other_user.programs.create!(title: "Theirs")
    result = call_tool("get_program", uuid: other.uuid)
    assert_equal true, result["isError"]
    assert_match(/not found/i, text_from(result))
  end

  test "create_program creates a program with nested exercises" do
    result = call_tool("create_program",
      title: "Pull",
      description: "Back/biceps",
      exercises: [
        {name: "Pull-ups", repeat_count: 3},
        {name: "Rows", repeat_count: 4}
      ])
    parsed = JSON.parse(text_from(result))
    assert_equal "Pull", parsed["title"]
    assert_equal [1, 2], parsed["exercises"].map { |e| e["position"] }
    assert @user.programs.find_by(uuid: parsed["uuid"])
  end

  test "create_program accepts reps and persists it; defaults to 1 when omitted" do
    result = call_tool("create_program",
      title: "Mixed",
      exercises: [
        {name: "Push-ups", repeat_count: 3, reps: 10},
        {name: "Farmer carry", repeat_count: 5}
      ])
    parsed = JSON.parse(text_from(result))
    assert_equal [10, 1], parsed["exercises"].map { |e| e["reps"] }
  end

  test "create_program rejects exercises missing required fields via schema" do
    assert_no_difference -> { Program.where(user: @user).count } do
      post_mcp jsonrpc("tools/call", {
        name: "create_program",
        arguments: {title: "Bad", exercises: [{name: "incomplete"}]}
      })
      body = JSON.parse(response.body)
      assert_equal(-32602, body.dig("error", "code"))
    end
  end

  test "update_program changes the title" do
    call_tool("update_program", uuid: @program.uuid, title: "Push v2")
    assert_equal "Push v2", @program.reload.title
  end

  test "delete_program removes the program" do
    call_tool("delete_program", uuid: @program.uuid)
    assert_nil Program.find_by(uuid: @program.uuid)
  end

  test "add_exercise appends to the end" do
    text = text_from(call_tool("add_exercise",
      program_uuid: @program.uuid,
      name: "Pushup",
      repeat_count: 12))
    parsed = JSON.parse(text)
    names = parsed["exercises"].map { |e| e["name"] }
    assert_equal ["Bench", "OHP", "Pushup"], names
  end

  test "add_exercise accepts reps" do
    text = text_from(call_tool("add_exercise",
      program_uuid: @program.uuid,
      name: "Pushup",
      repeat_count: 3,
      reps: 12))
    parsed = JSON.parse(text)
    pushup = parsed["exercises"].find { |e| e["name"] == "Pushup" }
    assert_equal 3, pushup["repeat_count"]
    assert_equal 12, pushup["reps"]
  end

  test "add_exercise inserts at the given position" do
    call_tool("add_exercise",
      program_uuid: @program.uuid,
      name: "Incline",
      repeat_count: 5,
      position: 2)
    positions = @program.exercises.order(:position).pluck(:name, :position)
    assert_equal [["Bench", 1], ["Incline", 2], ["OHP", 3]], positions
  end

  test "update_exercise changes attributes" do
    call_tool("update_exercise", exercise_id: @e1.id, repeat_count: 8)
    assert_equal 8, @e1.reload.repeat_count
  end

  test "update_exercise can change reps independently of repeat_count" do
    call_tool("update_exercise", exercise_id: @e1.id, reps: 7)
    @e1.reload
    assert_equal 7, @e1.reps
    assert_equal 5, @e1.repeat_count
  end

  test "update_exercise repositions and resequences" do
    call_tool("update_exercise", exercise_id: @e1.id, position: 2)
    positions = @program.exercises.order(:position).pluck(:name, :position)
    assert_equal [["OHP", 1], ["Bench", 2]], positions
  end

  test "update_exercise on another user's exercise returns an error" do
    other = @other_user.programs.create!(title: "Theirs")
    their_ex = other.exercises.create!(name: "X", repeat_count: 1, position: 1)
    result = call_tool("update_exercise", exercise_id: their_ex.id, name: "hax")
    assert_equal true, result["isError"]
    assert_equal "X", their_ex.reload.name
  end

  test "remove_exercise resequences trailing positions" do
    @program.exercises.create!(name: "Dips", repeat_count: 8, position: 3)
    call_tool("remove_exercise", exercise_id: @e1.id)
    positions = @program.exercises.order(:position).pluck(:name, :position)
    assert_equal [["OHP", 1], ["Dips", 2]], positions
  end

  test "replace_exercises atomically swaps the exercise list" do
    text = text_from(call_tool("replace_exercises",
      program_uuid: @program.uuid,
      exercises: [
        {name: "Squat", repeat_count: 5},
        {name: "Lunge", repeat_count: 10}
      ]))
    parsed = JSON.parse(text)
    assert_equal ["Squat", "Lunge"], parsed["exercises"].map { |e| e["name"] }
    assert_nil Exercise.find_by(id: @e1.id)
    assert_nil Exercise.find_by(id: @e2.id)
  end

  test "create_program accepts duration_seconds and clears reps" do
    result = call_tool("create_program",
      title: "Hold",
      exercises: [
        {name: "Plank", repeat_count: 3, duration_seconds: 45}
      ])
    parsed = JSON.parse(text_from(result))
    plank = parsed["exercises"].first
    assert_equal 45, plank["duration_seconds"]
    assert_nil plank["reps"]
  end

  test "add_exercise accepts duration_seconds" do
    text = text_from(call_tool("add_exercise",
      program_uuid: @program.uuid,
      name: "Plank",
      repeat_count: 3,
      duration_seconds: 30))
    parsed = JSON.parse(text)
    plank = parsed["exercises"].find { |e| e["name"] == "Plank" }
    assert_equal 30, plank["duration_seconds"]
    assert_nil plank["reps"]
  end

  test "update_exercise can switch reps to duration" do
    @e1.update!(reps: 10)
    call_tool("update_exercise", exercise_id: @e1.id, duration_seconds: 60)
    @e1.reload
    assert_equal 60, @e1.duration_seconds
    assert_nil @e1.reps
  end

  test "replace_exercises persists per-item reps" do
    text = text_from(call_tool("replace_exercises",
      program_uuid: @program.uuid,
      exercises: [
        {name: "Squat", repeat_count: 3, reps: 8},
        {name: "Lunge", repeat_count: 5}
      ]))
    parsed = JSON.parse(text)
    assert_equal [8, 1], parsed["exercises"].map { |e| e["reps"] }
  end

  test "successful tool calls bump the token's last_used_at" do
    assert_nil @pat.last_used_at
    call_tool("list_programs")
    assert_not_nil @pat.reload.last_used_at
  end

  # Load-bearing invariant: MCP write tools never add to the personal exercise
  # library. Asserted per-tool so a regression is pinned to the offender.
  test "no MCP write tool adds to the user's exercise library" do
    @user.library_exercises.create!(name: "Existing library item")

    assert_no_difference -> { LibraryExercise.count }, "create_program polluted the library" do
      call_tool("create_program",
        title: "Pull",
        exercises: [{name: "Pull-up", repeat_count: 3}, {name: "Row", repeat_count: 5}])
    end

    assert_no_difference -> { LibraryExercise.count }, "update_program polluted the library" do
      call_tool("update_program", uuid: @program.uuid, title: "Push v2", description: "new")
    end

    assert_no_difference -> { LibraryExercise.count }, "add_exercise polluted the library" do
      call_tool("add_exercise", program_uuid: @program.uuid, name: "Pushup", repeat_count: 12)
    end

    assert_no_difference -> { LibraryExercise.count }, "update_exercise polluted the library" do
      call_tool("update_exercise", exercise_id: @e1.id, name: "Bench Press", repeat_count: 8)
    end

    assert_no_difference -> { LibraryExercise.count }, "remove_exercise polluted the library" do
      call_tool("remove_exercise", exercise_id: @e2.id)
    end

    assert_no_difference -> { LibraryExercise.count }, "replace_exercises polluted the library" do
      call_tool("replace_exercises",
        program_uuid: @program.uuid,
        exercises: [{name: "Squat", repeat_count: 5}, {name: "Lunge", repeat_count: 10}])
    end

    assert_no_difference -> { LibraryExercise.count }, "delete_program polluted the library" do
      call_tool("delete_program", uuid: @program.uuid)
    end
  end
end
