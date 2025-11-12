/**
 * Session Persistence Module
 *
 * Manages session state in IndexedDB to work around iOS PWA cookie limitations.
 * iOS Safari can aggressively clear cookies in standalone mode, so we maintain
 * a local copy of session data that survives cookie eviction.
 */

const DB_NAME = 'wombat-workouts-session';
const DB_VERSION = 1;
const STORE_NAME = 'session';

class SessionPersistence {
  constructor() {
    this.db = null;
    this.initPromise = this.initDB();
  }

  /**
   * Initialize IndexedDB
   */
  async initDB() {
    return new Promise((resolve, reject) => {
      const request = indexedDB.open(DB_NAME, DB_VERSION);

      request.onerror = () => {
        console.error('IndexedDB error:', request.error);
        reject(request.error);
      };

      request.onsuccess = () => {
        this.db = request.result;
        resolve(this.db);
      };

      request.onupgradeneeded = (event) => {
        const db = event.target.result;

        // Create object store if it doesn't exist
        if (!db.objectStoreNames.contains(STORE_NAME)) {
          db.createObjectStore(STORE_NAME);
        }
      };
    });
  }

  /**
   * Store session data after successful authentication
   */
  async saveSession(userData) {
    await this.initPromise;

    const sessionData = {
      userId: userData.userId,
      email: userData.email,
      authenticatedAt: Date.now(),
      lastVerified: Date.now(),
    };

    return new Promise((resolve, reject) => {
      const transaction = this.db.transaction([STORE_NAME], 'readwrite');
      const store = transaction.objectStore(STORE_NAME);
      const request = store.put(sessionData, 'current');

      request.onsuccess = () => {
        console.log('Session saved to IndexedDB');
        resolve(sessionData);
      };

      request.onerror = () => {
        console.error('Failed to save session:', request.error);
        reject(request.error);
      };
    });
  }

  /**
   * Retrieve stored session data
   */
  async getSession() {
    await this.initPromise;

    return new Promise((resolve, reject) => {
      const transaction = this.db.transaction([STORE_NAME], 'readonly');
      const store = transaction.objectStore(STORE_NAME);
      const request = store.get('current');

      request.onsuccess = () => {
        resolve(request.result || null);
      };

      request.onerror = () => {
        console.error('Failed to get session:', request.error);
        reject(request.error);
      };
    });
  }

  /**
   * Update last verified timestamp
   */
  async updateLastVerified() {
    await this.initPromise;

    const session = await this.getSession();
    if (!session) return null;

    session.lastVerified = Date.now();

    return new Promise((resolve, reject) => {
      const transaction = this.db.transaction([STORE_NAME], 'readwrite');
      const store = transaction.objectStore(STORE_NAME);
      const request = store.put(session, 'current');

      request.onsuccess = () => resolve(session);
      request.onerror = () => reject(request.error);
    });
  }

  /**
   * Clear session data (on logout)
   */
  async clearSession() {
    await this.initPromise;

    return new Promise((resolve, reject) => {
      const transaction = this.db.transaction([STORE_NAME], 'readwrite');
      const store = transaction.objectStore(STORE_NAME);
      const request = store.delete('current');

      request.onsuccess = () => {
        console.log('Session cleared from IndexedDB');
        resolve();
      };

      request.onerror = () => {
        console.error('Failed to clear session:', request.error);
        reject(request.error);
      };
    });
  }

  /**
   * Check if session is still valid (not too old)
   * Sessions older than 30 days are considered expired
   */
  async isSessionValid() {
    const session = await this.getSession();
    if (!session) return false;

    const THIRTY_DAYS = 30 * 24 * 60 * 60 * 1000;
    const age = Date.now() - session.authenticatedAt;

    return age < THIRTY_DAYS;
  }

  /**
   * Check if session needs verification
   * If last verified more than 1 hour ago, should re-verify with server
   */
  async needsVerification() {
    const session = await this.getSession();
    if (!session) return false;

    const ONE_HOUR = 60 * 60 * 1000;
    const timeSinceVerified = Date.now() - session.lastVerified;

    return timeSinceVerified > ONE_HOUR;
  }
}

// Export singleton instance
export const sessionPersistence = new SessionPersistence();
