# Spec Requirements: Notification System (PWA + Flash Messages + Scheduled Reminders)

## Initial Description

**Feature: Notification System (PWA + Flash Messages + Scheduled Reminders)**

This feature includes three interconnected components:

1. **Popover Flash Messages** - Implement modern popover-style flash messages for system notifications (success, error, info) with better UX than current implementation

2. **PWA (Progressive Web App)** - Convert the app to a PWA to enable:
   - Installation on mobile devices
   - Push notification capabilities
   - Offline functionality (basic)
   - App-like experience

3. **Scheduled Reminders** - Implement a reminder system where users can:
   - Set recurring notifications for specific programs (e.g., "Monday, Wednesday, Friday at 7am")
   - Receive app push notifications (not email) to remind them to work out
   - Uses Solid Queue (Rails 8 default) for background job processing
   - Requires PWA push notification infrastructure

These features build on each other: PWA setup enables push notifications, which scheduled reminders will use.

## Requirements Discussion

### First Round Questions

**Q1:** For the popover flash messages, I'm assuming we want them to auto-dismiss after a few seconds (like 3-5 seconds) and have a manual close button. Should they stack if multiple messages appear, or replace each other?

**Answer:** Auto-dismiss after 3 seconds. Stack vertically if multiple appear. Include manual close button.

**Q2:** For the PWA manifest, I'm thinking we should use the app name "FitOrForget" with a simple barbell or dumbbell icon. Do you have branding assets, or should we use a free icon from a library like Heroicons or FontAwesome?

**Answer:** App name is "FitOrForget". Need to create a brown wombat lifting weights as the icon (replace `/public/icon.png`).

**Q3:** For scheduled reminders, I assume users should be able to:
- Set multiple reminders per program
- Choose specific days of the week
- Set a specific time
- Enable/disable reminders without deleting them
Is this correct, or should we keep it simpler (e.g., one reminder per program)?

**Answer:** Keep it simpler - one reminder per program. All the listed capabilities (days of week, time, enable/disable) are correct.

**Q4:** For the background job processing with Solid Queue, should we create a daily scheduled job that checks for all reminders due "today" and enqueues notification jobs? Or should we calculate the exact next occurrence and schedule individual jobs?

**Answer:** Daily job approach - check for reminders due today and enqueue notification jobs. Simpler and more reliable.

**Q5:** I'm assuming the flash message types should be: notice (green/success), alert (red/error), and info (blue). Should we support any other types or different color schemes?

**Answer:** (Clarified in follow-up) Notice (green/success) and Alert (yellow/warning) only. These are the two types already in use in the app.

**Q6:** For the PWA offline functionality, should we cache workout data for offline viewing, or just make the shell of the app work offline with a "you're offline" message?

**Answer:** Just make the shell work with a basic "you're offline" message. No need to cache workout data initially.

**Q7:** Should the reminder notification click open the app to a specific program page, or just to the home/dashboard?

**Answer:** Click should open the specific program page that the reminder is for.

**Q8:** What should we explicitly NOT include in this feature? For example: email notifications, SMS notifications, reminder history/logs, reminder analytics?

**Answer:** Do NOT include:
- Email notifications
- SMS notifications
- Reminder history or logs
- Analytics on reminders
- Snooze functionality
- Custom notification messages (use simple default)

### Existing Code to Reference

**Similar Features Identified:**
- Current flash implementation: `/app/views/shared/_flash_messages.html.erb` - reference for existing flash message structure and styling
- Existing service worker: `/public/service-worker.js` - has commented push notification code that can be uncommented and enhanced

**Backend patterns:**
- Background jobs will use Solid Queue (Rails 8 default)
- Follow existing job patterns in the codebase

### Follow-up Questions

**Follow-up 1:** You mentioned flash types should be notice and alert. What colors/styles should these have? I suggested green for success and red for error, but you said alert is already in use - what's the current styling?

**Answer:** Notice (styled like success/green) and Alert (styled like warning/yellow) are sufficient. These are the two types already in use.

**Follow-up 2:** For the popover positioning, should they appear in the top-right corner of the viewport, or somewhere else like top-center?

**Answer:** Top-right of the content area (not viewport corner, within content bounds).

**Follow-up 3:** For reminder times, should we store the user's timezone and notify them at "10am" in their timezone, or use UTC and let them set "10am UTC"?

**Answer:** Store the user's timezone. Notify them at "10am" in their current timezone. Keep implementation simple and clean. User acknowledges timezone calculation might be tricky.

**Follow-up 4:** Should the reminder management UI be on each program's page, or on a separate "Reminders" settings page?

**Answer:** Separate reminders page accessed from a bell icon in the navbar (not on individual program pages).

**Follow-up 5:** For the push notification permission request, should we prompt users immediately on first visit, or wait until they try to set up a reminder?

**Answer:** Show an explanation before triggering the browser's native permission prompt.

**Follow-up 6:** For the service worker approach, since you mentioned uncommenting existing code - should we use the Web Push API with VAPID keys, or a third-party service like OneSignal or Pusher?

**Answer:** User has never implemented PWA push notifications before and is asking for recommendation. **Recommendation**: Use the Web Push API with service workers (standard approach). Uncomment and enhance the existing service-worker.js code. Will need:
- VAPID keys for push notification authentication
- Store push subscriptions in database
- Background job to send notifications via Web Push protocol
- Service worker to receive and display notifications

**Follow-up 7:** Should we check if the user has the PWA installed before sending notifications, or always send them (they'll work in browser too)?

**Answer:** Always send notifications. Don't check if PWA is installed or get fancy with detection. Just send them regardless.

## Visual Assets

### Files Provided:
No visual assets provided.

### Visual Insights:
No visuals to analyze.

## Requirements Summary

### Functional Requirements

#### Component 1: Popover Flash Messages
- Replace current flash message implementation with modern popover style
- Support two message types:
  - Notice: Green/success styling
  - Alert: Yellow/warning styling
- Auto-dismiss after 3 seconds
- Include manual close button
- Stack vertically when multiple messages appear
- Position in top-right of content area (not viewport corner)
- Reference existing implementation at `/app/views/shared/_flash_messages.html.erb`

#### Component 2: PWA (Progressive Web App)
- Create PWA manifest with:
  - App name: "FitOrForget"
  - Icon: Brown wombat lifting weights (replace `/public/icon.png`)
  - Enable installation on mobile devices
  - App-like experience
- Service worker implementation:
  - Uncomment and enhance existing `/public/service-worker.js`
  - Implement Web Push API with VAPID keys
  - Receive and display push notifications
  - Basic offline functionality (shell only with "you're offline" message)
  - No workout data caching initially
- Push notification infrastructure:
  - Generate VAPID keys for authentication
  - Store push subscriptions in database
  - Background job to send notifications via Web Push protocol

#### Component 3: Scheduled Reminders
- User capabilities:
  - One reminder per program (keep it simple)
  - Choose specific days of the week
  - Set specific time
  - Enable/disable reminders without deleting
- Reminder management:
  - Separate reminders page (not on program pages)
  - Accessed via bell icon in navbar
  - List all reminders with program names
  - Toggle on/off functionality
- Notification behavior:
  - Store user's timezone
  - Notify at specified time in user's timezone
  - Clicking notification opens specific program page
  - Always send notifications (don't check for PWA installation)
  - Use simple default notification message (no customization)
- Permission handling:
  - Show explanation before triggering native permission prompt
  - Don't prompt immediately on first visit
  - Prompt when user tries to set up reminder
- Background processing:
  - Use Solid Queue (Rails 8 default)
  - Daily scheduled job checks for reminders due today
  - Enqueue individual notification jobs for each reminder
  - Simple and reliable approach over exact time scheduling

### Reusability Opportunities
- Existing flash message partial at `/app/views/shared/_flash_messages.html.erb`
- Existing service worker with commented push code at `/public/service-worker.js`
- Follow existing background job patterns (Solid Queue)
- Use existing navbar structure for bell icon placement

### Scope Boundaries

**In Scope:**
- Popover-style flash messages with auto-dismiss and manual close
- PWA manifest and installation capability
- Service worker with Web Push API integration
- Basic offline shell functionality
- Reminder creation, editing, deletion
- One reminder per program with day/time selection
- Enable/disable toggle for reminders
- Separate reminders management page
- Bell icon in navbar
- Daily background job for reminder processing
- Push notification delivery
- Timezone-aware notifications
- Notification clicks open specific program pages
- Permission prompt with explanation
- Database storage for push subscriptions
- VAPID key generation and configuration

**Out of Scope:**
- Email notifications
- SMS notifications
- Reminder history or logs
- Analytics on reminder usage
- Snooze functionality
- Custom notification messages per reminder
- Multiple reminders per program
- Advanced offline capabilities (workout data caching)
- Notification read/unread status tracking
- Third-party notification services (OneSignal, Pusher, etc.)
- Complex scheduling (exact time calculations per reminder)

### Technical Considerations

#### Push Notification Infrastructure
- Need to generate VAPID keys for Web Push API authentication
- Store public and private VAPID keys securely (environment variables)
- Create database model for push subscriptions (user_id, endpoint, p256dh_key, auth_key)
- Service worker must be served from root path with proper MIME type
- Browser compatibility: Modern browsers support Web Push API

#### Timezone Handling
- Store user timezone (likely in User model)
- Convert reminder times from user's timezone to UTC for storage
- Calculate "due today" in user's timezone for daily job processing
- User acknowledges this might be tricky - keep implementation simple
- Consider using Rails' `Time.zone` and ActiveSupport::TimeZone

#### Background Jobs (Solid Queue)
- Create daily scheduled job (runs once per day, checks all reminders)
- Create notification delivery job (enqueued for each reminder due)
- Job should handle push subscription errors gracefully
- Consider retry logic for failed notification deliveries

#### Service Worker
- Uncomment existing code in `/public/service-worker.js`
- Add push event listener to receive notifications
- Add notification click handler to open specific program page
- Cache app shell for offline functionality
- Register service worker in main application layout

#### Database Considerations
- New table: push_subscriptions (user_id, endpoint, keys, timestamps)
- New table or model: reminders (user_id, program_id, days_of_week, time, enabled, timezone, timestamps)
- Index on enabled reminders for daily job query performance
- Foreign key constraints for data integrity

#### Icon/Asset Requirements
- Create brown wombat lifting weights icon
- Generate multiple sizes for PWA (192x192, 512x512 minimum)
- Replace `/public/icon.png`
- Update manifest with icon paths

#### Flash Message Implementation
- Consider Stimulus controller for auto-dismiss behavior
- Use Turbo Streams for dynamic message insertion
- Maintain existing flash types (notice, alert)
- CSS transitions for smooth appearance/dismissal
- Z-index management for stacking

#### Security Considerations
- VAPID keys must be kept secret (private key)
- Validate push subscription endpoints before storing
- User must own the program they're setting reminders for
- Permission checks for reminder CRUD operations
- CSRF protection for subscription endpoints

#### Browser Compatibility Notes
- Service workers require HTTPS (except localhost)
- Push notifications not supported in all browsers (especially iOS Safari has limitations)
- Consider graceful degradation for unsupported browsers
- Test on iOS, Android, and desktop browsers
