# Task Breakdown: Notification System (PWA + Flash Messages + Scheduled Reminders)

## Overview
Total Tasks: 5 task groups with 32 sub-tasks

This feature has three main components implemented in strategic order:
1. **Popover Flash Messages** - Standalone enhancement (can be implemented first)
2. **PWA Setup** - Foundation for push notifications (must precede reminders)
3. **Scheduled Reminders** - Requires both database models and PWA infrastructure

## Task List

### Phase 1: Foundation - Flash Messages

#### Task Group 1: Popover Flash Message System
**Dependencies:** None

- [x] 1.0 Complete popover flash message system
  - [x] 1.1 Write 2-8 focused tests for flash message behavior
    - Limit to 2-8 highly focused tests maximum
    - Test only critical behaviors (e.g., rendering notice/alert, auto-dismiss timing, manual close)
    - Skip exhaustive testing of edge cases and multiple message scenarios
  - [x] 1.2 Create Stimulus flash controller
    - File: `/app/javascript/controllers/flash_controller.js`
    - Auto-dismiss after 3 seconds using setTimeout
    - Manual close button handler with smooth removal
    - Follow pattern from existing Stimulus controllers (e.g., `collapsible_controller.js`)
  - [x] 1.3 Update flash messages partial for popover styling
    - File: `/app/views/shared/_flash_messages.html.erb`
    - Add Stimulus data attributes for controller connection
    - Support notice (green/success) and alert (yellow/warning) types
    - Include manual close button with icon
    - Position: fixed top-right of content area
  - [x] 1.4 Add CSS for popover flash messages
    - Tailwind classes for styling (green for notice, yellow for alert)
    - Smooth fade-in/fade-out transitions
    - Vertical stacking with proper spacing
    - Z-index above navbar but below modals
    - Responsive design (adjust position on mobile)
  - [x] 1.5 Ensure flash message tests pass
    - Run ONLY the 2-8 tests written in 1.1
    - Verify auto-dismiss works correctly
    - Verify manual close removes message
    - Do NOT run the entire test suite at this stage

**Acceptance Criteria:**
- The 2-8 tests written in 1.1 pass
- Flash messages appear as popovers in top-right
- Auto-dismiss after 3 seconds with smooth animation
- Manual close button works
- Multiple messages stack vertically
- Existing flash[:notice] and flash[:alert] API continues to work

---

### Phase 2: PWA Infrastructure

#### Task Group 2: PWA Manifest and Service Worker Setup
**Dependencies:** Task Group 1

- [ ] 2.0 Complete PWA infrastructure setup
  - [ ] 2.1 Write 2-8 focused tests for service worker registration
    - Limit to 2-8 highly focused tests maximum
    - Test only critical setup (e.g., manifest loads, service worker registers successfully)
    - Skip exhaustive testing of offline caching and push event handling
  - [ ] 2.2 Generate VAPID keys for Web Push API
    - Install web-push gem: Add to Gemfile (`gem 'web-push', '~> 3.0'`)
    - Run `bundle install`
    - Generate keys: `WebPush.generate_key` in Rails console
    - Store in Rails credentials or environment variables (VAPID_PUBLIC_KEY, VAPID_PRIVATE_KEY)
    - Document key generation process in README or deployment notes
  - [ ] 2.3 Create PWA manifest.json
    - File: `/public/manifest.json`
    - App name: "FitOrForget"
    - Short name: "FitOrForget"
    - Theme color and background color (match existing app colors)
    - Display: "standalone"
    - Start URL: "/"
    - Icons: Reference brown wombat icon (192x192 and 512x512)
  - [ ] 2.4 Create brown wombat icon assets
    - Design brown wombat lifting weights icon
    - Generate sizes: 192x192px and 512x512px (minimum PWA requirements)
    - Also create favicon sizes: 16x16, 32x32, apple-touch-icon
    - Save to `/public/icon-192.png`, `/public/icon-512.png`, etc.
    - Replace or supplement existing `/public/icon.png`
  - [ ] 2.5 Implement service worker with push notification handlers
    - File: `/public/service-worker.js`
    - Add push event listener to receive and display notifications
    - Add notificationclick event listener to open specific program page
    - Implement basic offline cache for app shell (HTML, CSS, JS)
    - Add fallback offline page
    - Ensure proper MIME type (application/javascript)
  - [ ] 2.6 Register service worker in application layout
    - File: `/app/views/layouts/application.html.erb`
    - Uncomment or add manifest link tag
    - Add JavaScript to register service worker on page load
    - Handle registration errors gracefully
    - Check for service worker support before registering
  - [ ] 2.7 Create offline fallback page
    - File: `/public/offline.html`
    - Simple, styled page with "You're offline" message
    - Match app branding and basic styles
    - Include link to return when online
  - [ ] 2.8 Ensure PWA infrastructure tests pass
    - Run ONLY the 2-8 tests written in 2.1
    - Verify manifest loads correctly
    - Verify service worker registers
    - Do NOT run the entire test suite at this stage

**Acceptance Criteria:**
- The 2-8 tests written in 2.1 pass
- VAPID keys generated and stored securely
- PWA manifest loads correctly
- App can be installed on mobile devices
- Service worker registers successfully
- Push notification handlers implemented
- Basic offline functionality works

---

### Phase 3: Database Layer for Reminders

#### Task Group 3: Database Models and Migrations
**Dependencies:** Task Group 2

- [ ] 3.0 Complete database layer for push subscriptions and reminders
  - [ ] 3.1 Write 2-8 focused tests for model validations and associations
    - Limit to 2-8 highly focused tests maximum
    - Test only critical model behaviors (e.g., required fields, associations, timezone handling)
    - Skip exhaustive validation and edge case testing
  - [ ] 3.2 Create PushSubscription model and migration
    - Model: `/app/models/push_subscription.rb`
    - Migration: Create push_subscriptions table
    - Fields: user_id (foreign key, indexed, not null), endpoint (text, not null), p256dh_key (text, not null), auth_key (text, not null), timestamps
    - Validations: Presence of all required fields, endpoint must be HTTPS URL
    - Association: belongs_to :user
  - [ ] 3.3 Create Reminder model and migration
    - Model: `/app/models/reminder.rb`
    - Migration: Create reminders table
    - Fields: user_id (foreign key, indexed, not null), program_id (foreign key, indexed, not null), days_of_week (jsonb or text array), time (time), timezone (string), enabled (boolean, default: true, indexed), timestamps
    - Validations: Presence of required fields, time format, days_of_week array contains valid day names
    - Associations: belongs_to :user, belongs_to :program
    - Add index on (enabled, days_of_week) for query performance
  - [ ] 3.4 Add timezone to users table (if not present)
    - Migration: Add timezone column to users table (string, nullable)
    - Default: nil (will be set on first reminder creation)
    - Update User model to validate timezone format if present
  - [ ] 3.5 Update User model associations
    - File: `/app/models/user.rb`
    - Add: has_many :push_subscriptions, dependent: :destroy
    - Add: has_many :reminders, dependent: :destroy
  - [ ] 3.6 Update Program model associations
    - File: `/app/models/program.rb`
    - Add: has_one :reminder, dependent: :destroy
  - [ ] 3.7 Run migrations and verify schema
    - Run: `rails db:migrate`
    - Verify tables created with correct columns and indexes
    - Check foreign key constraints are in place
  - [ ] 3.8 Ensure database layer tests pass
    - Run ONLY the 2-8 tests written in 3.1
    - Verify validations work correctly
    - Verify associations work correctly
    - Do NOT run the entire test suite at this stage

**Acceptance Criteria:**
- The 2-8 tests written in 3.1 pass
- PushSubscription model validates and associates correctly
- Reminder model validates and associates correctly
- Migrations run successfully
- Indexes created for query performance
- User and Program models updated with new associations

---

### Phase 4: API and Background Jobs

#### Task Group 4: Controllers, Routes, and Background Jobs
**Dependencies:** Task Group 3

- [ ] 4.0 Complete API layer and background job implementation
  - [ ] 4.1 Write 2-8 focused tests for controllers and jobs
    - Limit to 2-8 highly focused tests maximum
    - Test only critical actions (e.g., create reminder, destroy subscription, job enqueues notifications)
    - Skip exhaustive testing of all CRUD operations and error scenarios
  - [ ] 4.2 Create PushSubscriptionsController
    - File: `/app/controllers/push_subscriptions_controller.rb`
    - Actions: create, destroy (POST and DELETE only)
    - Create: Accept endpoint, p256dh_key, auth_key from client, associate with current_user
    - Destroy: Remove subscription by ID (ensure user owns subscription)
    - Authorization: User can only manage their own subscriptions
    - Follow RESTful conventions and existing controller patterns
  - [ ] 4.3 Create RemindersController
    - File: `/app/controllers/reminders_controller.rb`
    - Actions: index, create, update, destroy
    - Index: List all reminders for current_user with program names
    - Create: Validate user owns program, save timezone from client
    - Update: Toggle enabled status, update days/time
    - Destroy: Remove reminder (ensure user owns reminder)
    - Authorization: User can only manage reminders for their own programs
  - [ ] 4.4 Add routes for subscriptions and reminders
    - File: `/config/routes.rb`
    - POST /push_subscriptions - create subscription
    - DELETE /push_subscriptions/:id - destroy subscription
    - GET /reminders - index page
    - POST /reminders - create reminder
    - PATCH /reminders/:id - update reminder
    - DELETE /reminders/:id - destroy reminder
    - Follow RESTful conventions
  - [ ] 4.5 Create ReminderCheckJob (daily scheduled job)
    - File: `/app/jobs/reminder_check_job.rb`
    - Query reminders where enabled=true and current day in days_of_week array
    - For each reminder, calculate if notification time has arrived in user's timezone
    - Enqueue SendPushNotificationJob for each due reminder
    - Handle timezone conversion using ActiveSupport::TimeZone
    - Follow existing job patterns in codebase
  - [ ] 4.6 Create SendPushNotificationJob (individual notification delivery)
    - File: `/app/jobs/send_push_notification_job.rb`
    - Accept reminder_id as parameter
    - Look up reminder and associated program
    - Fetch all push subscriptions for reminder's user
    - Use web-push gem to send notification to each subscription
    - Notification payload: title, body ("Time to work out! [Program Name]"), program URL
    - Handle subscription errors gracefully (remove invalid subscriptions)
    - Follow existing job patterns in codebase
  - [ ] 4.7 Configure Solid Queue for daily ReminderCheckJob
    - File: `/config/recurring.yml` or Solid Queue configuration
    - Schedule ReminderCheckJob to run daily (e.g., every hour or once at midnight UTC)
    - Ensure Solid Queue is properly configured in production
    - Test job scheduling in development environment
  - [ ] 4.8 Ensure API and job tests pass
    - Run ONLY the 2-8 tests written in 4.1
    - Verify reminder CRUD operations work
    - Verify job enqueues notifications correctly
    - Do NOT run the entire test suite at this stage

**Acceptance Criteria:**
- The 2-8 tests written in 4.1 pass
- PushSubscriptionsController creates and destroys subscriptions
- RemindersController handles CRUD operations with proper authorization
- ReminderCheckJob identifies due reminders correctly
- SendPushNotificationJob sends notifications via Web Push API
- Solid Queue scheduled to run ReminderCheckJob daily
- Invalid subscriptions removed gracefully

---

### Phase 5: Frontend UI and Integration

#### Task Group 5: Reminders UI and Client-Side Integration
**Dependencies:** Task Group 4

- [ ] 5.0 Complete reminders UI and client-side push subscription
  - [ ] 5.1 Write 2-8 focused tests for reminders UI
    - Limit to 2-8 highly focused tests maximum
    - Test only critical UI behaviors (e.g., reminder list renders, toggle works, form submission)
    - Skip exhaustive testing of all form states and interactions
  - [ ] 5.2 Add bell icon to navbar
    - File: `/app/views/shared/_navbar.html.erb`
    - Add bell icon linking to /reminders
    - Position next to Dashboard/Programs links in desktop nav
    - Match existing icon style and spacing
    - Add appropriate aria-label for accessibility
  - [ ] 5.3 Create reminders index page
    - File: `/app/views/reminders/index.html.erb`
    - Page title: "Reminders" or "Workout Reminders"
    - List all reminders with program names
    - Show schedule (days of week and time) for each reminder
    - Include enable/disable toggle switch for each reminder
    - Add "Delete" button for each reminder
    - Show "Create Reminder" button/link
    - If no push notification permission: Show explanation and permission request button
    - Match existing minimalist aesthetic
  - [ ] 5.4 Create reminder form (create/edit)
    - Can be inline on index page or separate partial
    - Fields: Program selector (dropdown), Days of week (multi-select checkboxes), Time picker, Timezone (auto-detected and hidden)
    - Validation: Required fields, at least one day selected
    - Submit creates or updates reminder via Turbo
    - Follow existing form patterns and Tailwind styling
  - [ ] 5.5 Implement client-side push subscription JavaScript
    - File: `/app/javascript/controllers/push_subscription_controller.js` or inline script
    - Detect user timezone using JavaScript: `Intl.DateTimeFormat().resolvedOptions().timeZone`
    - Request notification permission when user clicks "Enable Notifications" button
    - Show explanation before triggering browser's native permission prompt
    - On permission granted: Subscribe to push notifications via service worker
    - Send subscription details to PushSubscriptionsController (endpoint, p256dh_key, auth_key)
    - On permission denied: Show appropriate message
    - Check permission status on page load and adjust UI accordingly
  - [ ] 5.6 Implement reminder toggle functionality
    - Use Turbo Frames or Stimulus to toggle enabled status without full page reload
    - Send PATCH request to RemindersController update action
    - Update UI to reflect new state (visual feedback)
    - Handle errors gracefully
  - [ ] 5.7 Add timezone detection and storage
    - Detect timezone on first reminder creation using JavaScript
    - Save to user record if not already set
    - Display current timezone to user for confirmation
    - Allow manual timezone override if needed (future enhancement - keep simple for now)
  - [ ] 5.8 Ensure reminders UI tests pass
    - Run ONLY the 2-8 tests written in 5.1
    - Verify reminder list renders correctly
    - Verify toggle and delete functions work
    - Do NOT run the entire test suite at this stage

**Acceptance Criteria:**
- The 2-8 tests written in 5.1 pass
- Bell icon in navbar links to reminders page
- Reminders index page lists all reminders with program names and schedules
- Enable/disable toggle works without page reload
- Create reminder form validates and submits correctly
- Push subscription created on permission grant
- Timezone detected and stored automatically
- Permission prompt shows explanation before browser prompt
- UI matches existing minimalist design

---

### Phase 6: Testing and Polish

#### Task Group 6: Test Review, Gap Analysis, and Final Integration
**Dependencies:** Task Groups 1-5

- [ ] 6.0 Review existing tests and fill critical gaps only
  - [ ] 6.1 Review tests from Task Groups 1-5
    - Review the 2-8 tests written by each specialist in previous task groups
    - Total existing tests: approximately 10-40 tests
  - [ ] 6.2 Analyze test coverage gaps for THIS feature only
    - Identify critical user workflows that lack test coverage
    - Focus ONLY on gaps related to notification system requirements
    - Prioritize end-to-end workflows: flash messages, PWA installation, reminder creation, notification delivery
    - Do NOT assess entire application test coverage
  - [ ] 6.3 Write up to 10 additional strategic tests maximum
    - Add maximum of 10 new tests to fill identified critical gaps
    - Focus on integration points and end-to-end workflows
    - Examples: User creates reminder and receives notification, invalid subscription removed gracefully, timezone conversion accuracy
    - Do NOT write comprehensive coverage for all scenarios
    - Skip edge cases, performance tests, and accessibility tests unless business-critical
  - [ ] 6.4 Run feature-specific tests only
    - Run ONLY tests related to notification system feature
    - Expected total: approximately 20-50 tests maximum
    - Verify all critical workflows pass
    - Do NOT run the entire application test suite
  - [ ] 6.5 Test PWA installation manually
    - Test on Android device (Chrome browser)
    - Test on iOS device (Safari browser - note limitations)
    - Verify app installs with correct icon and name
    - Verify service worker registers and updates
  - [ ] 6.6 Test push notifications manually
    - Create reminder in app
    - Trigger notification manually via Rails console or scheduled job
    - Verify notification appears on device
    - Click notification and verify it opens correct program page
    - Test on multiple browsers and devices
  - [ ] 6.7 Test timezone accuracy
    - Create reminders in different timezones
    - Verify notifications sent at correct local time
    - Test edge cases: DST transitions, UTC boundary times
  - [ ] 6.8 Verify security and authorization
    - Test that users can only access their own reminders
    - Test that users can only set reminders for programs they own
    - Verify VAPID private key is not exposed to client
    - Test CSRF protection on subscription and reminder endpoints

**Acceptance Criteria:**
- All feature-specific tests pass (approximately 20-50 tests total)
- Critical user workflows for notification system are covered
- No more than 10 additional tests added when filling gaps
- PWA installs correctly on mobile devices
- Push notifications deliver at correct local time
- Clicking notification opens specific program page
- Security and authorization verified
- Manual testing completed on target devices and browsers

---

## Execution Order

Recommended implementation sequence:
1. **Phase 1: Foundation - Flash Messages** (Task Group 1) - Standalone enhancement, no dependencies
2. **Phase 2: PWA Infrastructure** (Task Group 2) - Sets up manifest, service worker, and VAPID keys
3. **Phase 3: Database Layer** (Task Group 3) - Creates models and migrations for reminders and subscriptions
4. **Phase 4: API and Background Jobs** (Task Group 4) - Implements controllers, routes, and scheduled jobs
5. **Phase 5: Frontend UI** (Task Group 5) - Builds reminders management page and client-side integration
6. **Phase 6: Testing and Polish** (Task Group 6) - Fills test gaps, manual testing, and final verification

---

## Implementation Notes

### Critical Dependencies
- Flash messages can be implemented independently
- PWA setup must precede reminder notifications (service worker required)
- Database models must exist before controllers and jobs
- Client-side push subscription requires service worker registration
- Scheduled jobs require database models and controllers

### Testing Philosophy
- Each phase writes 2-8 focused tests during development
- Tests verify critical behaviors only, not exhaustive coverage
- Final test gap analysis adds maximum 10 additional tests
- Focus on end-to-end user workflows over unit test coverage
- Manual testing required for PWA installation and push notifications

### Security Checklist
- [ ] VAPID private key stored securely (credentials or env vars)
- [ ] Push subscription endpoints validated (HTTPS only)
- [ ] User authorization on all reminder and subscription endpoints
- [ ] CSRF protection enabled
- [ ] Service worker served with correct MIME type

### Browser Compatibility Notes
- Service workers require HTTPS (except localhost)
- iOS Safari has limited push notification support (iOS 16.4+ with limitations)
- Test on Chrome (Android), Safari (iOS), and Firefox
- Graceful degradation for unsupported browsers

### Deployment Checklist
- [ ] Generate VAPID keys in production
- [ ] Store keys in Rails credentials or environment variables
- [ ] Configure Solid Queue recurring task for ReminderCheckJob
- [ ] Ensure service worker accessible at `/service-worker.js`
- [ ] Create and deploy wombat icon assets (192x192, 512x512)
- [ ] Test HTTPS requirement in production environment
- [ ] Verify manifest.json loads correctly
- [ ] Test PWA installation on production URL

---

## Reusable Code References

### Existing Patterns to Follow
- **Flash messages**: `/app/views/shared/_flash_messages.html.erb` - Current implementation
- **Stimulus controllers**: `/app/javascript/controllers/collapsible_controller.js` - Controller pattern
- **Navbar**: `/app/views/shared/_navbar.html.erb` - Navigation structure
- **User model**: `/app/models/user.rb` - Association patterns
- **Program model**: `/app/models/program.rb` - Association patterns
- **Migrations**: `/db/migrate/20251026215340_create_programs.rb` - Migration structure
- **Jobs**: `/app/jobs/application_job.rb` - Job patterns

### Standards Compliance
- Use **Rails 8** conventions
- Follow **Tailwind CSS** for styling
- Use **Stimulus** for JavaScript interactions
- Use **Turbo** for dynamic updates
- Follow **minitest** for testing
- Use **ActiveRecord** for database queries
- Use **Postgres** data types (jsonb for arrays)
- Follow **RESTful** conventions for routes and controllers
