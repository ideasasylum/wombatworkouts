require "test_helper"

module Api
  module V1
    class ProgramsControllerTest < ActionDispatch::IntegrationTest
      setup do
        @user = users(:one)
        @other_user = users(:two)
        @pat = @user.personal_access_tokens.create!(name: "test")
        @raw_token = @pat.token
        @program = @user.programs.create!(title: "Push Day", description: "Upper body")
        @program.exercises.create!(name: "Bench", repeat_count: 5, position: 1)
      end

      def auth_headers(token = @raw_token)
        {"Authorization" => "Bearer #{token}", "Content-Type" => "application/json"}
      end

      test "rejects request without Authorization header" do
        get "/api/v1/programs"
        assert_response :unauthorized
        assert_equal "unauthorized", JSON.parse(response.body)["error"]
        assert_match(/Bearer/, response.headers["WWW-Authenticate"])
      end

      test "rejects unknown bearer token" do
        get "/api/v1/programs", headers: {"Authorization" => "Bearer wwp_nope"}
        assert_response :unauthorized
      end

      test "rejects revoked token" do
        @pat.revoke!
        get "/api/v1/programs", headers: auth_headers
        assert_response :unauthorized
      end

      test "index returns the user's programs" do
        get "/api/v1/programs", headers: auth_headers
        assert_response :ok
        body = JSON.parse(response.body)
        assert_equal 1, body["programs"].size
        assert_equal "Push Day", body["programs"].first["title"]
        assert_equal 1, body["programs"].first["exercise_count"]
      end

      test "index does not include other users' programs" do
        @other_user.programs.create!(title: "Secret")
        get "/api/v1/programs", headers: auth_headers
        body = JSON.parse(response.body)
        assert_equal ["Push Day"], body["programs"].map { |p| p["title"] }
      end

      test "show returns full program with exercises" do
        get "/api/v1/programs/#{@program.uuid}", headers: auth_headers
        assert_response :ok
        body = JSON.parse(response.body)
        assert_equal @program.uuid, body["uuid"]
        assert_equal 1, body["exercises"].size
        assert_equal "Bench", body["exercises"].first["name"]
      end

      test "show returns 404 for another user's program" do
        other = @other_user.programs.create!(title: "Theirs")
        get "/api/v1/programs/#{other.uuid}", headers: auth_headers
        assert_response :not_found
      end

      test "create with no exercises" do
        post "/api/v1/programs",
          params: {title: "Leg Day"}.to_json,
          headers: auth_headers
        assert_response :created
        body = JSON.parse(response.body)
        assert_equal "Leg Day", body["title"]
        assert_equal [], body["exercises"]
      end

      test "create with nested exercises is atomic and assigns positions" do
        post "/api/v1/programs",
          params: {
            title: "Pull Day",
            description: "Back & biceps",
            exercises: [
              {name: "Pull-ups", repeat_count: 3, reps: 8},
              {name: "Rows", repeat_count: 4, reps: 10, description: "barbell"}
            ]
          }.to_json,
          headers: auth_headers
        assert_response :created
        body = JSON.parse(response.body)
        assert_equal 2, body["exercises"].size
        assert_equal [1, 2], body["exercises"].map { |e| e["position"] }
        assert_equal ["Pull-ups", "Rows"], body["exercises"].map { |e| e["name"] }
        assert_equal [8, 10], body["exercises"].map { |e| e["reps"] }
      end

      test "create rolls back the program if a nested exercise is invalid" do
        assert_no_difference -> { Program.count } do
          post "/api/v1/programs",
            params: {
              title: "Bad",
              exercises: [
                {name: "OK", repeat_count: 3},
                {name: "Missing reps"}
              ]
            }.to_json,
            headers: auth_headers
        end
        assert_response :unprocessable_entity
        body = JSON.parse(response.body)
        assert_equal "validation_failed", body["error"]
      end

      test "create returns 422 with validation errors on missing title" do
        post "/api/v1/programs", params: {description: "no title"}.to_json, headers: auth_headers
        assert_response :unprocessable_entity
        assert_equal "validation_failed", JSON.parse(response.body)["error"]
      end

      test "update changes title and description" do
        patch "/api/v1/programs/#{@program.uuid}",
          params: {title: "Push Day v2"}.to_json,
          headers: auth_headers
        assert_response :ok
        assert_equal "Push Day v2", @program.reload.title
      end

      test "update returns 404 for another user's program" do
        other = @other_user.programs.create!(title: "Theirs")
        patch "/api/v1/programs/#{other.uuid}", params: {title: "Hax"}.to_json, headers: auth_headers
        assert_response :not_found
        assert_equal "Theirs", other.reload.title
      end

      test "destroy removes the program and its exercises" do
        delete "/api/v1/programs/#{@program.uuid}", headers: auth_headers
        assert_response :no_content
        assert_nil Program.find_by(uuid: @program.uuid)
      end

      test "destroy returns 404 for another user's program" do
        other = @other_user.programs.create!(title: "Theirs")
        delete "/api/v1/programs/#{other.uuid}", headers: auth_headers
        assert_response :not_found
      end

      test "successful auth bumps last_used_at on the token" do
        assert_nil @pat.last_used_at
        get "/api/v1/programs", headers: auth_headers
        assert_not_nil @pat.reload.last_used_at
      end

      test "create with nested exercises does not add to the user's exercise library" do
        @user.library_exercises.create!(name: "Existing")
        assert_no_difference -> { LibraryExercise.count } do
          post "/api/v1/programs",
            params: {title: "Pull", exercises: [{name: "Pull-up", repeat_count: 3}]}.to_json,
            headers: auth_headers
        end
      end
    end
  end
end
