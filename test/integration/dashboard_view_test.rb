require "test_helper"

class DashboardViewTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(email: "test@example.com")
  end

  test "should render programs section with programs" do
    sign_in_as(@user)

    @user.programs.create!(title: "Test Program", description: "Test description")

    get dashboard_path
    assert_response :success
    assert_select "h1", text: "Programs"
    assert_select "h3", text: "Test Program"
  end

  test "should render workouts section when workouts exist" do
    sign_in_as(@user)

    program = @user.programs.create!(title: "Test Program")
    @user.workouts.create!(program: program, program_title: "Test Program", exercises_data: [])

    get dashboard_path
    assert_response :success
    assert_select "h2", text: "Recent Workouts"
  end

  test "should show empty state when no programs exist" do
    sign_in_as(@user)

    get dashboard_path
    assert_response :success
    assert_select "h2", text: "Create Your First Program"
  end

  test "should hide workouts section when no workouts exist" do
    sign_in_as(@user)

    get dashboard_path
    assert_response :success
    assert_select "h2", text: "Recent Workouts", count: 0
  end

  test "should show View All Programs link when more than 5 programs" do
    sign_in_as(@user)

    7.times do |i|
      @user.programs.create!(title: "Program #{i}")
    end

    get dashboard_path
    assert_response :success
    assert_select "a[href=?]", programs_path, text: "View All Programs"
  end

  test "should show View All Workouts link when more than 5 workouts" do
    sign_in_as(@user)

    program = @user.programs.create!(title: "Test Program")
    7.times do |i|
      @user.workouts.create!(program: program, program_title: "Test", exercises_data: [])
    end

    get dashboard_path
    assert_response :success
    assert_select "a[href=?]", workouts_path, text: "View All Workouts"
  end

  test "should show Start button on program cards" do
    sign_in_as(@user)

    program = @user.programs.create!(title: "Test Program")

    get dashboard_path
    assert_response :success
    assert_select "a[href=?]", new_workout_path(program_id: program.uuid), text: "Start"
  end
end
