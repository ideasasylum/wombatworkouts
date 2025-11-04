# Task Breakdown: Minimalist Notepad UI Redesign

## Overview
Total Task Groups: 11
Estimated Complexity: High (comprehensive UI overhaul across 8 pages)

This is a complete visual redesign to match a live prototype exactly. All existing functionality must be preserved while transforming the UI to a minimalist, notepad-inspired aesthetic.

## Task List

### Phase 1: Design System Foundation

#### Task Group 1: Design Tokens & Typography Setup
**Dependencies:** None
**Complexity:** Low
**Visual Reference:** All prototype screenshots for color/typography verification

- [x] 1.0 Establish design system foundation
  - [x] 1.1 Update Tailwind configuration
    - Add Inter font family (load from Google Fonts or self-host)
    - Configure custom color palette with exact RGB values
    - Set default border-radius to 2px globally
    - Add custom design tokens to Tailwind theme
  - [x] 1.2 Create CSS custom properties in application.css
    - Define color system variables:
      - `--color-background: rgb(237, 242, 247)`
      - `--color-surface: rgb(255, 255, 255)`
      - `--color-text-primary: rgb(26, 26, 26)`
      - `--color-text-secondary: rgb(107, 114, 128)`
      - `--color-border: rgb(229, 231, 235)`
      - `--color-button-primary-bg: rgb(26, 26, 26)`
      - `--color-button-primary-text: rgb(255, 255, 255)`
    - Define typography scale variables:
      - `--font-size-h1: 18px` (weight 700, line-height 28px)
      - `--font-size-h2: 16px` (weight 600, line-height 24px)
      - `--font-size-h3: 16px` (weight 500, line-height 24px)
      - `--font-size-body: 16px` (weight 400, line-height 24px)
      - `--font-size-button: 14px` (weight 500, line-height 20px)
    - Define spacing/layout variables:
      - `--radius-minimal: 2px`
      - `--shadow-card: 0 1px 3px rgba(0,0,0,0.1)`
      - `--spacing-card-padding: 1.5rem`
      - `--spacing-section-gap: 2rem`
  - [x] 1.3 Update application layout background
    - Change body background from `bg-gray-50` to `bg-[rgb(237,242,247)]`
    - Update in `/app/views/layouts/application.html.erb`
    - Ensure background color applies to all authenticated views
  - [x] 1.4 Remove all gradient-based styling
    - Search codebase for gradient classes (e.g., `bg-gradient-*`)
    - Replace with solid color alternatives
    - Update button components to use solid black instead of indigo gradients

**Acceptance Criteria:**
- Inter font loads successfully across all pages
- CSS custom properties defined and accessible
- Body background color matches prototype: rgb(237, 242, 247)
- No gradients remain in the application
- Tailwind configuration includes all custom design tokens
- Typography scale matches specification exactly

---

### Phase 2: Icon & Component Library

#### Task Group 2: Icon System Implementation
**Dependencies:** Task Group 1
**Complexity:** Medium
**Visual Reference:** All prototype screenshots showing icon usage

- [x] 2.0 Build complete icon library
  - [x] 2.1 Identify icon library used in Lovable prototype
    - Analyze prototype screenshots to determine icon style (likely Heroicons outline)
    - Verify icon library compatibility with Rails/ERB partials
    - Document icon library choice and usage pattern
  - [x] 2.2 Create new icon partials in `/app/views/shared/icons/`
    - Create `_menu.html.erb` (hamburger menu: three horizontal lines)
    - Create `_pencil.html.erb` (edit action)
    - Create `_trash.html.erb` (delete action)
    - Create `_user_plus.html.erb` (sign up action)
    - Create `_arrow_right.html.erb` (sign in action)
    - Create `_check.html.erb` (complete/checkmark action)
    - Create `_skip_forward.html.erb` (skip action)
    - Create `_grip_vertical.html.erb` (drag handle)
    - Each icon should accept `class` parameter for sizing/color control
    - Standard sizing: `w-5 h-5` (20x20px) for buttons, `w-4 h-4` (16x16px) inline
  - [x] 2.3 Update existing icon partials
    - Verify `_play.html.erb` matches prototype style
    - Verify `_plus.html.erb` matches prototype style
    - Verify `_save.html.erb` matches prototype style
    - Ensure consistent SVG structure and class handling across all icons
  - [x] 2.4 Create icon usage documentation
    - Document which icon to use for each action type
    - Provide code examples for common use cases
    - Document sizing and color customization patterns

**Acceptance Criteria:**
- All required icons created as ERB partials
- Icons render with consistent sizing and styling
- Icons accept and properly handle class parameter
- Icon SVG structure matches Heroicons outline style
- Documentation complete with usage examples

---

#### Task Group 3: Base Component Updates
**Dependencies:** Task Groups 1-2
**Complexity:** Medium
**Visual Reference:** All prototype screenshots showing buttons, cards, forms

- [x] 3.0 Update core reusable components
  - [x] 3.1 Update button component (`/app/views/shared/_button.html.erb`)
    - Remove indigo color scheme completely
    - Implement primary variant: solid black bg (`bg-[rgb(26,26,26)]`), white text
    - Implement secondary variant: white bg with black border, icon only
    - Add icon-only button variant (no text, just icon)
    - Add icon+text button variant (icon left of text)
    - Apply 2px border-radius to all button variants
    - Use 14px font size, weight 500, line-height 20px for button text
    - Ensure proper padding for touch targets (minimum 44x44px on mobile)
    - Reuse pattern from existing button partial, adapt for new styles
  - [x] 3.2 Create card component pattern
    - Define reusable Tailwind classes for card styling
    - White background: `bg-white`
    - Shadow: `shadow-sm` or custom shadow matching `0 1px 3px rgba(0,0,0,0.1)`
    - Border radius: `rounded-sm` (2px)
    - Padding: `p-6` (1.5rem)
    - Document card component usage pattern
    - Created `/app/views/shared/_card.html.erb` partial
  - [x] 3.3 Update form input styling patterns
    - Created CSS utility classes for form inputs (.form-input, .form-textarea, .form-select)
    - Apply minimal border style to inputs/textareas
    - Set input backgrounds to white (`bg-white`)
    - Apply 2px border-radius to all form controls
    - Ensure labels appear above inputs (not inline or floating)
    - Add placeholder text styling (gray, not too light)
    - Maintain accessibility: proper label/input associations
  - [x] 3.4 Update navigation bar (`/app/views/shared/_navbar.html.erb`)
    - Redesign for desktop: horizontal top nav with text links
    - Add "Dashboard" and "Programs" text links
    - Position logo "Wombat Workouts" in top left
    - Position user email and "Log out" link in top right (desktop only)
    - Apply minimal styling: white background or subtle contrast
    - Remove any gradient or heavy styling from current navbar
    - Prepare structure for hamburger menu (full implementation in Task Group 5)

**Acceptance Criteria:**
- Button component supports primary, secondary, icon-only, and icon+text variants
- Buttons use solid black for primary, outline for secondary (no indigo colors)
- Card component pattern established and documented
- Form inputs have minimal styling with white backgrounds and 2px borders
- Labels positioned above inputs consistently
- Navigation bar redesigned for desktop layout
- All components use design tokens from Task Group 1
- Comprehensive component documentation created

---

### Phase 3: Authentication & Layout Views

#### Task Group 4: Authentication Pages & Base Layout
**Dependencies:** Task Groups 1-3
**Complexity:** Low
**Visual Reference:** `prototype-auth-desktop.png`, `prototype-auth-mobile.png`

- [x] 4.0 Complete authentication views redesign
  - [x] 4.1 Update authentication layout template
    - Remove navigation bar for unauthenticated layout (already configured in application.html.erb)
    - Center form on light background (rgb(237, 242, 247))
    - Apply max-width constraint to form container
    - Ensure mobile-responsive padding and spacing
  - [x] 4.2 Update sign in view (`app/views/sessions/new_signin.html.erb`)
    - Add "Wombat Workouts" title (18px, weight 700)
    - Add "Track your exercises" tagline below title (gray text)
    - Single email input field with minimal styling
    - Two buttons side-by-side:
      - "Sign Up" button: outline style, user-plus icon
      - "Sign In" button: solid style, arrow-right icon
    - Match prototype layout exactly
  - [x] 4.3 Update sign up view (`app/views/sessions/new_signup.html.erb`)
    - Apply same minimal styling as sign in view
    - Maintain form field order and button arrangement per prototype
  - [x] 4.4 Update signin challenge partial (`app/views/sessions/_signin_challenge.html.erb`)
    - Replace indigo colors with black/white monochrome design
    - Update spinner color to black
    - Update text colors to use design system tokens
    - Update error container to use minimal white card with border
    - Update "Try a different email" link styling
  - [x] 4.5 Update signup challenge partial (`app/views/sessions/_signup_challenge.html.erb`)
    - Replace indigo colors with black/white monochrome design
    - Update spinner color to black
    - Update text colors to use design system tokens
    - Update error container to use minimal white card with border
    - Update "Try a different email" link styling
  - [x] 4.6 Update flash message styling (`/app/views/shared/_flash_messages.html.erb`)
    - Apply minimal styling consistent with design system (already done in Task Group 3)
    - Use white cards with subtle borders for messages
    - Maintain error/success color coding (minimal, not gradients)

**Acceptance Criteria:**
- Authentication pages match prototype exactly
- Form centered with appropriate spacing
- Buttons render with correct styles and icons (user-plus for Sign Up, arrow-right for Sign In)
- No navigation bar on unauthenticated layout
- Flash messages styled consistently with design system
- Mobile responsive with proper touch targets
- Challenge partials use minimalist black/white color scheme
- No indigo colors remain in authentication flow

**Testing Note:** Tests will be written in Task Group 11 (Visual QA & Testing phase) to verify authentication pages render correctly and all functionality works as expected.

---

### Phase 4: Programs & Exercises Views

#### Task Group 5: Programs List with Hamburger Menu
**Dependencies:** Task Groups 1-4
**Complexity:** Medium
**Visual Reference:** `prototype-dashboard-desktop.png`, `prototype-dashboard-mobile.png`, `prototype-programs-desktop.png`, `prototype-programs-mobile.png`

- [x] 5.0 Update programs and dashboard views
  - [x] 5.1 Implement hamburger menu (mobile navigation)
    - Create Stimulus controller for menu toggle
    - Mobile: hamburger icon button in top-right
    - Menu drawer slides in from right with overlay
    - Menu contains: Dashboard, Programs links, user email, logout
    - Desktop: show full navbar (no hamburger)
  - [x] 5.2 Update dashboard view (dashboard/index.html.erb)
    - Section heading: "Programs" with "New" button
    - Program cards with white background, minimal shadow
    - Card content: title (clickable link), description, "Start" button, edit/delete icons
    - Empty state if no programs
  - [x] 5.3 Update programs index view (programs/index.html.erb)
    - Similar layout to dashboard
    - Use card component for each program
    - Edit icon (pencil), Delete icon (trash) - icon-only buttons
    - "Start" button - primary button with play icon

**Acceptance Criteria:**
- Hamburger menu works on mobile (< 768px)
- Menu drawer slides in with overlay
- Desktop shows full navbar (no hamburger)
- Program cards match prototype styling
- Clickable program titles link to show page
- Icon-only buttons for edit/delete
- "New" and "Start" buttons match prototype

---

#### Task Group 6: New/Edit Program Forms
**Dependencies:** Task Groups 1-5
**Complexity:** Low
**Visual Reference:** `prototype-program-new-desktop.png`, `prototype-program-new-mobile.png`

- [x] 6.0 Complete program form redesign
  - [x] 6.1 Write 2-3 focused tests for program forms
    - Test new program form renders correctly
    - Test form submission creates program
    - Test edit program form pre-populates data
    - Do NOT write exhaustive validation tests at this stage
  - [x] 6.2 Update new program form (`/app/views/programs/new.html.erb`)
    - Add "New Program" heading (h1 style: 18px, weight 700)
    - Create "Name" field with label above input
    - Add placeholder text: "e.g., Upper Body Strength"
    - Create "Description (optional)" textarea with label above
    - Add placeholder text: "Brief description..."
    - Apply minimal input styling (white bg, 2px border, subtle border color)
    - Position "Create" button (solid style, save icon) bottom-right of form
    - Ensure form contained in white card with proper padding
  - [x] 6.3 Update edit program form (`/app/views/programs/edit.html.erb`)
    - Change heading to "Edit Program"
    - Apply same styling as new program form
    - Change button text to "Save" (keep save icon)
    - Pre-populate form fields with existing program data
  - [x] 6.4 Update form partial (_form.html.erb)
    - Apply new form styling using form-label and form-input utilities
    - Use form-textarea for description field
    - Add Cancel button (secondary style)
    - Add Create/Save button with save icon (primary style)
    - Position buttons at bottom-right in flex container
    - Match prototype layout

**Acceptance Criteria:**
- New/edit forms match prototype styling
- Form inputs use minimal white styling with borders
- Save button uses primary style with save icon
- Cancel button uses secondary/outline style
- Forms are responsive on mobile
- No gradients on form pages
- All 3 tests pass

---

#### Task Group 7: Program Detail/Show View
**Dependencies:** Task Groups 1-6
**Complexity:** Medium

- [x] 7.0 Update program show page with exercises
  - [x] 7.1 Update program header section
    - Program title (h1 style)
    - Description text (gray, smaller)
    - "Start Workout" button (primary with play icon)
    - Edit icon button (pencil)
    - Delete icon button (trash)
  - [x] 7.2 Update exercises section
    - "Exercises" heading (h2 style)
    - "Add Exercise" button (secondary with plus icon)
    - Exercise cards in white with minimal shadow
    - Each card: exercise name, repeat count, description
    - Edit/delete icon buttons for each exercise
    - Drag handle icon for reordering
    - Empty state if no exercises
  - [x] 7.3 Update exercise inline form (Turbo Frame)
    - Form appears inline when adding/editing
    - Use form utilities from Task Group 3
    - Save/Cancel buttons with proper styling
  - [x] 7.4 Ensure Turbo Frame updates work correctly
    - Verify add exercise form appears inline
    - Verify exercise list updates without page reload
    - Maintain drag-and-drop functionality

**Acceptance Criteria:**
- Program show page matches prototype styling
- Start Workout button is primary style with play icon
- Edit/delete are icon-only buttons
- Exercise cards have white background
- Add Exercise button matches prototype
- Turbo Frame updates work smoothly
- Drag-and-drop still functional

---

### Phase 5: Workout Views

#### Task Group 8: Workout Preview View
**Dependencies:** Task Groups 1-7
**Complexity:** Low

- [x] 8.0 Update workout preview/new page
  - [x] 8.1 Update workout new view (workouts/new.html.erb)
    - Program title (h1 style)
    - Exercise count display
    - List of exercises to complete
    - Each exercise card: name, reps, description
    - "Begin Workout" button (primary with play icon)
    - "Cancel" button (secondary)
  - [x] 8.2 Ensure preview page is responsive
    - Mobile: "Begin Workout" button fixed at bottom
    - Desktop: button in normal flow
    - Cards stack properly on mobile

**Acceptance Criteria:**
- Preview page matches prototype styling
- Exercise list displays clearly
- Begin Workout button is primary with play icon
- Cancel button is secondary style
- Mobile has floating action button at bottom
- Cards are white with minimal shadow

---

#### Task Group 9: Active Workout View with Progress
**Dependencies:** Task Groups 1-8
**Complexity:** Medium

- [x] 9.0 Update active workout page
  - [x] 9.1 Update workout show view (workouts/show.html.erb)
    - Progress indicator: "Exercise X of Y" at top
    - Current exercise card (white, prominent)
    - Exercise name (h2 style)
    - Set information (e.g., "Set 2 of 3")
    - Exercise description
    - "Mark Complete" button (primary with check icon)
    - "Skip" button (secondary with skip icon)
  - [x] 9.2 Implement mobile floating action buttons
    - Mobile: buttons fixed at bottom of screen
    - "Mark Complete" and "Skip" side by side
    - Full-width on mobile, proper spacing
    - Desktop: buttons in normal flow
  - [x] 9.3 Ensure Turbo Stream updates work
    - Progress indicator updates
    - Next exercise loads smoothly
    - Completion state updates correctly

**Acceptance Criteria:**
- Progress indicator displays correctly
- Current exercise card is prominent
- Mark Complete button is primary with check icon
- Skip button is secondary with skip icon
- Mobile has floating action buttons at bottom
- Turbo Stream updates work smoothly
- Desktop/mobile layouts match prototype

---

#### Task Group 10: Workout Complete View
**Dependencies:** Task Groups 1-9
**Complexity:** Low
**Visual Reference:** `prototype-workout-complete-desktop.png`, `prototype-workout-complete-mobile.png`

- [x] 10.0 Update workout completion state
  - [x] 10.1 Update completed workout display in show view
    - "Workout Complete!" heading (h1 style)
    - Celebration emoji or icon (checkmark icon)
    - Summary stats: exercises completed, time taken
    - "Back to Dashboard" button (primary)
    - List of completed exercises (optional detail)
  - [x] 10.2 Ensure completion screen is responsive
    - Mobile: button at bottom or inline depending on content
    - Desktop: button in normal flow
    - Stats display clearly on all sizes

**Acceptance Criteria:**
- Completion message is clear and prominent
- Stats display correctly
- Back to Dashboard button is primary style
- Layout is responsive on mobile
- Design matches prototype completion state

---

### Phase 6: Visual QA & Testing

#### Task Group 11: Visual QA & Testing
**Dependencies:** Task Groups 1-10
**Complexity:** Medium

- [x] 11.0 Comprehensive visual quality assurance
  - [x] 11.1 Visual comparison using Chrome MCP
    - Compare live app against all 16 prototype screenshots
    - Verify colors match exactly (5px tolerance)
    - Check typography, spacing, borders
    - Test at both desktop (1280x720) and mobile (375x667) viewports
  - [x] 11.2 Responsive behavior testing
    - Test hamburger menu at 768px breakpoint
    - Test floating action buttons on mobile workout views
    - Verify all touch targets are 44x44px minimum
  - [x] 11.3 Run all existing tests
    - Run full test suite: bin/rails test
    - Run system tests: bin/rails test:system
    - Ensure no regressions
  - [x] 11.4 Accessibility audit
    - Check color contrast meets WCAG AA
    - Verify all icon-only buttons have aria-labels
    - Test keyboard navigation
  - [x] 11.5 Document any visual gaps
    - Note any differences from prototype
    - Create list of remaining fixes if needed (max 5)

**Acceptance Criteria:**
- Visual comparison completed for all pages
- All tests pass
- Responsive behavior verified
- Accessibility standards met
- Any gaps documented

---

## Execution Order

Recommended implementation sequence:
1. **Phase 1:** Design System Foundation (Task Group 1)
2. **Phase 2:** Icon & Component Library (Task Groups 2-3)
3. **Phase 3:** Authentication & Layout Views (Task Group 4)
4. **Phase 4:** Programs & Exercises Views (Task Groups 5-7)
5. **Phase 5:** Workout Views (Task Groups 8-10)
6. **Phase 6:** Visual QA & Testing (Task Group 11)

## Dependencies Map

```
Task Group 1 (Design Tokens)
    |
    v
Task Group 2 (Icons) -----> Task Group 3 (Components)
    |                              |
    v                              v
Task Group 4 (Auth & Layout)
    |
    v
Task Group 5 (Programs List) ----> Task Group 6 (Program Forms)
    |                                      |
    v                                      v
Task Group 7 (Program Detail)
    |
    v
Task Group 8 (Workout Preview)
    |
    v
Task Group 9 (Active Workout)
    |
    v
Task Group 10 (Completed Workout)
    |
    v
Task Group 11 (Visual QA & Testing)
```

## Important Notes

### Testing Philosophy
- This redesign follows a **focused test-driven approach**
- Each task group (4-10) writes 2-5 tests maximum for critical behaviors only
- Tests verify visual rendering and core functionality, not exhaustive coverage
- Final QA phase (Task Group 11) adds maximum of 5 additional tests only if critical gaps exist
- Total expected tests: approximately 21-29 tests maximum for entire redesign

### Visual Fidelity Requirements
- **Pixel-perfect implementation required** - match prototype within 5px tolerance
- Use Chrome MCP or similar tool for automated visual comparison in Task Group 11
- All 16 prototype screenshots serve as visual specification reference
- Color values must match exactly - no approximations

### Functionality Preservation
- **All existing features must continue to work** without regression
- Turbo and Stimulus behavior must remain intact
- Forms validate and submit correctly
- Navigation functions as before
- CRUD operations work without changes

### Mobile-Specific Features
- Hamburger menu appears at 768px breakpoint (Tailwind 'md')
- Floating action buttons appear **only** on active workout view on mobile
- Touch targets minimum 44x44px throughout
- Test on actual mobile devices during Task Group 11

### Design System Consistency
- Centralize design tokens in Task Group 1
- All colors, typography, and spacing use defined tokens
- No hardcoded values scattered throughout views
- Reusable component partials follow existing Rails/ERB patterns

### Out of Scope
- Actual drag-and-drop exercise reordering (show handle but maintain current behavior)
- Dark mode implementation
- Additional theme customization
- Advanced animations and transitions
- New features beyond visual redesign
- Backend/database modifications
- Changing business logic or controller actions

## Success Metrics

- All 8 pages match prototype screenshots within 5px tolerance
- Approximately 21-29 feature-specific tests pass (not entire suite)
- No functionality regressions introduced
- Color contrast meets WCAG AA standards
- All touch targets meet 44x44px minimum on mobile
- Hamburger menu and floating buttons function smoothly
- Inter font loads efficiently across all pages
- Cross-browser compatibility verified
- Zero gradients remain in application
- Design system tokens centralized and documented
