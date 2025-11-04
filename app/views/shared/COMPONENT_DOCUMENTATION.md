# Minimalist UI Design System - Component Documentation

This document provides comprehensive documentation for reusable components in the Wombat Workouts minimalist UI redesign.

## Design Tokens

All components use centralized design tokens defined in `/app/assets/tailwind/application.css`.

### Colors
- **Background**: `rgb(237, 242, 247)` or `--color-background`
- **Surface** (cards, inputs): `rgb(255, 255, 255)` or `--color-surface`
- **Text Primary**: `rgb(26, 26, 26)` or `--color-text-primary`
- **Text Secondary**: `rgb(107, 114, 128)` or `--color-text-secondary`
- **Border**: `rgb(229, 231, 235)` or `--color-border`
- **Button Primary**: `rgb(26, 26, 26)` or `--color-button-primary-bg`

### Typography
- **h1**: 18px, weight 700, line-height 28px (`.text-h1`)
- **h2**: 16px, weight 600, line-height 24px (`.text-h2`)
- **h3**: 16px, weight 500, line-height 24px (`.text-h3`)
- **body**: 16px, weight 400, line-height 24px (`.text-body`)
- **button**: 14px, weight 500, line-height 20px (`.text-button`)

### Spacing
- **Card padding**: 1.5rem (`.p-6`)
- **Section gap**: 2rem (`.space-y-8`)
- **Border radius**: 2px (`.rounded-sm`)
- **Card shadow**: `0 1px 3px rgba(0,0,0,0.1)` (`.shadow-sm`)

---

## Button Component

**Location**: `/app/views/shared/_button.html.erb`

### Usage

```erb
<!-- Primary button with icon and text -->
<%= render "shared/button",
  text: "Start Workout",
  icon: "play",
  type: :primary,
  url: workout_path(@workout) %>

<!-- Secondary button (outline style) -->
<%= render "shared/button",
  text: "Cancel",
  type: :secondary,
  url: programs_path %>

<!-- Icon-only button -->
<%= render "shared/button",
  icon: "pencil",
  type: :icon_only,
  url: edit_program_path(@program),
  html_options: { "aria-label": "Edit program" } %>

<!-- Button (not a link) with form submission -->
<%= render "shared/button",
  text: "Create",
  icon: "save",
  type: :primary,
  html_options: { type: "submit" } %>
```

### Parameters

- `text` (String, optional): Button text. Required for primary/secondary, optional for icon_only
- `icon` (String, optional): Icon name (renders from `shared/icons/#{icon}`)
- `type` (Symbol): Button style
  - `:primary` - Solid black background, white text
  - `:secondary` - White background, black border and text
  - `:icon_only` - Transparent background, minimal styling, icon only
- `size` (Symbol): `:small`, `:base` (default), `:large`
- `icon_position` (Symbol): `:left` (default) or `:right`
- `url` (String, optional): Link destination (makes it a link_to instead of button)
- `http_method` (Symbol, optional): HTTP method for link_to (e.g., `:delete`, `:post`)
- `full_width` (Boolean): Make button full width on mobile (default: false)
- `html_options` (Hash): Additional HTML attributes (class, data, aria-label, etc.)

### Styling Details

**Primary Button:**
- Background: `rgb(26, 26, 26)` (black)
- Text: white
- Border: transparent
- Hover: 90% opacity
- Border radius: 2px
- Min height: 44x44px (touch-friendly)

**Secondary Button:**
- Background: white
- Text: `rgb(26, 26, 26)` (black)
- Border: 1px solid black
- Hover: light gray background
- Border radius: 2px
- Min height: 44x44px

**Icon-Only Button:**
- Background: transparent
- Text/Icon: black
- Border: transparent
- Hover: light gray background
- Padding: 8px (p-2)
- Min size: 44x44px (touch-friendly)
- **Accessibility**: Always include `aria-label` in html_options

---

## Card Component

**Location**: `/app/views/shared/_card.html.erb`

### Usage

```erb
<!-- Basic card with default padding -->
<%= render "shared/card" do %>
  <h2 class="text-h2 mb-4">Program Details</h2>
  <p class="text-body">Program description goes here...</p>
<% end %>

<!-- Card with custom padding -->
<%= render "shared/card", padding: "lg" do %>
  <!-- Large padding content -->
<% end %>

<!-- Card with additional classes -->
<%= render "shared/card", html_options: { class: "mb-4" } do %>
  <!-- Content -->
<% end %>
```

### Parameters

- `padding` (String): Padding size
  - `'none'` - No padding
  - `'sm'` - Small padding (p-4, 1rem)
  - `'base'` (default) - Base padding (p-6, 1.5rem)
  - `'lg'` - Large padding (p-8, 2rem)
- `html_options` (Hash): Additional HTML attributes (class, data, id, etc.)
- Block content: Card content passed as block

### Styling Details

- Background: white
- Border radius: 2px
- Shadow: `0 1px 3px rgba(0,0,0,0.1)`
- Default padding: 1.5rem (p-6)

### Alternative: Utility Classes

You can also use the `.card` utility class directly:

```erb
<div class="card">
  <!-- Content -->
</div>
```

---

## Form Input Styling

**Location**: CSS utilities in `/app/assets/tailwind/application.css`

### Usage

```erb
<!-- Text input with label -->
<div>
  <%= f.label :title, "Name", class: "form-label" %>
  <%= f.text_field :title,
    class: "form-input",
    placeholder: "e.g., Upper Body Strength" %>
</div>

<!-- Textarea -->
<div>
  <%= f.label :description, "Description (optional)", class: "form-label" %>
  <%= f.text_area :description,
    class: "form-textarea",
    placeholder: "Brief description...",
    rows: 4 %>
</div>

<!-- Input with error state -->
<div>
  <%= f.label :title, "Name", class: "form-label" %>
  <%= f.text_field :title,
    class: "form-input #{'error' if @program.errors[:title].any?}" %>
  <% if @program.errors[:title].any? %>
    <p class="form-error"><%= @program.errors[:title].first %></p>
  <% end %>
</div>
```

### CSS Classes

**`.form-label`**
- Font size: 14px
- Font weight: 500
- Color: `rgb(26, 26, 26)`
- Margin bottom: 0.5rem
- Display: block (label above input)

**`.form-input`** / **`.form-textarea`** / **`.form-select`**
- Background: white
- Border: 1px solid `rgb(229, 231, 235)`
- Border radius: 2px
- Padding: 0.75rem 1rem
- Font size: 16px
- Color: `rgb(26, 26, 26)`
- Placeholder color: `rgb(107, 114, 128)`
- Focus state: 2px solid black border
- Width: 100%

**`.form-error`**
- Color: red-500
- Font size: 14px
- Margin top: 0.25rem

### Styling Details

**Default State:**
- 1px border in light gray
- White background
- Black text
- Gray placeholder text

**Focus State:**
- 2px solid black border
- No outline
- Padding adjusted to prevent layout shift

**Error State:**
- Red border (apply `.error` class)
- Show error message with `.form-error` class

---

## Navbar Component

**Location**: `/app/views/shared/_navbar.html.erb`

### Usage

```erb
<!-- In application layout -->
<%= render "shared/navbar" %>
```

### Features

**Desktop (>= 768px):**
- Logo: "Wombat Workouts" (18px, weight 700, black)
- Navigation links: "Dashboard" and "Programs" (14px, weight 500)
- User email displayed
- "Log out" button (primary style)

**Mobile (< 768px):**
- Logo visible
- Hamburger menu icon (top right)
- Navigation drawer slides in from right (full implementation in Task Group 5)
- Backdrop overlay when drawer open
- Navigation links, user email, and logout button in drawer

### Styling Details

- Background: white
- Border bottom: 1px solid gray-200
- Fixed positioning (top of viewport)
- Height: 64px (h-16)
- Z-index: 50

**Mobile Menu (Placeholder - Full implementation in Task Group 5):**
- Drawer slides from right
- Max width: 320px
- Backdrop: black with 25% opacity
- Close on backdrop click or link click
- Requires Stimulus controller for toggle behavior

---

## Typography Classes

Use these utility classes for consistent typography:

```erb
<!-- Page heading -->
<h1 class="text-h1">Programs</h1>

<!-- Section heading -->
<h2 class="text-h2">Exercises</h2>

<!-- Card title -->
<h3 class="text-h3">Ankle Rehab</h3>

<!-- Body text -->
<p class="text-body">A comprehensive rehabilitation program...</p>

<!-- Button text (automatically applied to button component) -->
<span class="text-button">Start</span>
```

---

## Color Utilities

### Using RGB Values Directly

```erb
<!-- Background color -->
<div class="bg-[rgb(237,242,247)]">Page background</div>

<!-- Text colors -->
<p class="text-[rgb(26,26,26)]">Primary text</p>
<p class="text-[rgb(107,114,128)]">Secondary text</p>

<!-- Border -->
<div class="border border-[rgb(229,231,235)]">Bordered element</div>
```

### Using CSS Custom Properties

```erb
<div style="background-color: var(--color-background)">
  <p style="color: var(--color-text-primary)">Content</p>
</div>
```

---

## Icons

**Location**: `/app/views/shared/icons/`

### Available Icons

- `play` - Start/play action
- `plus` - Add/create action
- `save` - Save action
- `pencil` - Edit action
- `trash` - Delete action
- `check` - Complete/checkmark action
- `skip_forward` - Skip action
- `user_plus` - Sign up action
- `arrow_right` - Sign in action
- `menu` - Hamburger menu (mobile)
- `grip_vertical` - Drag handle

### Usage

```erb
<!-- Standalone icon -->
<%= render "shared/icons/play", class: "w-5 h-5" %>

<!-- Icon in button (automatic via button component) -->
<%= render "shared/button", text: "Start", icon: "play", type: :primary %>

<!-- Icon with custom sizing -->
<%= render "shared/icons/trash", class: "w-4 h-4 text-red-600" %>
```

### Sizing Guidelines

- **w-5 h-5** (20x20px): Standard size for buttons
- **w-4 h-4** (16x16px): Inline icons
- **w-6 h-6** (24x24px): Larger icons (e.g., hamburger menu)

---

## Best Practices

### Button Usage

1. **Primary buttons**: Use for main actions (Create, Start, Save, Complete)
2. **Secondary buttons**: Use for less prominent actions (Cancel, outline "+ New")
3. **Icon-only buttons**: Use for edit/delete actions in cards
4. Always include `aria-label` for icon-only buttons

### Form Styling

1. Always place labels above inputs (not inline or floating)
2. Use placeholder text for guidance
3. Apply `.error` class and show error messages for validation failures
4. Ensure 2px border-radius on all form controls

### Card Usage

1. Use cards for grouping related content
2. Maintain consistent white background
3. Use default padding unless specific layout requires adjustment
4. Apply subtle shadow for elevation

### Color Usage

1. Use black (`rgb(26,26,26)`) for primary text and buttons
2. Use gray (`rgb(107,114,128)`) for secondary text
3. Avoid colored accents - keep monochromatic
4. Use off-white background (`rgb(237,242,247)`) for pages

### Accessibility

1. Minimum touch targets: 44x44px on mobile
2. Icon-only buttons must have aria-label
3. Proper label/input associations
4. Focus states visible and appropriate
5. Color contrast meets WCAG AA standards

---

## Migration from Old Components

### Button Changes

**Old (indigo colors):**
```erb
type: :primary  # Was indigo-600
type: :secondary  # Was gray border
type: :success  # Was green-600
type: :danger  # Was red-600
```

**New (monochrome):**
```erb
type: :primary  # Now black bg, white text
type: :secondary  # Now white bg, black border
type: :icon_only  # New type for icon-only buttons
# Remove :success, :danger, :indigo_secondary types
```

### Form Input Changes

**Old:**
```erb
class: "border-gray-300 focus:ring-indigo-500 focus:border-indigo-500"
```

**New:**
```erb
class: "form-input"  # Handles all styling via CSS
```

### Navbar Changes

**Old:**
- Indigo colors for logo and links
- No mobile hamburger menu

**New:**
- Black text for logo and links
- Responsive hamburger menu structure
- Prepared for mobile menu implementation (Task Group 5)

---

## Next Steps

Future task groups will implement:
- **Task Group 4**: Authentication pages with new styling
- **Task Group 5**: Full hamburger menu functionality with Stimulus
- **Task Group 6-7**: Programs views updated
- **Task Group 8-10**: Workout views updated
- **Task Group 11**: Visual QA and testing
