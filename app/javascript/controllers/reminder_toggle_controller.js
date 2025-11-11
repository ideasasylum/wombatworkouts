import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="reminder-toggle"
export default class extends Controller {
  static targets = ["statusText"]

  async toggle(event) {
    const checkbox = event.target
    const reminderId = checkbox.dataset.reminderId
    const enabled = checkbox.checked

    try {
      const response = await fetch(`/reminders/${reminderId}`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': this.getCsrfToken()
        },
        body: JSON.stringify({
          reminder: {
            enabled: enabled
          }
        })
      })

      if (!response.ok) {
        // Revert checkbox state on error
        checkbox.checked = !enabled
        throw new Error('Failed to update reminder')
      }

      // Update the status text if target exists
      if (this.hasStatusTextTarget) {
        this.statusTextTarget.textContent = enabled ? 'On' : 'Off'
      }

      console.log('Reminder updated successfully')
    } catch (error) {
      console.error('Error toggling reminder:', error)
      alert('Failed to update reminder. Please try again.')
      // Revert checkbox state and text
      checkbox.checked = !enabled
      if (this.hasStatusTextTarget) {
        this.statusTextTarget.textContent = !enabled ? 'On' : 'Off'
      }
    }
  }

  getCsrfToken() {
    const metaTag = document.querySelector('meta[name="csrf-token"]')
    return metaTag ? metaTag.content : ''
  }
}
