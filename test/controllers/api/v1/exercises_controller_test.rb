require "test_helper"

module Api
  module V1
    class ExercisesControllerTest < ActionDispatch::IntegrationTest
      setup do
        @user = users(:one)
        @other_user = users(:two)
        @pat = @user.personal_access_tokens.create!(name: "test")
        @raw_token = @pat.token
        @program = @user.programs.create!(title: "Push")
        @e1 = @program.exercises.create!(name: "Bench", repeat_count: 5, position: 1)
        @e2 = @program.exercises.create!(name: "OHP", repeat_count: 5, position: 2)
        @e3 = @program.exercises.create!(name: "Dips", repeat_count: 8, position: 3)
      end

      def auth_headers(token = @raw_token)
        {"Authorization" => "Bearer #{token}", "Content-Type" => "application/json"}
      end

      test "create appends an exercise by default" do
        post "/api/v1/programs/#{@program.uuid}/exercises",
          params: {name: "Pushup", repeat_count: 12}.to_json,
          headers: auth_headers
        assert_response :created
        body = JSON.parse(response.body)
        assert_equal 4, body["position"]
      end

      test "create with explicit position shifts existing exercises" do
        post "/api/v1/programs/#{@program.uuid}/exercises",
          params: {name: "Incline", repeat_count: 5, position: 2}.to_json,
          headers: auth_headers
        assert_response :created
        body = JSON.parse(response.body)
        assert_equal 2, body["position"]

        positions = @program.exercises.order(:position).pluck(:name, :position)
        assert_equal [["Bench", 1], ["Incline", 2], ["OHP", 3], ["Dips", 4]], positions
      end

      test "create rejects creating in another user's program" do
        other = @other_user.programs.create!(title: "Theirs")
        post "/api/v1/programs/#{other.uuid}/exercises",
          params: {name: "X", repeat_count: 1}.to_json,
          headers: auth_headers
        assert_response :not_found
      end

      test "create returns 422 on validation error" do
        post "/api/v1/programs/#{@program.uuid}/exercises",
          params: {name: "no reps"}.to_json,
          headers: auth_headers
        assert_response :unprocessable_entity
      end

      test "update changes attributes" do
        patch "/api/v1/exercises/#{@e1.id}",
          params: {name: "Bench v2", repeat_count: 8}.to_json,
          headers: auth_headers
        assert_response :ok
        @e1.reload
        assert_equal "Bench v2", @e1.name
        assert_equal 8, @e1.repeat_count
      end

      test "update can move an exercise down (resequences others)" do
        patch "/api/v1/exercises/#{@e1.id}",
          params: {position: 3}.to_json,
          headers: auth_headers
        assert_response :ok
        positions = @program.exercises.order(:position).pluck(:name, :position)
        assert_equal [["OHP", 1], ["Dips", 2], ["Bench", 3]], positions
      end

      test "update can move an exercise up (resequences others)" do
        patch "/api/v1/exercises/#{@e3.id}",
          params: {position: 1}.to_json,
          headers: auth_headers
        assert_response :ok
        positions = @program.exercises.order(:position).pluck(:name, :position)
        assert_equal [["Dips", 1], ["Bench", 2], ["OHP", 3]], positions
      end

      test "update on another user's exercise returns 404" do
        other = @other_user.programs.create!(title: "Theirs")
        their_ex = other.exercises.create!(name: "X", repeat_count: 1, position: 1)
        patch "/api/v1/exercises/#{their_ex.id}", params: {name: "hax"}.to_json, headers: auth_headers
        assert_response :not_found
        assert_equal "X", their_ex.reload.name
      end

      test "destroy removes exercise and resequences trailing positions" do
        delete "/api/v1/exercises/#{@e2.id}", headers: auth_headers
        assert_response :no_content
        positions = @program.exercises.order(:position).pluck(:name, :position)
        assert_equal [["Bench", 1], ["Dips", 2]], positions
      end

      test "destroy on another user's exercise returns 404" do
        other = @other_user.programs.create!(title: "Theirs")
        their_ex = other.exercises.create!(name: "X", repeat_count: 1, position: 1)
        delete "/api/v1/exercises/#{their_ex.id}", headers: auth_headers
        assert_response :not_found
        assert Exercise.exists?(their_ex.id)
      end

      test "no auth header returns 401" do
        post "/api/v1/programs/#{@program.uuid}/exercises", params: {name: "x", repeat_count: 1}.to_json
        assert_response :unauthorized
      end
    end
  end
end
