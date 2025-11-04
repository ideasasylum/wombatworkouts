# Specification: Minimalist Notepad UI Redesign

## Goal
Transform the Wombat Workouts application to match a minimalist, notepad-inspired visual design provided in a fully functional prototype. Replace all current styling with a clean, flat aesthetic using minimal colors, Inter typography, and icon-first navigation while preserving all existing functionality.

## User Stories
- As a user, I want a clean, distraction-free interface so that I can focus on tracking my workouts
- As a mobile user, I want a hamburger menu and floating action buttons so that navigation is accessible and primary actions are within thumb reach
- As a user, I want consistent, minimal styling across all pages so that the interface feels cohesive and professional
- As a developer, I want a well-documented design system so that future UI changes maintain visual consistency

## Core Requirements

### Visual Design Fidelity
- Match prototype design pixel-perfect across all 8 pages (auth, dashboard, program new/show, workout preview/active/complete)
- Implement exact color system: background rgb(237,242,247), text rgb(26,26,26), cards white
- Use Inter font family with specified type scale (h1: 18px/700, h2: 16px/600, body: 16px/400)
- Apply 2px border-radius throughout for minimal rounding
- Use solid colors only - no gradients anywhere

### Navigation System
- Desktop/tablet: Horizontal top navigation bar with text links ("Dashboard", "Programs")
- Mobile: Hamburger menu icon (top right) with slide-out navigation drawer
- User email and "Log out" link in top right on desktop, inside drawer on mobile
- Logo "Wombat Workouts" always visible in top left

### Button & Icon System
- Primary actions: Solid black background (rgb(26,26,26)) with white text and icon
- Secondary actions: White background with black border, icon only (no text on icon-only buttons)
- Major actions include icon + text label (e.g., "Start Workout" with play icon)
- All icons must be inline SVG following Heroicons style (current icon pattern in codebase)
- Required icons: play, plus, edit (pencil), delete (trash), hamburger menu (three horizontal lines), user-plus, arrow-right, checkmark, skip-forward, save, grip-vertical (drag handle)

### Card Component System
- White background (rgb(255,255,255)) with subtle shadow
- 2px border-radius
- Consistent padding (p-6 in Tailwind = 1.5rem)
- Used for: program cards, exercise list items, workout content areas, form containers

### Form Styling
- Labels above inputs (not inline or floating)
- Input backgrounds match card white
- Placeholder text for guidance
- Text inputs and textareas have minimal border styling
- 2px border-radius on all form controls

### Responsive Behavior
- Breakpoint at Tailwind's 'md' (768px) triggers hamburger menu
- Mobile floating action buttons appear only on active workout view
- Buttons use fixed positioning at bottom with backdrop/shadow
- Touch targets minimum 44x44px on mobile
- Full-width cards on mobile with appropriate padding

### Page-Specific Requirements

**Authentication (Unauthenticated Layout):**
- Centered form on light background
- "Wombat Workouts" title (18px, weight 700)
- "Track your exercises" tagline below (gray text)
- Single email input field
- Two buttons side-by-side: "Sign Up" (outline, user-plus icon) and "Sign In" (solid, arrow-right icon)
- No navigation bar when unauthenticated

**Dashboard/Programs List:**
- Page heading "Programs" (h1 style)
- "+ New" button (outline style) aligned top right next to heading
- Program cards showing: title (h3), description (gray text), "Start" button (solid, play icon)
- Collapsible "More details" link in each card
- Icon-only edit (pencil) and delete (trash) buttons aligned right on each card

**New/Edit Program Form:**
- Simple form with "New Program" or "Edit Program" heading
- "Name" field (required)
- "Description (optional)" textarea
- "Create" or "Save" button (solid, save icon) positioned bottom-right of form

**Program Detail View:**
- Program info card at top with name and description
- Full-width "Start Workout" button (solid, play icon)
- "Exercises" section header with "+ Add" button (outline)
- Exercise cards with: grip-vertical drag handle (left), exercise name, rep count below name, notes below reps, icon-only edit/delete (right)
- Bottom actions: "Edit Program" and "Delete" buttons (both outline style with icons)

**Workout Preview (Before Starting):**
- Similar to program detail but in workout context
- Shows complete exercise list with all details
- "Start Workout" button as primary CTA

**Active Workout:**
- Progress bar at top showing "Exercise X of Y" and percentage (e.g., "20%")
- Large exercise name as heading
- "Set X of Y" counter
- Exercise notes in a card below
- Desktop: "Skip" (outline, skip-forward icon) and "Complete" (solid, checkmark icon) buttons at bottom
- Mobile: Same buttons as floating action buttons pinned to bottom of viewport with backdrop

**Completed Workout:**
- Summary view showing completed exercises
- Success messaging
- Return to programs CTA

## Visual Design

### Prototype Reference
- Desktop mockups: planning/visuals/prototype-*-desktop.png
- Mobile mockups: planning/visuals/prototype-*-mobile.png
- All 16 screenshots provide complete visual specifications

### Design System Tokens

**Colors:**
```
--color-background: rgb(237, 242, 247)    /* Page background */
--color-surface: rgb(255, 255, 255)       /* Cards, inputs */
--color-text-primary: rgb(26, 26, 26)     /* Main text */
--color-text-secondary: rgb(107, 114, 128) /* Gray-600 equivalent */
--color-border: rgb(229, 231, 235)        /* Gray-200 equivalent */
--color-button-primary-bg: rgb(26, 26, 26)
--color-button-primary-text: rgb(255, 255, 255)
```

**Typography:**
```
--font-family: 'Inter', sans-serif
--font-size-h1: 18px      /* Weight: 700, Line-height: 28px */
--font-size-h2: 16px      /* Weight: 600, Line-height: 24px */
--font-size-h3: 16px      /* Weight: 500, Line-height: 24px */
--font-size-body: 16px    /* Weight: 400, Line-height: 24px */
--font-size-button: 14px  /* Weight: 500, Line-height: 20px */
```

**Spacing:**
```
--radius-minimal: 2px     /* All rounded corners */
--shadow-card: 0 1px 3px rgba(0,0,0,0.1)
--spacing-card-padding: 1.5rem (Tailwind p-6)
--spacing-section-gap: 2rem (Tailwind space-y-8)
```

**Breakpoints:**
```
--breakpoint-mobile: < 768px (Tailwind md breakpoint)
--breakpoint-tablet: >= 768px
--breakpoint-desktop: >= 1024px (Tailwind lg breakpoint)
```

## Reusable Components

### Existing Code to Leverage
- **Button Partial:** `/app/views/shared/_button.html.erb` - Update type classes and remove gradient-based colors
- **Icon Partials:** `/app/views/shared/icons/*.html.erb` - Add new icon types matching prototype (pencil, trash, menu, user-plus, arrow-right, check, skip-forward, grip-vertical)
- **Navbar Partial:** `/app/views/shared/_navbar.html.erb` - Complete redesign needed for top nav + hamburger menu
- **Layout:** `/app/views/layouts/application.html.erb` - Update body background color class
- **Tailwind Config:** Existing Tailwind 4.1 setup at `/app/assets/tailwind/application.css` - Extend with custom design tokens

### New Components Required
- **Hamburger Menu Component:** Mobile navigation drawer with slide-in animation
- **Floating Action Buttons:** Mobile-specific fixed-position button container for workout actions
- **Progress Bar Component:** Horizontal bar showing workout completion percentage
- **Card Component Partial:** Reusable card wrapper (though inline Tailwind classes may suffice)
- **Collapsible Details Component:** For "More details" expandable section in program cards

### Component Updates Needed
- Button component: Replace indigo color scheme with black/white monochrome
- Button component: Support icon-only variant without text
- Icon system: Add 8 new icon SVG partials matching Heroicons outline style
- Navbar: Add responsive behavior with hamburger menu
- All form inputs: Remove current styling, apply minimal border style

## Technical Approach

### Design System Implementation
1. Update Tailwind config to include Inter font family (load from Google Fonts or self-host)
2. Create CSS custom properties in application.css for design tokens
3. Update body background from `bg-gray-50` to `bg-[rgb(237,242,247)]`
4. Replace all indigo colors (indigo-600, indigo-700) with black/white equivalents
5. Update border-radius from default (0.375rem/6px) to minimal (0.125rem/2px) globally

### Icon System
- Continue using inline SVG approach (no external icon library needed)
- Create new icon partials based on Heroicons outline style
- Each icon accepts `class` parameter for sizing and color control
- Standard sizing: w-5 h-5 (20x20px) for most buttons, w-4 h-4 (16x16px) for inline icons

### Responsive Navigation
- Use Stimulus controller for hamburger menu toggle behavior
- Mobile menu: Fixed overlay with slide-in animation from right
- Backdrop/overlay when menu open (semi-transparent black)
- Close on backdrop click or menu link click
- Z-index management: navbar z-50, mobile menu z-50, backdrop z-40

### Layout Structure
- Desktop: max-w-4xl container, centered content
- Mobile: full-width with px-4 side padding
- Maintain existing Turbo Frames for navigation (no page structure changes)

### Migration Strategy
1. Phase 1: Design system setup (fonts, colors, tokens)
2. Phase 2: Update shared components (buttons, icons, navbar)
3. Phase 3: Update layout and global styles
4. Phase 4: Update authentication pages
5. Phase 5: Update programs views (index, new, edit, show)
6. Phase 6: Update workout views (preview, active, complete)
7. Phase 7: Mobile-specific components (hamburger menu, floating buttons)
8. Phase 8: Visual QA against prototype screenshots

### Testing Requirements
- Visual regression testing using prototype screenshots as reference
- Test hamburger menu open/close on mobile viewport
- Test floating action buttons appear only on workout active view (mobile)
- Verify all existing functionality preserved (forms submit, navigation works, CRUD operations)
- Test responsive behavior at breakpoints: 375px (mobile), 768px (tablet), 1024px (desktop)
- Keyboard navigation testing (tab through forms, escape closes menu)
- Touch target size verification on mobile (minimum 44x44px)

## Out of Scope

### Explicitly Excluded
- Changing database schema or adding new models
- Modifying business logic or controller actions
- Adding new features beyond visual redesign
- Changing API endpoints or backend validation
- Creating new pages not shown in prototype
- Modifying JavaScript behavior except for visual interactions (menu toggle, collapsible sections)
- Adding animations beyond simple transitions (menu slide, button hover states)
- Implementing drag-and-drop reordering (show drag handle but maintain current behavior)
- Literal notepad styling (paper texture, lines, etc.) - keep clean digital aesthetic

### Future Enhancements
- Actual drag-and-drop exercise reordering
- Dark mode variant
- Additional theme customization
- Advanced animations and transitions
- Workout history and statistics visualizations

## Success Criteria

### Visual Accuracy
- All pages match prototype screenshots within 5px tolerance for spacing
- Color values exactly match specified RGB values
- Typography (font family, sizes, weights) matches specification exactly
- Border radius consistently 2px throughout
- Card shadows match subtle elevation style from prototype

### Functional Preservation
- All existing features continue to work without regression
- Forms validate and submit correctly
- Navigation (links, buttons, back buttons) functions as before
- Turbo and Stimulus behavior remains intact
- Flash messages display appropriately with new styling

### Responsive Requirements
- Hamburger menu appears at 768px breakpoint and functions correctly
- Navigation drawer slides in smoothly with backdrop overlay
- Floating action buttons appear on mobile workout view and are thumb-accessible
- Touch targets meet 44x44px minimum on mobile
- Layout adapts appropriately from 375px to 1920px+ widths

### Performance
- Page load times not negatively impacted by design changes
- Inter font loads efficiently (subset if possible)
- Tailwind purge removes unused styles in production
- No layout shift during page load

### Accessibility
- Color contrast meets WCAG AA standards (4.5:1 for normal text)
- Icon-only buttons include aria-label attributes
- Keyboard navigation works throughout interface
- Focus states visible and appropriate
- Form labels properly associated with inputs
- Mobile menu closeable with escape key

### Code Quality
- Design tokens centralized and easy to update
- Component partials follow existing patterns and conventions
- No hardcoded colors or spacing values scattered in views
- CSS follows project standards (Tailwind-first approach)
- Views remain readable and maintainable

### Documentation
- Design system tokens documented in CSS file or separate doc
- Component partials have clear parameter documentation
- Responsive breakpoints documented
- Migration/deployment notes included for design system changes
