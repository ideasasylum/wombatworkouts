require "test_helper"

class ProgramsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @other_user = users(:two)
    @program = @user.programs.create!(title: "Test Program", description: "Test description")
    @other_program = @other_user.programs.create!(title: "Other Program")
  end

  test "should redirect to signin when not authenticated" do
    get programs_path
    assert_redirected_to signin_path
    assert_equal "Please sign in to continue", flash[:alert]
  end

  test "index requires authentication" do
    get programs_path
    assert_redirected_to signin_path
  end

  test "new requires authentication" do
    get new_program_path
    assert_redirected_to signin_path
  end

  test "create requires authentication" do
    post programs_path, params: {program: {title: "Test"}}
    assert_redirected_to signin_path
  end

  # Task 1.1: Tests for public program viewing
  test "public user can access program via UUID without authentication" do
    get program_path(@program)
    assert_response :success
    assert_select "h1", text: @program.title
  end

  test "authenticated non-owner can access program via UUID" do
    sign_in_as(@other_user)
    get program_path(@program)
    assert_response :success
    assert_select "h1", text: @program.title
  end

  test "authenticated owner can access their own program via UUID" do
    sign_in_as(@user)
    get program_path(@program)
    assert_response :success
    assert_select "h1", text: @program.title
  end

  test "program not found returns 404" do
    assert_raises(ActiveRecord::RecordNotFound) do
      Program.find_by!(uuid: "nonexistent-uuid")
    end
  end

  # Task 3.1: View rendering tests
  test "owner view shows edit controls and Back to Programs link" do
    sign_in_as(@user)
    get program_path(@program)
    assert_response :success

    # Edit controls present (icon buttons with aria-labels)
    assert_match(/Edit program/, response.body, "Should contain 'Edit program' button")
    assert_match(/Delete program/, response.body, "Should contain 'Delete program' button")
    assert_match(/Add Exercise/, response.body, "Should contain 'Add Exercise' link")

    # Signup CTA not present
    assert_no_match(/Create Your Own Programs/, response.body, "Should not contain signup CTA")
  end

  test "non-authenticated view hides edit controls and signup CTA displays" do
    get program_path(@program)
    assert_response :success

    # Edit controls not present
    assert_no_match(/Edit program/, response.body, "Should not contain 'Edit program' button")
    assert_no_match(/Delete program/, response.body, "Should not contain 'Delete program' button")
    assert_no_match(/Add Exercise/, response.body, "Should not contain 'Add Exercise' link")

    # Signup CTA present
    assert_match(/Create Your Own Programs/, response.body, "Should contain signup CTA heading")
    assert_match(/Sign Up Free/, response.body, "Should contain 'Sign Up Free' link")
  end

  test "authenticated non-owner view hides edit controls" do
    sign_in_as(@other_user)
    get program_path(@program)
    assert_response :success

    # Edit controls not present
    assert_no_match(/Edit program/, response.body, "Should not contain 'Edit program' button")
    assert_no_match(/Delete program/, response.body, "Should not contain 'Delete program' button")
    assert_no_match(/Add Exercise/, response.body, "Should not contain 'Add Exercise' link")

    # Signup CTA not present (authenticated user)
    assert_no_match(/Create Your Own Programs/, response.body, "Should not contain signup CTA")
  end

  test "video embeds render correctly in view" do
    @program.exercises.create!(
      name: "Test Exercise",
      repeat_count: 10,
      position: 1,
      video_url: "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
    )

    get program_path(@program)
    assert_response :success

    # Check for embedded video iframe
    assert_match(/youtube-nocookie\.com\/embed\/dQw4w9WgXcQ/, response.body)
    assert_match(/aspect-video/, response.body)
  end

  test "SEO meta tags are present in head" do
    get program_path(@program)
    assert_response :success

    # Check for title tag
    assert_match(/<title>.*#{@program.title}.*<\/title>/, response.body)

    # Check for meta description
    assert_match(/<meta name="description"/, response.body)

    # Check for Open Graph tags
    assert_match(/<meta property="og:title"/, response.body)
    assert_match(/<meta property="og:description"/, response.body)
    assert_match(/<meta property="og:type"/, response.body)
    assert_match(/<meta property="og:url"/, response.body)

    # Check for Twitter Card tags
    assert_match(/<meta name="twitter:card"/, response.body)
    assert_match(/<meta name="twitter:title"/, response.body)
    assert_match(/<meta name="twitter:description"/, response.body)
  end

  test "edit requires authentication" do
    get edit_program_path(@program)
    assert_redirected_to signin_path
  end

  test "update requires authentication" do
    patch program_path(@program), params: {program: {title: "Updated"}}
    assert_redirected_to signin_path
  end

  test "destroy requires authentication" do
    delete program_path(@program)
    assert_redirected_to signin_path
  end

  # Task Group 2.1: Tests for ProgramsController#duplicate
  test "authenticated user can duplicate non-owned program" do
    sign_in_as(@other_user)

    assert_difference("Program.count", 1) do
      post duplicate_program_path(@program)
    end

    duplicated = Program.last
    assert_equal @program.title, duplicated.title
    assert_equal @program.description, duplicated.description
    assert_equal @other_user.id, duplicated.user_id
    assert_not_equal @program.uuid, duplicated.uuid
  end

  test "duplicate redirects to new copy with flash message" do
    sign_in_as(@other_user)

    post duplicate_program_path(@program)

    duplicated = Program.last
    assert_redirected_to program_path(duplicated)
    follow_redirect!
    assert_equal "Program saved to your library", flash[:notice]
  end

  test "duplicate requires authentication" do
    post duplicate_program_path(@program)
    assert_redirected_to signin_path
  end

  test "duplicate copies all exercises" do
    @program.exercises.create!(name: "Exercise 1", repeat_count: 3, position: 1)
    @program.exercises.create!(name: "Exercise 2", repeat_count: 5, position: 2)

    sign_in_as(@other_user)

    assert_difference("Exercise.count", 2) do
      post duplicate_program_path(@program)
    end

    duplicated = Program.last
    assert_equal 2, duplicated.exercises.count
    assert_equal "Exercise 1", duplicated.exercises.order(:position).first.name
    assert_equal "Exercise 2", duplicated.exercises.order(:position).last.name
  end
end
