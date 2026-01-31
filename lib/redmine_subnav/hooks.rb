module RedmineSubnav
  class Hooks < Redmine::Hook::ViewListener
    include RedmineSubnav::WikiSidebarHelper

    def view_layouts_base_html_head(context = {})
      # Insert CSS/JS
      stylesheet_link_tag('wiki_sidebar', plugin: 'redmine_subnav') +
      javascript_include_tag('wiki_sidebar', plugin: 'redmine_subnav')
    end

    def view_layouts_base_body_bottom(context = {})
      # Render Sidebar
      return '' unless context[:project]
      
      # Check if plugin is enabled/configured (simple logic for now)
      # We use Setting.plugin_redmine_subnav['sidebar_mode']
      mode = Setting.plugin_redmine_subnav['sidebar_mode']
      return '' if mode.blank? || mode == 'none'
      
      # Ensure wiki module is enabled if we are in wiki mode
      return '' if mode == 'wiki' && !context[:project].module_enabled?(:wiki)

      sidebar_content = render_sidebar_navigation(context[:project], mode)
      return '' if sidebar_content.empty?

      output = []
      output << <<~HTML
        <div id="mini-wiki-sidebar" class="mini-wiki-sidebar">
          <div class="mini-wiki-sidebar-toggle" onclick="toggleWikiSidebar()">
            <span class="icon"></span>
          </div>
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
