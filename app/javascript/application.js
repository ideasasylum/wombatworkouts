// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

import "trix"
import "@rails/actiontext"

// Close the PWA install dialog before Turbo navigates or caches the page,
// so it doesn't appear stuck open on the next page or when restored from cache.
document.addEventListener("turbo:before-cache", () => {
  const el = document.querySelector("pwa-install")
  if (el && typeof el.hideDialog === "function") el.hideDialog()
})
