import { Controller } from "@hotwired/stimulus"

/**
 * Mobile Menu Controller
 *
 * Manages the mobile navigation drawer (hamburger menu)
 * - Toggles menu visibility on mobile viewports
 * - Handles backdrop click to close menu
 * - Supports keyboard navigation (Escape key to close)
 * - Prevents body scroll when menu is open
 */
export default class extends Controller {
  static targets = ["drawer"]

  connect() {
    // Bind keyboard listener
    this.handleKeydown = this.handleKeydown.bind(this)
  }

  disconnect() {
    // Cleanup: Remove event listener and restore scroll
    document.removeEventListener('keydown', this.handleKeydown)
    this.enableBodyScroll()
  }

  /**
   * Toggle menu open/close
   */
  toggle() {
    if (this.isOpen()) {
      this.close()
    } else {
      this.open()
    }
  }

  /**
   * Open the menu drawer
   */
  open() {
    // Show the drawer
    this.drawerTarget.classList.remove('hidden')

    // Add keyboard listener
    document.addEventListener('keydown', this.handleKeydown)

    // Prevent body scroll
    this.disableBodyScroll()

    // Trigger animation on next frame
    requestAnimationFrame(() => {
      this.drawerTarget.querySelector('[data-drawer-panel]')?.classList.remove('translate-x-full')
    })
  }

  /**
   * Close the menu drawer
   */
  close() {
    const panel = this.drawerTarget.querySelector('[data-drawer-panel]')

    // Trigger slide-out animation
    if (panel) {
      panel.classList.add('translate-x-full')
    }

    // Remove keyboard listener
    document.removeEventListener('keydown', this.handleKeydown)

    // Restore body scroll
    this.enableBodyScroll()

    // Hide drawer after animation completes
    setTimeout(() => {
      this.drawerTarget.classList.add('hidden')
    }, 300) // Match transition duration
  }

  /**
   * Check if menu is currently open
   */
  isOpen() {
    return !this.drawerTarget.classList.contains('hidden')
  }

  /**
   * Handle keyboard events (Escape to close)
   */
  handleKeydown(event) {
    if (event.key === 'Escape' && this.isOpen()) {
      this.close()
    }
  }

  /**
   * Prevent body scroll when menu is open
   */
  disableBodyScroll() {
    document.body.style.overflow = 'hidden'
  }

  /**
   * Restore body scroll when menu is closed
   */
  enableBodyScroll() {
    document.body.style.overflow = ''
  }
}
