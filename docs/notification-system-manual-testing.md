# Notification System - Manual Testing Guide

This document provides step-by-step instructions for manually testing the notification system feature on real devices.

## Prerequisites

- The application must be running in production or staging environment with HTTPS
- VAPID keys must be configured (`VAPID_PUBLIC_KEY` and `VAPID_PRIVATE_KEY`)
- Test devices: Android (Chrome) and iOS (Safari 16.4+)
- Solid Queue must be running to process background jobs

## Test 1: PWA Installation on Android

### Device: Android with Chrome Browser

**Steps:**
1. Navigate to the app URL in Chrome
2. Look for the "Install app" prompt at the bottom of the screen OR tap the three-dot menu and select "Install app"
3. Confirm the installation dialog
4. Open the installed app from the home screen
5. Verify the app opens in standalone mode (no browser UI visible)
6. Verify the brown wombat icon appears on the home screen
7. Verify the app name shows as "Wombat Workouts"

**Expected Results:**
- App installs successfully
- Icon displays correctly (brown wombat lifting weights)
- App opens in standalone mode without browser chrome
- App name is "Wombat Workouts"

**Status:** [ ] Pass [ ] Fail [ ] N/A

**Notes:**
_____________________________________________________________________

## Test 2: PWA Installation on iOS

### Device: iOS with Safari Browser (16.4+)

**Steps:**
1. Navigate to the app URL in Safari
2. Tap the Share button at the bottom of the screen
3. Scroll down and tap "Add to Home Screen"
4. Confirm the installation
5. Open the installed app from the home screen
6. Verify the app opens
7. Verify the brown wombat icon appears on the home screen

**Expected Results:**
- App installs successfully
- Icon displays correctly
- App name is "Wombat Workouts"

**Limitations on iOS:**
- Push notifications have limitations in iOS Safari
- Notifications may not work unless the PWA is in the foreground
- iOS 16.4+ required for Web Push support

**Status:** [ ] Pass [ ] Fail [ ] N/A

**Notes:**
_____________________________________________________________________

## Test 3: Service Worker Registration

### Device: Any desktop or mobile browser

**Steps:**
1. Navigate to the app URL
2. Open browser DevTools (F12 or Inspect)
3. Go to the Application/Storage tab
4. Click on "Service Workers" in the left sidebar
5. Verify a service worker is registered for the app origin
6. Check the service worker status is "activated and is running"

**Expected Results:**
- Service worker registered at `/service-worker.js`
- Service worker status shows as activated
- No errors in the console

**Status:** [ ] Pass [ ] Fail [ ] N/A

**Notes:**
_____________________________________________________________________

## Test 4: Create Reminder and Enable Notifications

### Device: Android Chrome or Desktop Chrome (recommended)

**Steps:**
1. Sign in to the app
2. Create a test program if you don't have one
3. Click the bell icon in the navbar to access Reminders page
4. Click "Enable Notifications" button (if not already enabled)
5. Review the explanation text
6. Click "Allow" when the browser prompts for notification permission
7. Verify the page updates to show the reminder creation form
8. Select a program from the dropdown
9. Check at least one day of the week (e.g., today's day)
10. Set a time that is 5 minutes in the future
11. Click "Create Reminder"
12. Verify the reminder appears in the list with correct details

**Expected Results:**
- Notification permission is granted
- Push subscription is created in the database
- Reminder is created successfully
- Reminder shows program name, days, time, and enabled toggle
- User timezone is detected and stored automatically

**Status:** [ ] Pass [ ] Fail [ ] N/A

**Notes:**
_____________________________________________________________________

## Test 5: Receive Push Notification (Scheduled)

### Device: Android Chrome or Desktop Chrome

**Prerequisites:**
- Reminder created in Test 4 with a time in the near future
- Solid Queue background jobs are running
- ReminderCheckJob is scheduled (check `config/recurring.yml`)

**Steps:**
1. Wait for the scheduled time to pass
2. Wait for ReminderCheckJob to run (runs hourly by default)
3. Check that a notification appears on the device
4. Click the notification
5. Verify the app opens to the specific program page

**Expected Results:**
- Notification appears at or after the scheduled time
- Notification title: "Workout Reminder"
- Notification body: "Time to work out! [Program Name]"
- Clicking notification opens the specific program page
- Reminder's `last_sent_at` timestamp is updated in the database

**Status:** [ ] Pass [ ] Fail [ ] N/A

**Notes:**
_____________________________________________________________________

## Test 6: Trigger Push Notification Manually

### Device: Any browser

**Prerequisites:**
- Reminder created in Test 4
- Access to Rails console in production/staging

**Steps:**
1. Open Rails console: `rails console` or `heroku run rails console`
2. Find the reminder: `reminder = Reminder.last`
3. Manually trigger the notification job:
   ```ruby
   SendPushNotificationJob.perform_now(reminder.id)
   ```
4. Check that a notification appears on the device with the PWA open
5. Click the notification
6. Verify the app navigates to the specific program page

**Expected Results:**
- Notification appears immediately (within 1-2 seconds)
- Notification displays with correct title and body
- Clicking opens the correct program page
- No errors in Rails console

**Status:** [ ] Pass [ ] Fail [ ] N/A

**Notes:**
_____________________________________________________________________

## Test 7: Timezone Accuracy

### Device: Any browser

**Test Scenario 1: Local Timezone**

**Steps:**
1. Create a reminder for today with a time 5 minutes in the future (local time)
2. Note the current timezone displayed on the reminders page
3. Manually trigger ReminderCheckJob after the scheduled time passes:
   ```ruby
   ReminderCheckJob.perform_now
   ```
4. Verify notification is sent (check that SendPushNotificationJob is enqueued)

**Expected Results:**
- Reminder respects local timezone setting
- Notification is sent when local time reaches the scheduled time

**Status:** [ ] Pass [ ] Fail [ ] N/A

**Test Scenario 2: Different Timezone**

**Steps:**
1. In Rails console, create a reminder in a different timezone:
   ```ruby
   user = User.find_by(email: "your@email.com")
   program = user.programs.first
   user.update(timezone: "America/New_York")

   # Create reminder for current day in NY time, 1 hour ago
   ny_time = Time.current.in_time_zone("America/New_York")
   current_day = ny_time.strftime("%A").downcase
   scheduled_time = (ny_time - 1.hour).strftime("%H:%M")

   reminder = user.reminders.create!(
     program: program,
     days_of_week: [current_day],
     time: scheduled_time,
     timezone: "America/New_York"
   )
   ```
2. Run ReminderCheckJob:
   ```ruby
   ReminderCheckJob.perform_now
   ```
3. Verify notification job is enqueued for the reminder

**Expected Results:**
- Reminder timezone conversion works correctly
- Notifications are sent based on user's timezone, not server timezone

**Status:** [ ] Pass [ ] Fail [ ] N/A

**Notes:**
_____________________________________________________________________

## Test 8: Toggle Reminder On/Off

### Device: Any browser

**Steps:**
1. Navigate to the Reminders page
2. Locate an existing reminder
3. Click the toggle switch to disable the reminder
4. Verify the toggle changes to the "off" position
5. Verify the reminder card shows as disabled (grayed out or similar visual indicator)
6. Manually trigger ReminderCheckJob
7. Verify NO notification is sent for the disabled reminder
8. Click the toggle again to re-enable
9. Verify the toggle changes to the "on" position

**Expected Results:**
- Toggle switches state without page reload
- Disabled reminders do not trigger notifications
- Visual feedback shows enabled/disabled state clearly

**Status:** [ ] Pass [ ] Fail [ ] N/A

**Notes:**
_____________________________________________________________________

## Test 9: Delete Reminder

### Device: Any browser

**Steps:**
1. Navigate to the Reminders page
2. Locate an existing reminder
3. Click the Delete button
4. Confirm the deletion in the browser dialog
5. Verify the reminder is removed from the list
6. Verify a success flash message appears
7. Verify the reminder is removed from the database

**Expected Results:**
- Confirmation dialog appears before deletion
- Reminder is removed from UI immediately
- Success message displayed
- Reminder record deleted from database

**Status:** [ ] Pass [ ] Fail [ ] N/A

**Notes:**
_____________________________________________________________________

## Test 10: Flash Messages Behavior

### Device: Desktop browser (for better visibility)

**Steps:**
1. Perform any action that triggers a success message (e.g., create a reminder)
2. Observe the flash message appears in the top-right of the content area
3. Verify the message has green/success styling
4. Wait 3 seconds
5. Verify the message auto-dismisses with a smooth fade-out animation
6. Perform an action that triggers an error message
7. Verify the error message appears with yellow/warning styling
8. Click the close button (X) on the message
9. Verify the message closes immediately

**Expected Results:**
- Flash messages appear in top-right of content area
- Success messages are green
- Warning/error messages are yellow
- Messages auto-dismiss after 3 seconds
- Close button immediately removes the message
- Smooth fade-in and fade-out animations

**Status:** [ ] Pass [ ] Fail [ ] N/A

**Notes:**
_____________________________________________________________________

## Test 11: Offline Behavior

### Device: Any browser

**Steps:**
1. With the PWA installed, open the app
2. Disconnect from the internet (turn off WiFi or enable airplane mode)
3. Try to navigate within the app
4. Verify the offline page appears with "You're Offline" message
5. Verify the offline page matches the app branding
6. Reconnect to the internet
7. Verify the app automatically detects connection and works again

**Expected Results:**
- Offline page displays when no internet connection
- Offline page shows "You're Offline" message
- Offline page has app branding (brown wombat theme)
- App resumes working when connection restored

**Status:** [ ] Pass [ ] Fail [ ] N/A

**Notes:**
_____________________________________________________________________

## Test 12: Security - Authorization

### Device: Any browser

**Prerequisites:**
- Two test user accounts

**Test Scenario 1: Cannot access other user's reminders**

**Steps:**
1. Sign in as User A
2. Create a reminder
3. Note the reminder ID from the URL or database
4. Sign out
5. Sign in as User B
6. Try to access User A's reminder by navigating directly to the edit/show URL (if available)
7. Try to update User A's reminder via API request

**Expected Results:**
- User B cannot view or edit User A's reminders
- Attempting to access returns "Reminder not found" or redirects with error

**Status:** [ ] Pass [ ] Fail [ ] N/A

**Test Scenario 2: Cannot create reminder for other user's program**

**Steps:**
1. Sign in as User A
2. Create a program (note the program ID)
3. Sign out
4. Sign in as User B
5. Navigate to Reminders page
6. In browser DevTools console, try to submit a reminder form with User A's program ID:
   ```javascript
   fetch('/reminders', {
     method: 'POST',
     headers: {
       'Content-Type': 'application/json',
       'X-CSRF-Token': document.querySelector('[name=csrf-token]').content
     },
     body: JSON.stringify({
       reminder: {
         program_id: '<USER_A_PROGRAM_ID>',
         days_of_week: ['monday'],
         time: '09:00',
         timezone: 'America/New_York'
       }
     })
   })
   ```
7. Verify the request is rejected

**Expected Results:**
- User B cannot create reminder for User A's program
- Request returns 422 Unprocessable Entity or similar error

**Status:** [ ] Pass [ ] Fail [ ] N/A

**Notes:**
_____________________________________________________________________

## Test 13: Security - VAPID Key Exposure

### Device: Any browser

**Steps:**
1. Navigate to the Reminders page
2. Open browser DevTools
3. View the page source (Ctrl+U or Cmd+U)
4. Search for "VAPID_PRIVATE_KEY" in the source
5. Check the Network tab for any API responses
6. Search all responses for "VAPID_PRIVATE_KEY"

**Expected Results:**
- VAPID private key is NOT present in page source
- VAPID private key is NOT exposed in any API responses
- Only the VAPID public key should be visible (this is expected and safe)

**Status:** [ ] Pass [ ] Fail [ ] N/A

**Notes:**
_____________________________________________________________________

## Test 14: Multiple Devices/Subscriptions

### Device: Two different browsers or devices

**Steps:**
1. Sign in as the same user on Device A (e.g., Desktop Chrome)
2. Enable notifications and grant permission
3. Sign in as the same user on Device B (e.g., Mobile Chrome)
4. Enable notifications and grant permission on Device B
5. Create a reminder with a time in the near future
6. Manually trigger the notification job
7. Verify both Device A and Device B receive the notification

**Expected Results:**
- User can have multiple push subscriptions
- Notifications are sent to all subscribed devices
- Each device receives the notification independently

**Status:** [ ] Pass [ ] Fail [ ] N/A

**Notes:**
_____________________________________________________________________

## Test 15: Notification Not Sent Twice on Same Day

### Device: Any browser

**Steps:**
1. Create a reminder for today with a past time (e.g., 1 hour ago)
2. Manually trigger ReminderCheckJob:
   ```ruby
   ReminderCheckJob.perform_now
   ```
3. Verify notification is sent (check `last_sent_at` timestamp)
4. Run ReminderCheckJob again:
   ```ruby
   ReminderCheckJob.perform_now
   ```
5. Verify NO new notification is sent
6. Check that `last_sent_at` is still set to the first send time

**Expected Results:**
- First run sends notification and sets `last_sent_at`
- Second run does NOT send duplicate notification
- `last_sent_at` prevents multiple notifications on same day

**Status:** [ ] Pass [ ] Fail [ ] N/A

**Notes:**
_____________________________________________________________________

## Browser Compatibility Notes

### Chrome (Android/Desktop)
- Full support for PWA installation
- Full support for push notifications
- Recommended for testing

### Safari (iOS 16.4+)
- PWA installation supported
- Push notifications supported with limitations
- Notifications may only work when PWA is in foreground
- Limited background notification support

### Firefox (Android/Desktop)
- PWA installation supported
- Push notifications supported
- Test for compatibility

### Safari (iOS < 16.4)
- PWA installation supported
- Push notifications NOT supported
- Users will not be able to enable notifications

### Other Browsers
- May have varying levels of support
- Check https://caniuse.com/web-app-manifest and https://caniuse.com/push-api

## Troubleshooting

### Notifications not appearing

**Possible causes:**
1. Notification permission not granted - Check browser settings
2. Service worker not registered - Check DevTools → Application → Service Workers
3. VAPID keys not configured - Check environment variables
4. Push subscription not created - Check database for push_subscriptions records
5. Solid Queue not running - Check background job status
6. Reminder disabled - Check reminder.enabled status

**Debugging steps:**
1. Check Rails logs for errors
2. Check browser console for JavaScript errors
3. Verify service worker is registered and active
4. Check database: `PushSubscription.count` and `Reminder.enabled.count`
5. Manually run jobs in Rails console to isolate issues

### Service worker not updating

**Solution:**
1. In DevTools → Application → Service Workers
2. Click "Update" or "Unregister"
3. Hard refresh the page (Ctrl+Shift+R or Cmd+Shift+R)
4. Re-register the service worker

### Push subscription fails

**Possible causes:**
1. HTTPS required (except localhost)
2. VAPID public key not accessible to client
3. Browser permissions blocked

**Solution:**
1. Ensure app is served over HTTPS
2. Check that VAPID_PUBLIC_KEY is set and accessible
3. Reset browser permissions and try again

## Test Summary

**Date:** _____________________

**Tester:** _____________________

**Environment:** [ ] Production [ ] Staging [ ] Local

**Total Tests:** 15

**Passed:** _____ / 15

**Failed:** _____ / 15

**N/A:** _____ / 15

**Overall Assessment:**

[ ] All critical tests passed - Ready for deployment
[ ] Minor issues found - Acceptable for deployment with noted limitations
[ ] Major issues found - Not ready for deployment

**Critical Issues:**
_____________________________________________________________________
_____________________________________________________________________

**Non-Critical Issues:**
_____________________________________________________________________
_____________________________________________________________________

**Recommendations:**
_____________________________________________________________________
_____________________________________________________________________
