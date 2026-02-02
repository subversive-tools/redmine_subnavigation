module RedmineSubnavigation
  class Hooks < Redmine::Hook::ViewListener
    include RedmineSubnavigation::WikiSidebarHelper

    def view_layouts_base_html_head(context = {})
      # Insert CSS/JS
      stylesheet_link_tag('wiki_sidebar', plugin: 'redmine_subnavigation') +
      javascript_include_tag('wiki_sidebar', plugin: 'redmine_subnavigation')
    end

    def view_layouts_base_body_bottom(context = {})
      # Render Sidebar
      return '' unless context[:project]
      
      # Check if plugin is enabled/configured (simple logic for now)
      # We use Setting.plugin_redmine_subnavigation['sidebar_mode']
      mode = Setting.plugin_redmine_subnavigation['sidebar_mode']
      return '' if mode.blank? || mode == 'none'
      
      # 1. Module active in Project?
      return '' unless context[:project].module_enabled?(:subnavigation)
      
      # 2. Context Check: "Wiki & Headings" mode -> Only on WikiController
      if mode == 'wiki'
        return '' unless context[:controller] && context[:controller].is_a?(WikiController)
      end
      
      # Ensure wiki module is enabled if we are in wiki mode (redundant with above but safe)
      return '' if mode == 'wiki' && !context[:project].module_enabled?(:wiki)

      # Cache key to prevent rendering bottlenecks
      # Includes: Project ID, Project update time, User ID (permissions), and Mode
      cache_key = [
        'redmine_subnavigation',
        'sidebar',
        context[:project].id,
        context[:project].updated_on.to_i,
        context[:project].module_enabled?(:subnavigation),
        User.current.id,
        mode
      ].join('/')

      sidebar_content = Rails.cache.fetch(cache_key, expires_in: 10.minutes) do
        render_sidebar_navigation(context[:project], mode)
      end
      return '' if sidebar_content.empty?

      output = []
      output << <<~HTML
        <div class="mini-wiki-sidebar-toggle" onclick="toggleWikiSidebar()">
          <span class="icon"></span>
        </div>
        <div id="mini-wiki-sidebar" class="mini-wiki-sidebar">
          <div class="mini-wiki-sidebar-content">
            #{sidebar_content}
          </div>
        </div>
        <script>
          document.body.classList.add('has-mini-wiki-sidebar');
          document.body.classList.add('mini-sidebar-mode-#{mode}');
        </script>
      HTML
      output.join("\n").html_safe
    end
  end
end
