import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="push-subscription"
export default class extends Controller {
  static targets = ["permissionWarning", "permissionGranted", "timezoneInput"]

  connect() {
    // Detect and set timezone
    this.detectTimezone()

    // Check notification permission status on page load
    this.checkPermissionStatus()
  }

  detectTimezone() {
    const timezone = Intl.DateTimeFormat().resolvedOptions().timeZone

    // Set timezone in hidden field if present
    if (this.hasTimezoneInputTarget) {
      this.timezoneInputTarget.value = timezone
    }

    // Update user's timezone if not already set
    this.updateUserTimezone(timezone)
  }

  async updateUserTimezone(timezone) {
    // Only update if we have a timezone and user doesn't have one set
    // This is handled automatically via the reminder form submission
    // But we can also update the user record directly if needed
    console.log('Detected timezone:', timezone)
  }

  checkPermissionStatus() {
    if (!('Notification' in window)) {
      console.log('This browser does not support notifications')
      return
    }

    const permission = Notification.permission

    if (permission === 'default') {
      // Show permission request UI
      this.showPermissionWarning()
    } else if (permission === 'granted') {
      // Show granted message
      this.showPermissionGranted()
      // Ensure subscription exists
      this.ensureSubscription()
    } else {
      // Permission denied - show warning
      this.showPermissionWarning()
    }
  }

  showPermissionWarning() {
    if (this.hasPermissionWarningTarget) {
      this.permissionWarningTarget.classList.remove('hidden')
    }
    if (this.hasPermissionGrantedTarget) {
      this.permissionGrantedTarget.classList.add('hidden')
    }
  }

  showPermissionGranted() {
    if (this.hasPermissionWarningTarget) {
      this.permissionWarningTarget.classList.add('hidden')
    }
    if (this.hasPermissionGrantedTarget) {
      this.permissionGrantedTarget.classList.remove('hidden')
    }
  }

  async requestPermission() {
    if (!('Notification' in window)) {
      alert('This browser does not support notifications')
      return
    }

    if (!('serviceWorker' in navigator)) {
      alert('This browser does not support service workers')
      return
    }

    try {
      const permission = await Notification.requestPermission()

      if (permission === 'granted') {
        console.log('Notification permission granted')
        this.showPermissionGranted()

        // Subscribe to push notifications
        await this.subscribeToPush()
      } else {
        console.log('Notification permission denied')
        alert('Notifications are blocked. Please enable them in your browser settings.')
      }
    } catch (error) {
      console.error('Error requesting notification permission:', error)
      alert('An error occurred while requesting notification permission')
    }
  }

  async subscribeToPush() {
    try {
      // Wait for service worker to be ready
      const registration = await navigator.serviceWorker.ready

      // Get VAPID public key from meta tag or configuration
      const vapidPublicKey = this.getVapidPublicKey()

      if (!vapidPublicKey) {
        console.error('VAPID public key not found')
        return
      }

      // Subscribe to push notifications
      const subscription = await registration.pushManager.subscribe({
        userVisibleOnly: true,
        applicationServerKey: this.urlBase64ToUint8Array(vapidPublicKey)
      })

      console.log('Push subscription created:', subscription)

      // Send subscription to server
      await this.sendSubscriptionToServer(subscription)

    } catch (error) {
      console.error('Error subscribing to push notifications:', error)
      alert('An error occurred while setting up push notifications')
    }
  }

  async ensureSubscription() {
    try {
      const registration = await navigator.serviceWorker.ready
      const subscription = await registration.pushManager.getSubscription()

      if (!subscription) {
        // No subscription exists, create one
        await this.subscribeToPush()
      } else {
        console.log('Push subscription already exists')
      }
    } catch (error) {
      console.error('Error checking subscription:', error)
    }
  }

  async sendSubscriptionToServer(subscription) {
    const subscriptionObject = subscription.toJSON()

    try {
      const response = await fetch('/push_subscriptions', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': this.getCsrfToken()
        },
        body: JSON.stringify({
          push_subscription: {
            endpoint: subscriptionObject.endpoint,
            p256dh_key: subscriptionObject.keys.p256dh,
            auth_key: subscriptionObject.keys.auth
          }
        })
      })

      if (response.ok) {
        console.log('Subscription sent to server successfully')
      } else {
        const errorData = await response.json()
        console.error('Error sending subscription to server:', errorData)
      }
    } catch (error) {
      console.error('Error sending subscription to server:', error)
    }
  }

  getVapidPublicKey() {
    // Try to get from meta tag
    const metaTag = document.querySelector('meta[name="vapid-public-key"]')
    if (metaTag) {
      return metaTag.content
    }

    // Fallback to environment variable or hardcoded value
    // In production, this should come from the server
    return window.VAPID_PUBLIC_KEY || null
  }

  getCsrfToken() {
    const metaTag = document.querySelector('meta[name="csrf-token"]')
    return metaTag ? metaTag.content : ''
  }

  // Helper function to convert VAPID key to Uint8Array
  urlBase64ToUint8Array(base64String) {
    const padding = '='.repeat((4 - base64String.length % 4) % 4)
    const base64 = (base64String + padding)
      .replace(/\-/g, '+')
      .replace(/_/g, '/')

    const rawData = window.atob(base64)
    const outputArray = new Uint8Array(rawData.length)

    for (let i = 0; i < rawData.length; ++i) {
      outputArray[i] = rawData.charCodeAt(i)
    }
    return outputArray
  }
}
