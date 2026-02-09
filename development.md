# Development & Improvement Notes

This document contains suggestions for improving the `redmine_subnavigation` plugin. It is not intended for the public repository.

## 🚀 Future Improvements

### 1. JavaScript Performance (Critical)
**Issue**: Currently, `wiki_sidebar.js` attaches an event listener to *every single* `.expand-icon` using `forEach`.
```javascript
// Current implementation
const toggle = document.createElement('span');
toggle.onclick = function (e) { ... };
```
**Suggestion**: Use **Event Delegation**. Attach a single click listener to the `#mini-wiki-sidebar` container and check `e.target` for the `.expand-icon` class. This significantly reduces memory usage on large wiki/project trees.

### 2. CSS Modernization & Theming
**Issue**: Colors are hardcoded (e.g., `#f6f6f6`, `#007bff`).
**Suggestion**: Use **CSS Variables** (Custom Properties) to allow easy theming and Dark Mode support.
```css
:root {
  --subnav-bg: #f6f6f6;
  --subnav-active: #cce0f0;
  --subnav-primary: #007bff;
}
#mini-wiki-sidebar { background-color: var(--subnav-bg); }
```

### 3. Ruby Optimizations
**Issue**: The recursive rendering in `WikiSidebarHelper` (`render_tree`, `render_project_node`) is done purely in Ruby and might be slow for massive hierarchies.
**Suggestion**: Implement **Fragment Caching** in the view hooks.
```ruby
<% cache(["subnav", project.id, project.updated_on]) do %>
  <%= render_sidebar_navigation(project, mode) %>
<% end %>
```

### 4. Layout Stability (FOUC)
**Issue**: The sidebar is moved into `#wrapper` via JavaScript on `DOMContentLoaded`. This can cause a "jump" or layout shift on load.
**Suggestion**: If possible, use the layout hook `view_layouts_base_body_bottom` to render the sidebar *directly* in the correct DOM position if Redmine's hook placement allows, or use CSS Grid on `body` more robustly to avoid JS DOM manipulation for layout.

### 5. Mobile / Responsive Support
**Suggestion**: The current standard behavior collapses the sidebar, but on mobile, it might be better to have an "Overlay" mode where the sidebar slides in over the content instead of pushing it.

### 6. Testing
**Critical**: There are currently **NO automated tests**.
**Action**:
- Add `test/unit` for the Helper logic.
- Add `test/integration` or System Tests (Capybara) to verify the sidebar toggling and persistence.

### 7. CI/CD
**Suggestion**: Add a `.github/workflows/test.yml` to run tests and RuboCop on every push.
