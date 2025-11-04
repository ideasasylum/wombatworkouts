# Spec Requirements: Minimalist Notepad UI Redesign

## Initial Description

Redesign the application UI to have a minimalist, notepad-like aesthetic. The design should prioritize simplicity with:
- Minimal color palette
- Minimal text/words
- Icons prioritized over text labels where possible
- Clean, simple notepad-inspired styling
- Development approach: Desktop/tablet version first, then mobile version

This is a comprehensive UI overhaul that will affect styling across the entire application, transforming it from the current design to a more stripped-back, analog-inspired interface.

## Requirements Discussion

### Initial Context

User has created a fully functional prototype in Lovable.dev demonstrating the exact visual design to be implemented. The prototype includes 16 screenshots showing all major pages in both desktop and mobile views, providing complete visual specifications for the redesign.

### Design Philosophy

**Visual Identity:**
- Off-white/light gray-blue background: rgb(237, 242, 247)
- Near-black text: rgb(26, 26, 26)
- Solid colors only - no gradients anywhere
- Minimal color usage throughout
- Very minimal rounded corners (2px border-radius, almost square)
- Clean, flat design with minimal shadows
- Icon-first approach to navigation and actions

**Information Architecture:**
- Maintain current information density
- Clickable titles replace "View" buttons for navigation
- Current hierarchy is appropriate and should be maintained
- No literal paper styling (lines, texture, etc.) - clean digital aesthetic
- Use cards for content organization
- Maintain existing progress indicator structure

### Component Patterns

**Buttons:**
- Primary actions: Solid black background with white text and icon
- Secondary actions: Outline style with icon only (no text)
- Major actions: Icon + text label
- Secondary actions: Icon only
- No accent colors - keep monochromatic

**Icons:**
- Use same icon library as prototype (need to identify which library from Lovable prototype)
- Icons used consistently: play, plus, edit (pencil), delete (trash), hamburger menu, user-add, sign-in, checkmark, skip (forward), save, drag handle (vertical dots)

**Forms:**
- Simple input fields with minimal styling
- Labels positioned above inputs
- Text inputs and textareas use same background as cards
- Placeholder text for guidance
- 2px border-radius on form controls

**Cards:**
- White background (rgb(255, 255, 255))
- Minimal shadows for subtle elevation
- 2px border-radius
- Clean spacing between elements
- Used for grouping related content

### Typography Specifications

**Font Family:** Inter, sans-serif

**Type Scale:**
- h1 (Page titles): 18px, weight 700, line-height 28px
- h2 (Section headers): 16px, weight 600, line-height 24px
- h3 (Card titles): 16px, weight 500, line-height 24px
- body (Regular text): 16px, weight 400, line-height 24px
- button (Button text): 14px, weight 500, line-height 20px

**Text Colors:**
- Primary text: rgb(26, 26, 26) - near black
- Secondary text: gray (for descriptions, metadata)
- No colored text for emphasis

### Responsive Behavior

**Desktop/Tablet:**
- Top horizontal navigation bar with logo and text links
- User email and "Log out" link in top right
- Standard button placement within cards
- Main content centered with appropriate max-width

**Mobile:**
- Hamburger menu icon (top right) for navigation
- Navigation drawer slides in from side
- Floating action buttons at bottom of screen for primary actions (e.g., "Skip" and "Complete" during workout)
- Full-width cards with appropriate padding
- Touch-friendly button sizing

**Breakpoints:**
- Follow prototype's responsive breakpoints exactly
- Hamburger menu appears below tablet size
- Floating action buttons only on mobile

## Visual Assets

### Files Provided:

**Authentication Views:**
- `prototype-auth-desktop.png`: Clean centered auth form with "Wombat Workouts" title, tagline "Track your exercises", email input, and two buttons (outline "Sign Up" with user-plus icon, solid "Sign In" with arrow-right icon)
- `prototype-auth-mobile.png`: Same layout adapted for mobile with full-width form container

**Dashboard/Programs List:**
- `prototype-dashboard-desktop.png`: Top nav with text links, page heading "Programs", "+ New" button (outline style), program cards showing title, description, solid "Start" button with play icon, collapsible "More details" link, and icon-only edit/delete actions
- `prototype-dashboard-mobile.png`: Hamburger menu navigation, "+ New" button (outline), same card structure adapted for mobile width
- `prototype-programs-desktop.png`: Duplicate of dashboard view (same page)
- `prototype-programs-mobile.png`: Duplicate of dashboard mobile view

**New Program Form:**
- `prototype-program-new-desktop.png`: Simple form with "New Program" heading, "Name" and "Description (optional)" fields with placeholders, solid "Create" button with save icon positioned bottom-right
- `prototype-program-new-mobile.png`: Same form adapted for mobile

**Program Detail View:**
- `prototype-program-show-desktop.png`: Program card at top with full-width "Start Workout" button (solid, with play icon), "Exercises" section header with "+ Add" button, exercise cards showing drag handle, exercise name, rep count, exercise notes, icon-only edit/delete actions, program-level "Edit Program" and "Delete" buttons at bottom (outline style with icons)
- `prototype-program-show-mobile.png`: Same layout adapted for mobile with touch-friendly spacing

**Workout Preview (before starting):**
- `prototype-workout-preview-desktop.png`: Similar to program show view but in workout context
- `prototype-workout-preview-mobile.png`: Mobile adaptation

**Active Workout:**
- `prototype-workout-active-desktop.png`: Progress bar at top showing "Exercise 1 of 5" and "20%" completion, exercise name as large heading, set counter "Set 1 of 3", exercise notes in card, "Skip" (outline) and "Complete" (solid) buttons at bottom
- `prototype-workout-active-mobile.png`: Same layout with floating action buttons pinned to bottom of viewport

**Completed Workout:**
- `prototype-workout-complete-desktop.png`: Shows completed workout summary
- `prototype-workout-complete-mobile.png`: Mobile adaptation

### Visual Insights:

**Color System:**
- Background: rgb(237, 242, 247) - light bluish-gray
- Cards/Inputs: rgb(255, 255, 255) - pure white
- Text: rgb(26, 26, 26) - near black
- Secondary text: Medium gray for descriptions
- Buttons primary: Black with white text
- Buttons secondary: White with black border and text

**Spacing & Layout:**
- Generous whitespace between elements
- Cards have consistent internal padding
- Section headers clearly separate content areas
- Icons maintain consistent sizing
- Buttons have appropriate padding for touch targets

**Border & Elevation:**
- Border radius: 2px (almost square, very minimal rounding)
- Subtle shadows on cards for elevation
- No heavy drop shadows or 3D effects
- Clean separation through whitespace and subtle borders

**Icon Usage:**
- Navigation icons in mobile hamburger menu
- Action icons consistently placed (edit, delete on right side of cards)
- Primary buttons combine icon + text
- Secondary actions use icon only
- Drag handles for reorderable lists
- Progress indicators use simple bar (not circular)

**Fidelity Level:**
- High-fidelity mockups showing exact visual design
- Pixel-perfect implementation expected
- All colors, typography, spacing should match prototype exactly

## Requirements Summary

### Functional Requirements

**Visual Design:**
- Match prototype visual design exactly across all pages
- Implement design system with specified colors, typography, and spacing
- Use 2px border-radius throughout for minimal rounding
- No gradients - solid colors only
- Minimal color palette focused on black, white, and off-white background

**Navigation:**
- Desktop/tablet: Top horizontal nav with text links
- Mobile: Hamburger menu with slide-out navigation drawer
- User email and logout link in top right (desktop) or menu (mobile)

**Component Updates:**
- Buttons: Solid black for primary, outline for secondary
- Forms: Clean minimal styling with labels above inputs
- Cards: White background with subtle shadows
- Icons: Implement icon library matching prototype
- Progress bars: Simple horizontal bars (not circular)

**Page-by-Page Requirements:**
- Authentication page: Centered form with minimal styling
- Programs list/Dashboard: Card layout with collapsible details
- New program form: Simple two-field form
- Program detail: Exercise list with drag-and-drop handles
- Workout preview: Similar to program detail in workout context
- Active workout: Progress bar, large exercise display, action buttons
- Completed workout: Summary view
- Mobile: Floating action buttons for workout controls

**Typography:**
- Implement Inter font family
- Use exact type scale specified (h1: 18px/700, h2: 16px/600, etc.)
- Consistent line heights for readability

**Responsive Design:**
- Desktop-first approach, then mobile adaptation
- Implement hamburger menu below tablet breakpoint
- Floating action buttons on mobile only
- Touch-friendly target sizes on mobile

### Reusability Opportunities

No specific existing features or components were identified for reuse. This is a comprehensive visual redesign that will replace existing styling throughout the application. However, the implementation should:
- Create reusable partial/component files for common elements (buttons, cards, form inputs)
- Establish shared CSS/styling utilities for the design system
- Ensure consistent patterns across all pages

### Scope Boundaries

**In Scope:**
- Complete visual redesign of all application pages
- Update all layout templates and partials
- Implement new design system (colors, typography, spacing)
- Update button styles and icon usage patterns
- Implement responsive navigation (top nav + hamburger menu)
- Update form styling
- Update card components
- Implement floating action buttons for mobile workout views
- Match prototype design pixel-perfect

**Out of Scope:**
- Changing application functionality or business logic
- Adding new features beyond visual redesign
- Modifying database schema or models
- Changing API endpoints or backend logic
- Modifying JavaScript behavior (except where needed for visual interactions)
- Creating new pages not shown in prototype

### Technical Considerations

**Design System Implementation:**
- Identify icon library used in Lovable prototype
- Create CSS variables or constants for colors, typography, spacing
- Build reusable component partials for buttons, cards, forms
- Ensure Inter font is properly loaded

**Responsive Implementation:**
- Define breakpoint where hamburger menu appears
- Implement mobile navigation drawer
- Create floating action button component for mobile
- Test touch targets on mobile devices

**Testing Requirements:**
- Visual comparison against prototype screenshots for each page
- Test responsive behavior at various screen sizes
- Verify hamburger menu functionality on mobile
- Test floating action buttons in mobile workout views
- Verify all icons render correctly
- Test in multiple browsers
- Accessibility testing (contrast ratios, keyboard navigation)

**Integration Points:**
- Update Rails layouts and partials
- Modify CSS/SCSS files
- Update view templates across all controllers
- Ensure Turbo/Stimulus behavior remains functional
- Test that existing JavaScript interactions work with new markup

**Icon Library:**
- Identify which icon library Lovable prototype uses (likely Lucide, Heroicons, or similar)
- Install and configure icon library in Rails application
- Replace existing icons throughout application

### Views Requiring Updates

Based on prototype screenshots and typical Rails application structure:

**Layouts:**
- `app/views/layouts/application.html.erb` - Main layout with navigation
- Navigation partial - Desktop top nav and mobile hamburger menu
- Flash message styling

**Authentication:**
- `app/views/devise/sessions/new.html.erb` - Sign in page
- `app/views/devise/registrations/new.html.erb` - Sign up page (if separate)

**Programs:**
- `app/views/programs/index.html.erb` - Programs list/dashboard
- `app/views/programs/new.html.erb` - New program form
- `app/views/programs/edit.html.erb` - Edit program form
- `app/views/programs/show.html.erb` - Program detail with exercises
- Program card partial (if exists)

**Exercises:**
- Exercise card/list item partial
- Exercise form fields
- Any exercise-related partials

**Workouts:**
- `app/views/workouts/show.html.erb` or preview page
- Active workout view (during workout)
- Workout completion/summary view
- Workout progress component

**Shared Components/Partials:**
- Button components/partials
- Card components
- Form input partials
- Icon helpers/partials
- Progress bar component
- Mobile floating action button component

**Stylesheets:**
- Create or update design system variables
- Update component styles
- Update layout styles
- Update responsive breakpoints
- Add mobile-specific styles

### Quality Assurance

**Visual Accuracy Testing:**
- Use Chrome MCP or similar tools to compare implementation vs prototype screenshots
- Pixel-perfect comparison for spacing, sizing, colors
- Verify typography matches exactly
- Confirm border-radius and shadow values

**Functional Testing:**
- All existing functionality continues to work
- Navigation works on desktop and mobile
- Hamburger menu opens/closes correctly
- Forms submit properly
- Buttons trigger correct actions
- Drag-and-drop (if implemented) still functions

**Responsive Testing:**
- Test at multiple breakpoints
- Verify mobile-specific components appear/hide correctly
- Touch target sizes adequate on mobile
- Scrolling behavior appropriate
- Floating buttons position correctly

**Cross-browser Testing:**
- Test in Chrome, Firefox, Safari
- Test on actual mobile devices (iOS and Android)
- Verify Inter font loads correctly across browsers

**Accessibility Testing:**
- Color contrast meets WCAG AA standards
- Keyboard navigation works
- Icon-only buttons have appropriate labels
- Form labels properly associated
- Focus states visible and appropriate

## Implementation Notes

**Development Approach:**
1. Set up design system (colors, typography, spacing constants)
2. Identify and install icon library
3. Create base component partials (buttons, cards, form inputs)
4. Update layout and navigation (desktop + mobile)
5. Update each page/view systematically
6. Test each page against prototype for visual accuracy
7. Conduct responsive testing
8. Perform final cross-browser and accessibility testing

**Critical Success Factors:**
- Exact visual match to prototype
- All existing functionality preserved
- Responsive behavior works smoothly
- Mobile-specific features (hamburger menu, floating buttons) function correctly
- Consistent design system implementation across all pages
- Performance not degraded by design changes

**Constraints:**
- Must maintain all existing functionality
- Cannot modify backend logic or database
- Must work with existing Rails + Turbo + Stimulus architecture
- Must meet accessibility standards
