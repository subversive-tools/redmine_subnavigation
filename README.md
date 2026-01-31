# Redmine Subnavigation Plugin

A Redmine plugin that provides a collapsible sidebar navigation tree for projects, subprojects, wiki pages, and content headings.

## Features

- **Collapsible Sidebar**: Easily toggle the navigation tree.
- **Project Navigation**: Navigate through the project hierarchy.
- **Wiki Navigation**: Tree view of all wiki pages in the project.
- **Content Headings**: Automatically lists headings (h1, h2, etc.) for the current wiki page for quick access.
- **Configurable Modes**:
  - `Disabled`
  - `Wiki & Page Headers`
  - `Full Hierarchy (Projects, Wiki & Headers)`

## Installation

**Important:** The plugin directory **MUST** be named `redmine_subnavigation` for the asset pipeline to function correctly.

1.  Clone or download the plugin into your Redmine `plugins` directory:
    ```bash
    cd /path/to/redmine/plugins
    git clone https://github.com/modoq/redmine_subnavigation.git redmine_subnavigation
    ```
    *Ensure the folder is named `redmine_subnavigation`.*

2.  Install dependencies and migrate:
    ```bash
    bundle install
    bundle exec rake redmine:plugins:migrate RAILS_ENV=production
    ```

3.  Restart Redmine.

## Configuration

Go to **Administration > Plugins > Redmine Subnavigation > Configure**.

- **Navigation Mode**: Choose between partial (Wiki only) or full (Projects + Wiki) navigation.

## License

MIT License
