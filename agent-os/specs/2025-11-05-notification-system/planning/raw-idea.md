# Raw Idea

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
