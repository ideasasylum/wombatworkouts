import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="flash"
// Handles popover flash messages with auto-dismiss and manual close
export default class extends Controller {
  static values = {
    autoDismiss: { type: Number, default: 3000 } // 3 seconds
  }

  connect() {
    // Show the popover immediately
    this.element.showPopover()

    // Add entrance animation class
    this.element.classList.add("flash-enter")

    // Auto-dismiss after specified time
    this.timeoutId = setTimeout(() => {
      this.close()
    }, this.autoDismissValue)
  }

  disconnect() {
    // Clean up timeout if element is removed
    if (this.timeoutId) {
      clearTimeout(this.timeoutId)
    }
  }

  close() {
    // Clear the auto-dismiss timeout if manually closing
    if (this.timeoutId) {
      clearTimeout(this.timeoutId)
    }

    // Add exit animation class
    this.element.classList.add("flash-exit")

    // Wait for animation to complete, then hide popover and remove element
    setTimeout(() => {
      this.element.hidePopover()
      this.element.remove()
    }, 200) // Match CSS transition duration
  }
}
