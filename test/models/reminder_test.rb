# == Schema Information
#
# Table name: reminders
#
#  id           :integer          not null, primary key
#  days_of_week :text             not null
#  enabled      :boolean          default(TRUE), not null
#  last_sent_at :datetime
#  time         :time             not null
#  timezone     :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  program_id   :integer          not null
#  user_id      :integer          not null
#
require "test_helper"

class ReminderTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @program = programs(:strength_program)
  end

  test "should be valid with all required fields" do
    reminder = Reminder.new(
      user: @user,
      program: @program,
      days_of_week: ["monday", "wednesday", "friday"],
      time: "09:00:00",
      timezone: "America/New_York"
    )
    assert reminder.valid?
  end

  test "should require days_of_week not to be nil" do
    reminder = Reminder.new(
      user: @user,
      program: @program,
      time: "09:00:00",
      timezone: "America/New_York"
    )
    assert_not reminder.valid?
    assert_includes reminder.errors[:days_of_week], "must include at least one day"
  end

  test "should require at least one day in days_of_week" do
    reminder = Reminder.new(
      user: @user,
      program: @program,
      days_of_week: [],
      time: "09:00:00",
      timezone: "America/New_York"
    )
    assert_not reminder.valid?
    assert_includes reminder.errors[:days_of_week], "must include at least one day"
  end

  test "should validate days_of_week contains valid day names" do
    reminder = Reminder.new(
      user: @user,
      program: @program,
      days_of_week: ["monday", "invalid_day"],
      time: "09:00:00",
      timezone: "America/New_York"
    )
    assert_not reminder.valid?
    assert_includes reminder.errors[:days_of_week], "contains invalid day names"
  end

  test "should require time" do
    reminder = Reminder.new(
      user: @user,
      program: @program,
      days_of_week: ["monday"],
      timezone: "America/New_York"
    )
    assert_not reminder.valid?
    assert_includes reminder.errors[:time], "can't be blank"
  end

  test "should require timezone" do
    reminder = Reminder.new(
      user: @user,
      program: @program,
      days_of_week: ["monday"],
      time: "09:00:00"
    )
    assert_not reminder.valid?
    assert_includes reminder.errors[:timezone], "can't be blank"
  end

  test "should validate timezone is valid" do
    reminder = Reminder.new(
      user: @user,
      program: @program,
      days_of_week: ["monday"],
      time: "09:00:00",
      timezone: "Invalid/Timezone"
    )
    assert_not reminder.valid?
    assert_includes reminder.errors[:timezone], "is not a valid timezone"
  end

  test "should belong to user and program" do
    reminder = Reminder.create!(
      user: @user,
      program: @program,
      days_of_week: ["monday"],
      time: "09:00:00",
      timezone: "America/New_York"
    )
    assert_equal @user, reminder.user
    assert_equal @program, reminder.program
  end

  test "should default enabled to true" do
    reminder = Reminder.create!(
      user: @user,
      program: @program,
      days_of_week: ["monday"],
      time: "09:00:00",
      timezone: "America/New_York"
    )
    assert reminder.enabled?
  end

  test "enabled scope should return only enabled reminders" do
    enabled_reminder = Reminder.create!(
      user: @user,
      program: @program,
      days_of_week: ["monday"],
      time: "09:00:00",
      timezone: "America/New_York",
      enabled: true
    )

    disabled_reminder = Reminder.create!(
      user: @user,
      program: programs(:cardio_program),
      days_of_week: ["tuesday"],
      time: "10:00:00",
      timezone: "America/New_York",
      enabled: false
    )

    enabled_reminders = Reminder.enabled
    assert_includes enabled_reminders, enabled_reminder
    assert_not_includes enabled_reminders, disabled_reminder
  end
end
