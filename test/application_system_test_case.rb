require "test_helper"

# Register custom Playwright driver for Capybara
Capybara.register_driver :wombat_playwright do |app|
  # Use the project-local Playwright CLI (via Yarn) so the browser version
  # matches what `yarn playwright install` downloaded. The default `npx
  # playwright` ignores Yarn 3 PnP and pulls the latest from the registry,
  # which can mismatch the cached browser revision.
  Capybara::Playwright::Driver.new(app,
    browser_type: ENV["PLAYWRIGHT_BROWSER"]&.to_sym || :chromium,
    playwright_cli_executable_path: "yarn playwright",
    headless: (false unless ENV["CI"] || ENV["PLAYWRIGHT_HEADLESS"]))
end

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :wombat_playwright
end
