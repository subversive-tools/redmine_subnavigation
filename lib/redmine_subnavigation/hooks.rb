module RedmineSubnavigation
  class Hooks < Redmine::Hook::ViewListener
    include RedmineSubnavigation::WikiSidebarHelper

    def view_layouts_base_html_head(context = {})
      # Insert CSS/JS
      stylesheet_link_tag('wiki_sidebar', plugin: 'redmine_subnavigation') +
      javascript_include_tag('wiki_sidebar', plugin: 'redmine_subnavigation')
    end

    def view_layouts_base_body_bottom(context = {})
      # Initialize output buffer
      output = []
      
      # 1. Global UI Features (Sticky Menu)
      # This should apply even if the sidebar module is not active in the current project
      settings = Setting.plugin_redmine_subnavigation
      
      script = String.new
      script << 'document.body.classList.add("mini-sidebar-sticky-top-menu");' if settings['sticky_top_menu']
      
      unless script.empty?
        output << "<script>#{script}</script>"
      end

      # 2. Render Sidebar (Conditional)
      mode = settings['sidebar_mode']
      return output.join("\n").html_safe if mode.blank? || mode == 'none'

      # Determine if we should render
      should_render = false
      project = context[:project]
      
      if project
        # Project Context
        if project.module_enabled?(:subnavigation)
          if mode == 'wiki'
            should_render = context[:controller].is_a?(WikiController) && project.module_enabled?(:wiki)
          else
            should_render = true
          end
        end
      else
        # Global Context (e.g. /projects)
        # Only render if mode is 'project_wiki' and we are on the projects index
        if mode == 'project_wiki' && context[:controller].is_a?(ProjectsController) && context[:request].path == '/projects'
          should_render = true
        end
      end
      
      return output.join("\n").html_safe unless should_render

      # Cache Strategy
      if project
        if mode == 'project_wiki'
          # In 'project_wiki', we render the full tree (Root -> descendants).
          # This content is identical for all subprojects of the same root 
          # (assuming we rely on JS for active state).
          # So we can cache by Root Project to save memory/processing.
          root_project = project.root
          tree_project_ids = root_project.self_and_descendants.visible.pluck(:id)
          
          # Max update of any project in the tree (renames, structure changes)
          max_project_update = Project.where(id: tree_project_ids).maximum(:updated_on).to_i
          
          # Max update of any wiki page in the tree (for page titles/structure)
          begin
            max_wiki_update = WikiContent.joins(page: { wiki: :project })
                                         .where(projects: { id: tree_project_ids })
                                         .maximum(:updated_on).to_i
          rescue => e
            max_wiki_update = 0
          end
          
          tree_version = [max_project_update, max_wiki_update].max
          cache_identifier = "root/#{root_project.id}"
        else
          # In 'wiki' mode, we render ONLY the current project's wiki.
          # This MUST be cached by the specific Project ID.
          
          max_project_update = project.updated_on.to_i
          begin
            # Only check THIS project's wiki
            if project.wiki
               max_wiki_update = project.wiki.pages.joins(:content).maximum(:updated_on).to_i
            else
               max_wiki_update = 0
            end
          rescue => e
            max_wiki_update = 0
          end
          
          tree_version = [max_project_update, max_wiki_update].max
          cache_identifier = "project/#{project.id}"
        end
      else
        # Global Context (e.g. /projects index)
        # Renders all visible roots.
        tree_version = Project.visible.maximum(:updated_on).to_i
        cache_identifier = "global"
      end

      cache_key = [
        'redmine_subnavigation',
        'sidebar',
        cache_identifier,
        tree_version,
        User.current.id,
        mode,
        settings['header_max_depth']
      ].join('/')

      sidebar_content = Rails.cache.fetch(cache_key, expires_in: 10.minutes) do
        render_sidebar_navigation(project, mode)
      end
      
      return output.join("\n").html_safe if sidebar_content.empty?

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
          
          // Debugging
          console.log('Subnav Mode:', '#{mode}', 'Hide Breadcrumb:', '#{settings['hide_breadcrumb']}');

          #{ 
            should_hide = (settings['hide_breadcrumb'].to_s == '1' || settings['hide_breadcrumb'] == true) && mode == 'project_wiki'
            should_hide ? 'document.body.classList.add("mini-sidebar-hide-breadcrumb");' : '' 
          }
        </script>
      HTML
      output.join("\n").html_safe
    end
  end
end
