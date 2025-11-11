# == Schema Information
#
# Table name: push_subscriptions
#
#  id         :integer          not null, primary key
#  auth_key   :text             not null
#  endpoint   :text             not null
#  p256dh_key :text             not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :integer          not null
#
require "test_helper"

class PushSubscriptionTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
  end

  test "should be valid with all required fields" do
    subscription = @user.push_subscriptions.build(
      endpoint: "https://fcm.googleapis.com/fcm/send/test123",
      p256dh_key: "test_p256dh_key",
      auth_key: "test_auth_key"
    )
    assert subscription.valid?
  end

  test "should require endpoint" do
    subscription = @user.push_subscriptions.build(
      p256dh_key: "test_p256dh_key",
      auth_key: "test_auth_key"
    )
    assert_not subscription.valid?
    assert_includes subscription.errors[:endpoint], "can't be blank"
  end

  test "should require endpoint to be HTTPS URL" do
    subscription = @user.push_subscriptions.build(
      endpoint: "http://example.com/push",
      p256dh_key: "test_p256dh_key",
      auth_key: "test_auth_key"
    )
    assert_not subscription.valid?
    assert_includes subscription.errors[:endpoint], "must be an HTTPS URL"
  end

  test "should require p256dh_key" do
    subscription = @user.push_subscriptions.build(
      endpoint: "https://fcm.googleapis.com/fcm/send/test123",
      auth_key: "test_auth_key"
    )
    assert_not subscription.valid?
    assert_includes subscription.errors[:p256dh_key], "can't be blank"
  end

  test "should require auth_key" do
    subscription = @user.push_subscriptions.build(
      endpoint: "https://fcm.googleapis.com/fcm/send/test123",
      p256dh_key: "test_p256dh_key"
    )
    assert_not subscription.valid?
    assert_includes subscription.errors[:auth_key], "can't be blank"
  end

  test "should belong to user" do
    subscription = @user.push_subscriptions.create!(
      endpoint: "https://fcm.googleapis.com/fcm/send/test123",
      p256dh_key: "test_p256dh_key",
      auth_key: "test_auth_key"
    )
    assert_equal @user, subscription.user
  end

  test "should require user association" do
    subscription = PushSubscription.new(
      endpoint: "https://fcm.googleapis.com/fcm/send/test123",
      p256dh_key: "test_p256dh_key",
      auth_key: "test_auth_key"
    )
    assert_not subscription.valid?
    assert_includes subscription.errors[:user], "must exist"
  end
end
