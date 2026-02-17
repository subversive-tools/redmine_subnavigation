# Release Notes

## v0.5.4
- **SVG Icons:** Replaced text emojis with native-style SVG icons for Projects and Wiki pages, significantly improving the visual consistency with Redmine's administration menu.
- **Bug Fixes:**
    - Fixed 500 errors and caching issues on the Activity page by patching ETag generation.
    - Resolved sidebar visibility issues on the `/projects` page to strictly respect global settings.
    - Fixed a recursive activation bug that caused "stack level too deep" errors in complex project hierarchies.
- **Performance:** Optimized permission checks and sidebar rendering to reduce excessive database queries.

## v0.5.3
- **Permissions:** Refined access control logic to ensure the sidebar is only visible to users with the specific `view_subnavigation` permission, preventing unauthorized access to structure.
- **Layout Stability:** Addressed CSS conflicts where difference in Redmine themes caused the sidebar to overlap with the footer or main content area.
- **CI/CD:** Fixed GitHub Actions workflow (`test.yml`) to correctly install dependencies and run tests against Redmine 5.x and 6.x.

## v0.5.2
- **Documentation:** Added a detailed `INSTALL.md` guide covering plugin installation, configuration, and troubleshooting for users.
- **Project Structure:** Cleaned up the repository by removing legacy files and ensuring a standard Redmine plugin directory structure for better compatibility.

## v0.5.0
- **Documentation:** Comprehensive overhaul of the `README.md` and added `development.md` for contributors.
- **Licensing:** Verified and standardized license headers across the codebase.
- **Cleanup:** Established a standard `.gitignore` configuration for Redmine plugin development.

## v0.3.18
- **UI/UX:** Minor visual enhancements to the sidebar for better readability and interaction feedback.

## v0.3.17
- **Settings:** Added new layout configuration options to fine-tune sidebar width and positioning.
- **Logic:** Improved conditional rendering logic for cleaner template integration.

## v0.3.16
- **Feature:** Implemented cascading activation, allowing submodule settings to be inherited from parent projects.

## v0.3.15
- **Fix:** Resolved sticky overflow issues ensuring content remains accessible.
- **Fix:** Fixed hamburger toggle positioning when scrolling.

## v0.3.14
- **Fix:** Hardened the sticky sidebar container implementation to prevent layout shifts.

## v0.3.13
- **Fix:** Enhanced the sticky toggle and sidebar logic to be more robust across different screen sizes and scrolling behaviors.

## v0.3.12
- **Feat:** Implement sticky positioning for the hamburger toggle button, ensuring it remains accessible when scrolling down long pages.

## v0.3.11
- **Feat:** Added sticky positioning to the sidebar itself, allowing it to stay in view while scrolling through long wiki content.

## v0.3.10
- **Fix:** Prioritized content-first header matching to improve the accuracy of the active section highlighting in the sidebar.

## v0.3.9
- **Fix:** Refined the sidebar anchor matching logic to be "smarter" and avoid false positives when sections have similar names.

## v0.3.8
- **Fix:** Implemented fuzzy header matching and ensured that highlighted sections are always visible within the viewport.

## v0.3.7
- **Style:** Fixed font-size consistency for wiki page links in the sidebar to match the rest of the navigation.

## v0.3.6
- **Fix:** Addressed an issue where active state styling was not correctly applied to parent nodes when a child page was selected.

## v0.3.5
- **UI:** Improved the visual hierarchy of the sidebar by adjusting padding and margins for nested lists.

## v0.3.4
- **Refactor:** Cleaned up unused CSS classes and optimized stylesheet loading.

## v0.3.3
- **Logic:** Improved logic for handling H1 titles in wiki pages, ensuring the first header is correctly used as the page title when appropriate.
- **Polish:** Additional CSS refinements for nested list items and expansion states.
- **Fix:** Resolved a regex syntax error when parsing markdown headers.

## v0.3.2
- **Configuration:** Introduced `header_max_depth` setting to control how many levels of wiki headers are displayed in the sidebar (default: 3).
- **UI Improvements:** Enhanced the visual indentation of nested headers in the sidebar to make the document structure clearer and easier to scan.

## v0.3.1
- **Module Control:** Implemented stricter checks to ensure the sidebar only renders when the `subnavigation` module is explicitly enabled in the project settings.
- **Context Awareness:** Added logic to prevent the sidebar from appearing on unrelated plugin pages or global views where it wasn't intended.

## v0.3.0
- **Theming:** Refactored CSS to use CSS variables (Custom Properties), allowing for easier customization of colors, widths, and spacing to match different Redmine themes.
- **Performance:** Implemented fragment caching for the sidebar tree, significantly reducing rendering time for projects with large wiki structures.
- **JavaScript:** Rewrote the expand/collapse logic to use event delegation, improving performance and reliability on pages with many nodes.

## v0.2.0
- **Refactor:** Renamed the plugin from `redmine_wiki_navigation` to `redmine_subnavigation` to better reflect its purpose as a general subnavigation tool.
- **CSS Layout:** Fixed critical layout regressions that caused the sidebar to break on mobile devices and small screens.
