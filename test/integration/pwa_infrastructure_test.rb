require "test_helper"

class PwaInfrastructureTest < ActionDispatch::IntegrationTest
  # Test 1: PWA manifest loads successfully with correct content type
  test "manifest loads successfully with correct content type" do
    get "/manifest.json"
    assert_response :success
    assert_equal "application/json", response.media_type

    manifest = JSON.parse(response.body)
    assert_equal "Wombat Workouts", manifest["name"]
    assert_equal "Wombat Workouts", manifest["short_name"]
    assert_equal "standalone", manifest["display"]
    assert_equal "/", manifest["start_url"]
  end

  # Test 2: Manifest includes required icons
  test "manifest includes required PWA icons" do
    get "/manifest.json"
    assert_response :success

    manifest = JSON.parse(response.body)
    icons = manifest["icons"]

    assert icons.is_a?(Array), "Icons should be an array"
    assert icons.length >= 2, "Should have at least 2 icon sizes"

    # Check for 192x192 icon
    icon_192 = icons.find { |icon| icon["sizes"] == "192x192" }
    assert_not_nil icon_192, "Should have 192x192 icon"
    assert_equal "/icon-192.png", icon_192["src"]

    # Check for 512x512 icon
    icon_512 = icons.find { |icon| icon["sizes"] == "512x512" }
    assert_not_nil icon_512, "Should have 512x512 icon"
    assert_equal "/icon-512.png", icon_512["src"]
  end

  # Test 3: Service worker file is accessible
  test "service worker file is accessible" do
    get "/service-worker.js"
    assert_response :success

    # Accept both text/javascript and application/javascript MIME types
    assert_includes ["text/javascript", "application/javascript"], response.media_type,
      "Service worker should have JavaScript MIME type"

    # Verify service worker contains expected event listeners
    assert_includes response.body, "addEventListener('install'"
    assert_includes response.body, "addEventListener('push'"
    assert_includes response.body, "addEventListener('notificationclick'"
  end

  # Test 4: Offline page is accessible
  test "offline page is accessible" do
    get "/offline.html"
    assert_response :success
    assert_equal "text/html", response.media_type

    # Verify offline page contains expected content
    assert_includes response.body, "You're Offline"
    assert_includes response.body, "Wombat Workouts"
  end

  # Test 5: Application layout includes manifest link
  test "application layout includes PWA manifest link" do
    # Create a user to access a page
    User.create!(email: "test@example.com")

    # Visit a page that uses the application layout
    get root_path

    assert_response :success
    assert_select "link[rel='manifest']" do |elements|
      assert elements.any?, "Should have a manifest link tag"
      manifest_link = elements.first
      assert_equal "/manifest.json", manifest_link["href"]
    end
  end

  # Test 6: Application layout includes service worker registration script
  test "application layout includes service worker registration" do
    get root_path
    assert_response :success

    # Check that the page includes service worker registration code
    assert_includes response.body, "serviceWorker.register"
    assert_includes response.body, "/service-worker.js"
  end

  # Test 7: Icon files exist and are accessible
  test "PWA icon files are accessible" do
    # Test 192x192 icon
    get "/icon-192.png"
    assert_response :success
    assert_equal "image/png", response.media_type

    # Test 512x512 icon
    get "/icon-512.png"
    assert_response :success
    assert_equal "image/png", response.media_type

    # Test apple-touch-icon
    get "/apple-touch-icon.png"
    assert_response :success
    assert_equal "image/png", response.media_type
  end

  # Test 8: Manifest theme color matches app design
  test "manifest theme color matches app branding" do
    get "/manifest.json"
    assert_response :success

    manifest = JSON.parse(response.body)

    # Verify theme colors are set
    assert_not_nil manifest["theme_color"], "Theme color should be set"
    assert_not_nil manifest["background_color"], "Background color should be set"

    # Verify colors match app design (brown wombat theme)
    assert_equal "#8b7355", manifest["theme_color"]
    assert_equal "#edf2f7", manifest["background_color"]
  end
end
