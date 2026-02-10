# Redmine Subnavigation Plugin

![Version](https://img.shields.io/badge/version-0.5.2-blue.svg)
![Redmine](https://img.shields.io/badge/Redmine-5.0%20%7C%206.0-red.svg?logo=redmine)
![License](https://img.shields.io/badge/license-MIT-green.svg)

**A powerful, collapsible sidebar navigation tree for Redmine.**

Transform your Redmine experience with a clean, hierarchical view of your Projects, Wiki pages, and Wiki Headings. Designed for productivity and ease of use.

---

## 🚀 Features

- **📂 Project Hierarchy**: Navigate smoothly through projects and subprojects.
- **📄 Wiki Tree**: Visual tree structure for all wiki pages with expand/collapse functionality.
- **¶ Wiki Headings**: Automatic Table of Contents (h1, h2, etc.) for the current page.
- **⚡ Collapsible Sidebar**: Toggle the sidebar to maximize your workspace.
- **🧠 Smart State Persistence**: Remembers your sidebar width and expanded/collapsed state between page loads.
- **✨ Recursive Expansion**: Hold `Alt` / `Option` and click a triangle to expand/collapse all nested items at once.
- **🚫 Hide Breadcrumbs**: Optional setting to hide the Redmine breadcrumb trail for a cleaner look (Full Hierarchy mode only).
- **📌 Sticky Top Menu**: Optional setting to keep the main Redmine menu fixed at the top while scrolling.
- **🔄 Cascading Activation**: Automatically enables/disables the subnavigation module in subprojects when changed in a parent project (in 'Full Hierarchy' mode).
- **🎨 Modern Design**: Clean CSS using CSS variables, integrating seamlessly with modern Redmine themes (Light & Dark mode support).
- **🌍 Localized**: Available in English and German.

## 📸 Screenshots

| Wiki & Headers | Project Hierarchy |
|:---:|:---:|
| *(Add screenshot here)* | *(Add screenshot here)* |

## 📦 Installation

> [!IMPORTANT]
> The plugin directory **MUST** be named `redmine_subnavigation` for assets to load correctly.

1.  **Clone the repository** into your plugins directory:
    ```bash
    cd /path/to/redmine/plugins
    git clone https://github.com/modoq/redmine_subnavigation.git redmine_subnavigation
    ```

2.  **Install dependencies & assets**:
    ```bash
    bundle install
    bundle exec rake redmine:plugins:migrate RAILS_ENV=production
    ```
    *Note: This step copies the required CSS/JS assets to the public directory.*

3.  **Restart Redmine**.

## ✅ Compatibility

| Plugin Version | Redmine Version | Ruby Version |
|:--------------:|:---------------:|:------------:|
| **0.5.x**      | 5.0+, 6.0+      | 3.0+         |

## ⚙️ Configuration

Navigate to **Administration > Plugins > Subnavigation > Configure**.

| Option | Description |
|:---|:---|
| **Sidebar Mode** | |
| *Disabled* | Plugin is inactive. |
| *Wiki & Headings* | Sidebar shows Wiki pages and headings for the current project only. **Best for large instances where project hierarchy is too complex.** (Uses Project-specific caching) |
| *Full Hierarchy* | Sidebar shows the complete Project tree, Wiki pages, and headings. **Enables cascading module activation.** (Uses Root-Project caching for performance) |
| **Max Headings Depth** | Maximum depth of headings (h1, h2, h3, etc.) to show in the automatic Table of Contents. |
| **Hide Breadcrumb** | Hides the default Redmine breadcrumb trail (e.g., `Project > Wiki > Page`) for a cleaner header. *Only active in 'Full Hierarchy' mode.* |
| **Sticky Top Menu** | Fixes the black top menu bar to the top of the screen when scrolling. |

> [!NOTE]
> **Cascading Activation**: When "Full Hierarchy" (`project_wiki`) mode is enabled, enabling or disabling the **Subnavigation** module in a project's settings will automatically apply the same change to all its subprojects.

> [!TIP]
> **Power User Shortcut**: Hold **Alt / Option** while clicking an expand triangle to recursively expand or collapse all children.

## 🤝 Contributing

Contributions are welcome! Please fork the repository and submit a Pull Request.

1.  Fork it
2.  Create your feature branch (`git checkout -b feature/my-new-feature`)
3.  Commit your changes (`git commit -am 'Add some feature'`)
4.  Push to the branch (`git push origin feature/my-new-feature`)
5.  Create a new Pull Request

## 📄 License

This plugin is open source software licensed under the [MIT license](LICENSE).
