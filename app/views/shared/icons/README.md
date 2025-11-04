# Icon System Documentation

## Overview
This directory contains SVG icon partials following the Heroicons outline style. All icons are designed to be inline, customizable, and consistent with the minimalist design system.

## Available Icons

### Navigation & Menu
- `_menu.html.erb` - Hamburger menu icon (three horizontal lines)

### Actions
- `_play.html.erb` - Start/play action (used for "Start Workout")
- `_plus.html.erb` - Add/create action (used for "+ New", "+ Add")
- `_pencil.html.erb` - Edit action
- `_trash.html.erb` - Delete action
- `_save.html.erb` - Save action
- `_check.html.erb` - Complete/checkmark action
- `_skip_forward.html.erb` - Skip action

### User/Auth
- `_user_plus.html.erb` - Sign up action
- `_arrow_right.html.erb` - Sign in action / navigation forward

### Interface
- `_grip_vertical.html.erb` - Drag handle (vertical dots)

## Usage

### Basic Usage
```erb
<%= render "shared/icons/play" %>
```

### Custom Sizing
All icons accept a `class` parameter for customization:

```erb
<%= render "shared/icons/play", class: "w-6 h-6" %>
```

### Standard Sizes
- **Buttons (default):** `w-5 h-5` (20x20px)
- **Inline text:** `w-4 h-4` (16x16px)
- **Large actions:** `w-6 h-6` (24x24px)

### Color Customization
Icons use `currentColor` for stroke/fill, so they inherit the text color:

```erb
<span class="text-red-600">
  <%= render "shared/icons/trash", class: "w-5 h-5" %>
</span>
```

## Common Use Cases

### Primary Action Button
```erb
<button class="bg-[rgb(26,26,26)] text-white px-4 py-2 rounded-sm flex items-center gap-2">
  <%= render "shared/icons/play", class: "w-5 h-5" %>
  <span>Start Workout</span>
</button>
```

### Icon-Only Button
```erb
<button class="p-2 hover:bg-gray-100 rounded-sm" aria-label="Edit">
  <%= render "shared/icons/pencil", class: "w-5 h-5 text-gray-700" %>
</button>
```

### Secondary Action Button with Icon
```erb
<button class="border border-gray-300 px-4 py-2 rounded-sm flex items-center gap-2">
  <%= render "shared/icons/plus", class: "w-5 h-5" %>
  <span>New</span>
</button>
```

### Inline with Text
```erb
<div class="flex items-center gap-2">
  <%= render "shared/icons/grip_vertical", class: "w-4 h-4 text-gray-400" %>
  <span>Exercise Name</span>
</div>
```

## Icon Specifications

### SVG Structure
- All icons use `24x24` viewBox
- Outline style with `stroke-width="2"`
- `stroke-linecap="round"` and `stroke-linejoin="round"` for smooth corners
- `fill="none"` for outline icons (except grip_vertical which uses fill)
- `stroke="currentColor"` to inherit text color

### Accessibility
- Icon-only buttons MUST include `aria-label` attribute:
  ```erb
  <button aria-label="Edit program">
    <%= render "shared/icons/pencil", class: "w-5 h-5" %>
  </button>
  ```

### Design System Integration
Icons are part of the minimalist design system:
- Use with black/white color scheme
- Default sizing: 20x20px (w-5 h-5)
- Consistent 2px border-radius on containing buttons
- Minimal spacing between icon and text (gap-2)

## Adding New Icons

When adding new icons:
1. Follow Heroicons outline style
2. Use `24x24` viewBox
3. Include `local_assigns[:class] ||= "w-5 h-5"` for default sizing
4. Use `stroke="currentColor"` for color inheritance
5. Set `stroke-width="2"` for consistency
6. Add smooth corners with `stroke-linecap="round"` and `stroke-linejoin="round"`
7. Document the icon in this README

## Icon Sources
Icons are based on Heroicons (https://heroicons.com/), adapted for Rails ERB partials with customizable classes.
