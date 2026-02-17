module RedmineSubnavigation
  class Hooks < Redmine::Hook::ViewListener
    include RedmineSubnavigation::WikiSidebarHelper

    def view_layouts_base_html_head(context = {})
      # Insert CSS/JS
      stylesheet_link_tag('wiki_sidebar', plugin: 'redmine_subnavigation') +
      javascript_include_tag('wiki_sidebar', plugin: 'redmine_subnavigation')
    end

    def view_layouts_base_content(context = {})
      ''
    end

    def view_layouts_base_body_top(context = {})
      ''
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

      # Render Sidebar (Conditional)
      mode = settings['sidebar_mode']
      return output.join("\n").html_safe if mode.blank? || mode == 'none'

      # Determine if we should render
      should_render = false
      project = context[:project]
      
      if project
        # Project Context
        if project.module_enabled?(:subnavigation)
          if mode == 'wiki'
            should_render = context[:controller].is_a?(WikiController) && project.module_enabled?(:wiki) && User.current.allowed_to?(:view_subnavigation, project)
          else
            should_render = User.current.allowed_to?(:view_subnavigation, project)
          end
        end
      else
        # Global Context (e.g. /projects)
        # 1. Project Wiki Mode: Render on projects index
        if mode == 'project_wiki' && context[:controller].is_a?(ProjectsController) && context[:request].path == '/projects'
          should_render = settings['show_on_globally']
        end

        # 2. Show on Globally Setting
        # If enabled, render on other global pages (but not if we are already rendering)
        if !should_render && settings['show_on_globally']
          # Exclusions: Do not show on Admin, Login, My Page, Users list, or Settings
          path = context[:request].path
          controller_name = context[:controller].controller_name
          
          excluded_paths = ['/admin', '/login', '/account', '/my', '/settings', '/users']
          is_excluded = excluded_paths.any? { |p| path.start_with?(p) } ||
                        ['admin', 'account', 'my', 'settings', 'users'].include?(controller_name)

          should_render = true unless is_excluded
          
          # Force for Activity if it was somehow excluded or logic failed
          if path == '/activity'
             should_render = true 
          end
        end
      end
      
      return output.join("\n").html_safe unless should_render

      # Cache Strategy
      if project
        if mode == 'project_wiki'
          # In 'project_wiki', we render the full tree (Root -> descendants).
          # Cache by Root Project.
          root_project = project.root
          tree_project_ids = root_project.self_and_descendants.visible.pluck(:id)
          
          # Projects: Count (detects adds/removes) AND Max Update (detects edits)
          project_query = Project.where(id: tree_project_ids)
          project_sig = "#{project_query.count}-#{project_query.maximum(:updated_on).to_i}"
          
          begin
            wiki_pages_query = WikiPage.joins(wiki: :project).where(projects: { id: tree_project_ids })
            max_p_up = wiki_pages_query.maximum(:updated_on).to_i
            p_count = wiki_pages_query.count
            
            # Content updates
            max_c_up = WikiContent.joins(page: { wiki: :project })
                                  .where(projects: { id: tree_project_ids })
                                  .maximum(:updated_on).to_i
                                  
            wiki_sig = "#{p_count}-#{max_p_up}-#{max_c_up}"
          rescue => e
            wiki_sig = "0-0-0"
          end
          
          tree_version = "#{project_sig}|#{wiki_sig}"
          cache_identifier = "root/#{root_project.id}"
        else
          # In 'wiki' mode
          project_sig = "#{project.updated_on.to_i}"
          
          begin
            if project.wiki
               pages = project.wiki.pages
               p_count = pages.count
               max_p_up = pages.maximum(:updated_on).to_i
               max_c_up = pages.joins(:content).maximum(:updated_on).to_i
               wiki_sig = "#{p_count}-#{max_p_up}-#{max_c_up}"
            else
               wiki_sig = "0-0-0"
            end
          rescue => e
            wiki_sig = "0-0-0"
          end
          
          tree_version = "#{project_sig}|#{wiki_sig}"
          cache_identifier = "project/#{project.id}"
        end
      else
        # Global Context
        visible_projects = Project.visible
        tree_version = "#{visible_projects.count}-#{visible_projects.maximum(:updated_on).to_i}"
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
