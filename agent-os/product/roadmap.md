# Product Roadmap

## Development Path

This roadmap outlines the feature development sequence for Wombat Workouts, ordered by technical dependencies and the most direct path to delivering core value. Each feature represents an end-to-end implementation including frontend, backend, database, and testing.

---

1. [x] **User Authentication & Account Management** — Implement WebAuthn passwordless authentication for user sign-up, login, and session management using device biometrics (Face ID, Touch ID, fingerprint). Users can create accounts to own programs and track history. Requires webauthn gem and credential storage. `M`

2. [x] **Exercise Program CRUD** — Build the core Program model and controller with full CRUD operations. Users can create, edit, view, and delete exercise programs. Each program includes title, description, and UUID generation for sharing. `M`

3. [x] **Exercise Management within Programs** — Create the Exercise model with belongs_to relationship to Program. Users can add, edit, reorder, and remove exercises within a program. Each exercise includes name, repeat count (e.g., "3x"), video URL, and formatted description field. `M`

4. [x] **Public Program Viewing via UUID** — Implement public program access through UUID-based routes (e.g., /programs/:uuid). Anonymous users can view full program details including all exercises without authentication. UUID sharing system allows instant access via link. `S`

5. [x] **Session Start & Exercise Progression** — Build session management allowing users to start a program session and progress through exercises sequentially. Implement UI for marking individual exercises as complete during an active session, with clear visual indicators of progress (e.g., "Exercise 2 of 8"). `M`

6. [x] **Session Completion & History Tracking** — Create Session model to persist completed sessions with timestamps, associated program, and individual exercise completion records. Users can view their session history showing past completion dates and programs followed. `M`

7. [x] **Mobile-Responsive Exercise Interface** — Implement mobile-first UI using Tailwind CSS with large touch targets, clear typography, and optimized layout for phone screens. Exercise view displays video embeds, descriptions with proper formatting, and prominent completion buttons. Test across device sizes. `M`

8. [x] **Program Library & Dashboard** — Build user dashboard displaying all programs they've created (with edit/delete actions) and programs they've followed (with quick access to start new session). Implement basic filtering and sorting by recent activity. Dashboard shows 5 most recent programs and workouts with "View All" links when more exist. `S`

9. [~] **Exercise Video Embed Optimization** — Enhance video integration to support multiple platforms (YouTube, Vimeo, etc.) with proper responsive embeds. Implement video preview validation and fallback for invalid URLs. Consider autoplay and mute options for better UX. `S` _(Not necessary - YouTube and Instagram support sufficient)_

10. [x] **Exercise Description Formatting** — Add rich text formatting support for exercise descriptions (bold, lists, line breaks) using a simple markdown parser or Rails text helpers. Ensure formatted descriptions render properly on mobile. `XS`

11. [ ] **Scheduled Exercise Reminders** — Implement reminder system where users can set recurring notifications (e.g., "Monday, Wednesday, Friday at 7am") for specific programs. Build background job processing using Solid Queue (Rails 8 default) to send email reminders. `L`

12. [ ] **Progressive Web App (PWA) Setup** — Configure service workers, manifest file, and offline caching strategy to enable PWA installation. Users can add app to home screen and access previously viewed programs offline. Test installation flow on iOS and Android. `L`

13. [ ] **Production Deployment with Kamal 2** — Deploy the application to production server using Kamal 2 for zero-downtime deployments. Configure environment variables, SSL certificates, database migrations, and health checks. Set up deployment workflow for automated releases. `M`

---

## Development Status

### Completed (MVP Ready)
Items 1-8, 10 constitute the core MVP and are **COMPLETE**. The application delivers the full creator-follower workflow:
- WebAuthn passwordless authentication
- Program creation and management with exercises
- UUID-based sharing for frictionless access
- Workout session tracking with exercise completion
- Mobile-responsive design throughout
- Dashboard showing recent programs and workouts
- Exercise description formatting with markdown support

### Next Steps
The MVP is functional and ready for user testing. Remaining features are enhancements:

**Enhancement Features:**
- Item 11: Scheduled reminders for program adherence
- Item 12: PWA installation for native-like experience

**Infrastructure:**
- Item 13: Production deployment setup

### Notes
- Exercise timers intentionally omitted from initial roadmap - can be added as simple client-side feature later
- SQLite is sufficient for MVP; consider scaling strategy if concurrent usage grows significantly
- Video embed optimization (item 9) deemed unnecessary - current YouTube/Instagram support is sufficient
