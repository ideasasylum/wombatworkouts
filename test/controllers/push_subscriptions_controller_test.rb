require "test_helper"

class PushSubscriptionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @other_user = users(:two)
  end

  test "create requires authentication" do
    post push_subscriptions_path, params: {
      push_subscription: {
        endpoint: "https://fcm.googleapis.com/fcm/send/test",
        p256dh_key: "test_p256dh_key",
        auth_key: "test_auth_key"
      }
    }
    assert_redirected_to signin_path
  end

  test "authenticated user can create push subscription" do
    sign_in_as(@user)

    assert_difference("PushSubscription.count", 1) do
      post push_subscriptions_path, params: {
        push_subscription: {
          endpoint: "https://fcm.googleapis.com/fcm/send/test",
          p256dh_key: "test_p256dh_key",
          auth_key: "test_auth_key"
        }
      }
    end

    subscription = PushSubscription.last
    assert_equal @user.id, subscription.user_id
    assert_equal "https://fcm.googleapis.com/fcm/send/test", subscription.endpoint
    assert_response :created
  end

  test "destroy requires authentication" do
    subscription = @user.push_subscriptions.create!(
      endpoint: "https://fcm.googleapis.com/fcm/send/test",
      p256dh_key: "test_key",
      auth_key: "test_auth"
    )

    delete push_subscription_path(subscription)
    assert_redirected_to signin_path
  end

  test "user can only delete their own subscriptions" do
    sign_in_as(@user)
    other_subscription = @other_user.push_subscriptions.create!(
      endpoint: "https://fcm.googleapis.com/fcm/send/test",
      p256dh_key: "test_key",
      auth_key: "test_auth"
    )

    assert_no_difference("PushSubscription.count") do
      delete push_subscription_path(other_subscription)
    end

    assert_response :not_found
  end
end
