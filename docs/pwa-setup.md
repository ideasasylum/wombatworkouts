# PWA Setup Documentation

## Overview
Wombat Workouts has been configured as a Progressive Web App (PWA) with push notification support using the Web Push API and VAPID keys.

## Components

### 1. PWA Manifest (`/public/manifest.json`)
- Defines app metadata for installation
- App name: "Wombat Workouts"
- Theme color: Brown wombat (#8b7355)
- Background: Light gray (#edf2f7)
- Icons: 192x192 and 512x512 PNG files

### 2. Service Worker (`/public/service-worker.js`)
- Handles push notifications
- Provides basic offline functionality
- Caches app shell for offline access
- Manages notification clicks to open specific program pages

### 3. Offline Page (`/public/offline.html`)
- Displayed when user is offline and tries to access uncached content
- Automatically detects when connection is restored
- Matches app branding

### 4. Icon Assets
Generated icons in `/public/`:
- `icon-192.png` - 192x192 PWA icon
- `icon-512.png` - 512x512 PWA icon
- `apple-touch-icon.png` - 180x180 Apple device icon
- `favicon-16x16.png` - 16x16 favicon
- `favicon-32x32.png` - 32x32 favicon

## VAPID Keys

### What are VAPID Keys?
VAPID (Voluntary Application Server Identification) keys are used to authenticate your server when sending push notifications to users' browsers. They consist of:
- **Public Key**: Shared with the browser when subscribing to push notifications
- **Private Key**: Kept secret on the server, used to sign push notification requests

### Current Keys (Development)
The development environment uses keys stored in `.env` file:
```
VAPID_PUBLIC_KEY=BOBzPRa--l9k4O2VcVK6gIq1EYQgbdVv7ishpBu7MDQEEruczUmvisR-YHweXqXidoPSBbnwZs0BzknAO6iJgnM=
VAPID_PRIVATE_KEY=1TvU1kp9QLafkdRpkxxOp8DgTtTgWSQMQ21ZLGBGiak=
```

### Generating New VAPID Keys

#### Method 1: Using Rails Console
```bash
bin/rails console
```
```ruby
keys = WebPush.generate_key
puts "Public Key: #{keys.public_key}"
puts "Private Key: #{keys.private_key}"
```

#### Method 2: Using Rails Runner
```bash
bin/rails runner "keys = WebPush.generate_key; puts 'Public: #{keys.public_key}'; puts 'Private: #{keys.private_key}'"
```

## Deployment Setup

### Production Environment

#### Option 1: Environment Variables (Recommended for Docker/Kamal)
Set these environment variables in your production environment:
```bash
VAPID_PUBLIC_KEY=your_public_key_here
VAPID_PRIVATE_KEY=your_private_key_here
```

For Kamal deployment, add to `.kamal/secrets`:
```bash
VAPID_PUBLIC_KEY=$(op read "op://your-vault/vapid-keys/public")
VAPID_PRIVATE_KEY=$(op read "op://your-vault/vapid-keys/private")
```

#### Option 2: Rails Credentials
```bash
bin/rails credentials:edit --environment production
```

Add:
```yaml
vapid:
  public_key: your_public_key_here
  private_key: your_private_key_here
```

Then access in code:
```ruby
Rails.application.credentials.dig(:vapid, :public_key)
Rails.application.credentials.dig(:vapid, :private_key)
```

### Accessing VAPID Keys in Code

In your application, access keys via:
```ruby
# Public key (safe to expose to clients)
public_key = ENV['VAPID_PUBLIC_KEY'] || Rails.application.credentials.dig(:vapid, :public_key)

# Private key (keep secret, server-side only)
private_key = ENV['VAPID_PRIVATE_KEY'] || Rails.application.credentials.dig(:vapid, :private_key)
```

## Testing PWA Functionality

### Running Tests
```bash
bin/rails test test/integration/pwa_infrastructure_test.rb
```

Tests verify:
- Manifest loads correctly
- Service worker is accessible
- Icons are available
- Offline page works
- Theme colors match

### Manual Testing

#### Test PWA Installation (Desktop)
1. Visit the app in Chrome/Edge
2. Look for "Install" button in address bar
3. Click to install the app
4. App should open in standalone window

#### Test PWA Installation (Mobile)
**Android (Chrome):**
1. Visit the app
2. Tap "Add to Home Screen" from menu
3. App icon appears on home screen
4. Opens in fullscreen mode

**iOS (Safari - iOS 16.4+):**
1. Visit the app
2. Tap Share button
3. Select "Add to Home Screen"
4. Note: Push notifications have limited support on iOS

#### Test Service Worker
1. Open Chrome DevTools
2. Go to Application tab > Service Workers
3. Verify service worker is registered
4. Check "Offline" to test offline functionality
5. Reload page - should show offline page

#### Test Push Notifications (Manual)
After implementing push subscriptions:
```ruby
# In Rails console
user = User.find_by(email: 'your@email.com')
subscription = user.push_subscriptions.first

# Send test notification
WebPush.payload_send(
  message: JSON.generate({
    title: "Test Notification",
    body: "This is a test",
    url: "/dashboard"
  }),
  endpoint: subscription.endpoint,
  p256dh: subscription.p256dh_key,
  auth: subscription.auth_key,
  vapid: {
    subject: "mailto:your@email.com",
    public_key: ENV['VAPID_PUBLIC_KEY'],
    private_key: ENV['VAPID_PRIVATE_KEY']
  }
)
```

## Browser Support

### Service Workers & PWA Installation
- Chrome/Edge: Full support
- Firefox: Full support
- Safari (macOS): Limited support
- Safari (iOS 16.4+): Basic support with limitations

### Push Notifications
- Chrome/Edge (Desktop & Android): Full support
- Firefox (Desktop & Android): Full support
- Safari (macOS 13+): Supported
- Safari (iOS): Limited support (requires specific conditions)

## HTTPS Requirement
- Service Workers require HTTPS in production
- Exception: `localhost` works over HTTP for development
- Ensure your production deployment uses HTTPS

## Troubleshooting

### Service Worker Not Registering
- Check browser console for errors
- Verify `/service-worker.js` is accessible
- Ensure HTTPS is enabled (production)
- Clear browser cache and reload

### Manifest Not Loading
- Verify `/manifest.json` is accessible
- Check Content-Type is `application/json`
- Validate JSON syntax

### Icons Not Showing
- Verify icon files exist in `/public/`
- Check file permissions
- Clear browser cache
- Test icon URLs directly (e.g., `/icon-192.png`)

### Push Notifications Not Working
- Verify VAPID keys are set correctly
- Check notification permission is granted
- Verify subscription is saved to database
- Check service worker has `push` event listener
- Test in supported browser (Chrome/Firefox)

## Future Enhancements

Potential improvements:
- [ ] Custom brown wombat illustration for icons
- [ ] Advanced offline caching for workout data
- [ ] Background sync for workout completions
- [ ] Notification badges
- [ ] Rich notifications with images
- [ ] Web Share API integration

## Security Notes

1. **VAPID Private Key**: Never commit to git, never expose to clients
2. **VAPID Public Key**: Safe to expose to clients (used for subscriptions)
3. **Subscriptions**: Validate endpoints are HTTPS before saving
4. **User Authorization**: Verify users only access their own subscriptions
5. **CSRF Protection**: Ensure all subscription endpoints have CSRF protection

## Resources

- [Web Push Protocol](https://web.dev/push-notifications-overview/)
- [Service Worker API](https://developer.mozilla.org/en-US/docs/Web/API/Service_Worker_API)
- [PWA Best Practices](https://web.dev/pwa-checklist/)
- [web-push gem documentation](https://github.com/zaru/webpush)
