require "test_helper"

class DevSessionsControllerTest < ActionDispatch::IntegrationTest
  test "GET /__dev/signin is not routable in test env" do
    assert_raises(ActionController::RoutingError) do
      Rails.application.routes.recognize_path("/__dev/signin", method: :get)
    end
  end

  test "POST /__dev/signin is not routable in test env" do
    assert_raises(ActionController::RoutingError) do
      Rails.application.routes.recognize_path("/__dev/signin", method: :post)
    end
  end

  test "dev_signin_path url helper is not defined in test env" do
    refute Rails.application.routes.url_helpers.respond_to?(:dev_signin_path),
      "dev_signin_path should not exist outside development"
  end
end
