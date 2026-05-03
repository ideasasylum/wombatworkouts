import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="webauthn"
export default class extends Controller {
  static targets = ["loading", "error", "errorMessage"]
  static values = {
    options: Object,
    email: String,
    flow: String, // "registration", "authentication", or "conditional"
    verifyUrl: String // URL to submit credential to
  }

  connect() {
    // Check browser support on connect
    if (!this.checkBrowserSupport()) {
      return
    }

    // Auto-trigger WebAuthn flow when the partial loads
    // This provides a seamless experience without requiring a button click
    if (this.flowValue === "registration") {
      this.register()
    } else if (this.flowValue === "authentication") {
      this.authenticate()
    } else if (this.flowValue === "conditional") {
      this.authenticateConditional()
    }
  }

  disconnect() {
    // Abort any in-flight conditional get() so it doesn't leak across Turbo nav
    if (this.abortController) {
      this.abortController.abort()
      this.abortController = null
    }
  }

  checkBrowserSupport() {
    if (!window.PublicKeyCredential) {
      this.showError(
        "Your browser doesn't support biometric authentication. Please use a modern browser like Chrome, Safari, Firefox, or Edge."
      )
      return false
    }
    return true
  }

  async register() {
    if (!this.checkBrowserSupport()) {
      return
    }

    try {
      this.showLoading()
      this.hideError()

      // Parse and prepare the credential creation options
      const options = this.prepareCredentialCreationOptions(this.optionsValue)

      // Call WebAuthn API to create credential
      const credential = await navigator.credentials.create({ publicKey: options })

      if (!credential) {
        throw new Error("No credential returned")
      }

      // Convert credential response to format expected by backend
      const credentialResponse = this.encodeCredentialForRegistration(credential)

      // Submit to backend
      await this.submitCredential(credentialResponse)
    } catch (error) {
      this.hideLoading()
      this.handleRegistrationError(error)
    }
  }

  async authenticate() {
    if (!this.checkBrowserSupport()) {
      return
    }

    try {
      this.showLoading()
      this.hideError()

      // Parse and prepare the credential request options
      const options = this.prepareCredentialRequestOptions(this.optionsValue)

      // Call WebAuthn API to get credential
      const credential = await navigator.credentials.get({ publicKey: options })

      if (!credential) {
        throw new Error("No credential returned")
      }

      // Convert credential response to format expected by backend
      const credentialResponse = this.encodeCredentialForAuthentication(credential)

      // Submit to backend
      await this.submitCredential(credentialResponse)
    } catch (error) {
      this.hideLoading()
      this.handleAuthenticationError(error)
    }
  }

  // Conditional UI: passkey appears as autofill suggestion in the email field.
  // Browsers that support this skip the modal sheet entirely, sidestepping
  // Safari's "set up a passkey" interception that breaks the modal flow.
  async authenticateConditional() {
    if (!window.PublicKeyCredential ||
        typeof PublicKeyCredential.isConditionalMediationAvailable !== "function") {
      return
    }

    const supported = await PublicKeyCredential.isConditionalMediationAvailable()
    if (!supported) {
      return
    }

    if (this.abortController) {
      this.abortController.abort()
    }
    this.abortController = new AbortController()

    try {
      const options = this.prepareCredentialRequestOptions(this.optionsValue)
      const credential = await navigator.credentials.get({
        publicKey: options,
        mediation: "conditional",
        signal: this.abortController.signal
      })

      if (!credential) {
        return
      }

      const credentialResponse = this.encodeCredentialForAuthentication(credential)
      await this.submitCredential(credentialResponse)
    } catch (error) {
      if (error.name === "AbortError") {
        return
      }
      console.error("Conditional authentication error:", error)
    }
  }

  retry(event) {
    if (event && typeof event.preventDefault === "function") {
      event.preventDefault()
    }
    this.hideError()
    if (this.flowValue === "registration") {
      this.register()
    } else if (this.flowValue === "authentication") {
      this.authenticate()
    }
  }

  prepareCredentialCreationOptions(options) {
    // Convert base64 strings to ArrayBuffer
    return {
      ...options,
      challenge: this.base64ToArrayBuffer(options.challenge),
      user: {
        ...options.user,
        id: this.base64ToArrayBuffer(options.user.id)
      },
      excludeCredentials: (options.excludeCredentials || []).map(cred => ({
        ...cred,
        id: this.base64ToArrayBuffer(cred.id)
      }))
    }
  }

  prepareCredentialRequestOptions(options) {
    // Convert base64 strings to ArrayBuffer
    return {
      ...options,
      challenge: this.base64ToArrayBuffer(options.challenge),
      allowCredentials: (options.allowCredentials || []).map(cred => ({
        ...cred,
        id: this.base64ToArrayBuffer(cred.id)
      }))
    }
  }

  encodeCredentialForRegistration(credential) {
    // Convert ArrayBuffer responses to base64 for transmission to backend
    return {
      id: credential.id,
      rawId: this.arrayBufferToBase64(credential.rawId),
      type: credential.type,
      response: {
        clientDataJSON: this.arrayBufferToBase64(credential.response.clientDataJSON),
        attestationObject: this.arrayBufferToBase64(credential.response.attestationObject)
      }
    }
  }

  encodeCredentialForAuthentication(credential) {
    // Convert ArrayBuffer responses to base64 for transmission to backend
    return {
      id: credential.id,
      rawId: this.arrayBufferToBase64(credential.rawId),
      type: credential.type,
      response: {
        clientDataJSON: this.arrayBufferToBase64(credential.response.clientDataJSON),
        authenticatorData: this.arrayBufferToBase64(credential.response.authenticatorData),
        signature: this.arrayBufferToBase64(credential.response.signature),
        userHandle: credential.response.userHandle ? this.arrayBufferToBase64(credential.response.userHandle) : null
      }
    }
  }

  async submitCredential(credentialResponse) {
    // Create form and submit via Turbo
    const form = document.createElement("form")
    form.method = "POST"
    form.action = this.verifyUrlValue

    // Add CSRF token
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
    if (csrfToken) {
      const csrfInput = document.createElement("input")
      csrfInput.type = "hidden"
      csrfInput.name = "authenticity_token"
      csrfInput.value = csrfToken
      form.appendChild(csrfInput)
    }

    // Add email if known. Conditional UI submits without one — the server
    // resolves the user from the credential's external_id.
    if (this.hasEmailValue && this.emailValue.length > 0) {
      const emailInput = document.createElement("input")
      emailInput.type = "hidden"
      emailInput.name = "email"
      emailInput.value = this.emailValue
      form.appendChild(emailInput)
    }

    // Add credential response as JSON
    const credentialInput = document.createElement("input")
    credentialInput.type = "hidden"
    credentialInput.name = "credential_response"
    credentialInput.value = JSON.stringify(credentialResponse)
    form.appendChild(credentialInput)

    // Submit form
    document.body.appendChild(form)
    form.submit()
  }

  handleRegistrationError(error) {
    console.error("Registration error:", error)

    if (error.name === "NotAllowedError") {
      this.showError("Registration cancelled. Please try again.")
    } else if (error.name === "InvalidStateError") {
      this.showError("This device is already registered. Please try signing in instead.")
    } else if (error.name === "NotSupportedError") {
      this.showError("Your device doesn't support the required biometric features.")
    } else {
      this.showError("Unable to register credential. Please try again.")
    }
  }

  handleAuthenticationError(error) {
    console.error("Authentication error:", error)

    if (error.name === "NotAllowedError") {
      this.showError("Sign in cancelled.")
    } else if (error.name === "NotFoundError") {
      this.showError("Unable to verify your identity. This device may not be registered yet.")
    } else if (error.name === "TimeoutError") {
      this.showError("Authentication timed out. Please try again.")
    } else {
      this.showError("Unable to verify your identity. Please try again.")
    }
  }

  showLoading() {
    if (this.hasLoadingTarget) {
      this.loadingTarget.classList.remove("hidden")
    }
  }

  hideLoading() {
    if (this.hasLoadingTarget) {
      this.loadingTarget.classList.add("hidden")
    }
  }

  showError(message) {
    if (this.hasErrorTarget && this.hasErrorMessageTarget) {
      this.errorMessageTarget.textContent = message
      this.errorTarget.classList.remove("hidden")
    }
  }

  hideError() {
    if (this.hasErrorTarget) {
      this.errorTarget.classList.add("hidden")
    }
  }

  // Utility functions for base64/ArrayBuffer conversion
  base64ToArrayBuffer(base64) {
    // Handle URL-safe base64
    const padding = "=".repeat((4 - (base64.length % 4)) % 4)
    const base64Standard = (base64 + padding)
      .replace(/-/g, "+")
      .replace(/_/g, "/")

    const binaryString = window.atob(base64Standard)
    const bytes = new Uint8Array(binaryString.length)
    for (let i = 0; i < binaryString.length; i++) {
      bytes[i] = binaryString.charCodeAt(i)
    }
    return bytes.buffer
  }

  arrayBufferToBase64(buffer) {
    const bytes = new Uint8Array(buffer)
    let binary = ""
    for (let i = 0; i < bytes.length; i++) {
      binary += String.fromCharCode(bytes[i])
    }
    // Use URL-safe base64
    return window.btoa(binary)
      .replace(/\+/g, "-")
      .replace(/\//g, "_")
      .replace(/=/g, "")
  }
}
