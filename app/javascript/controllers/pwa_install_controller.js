import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="pwa-install"
// Wraps the <pwa-install> web component (https://github.com/khmyznikov/pwa-install)
// so we can show an install button in-page rather than auto-prompting.
export default class extends Controller {
  connect() {
    if (this.isInstalled()) {
      this.element.remove()
    } else {
      this.element.classList.remove("hidden")
    }
  }

  isInstalled() {
    if (window.matchMedia && window.matchMedia("(display-mode: standalone)").matches) {
      return true
    }
    if (window.navigator.standalone === true) {
      return true
    }
    return false
  }

  show(event) {
    event.preventDefault()
    const pwaInstall = document.querySelector("pwa-install")
    if (pwaInstall && typeof pwaInstall.showDialog === "function") {
      pwaInstall.showDialog(true)
    } else {
      console.warn("pwa-install element not found or not ready")
    }
  }
}
