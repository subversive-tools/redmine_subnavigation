# Changelog

All notable changes to this project will be documented in this file.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [0.5.5] - 2026-03-13

### Fixed
- Do not render sidebar for new or unsaved projects.

## [0.5.4] - 2026-02-18

### Added
- Hide sidebar automatically on mobile viewports (< 900px).

### Fixed
- Sidebar visibility and layout shift on initial load.
- Empty sidebar space on wiki index and new wiki pages.
- Ambiguous column error in `WikiContent.updated_on` cache query.
- Sidebar cache now correctly invalidates on wiki content updates.
- 500 error on `/projects` due to uninitialised settings.
- Sidebar excluded from additional admin pages (groups, roles, etc.) in global mode.
- Dynamic sidebar resizing enabled.

## [0.5.3] - 2026-02-17

### Fixed
- Permissions, layout issues, and CI pipeline.

## [0.5.2] - 2026-02-10

### Added
- Improved installation guide in README.

## [0.5.1] - 2026-02-09

### Fixed
- Cache invalidation when wiki pages are moved between projects.

## [0.5.0] - 2026-02-09

### Added
- Major stable release consolidating the v0.3.x series.
- Full project hierarchy tree (projects, subprojects, wiki pages, headings).
- Collapsible sidebar with persistent width and state across page loads.
- Recursive expand/collapse with `Alt`/`Option` + click.
- Cascading module activation: enabling/disabling the module in a parent project applies automatically to all subprojects (Full Hierarchy mode).
- Optional breadcrumb hiding.
- Sticky top menu option.
- Light and dark mode support via CSS variables.
- English and German localisation.

## [0.3.0] - 2026-02-02

### Added
- Sticky sidebar with hamburger toggle.
- Active state highlighting and auto-expansion of current page in tree.
- Header anchor matching and deep linking (h1–h6).
- Header deduplication and configurable heading depth.
- H1 title logic and compact CSS.

### Fixed
- Fuzzy header matching and visible highlights.
- Robust header anchors.
- JS active state and subpage expansion.
- Regex syntax errors.

## [0.2.0] - 2026-01-01

### Changed
- Plugin renamed from `redmine_subnav` to `redmine_subnavigation`.

### Fixed
- CSS layout and asset loading order.
- Localisation issues.

## [0.1.0] - 2025-12-01

### Added
- Initial release with basic sidebar navigation for wiki pages and headings.
