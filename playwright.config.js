const { defineConfig, devices } = require('@playwright/test');

/**
 * Playwright configuration for Wombat Workouts E2E tests
 * @see https://playwright.dev/docs/test-configuration
 */
module.exports = defineConfig({
  // Test directory location
  testDir: './test/playwright',

  // Run tests in parallel for faster execution
  fullyParallel: true,

  // Fail the build on CI if tests were accidentally left in debug mode
  forbidOnly: !!process.env.CI,

  // Retry on CI only
  retries: process.env.CI ? 2 : 0,

  // Reporter configuration
  reporter: [
    ['html', { outputFolder: 'playwright-report' }],
    ['list']
  ],

  // Shared settings for all tests
  use: {
    // Base URL to use in actions like `await page.goto('/')`
    baseURL: 'http://localhost:3000',

    // Collect trace when retrying the failed test
    trace: 'on-first-retry',

    // Screenshot on failure
    screenshot: 'only-on-failure',

    // Video on failure
    video: 'retain-on-failure',
  },

  // Test timeout (30 seconds per test)
  timeout: 30000,

  // Global setup to prepare authentication
  globalSetup: require.resolve('./test/playwright/global-setup.js'),

  // Configure projects for major browsers and viewports
  projects: [
    {
      name: 'desktop',
      use: {
        ...devices['Desktop Chrome'],
        viewport: { width: 1280, height: 720 },
      },
    },
    {
      name: 'mobile',
      use: {
        ...devices['iPhone SE'],
        viewport: { width: 375, height: 667 },
      },
    },
  ],

  // Run Rails test server before starting the tests
  webServer: {
    command: 'rails server -e test -p 3000',
    url: 'http://localhost:3000',
    timeout: 120000, // 2 minutes
    reuseExistingServer: !process.env.CI,
  },
});
