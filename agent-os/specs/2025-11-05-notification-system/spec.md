# Specification: Notification System (PWA + Flash Messages + Scheduled Reminders)

## Goal
Enable users to receive timely push notifications for workout reminders through a Progressive Web App, with improved in-app flash messaging for immediate feedback.

## User Stories
- As a user, I want to see clear, non-intrusive flash messages when I perform actions so I know the result of my actions
- As a user, I want to install the app on my mobile device so I can access it like a native app
- As a user, I want to set a reminder for a program so I don't forget to work out
- As a user, I want to choose which days and times to be reminded so reminders fit my schedule
- As a user, I want to enable/disable reminders without deleting them so I can pause notifications temporarily
- As a user, I want to click a notification and go directly to the program so I can start working out immediately

## Core Requirements

### Component 1: Popover Flash Messages
- Replace current inline flash messages with popover-style toast notifications
- Support two message types: notice (green/success) and alert (yellow/warning)
- Auto-dismiss after 3 seconds with smooth fade-out animation
- Include manual close button for user control
- Stack vertically in top-right of content area when multiple messages appear
- Use Stimulus controller for auto-dismiss behavior
- Maintain existing flash[:notice] and flash[:alert] API

### Component 2: PWA (Progressive Web App)
- Create PWA manifest with app name "FitOrForget" and brown wombat icon
- Enable installation on mobile and desktop devices
- Register service worker for push notification support
- Implement basic offline shell with "you're offline" message
- Generate and securely store VAPID keys for Web Push API
- Store push subscriptions in database (endpoint, keys, user association)
- Handle subscription creation via JavaScript on client
- Send notifications via Web Push protocol from background jobs

### Component 3: Scheduled Reminders
- One reminder per program (simple approach)
- Configure days of week (multi-select: Monday through Sunday)
- Set specific time for reminder (e.g., "7:00 AM")
- Enable/disable toggle without deleting reminder
- Store user timezone and send notifications in user's local time
- Separate reminders management page accessible via bell icon in navbar
- List all reminders with program names, schedule, and on/off toggle
- Show permission request explanation before triggering browser prompt
- Daily background job checks for reminders due today and enqueues notification jobs
- Notification click opens specific program page
- Simple default notification message: "Time to work out! [Program Name]"

## Visual Design
No mockups provided. Design should follow existing minimalist aesthetic:
- Flash messages: Clean, bordered containers with icons (check for notice, alert for warning)
- Reminders page: Simple list view with clear program names, schedule display, and toggle switches
- Bell icon in navbar: Use existing icon style, position next to Dashboard/Programs links
- Popover positioning: Fixed position in top-right of content area with z-index above navbar

## Reusable Components

### Existing Code to Leverage
- **Flash message partial**: `/app/views/shared/_flash_messages.html.erb` - Use as reference for styling and structure
- **Navbar structure**: `/app/views/shared/_navbar.html.erb` - Add bell icon to existing desktop nav links section
- **User model**: `/app/models/user.rb` - Add associations for push_subscriptions and reminders
- **Program model**: `/app/models/program.rb` - Add has_one :reminder relationship
- **Application layout**: `/app/views/layouts/application.html.erb` - Uncomment manifest link, register service worker
- **Job pattern**: `/app/jobs/application_job.rb` - Follow existing job structure for reminder jobs
- **Stimulus controllers**: Follow pattern from `/app/javascript/controllers/collapsible_controller.js` for flash controller
- **Migration pattern**: Follow structure from `/db/migrate/20251026215340_create_programs.rb`

### New Components Required
- **FlashController (Stimulus)**: Auto-dismiss behavior and manual close for popover messages - no existing toast/popover controller
- **ReminderCheckJob**: Daily scheduled job - no existing scheduled jobs in codebase
- **SendPushNotificationJob**: Individual notification delivery - requires Web Push gem integration
- **PushSubscription model**: Store subscription data - new database table needed
- **Reminder model**: Store reminder configuration - new database table needed
- **RemindersController**: CRUD operations for reminders - new resource
- **PushSubscriptionsController**: Handle subscription creation/deletion - new resource
- **Service worker**: Create new `/public/service-worker.js` with push event handlers
- **PWA manifest**: Create new `/public/manifest.json` with app metadata

## Technical Approach

### Database Schema
Two new tables required:

**push_subscriptions table**:
- user_id (foreign key, indexed, not null)
- endpoint (text, not null)
- p256dh_key (text, not null)
- auth_key (text, not null)
- timestamps

**reminders table**:
- user_id (foreign key, indexed, not null)
- program_id (foreign key, indexed, not null)
- days_of_week (text array or jsonb, stores ["monday", "wednesday", "friday"])
- time (time type, stores local time like "07:00:00")
- timezone (string, stores Rails timezone identifier like "America/New_York")
- enabled (boolean, default true, indexed for query performance)
- timestamps

Add index on reminders(enabled, days_of_week) for daily job queries.

### Models and Associations
- User has_many :push_subscriptions, dependent: :destroy
- User has_many :reminders, dependent: :destroy
- Program has_one :reminder, dependent: :destroy
- Reminder belongs_to :user, belongs_to :program
- PushSubscription belongs_to :user

### Controllers and Routes
- RemindersController: index, create, update, destroy (no show or edit needed)
- PushSubscriptionsController: create, destroy (POST and DELETE only)
- Routes follow RESTful conventions

### Background Jobs
- ReminderCheckJob: Runs daily via Solid Queue recurring task
  - Queries reminders where enabled=true and today's day in days_of_week array
  - For each matching reminder, calculates if notification time has arrived in user's timezone
  - Enqueues SendPushNotificationJob for each due reminder
- SendPushNotificationJob: Sends individual push notification
  - Uses web-push gem to send notification to user's subscribed endpoints
  - Handles subscription errors (removes invalid subscriptions)
  - Includes program URL in notification data for click handling

### Service Worker Implementation
Create `/public/service-worker.js` with:
- Push event listener to receive and display notifications
- NotificationClick event listener to open specific program page
- Basic offline cache for app shell (HTML, CSS, JS)
- Fallback offline page

### VAPID Keys
- Generate VAPID keys using web-push gem: `WebPush.generate_key`
- Store in Rails credentials or environment variables (VAPID_PUBLIC_KEY, VAPID_PRIVATE_KEY)
- Public key exposed to client for subscription creation
- Private key used server-side for signing push requests

### Timezone Handling
- Add timezone column to users table if not present
- Detect user timezone in JavaScript on first visit and save to user record
- Convert reminder times to UTC for storage using user's timezone
- Daily job queries reminders and calculates "due now" in user's timezone using ActiveSupport::TimeZone

### Flash Message Implementation
- Create Stimulus controller: flash_controller.js
- Auto-dismiss after 3 seconds using setTimeout
- Stack messages vertically with absolute positioning
- Turbo Streams can insert new flash messages dynamically
- CSS transitions for smooth appearance and dismissal

## Out of Scope
- Email notifications
- SMS notifications
- Reminder history or logs
- Analytics on reminder usage or engagement
- Snooze functionality
- Custom notification messages per reminder
- Multiple reminders per program
- Advanced offline capabilities (workout data caching)
- Notification read/unread status tracking
- Third-party notification services (OneSignal, Pusher)
- Complex scheduling (exact time calculations per reminder)
- Checking if PWA is installed before sending notifications

## Dependencies

### Gems to Add
- web-push (~> 3.0): For sending Web Push notifications via VAPID

### JavaScript Libraries
- None required (use native Web Push API and Service Worker API)

### External Services
- None (self-hosted push notifications via Web Push protocol)

## Security Considerations
- VAPID private key must be kept secret and stored securely in Rails credentials
- Validate push subscription endpoints before storing (must be HTTPS)
- User authorization: Users can only create/edit/delete their own reminders
- User authorization: Users can only set reminders for programs they own
- CSRF protection for subscription and reminder endpoints
- Service worker must be served with correct MIME type (application/javascript)
- Gracefully handle invalid or expired push subscriptions

## Testing Strategy

### Unit Tests
- Reminder model validations (required fields, time format, days array)
- PushSubscription model validations
- Job logic (ReminderCheckJob correctly identifies due reminders)
- Timezone conversion logic in reminder queries
- User can only access their own reminders and subscriptions

### Integration Tests
- Reminder CRUD operations via controller
- Push subscription creation and deletion
- Flash messages render correctly with proper styling
- Service worker registration and manifest loading

### System Tests
- User can create reminder for program
- User can toggle reminder on/off
- User can delete reminder
- Flash messages appear and auto-dismiss
- PWA manifest enables installation prompt (may require manual testing)
- Push notification permission flow (requires manual browser testing)

### Manual Testing Required
- Push notifications on actual mobile devices (iOS Safari has limitations)
- PWA installation on Android and iOS
- Notification click opens correct program page
- Offline mode displays appropriate message
- Browser compatibility (Chrome, Safari, Firefox)

## Deployment Considerations

### Environment Variables
- VAPID_PUBLIC_KEY: Public key for push subscriptions (client-side safe)
- VAPID_PRIVATE_KEY: Private key for signing push requests (server-side only)

### Production Setup
- Generate VAPID keys once and store securely in production credentials
- Configure Solid Queue to run ReminderCheckJob daily at appropriate time (e.g., every hour or once per day at midnight UTC)
- Ensure service worker is served from root path with proper headers
- Requires HTTPS in production (service workers require secure context)
- Add service worker to asset pipeline exclusions if needed

### Asset Generation
- Create brown wombat lifting weights icon in multiple sizes:
  - 192x192px (minimum PWA requirement)
  - 512x512px (minimum PWA requirement)
  - favicon sizes (16x16, 32x32, etc.)
- Replace `/public/icon.png` and `/public/icon.svg`

### Database Migrations
- Run migrations to create push_subscriptions and reminders tables
- Add timezone column to users table if not present
- Add indexes for query performance

## Success Criteria
- Flash messages appear as popovers in top-right, auto-dismiss after 3 seconds, and stack when multiple appear
- PWA can be installed on mobile devices with custom icon and app name
- Service worker registers successfully and handles push events
- Users can create one reminder per program with specific days and time
- Users can enable/disable reminders via toggle without deleting
- Daily background job identifies and enqueues notifications for due reminders
- Push notifications are delivered to users' devices at correct local time
- Clicking notification opens specific program page
- Permission prompt shows explanation before requesting browser permission
- Bell icon in navbar navigates to reminders management page
- Users without notification permission see appropriate messaging
- Invalid push subscriptions are gracefully handled and removed
