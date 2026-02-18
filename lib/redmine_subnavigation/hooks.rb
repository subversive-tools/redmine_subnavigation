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
      # 1. Global UI Features (Sticky Menu) - Better here than bottom for early layout
      settings = Setting.plugin_redmine_subnavigation || {}
      output = []
      
      if settings['sticky_top_menu']
        output << '<script>document.body.classList.add("mini-sidebar-sticky-top-menu");</script>'
      end

      # 2. Early Space Reservation for Sidebar
      if should_render_sidebar?(context, settings)
        output << <<~HTML.html_safe
          <script>
            (function() {
              var isClosed = localStorage.getItem('redmine_mini_wiki_sidebar_closed') === 'true';
              var storedWidth = localStorage.getItem('redmine_mini_wiki_sidebar_width');
              var isEdit = document.body.classList.contains('action-edit') || document.body.classList.contains('action-update');
              
              if (isClosed || isEdit) {
                document.body.classList.add('mini-wiki-sidebar-closed');
                document.documentElement.style.setProperty('--subnav-current-width', '20px');
              } else {
                var w = storedWidth ? storedWidth + 'px' : '280px';
                document.documentElement.style.setProperty('--subnav-current-width', w);
              }
              document.body.classList.add('has-mini-wiki-sidebar');
              
              // Mode specific class needed for grid areas
              var mode = '#{settings['sidebar_mode']}';
              document.body.classList.add('mini-sidebar-mode-' + mode);

              var hideBreadcrumb = #{settings['hide_breadcrumb'].to_s == '1' || settings['hide_breadcrumb'] == true};
              if (hideBreadcrumb && mode === 'project_wiki') {
                 document.body.classList.add("mini-sidebar-hide-breadcrumb");
              }
              
              // No-transition to prevent generic jumps
              document.body.classList.add('no-transition');
            })();
          </script>
        HTML
      end
      
      output.join("\n").html_safe
    end

    def view_layouts_base_body_bottom(context = {})
      settings = Setting.plugin_redmine_subnavigation || {}
      
      # Determine if we should render
      return '' unless should_render_sidebar?(context, settings)

      mode = settings['sidebar_mode']
      project = context[:project]

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
                                  .maximum('wiki_contents.updated_on').to_i
                                  
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
               max_c_up = WikiContent.where(page_id: pages.select(:id)).maximum(:updated_on).to_i
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
      
      return '' if sidebar_content.blank?

      # JS initialization is now handled up top or via wiki_sidebar.js
      # We just output the structure
      <<~HTML.html_safe
        <div id="mini-wiki-sidebar" class="mini-wiki-sidebar">
          <div class="mini-wiki-sidebar-toggle" onclick="toggleWikiSidebar()">
            <span class="icon"></span>
          </div>
          <div class="mini-wiki-sidebar-content">
            #{sidebar_content}
          </div>
        </div>
        <script>
           console.log('Subnav Mode:', '#{mode}');
        </script>
      HTML
    end

    private

    def should_render_sidebar?(context, settings)
      mode = settings['sidebar_mode']
      return false if mode.blank? || mode == 'none'

      project = context[:project]
      
      if project
        # Project Context
        if project.module_enabled?(:subnavigation)
          if mode == 'wiki'
            return context[:controller].is_a?(WikiController) && project.module_enabled?(:wiki) && User.current.allowed_to?(:view_subnavigation, project)
          else
            return User.current.allowed_to?(:view_subnavigation, project)
          end
        end
      else
        # Global Context (e.g. /projects)
        # 1. Project Wiki Mode: Render on projects index
        if mode == 'project_wiki' && context[:controller].is_a?(ProjectsController) && context[:request].path == '/projects'
          return settings['show_on_globally']
        end

        # 2. Show on Globally Setting
        if settings['show_on_globally']
          # Exclusions: Do not show on Admin, Login, My Page, Users list, or Settings
          path = context[:request].path
          controller_name = context[:controller].controller_name
          
          excluded_paths = [
            '/admin', '/login', '/account', '/my', '/settings', '/users',
            '/groups', '/roles', '/trackers', '/auth_sources', '/enumerations',
            '/issue_statuses', '/workflows', '/custom_fields'
          ]
          
          excluded_controllers = [
            'admin', 'account', 'my', 'settings', 'users', 'groups', 'roles', 
            'trackers', 'auth_sources', 'enumerations', 'issue_statuses', 
            'workflows', 'custom_fields'
          ]

          is_excluded = excluded_paths.any? { |p| path.start_with?(p) } ||
                        excluded_controllers.include?(controller_name)

          return true unless is_excluded
          
          # Force for Activity if it was somehow excluded or logic failed
          if path == '/activity'
             return true 
          end
        end
      end
      
      false
    end
  end
end
