import { Controller } from "@hotwired/stimulus"
import { sessionPersistence } from "../lib/session_persistence"

/**
 * Session Health Controller
 *
 * Monitors session health and handles recovery when iOS PWA loses cookies.
 * Runs health check on page load and periodically validates session state.
 */
export default class extends Controller {
  static values = {
    checkUrl: { type: String, default: "/session/health" },
    isAuthenticated: { type: Boolean, default: false },
    userData: { type: Object, default: {} }
  }

  async connect() {
    console.log("Session health controller connected");

    // If user is authenticated, save session to IndexedDB
    if (this.isAuthenticatedValue && this.userDataValue.userId) {
      await this.saveSessionLocally();
    }

    // Only run health check if user is supposed to be authenticated
    if (this.isAuthenticatedValue) {
      this.performHealthCheck();
    }

    // Set up periodic health checks (every 5 minutes)
    this.healthCheckInterval = setInterval(() => {
      if (this.isAuthenticatedValue) {
        this.performHealthCheck();
      }
    }, 5 * 60 * 1000);
  }

  async saveSessionLocally() {
    try {
      await sessionPersistence.saveSession({
        userId: this.userDataValue.userId,
        email: this.userDataValue.email
      });
      console.log("Session saved to IndexedDB");
    } catch (error) {
      console.error("Failed to save session locally:", error);
    }
  }

  disconnect() {
    if (this.healthCheckInterval) {
      clearInterval(this.healthCheckInterval);
    }
  }

  async performHealthCheck() {
    try {
      // Check if we have a local session stored
      const localSession = await sessionPersistence.getSession();

      if (!localSession) {
        console.log("No local session found");
        return;
      }

      // Check if session is still valid (not expired)
      const isValid = await sessionPersistence.isSessionValid();
      if (!isValid) {
        console.log("Local session expired");
        await sessionPersistence.clearSession();
        // Optionally redirect to login
        return;
      }

      // Check if we need to verify with server
      const needsVerification = await sessionPersistence.needsVerification();
      if (needsVerification) {
        console.log("Verifying session with server...");
        await this.verifyWithServer();
      }
    } catch (error) {
      console.error("Session health check failed:", error);
    }
  }

  async verifyWithServer() {
    try {
      const response = await fetch(this.checkUrlValue, {
        method: 'GET',
        headers: {
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest'
        },
        credentials: 'same-origin'
      });

      if (response.ok) {
        const data = await response.json();

        if (data.authenticated) {
          // Session is valid, update last verified timestamp
          await sessionPersistence.updateLastVerified();
          console.log("Session verified successfully");
        } else {
          // Server says not authenticated, but we have local session
          // This means cookie was lost - try to restore or prompt re-auth
          console.warn("Cookie lost - session exists locally but not on server");
          await this.handleCookieLoss();
        }
      } else if (response.status === 401) {
        // Unauthorized - clear local session and redirect
        console.log("Session expired on server");
        await sessionPersistence.clearSession();
        window.location.href = '/signin';
      } else {
        console.error("Health check failed:", response.status);
      }
    } catch (error) {
      console.error("Failed to verify session with server:", error);
      // Network error - keep local session for offline use
    }
  }

  async handleCookieLoss() {
    // When cookie is lost but local session exists, show a notification
    // and prompt user to re-authenticate
    const localSession = await sessionPersistence.getSession();

    if (localSession) {
      // Show a gentle notification that they need to sign in again
      console.log("Detected cookie loss for user:", localSession.email);

      // You can dispatch a custom event here for the UI to handle
      this.dispatch("cookieLost", {
        detail: { email: localSession.email },
        bubbles: true
      });

      // Clear the local session since cookie is gone
      await sessionPersistence.clearSession();

      // Redirect to signin with a helpful message
      const returnPath = encodeURIComponent(window.location.pathname);
      window.location.href = `/signin?return_to=${returnPath}&reason=session_expired`;
    }
  }
}
