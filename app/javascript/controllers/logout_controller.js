import { Controller } from "@hotwired/stimulus"
import { sessionPersistence } from "../lib/session_persistence"

/**
 * Logout Controller
 *
 * Handles logout by clearing IndexedDB session data before submitting logout form.
 * This ensures local session state is cleared on iOS PWA.
 */
export default class extends Controller {
  async submit(event) {
    // Prevent default form submission
    event.preventDefault()

    try {
      // Clear local session data
      await sessionPersistence.clearSession()
      console.log("Local session cleared on logout")
    } catch (error) {
      console.error("Failed to clear local session:", error)
    } finally {
      // Continue with form submission to server
      event.target.submit()
    }
  }
}
