module RedmineSubnavigation
  module WikiSidebarHelper
    
    def render_sidebar_navigation(project, mode)
      return '' if mode == 'none'
      
      if mode == 'project_wiki'
        # Render project tree hierarchy containing the current project
        render_project_tree(project)
      else
        # Default: Just the wiki tree for current project
        render_wiki_sidebar_tree(project)
      end
    end

    # Renders the wiki page tree for a single project
    def render_wiki_sidebar_tree(project)
      return '' unless project && project.wiki

      pages = project.wiki.pages.includes(:content).order(:title).to_a
      return '' if pages.empty?

      # Group by parent_id to build tree
      pages_by_parent = pages.group_by(&:parent_id)
      root_pages = pages_by_parent[nil] || []

      return '' if root_pages.empty?

      render_tree(root_pages, pages_by_parent)
    end

    private
    
    # Renders project hierarchy up to root
    # Renders project hierarchy up to root
    def render_project_tree(current_project)
        html = '<ul>'
        
        if current_project
          # Render tree for specific root
          root = current_project.root
          html << render_project_node(root, current_project)
        else
          # Render ALL visible roots (Global View)
          roots = Project.visible.roots.order(:name)
          Rails.logger.info "[Subnavigation] Rendering global tree. Visible roots: #{roots.count}"
          roots.each do |root|
             html << render_project_node(root, nil)
          end
        end
        
        html << '</ul>'
        html
    end
    
    def render_project_node(project, current_active_project)
       html = '<li class="' 
       # Expanded state is now handled by JS for caching compatibility
       html << '">'
       
       # Check for children (Project or Wiki)
       # Check for children (Project or Wiki)
       has_wiki_module = project.module_enabled?(:wiki) && User.current.allowed_to?(:view_wiki_pages, project)
       has_wiki_content = has_wiki_module && project.wiki && project.wiki.pages.exists?
       
       children_projects = project.children.visible.to_a
       has_children = children_projects.any? || has_wiki_content
       
       html << '<div class="node-label-container">'
       if has_children
         html << '<span class="expand-icon" title="' + I18n.t(:title_subnav_expand_collapse) + '"></span>'
       else
          html << '<span class="expand-icon-spacer"></span>' 
       end

       # Project Link
       # Active class is handled by JS based on current URL to allow caching across project views
       project_name = project.name
       icon = render_subnav_icon(:folder)
       link_content = "#{icon}<span>#{project_name}</span>".html_safe
       
       html << link_to(link_content, smart_project_path(project), class: "wiki-page-link type-project")
       html << '</div>'
       
       # Render Wiki Tree
       if has_wiki_content
           wiki_html = render_wiki_sidebar_tree(project)
           unless wiki_html.empty?
               html << wiki_html
           end
       end
       
       # Render Children
       if children_projects.any?
           html << '<ul>'
           children_projects.each do |child|
               html << render_project_node(child, current_active_project)
           end
           html << '</ul>'
       end
       
       html << '</li>'
       html
    end

    def render_tree(pages, pages_by_parent)
      html = '<ul>'
      pages.each do |page|
        children = pages_by_parent[page.id]
        has_subpages = children && children.any?
        
        # Pre-render headers to see if we have any
        header_content = render_headers(page)
        has_headers = !header_content.empty?
        
        has_children = has_subpages || has_headers
        
        html << '<li>'
        
        # Wrapped in container for alignment

        
        html << '<div class="node-label-container">'
        if has_children
            html << '<span class="expand-icon"></span>'
        else
            # Spacer?
             html << '<span class="expand-icon-spacer"></span>' 
        end
        html << link_to_page(page)
        html << '</div>'
        
        html << header_content
        
        if has_subpages
          html << render_tree(children, pages_by_parent)
        end
        html << '</li>'
      end
      html << '</ul>'
      html
    end

    def link_to_page(page)
      display_title = get_display_title(page)
      icon = render_subnav_icon(:page)
      
      # Basic link, improvements like "active" class can be handled by JS matching URL
      "<a href=\"#{Rails.application.routes.url_helpers.project_wiki_page_path(page.project, page.title)}\" class=\"wiki-page-link type-page\" data-title=\"#{page.title}\">#{icon}<span>#{display_title}</span></a>"
    end

    # Renders headers in a nested tree with expand/collapse capability
    def render_headers(page)
      return '' unless page.content
      
      text = page.content.text
      settings = Setting.plugin_redmine_subnavigation || {}
      max_depth = (settings['header_max_depth'] || 3).to_i
      
      # Extract Headers
      headers = []
      
      # Markdown
      text.scan(/^(\#{1,5})\s+(.+)$/).each do |match|
        level = match[0].length
        title = match[1].strip
        next if level > max_depth
        headers << { level: level, title: title, offset: Regexp.last_match.begin(0) }
      end
      
      # Textile
      text.scan(/^h([1-5])\.\s+(.+)$/).each do |match|
        level = match[0].to_i
        title = match[1].strip
        next if level > max_depth
        headers << { level: level, title: title, offset: Regexp.last_match.begin(0) }
      end

      return '' if headers.empty?
      
      # Sort
      headers.sort_by! { |h| h[:offset] }

      # Filter first if matches title
      display_title = get_display_title(page)
      if headers.first[:title] == display_title
        headers.shift
      end
      return '' if headers.empty?

      # Build Tree
      root = { level: 0, children: [] }
      stack = [root]

      headers.each do |header|
        node = header.merge(children: [])
        
        # Pop until we find a parent with level < current level
        while stack.last[:level] >= node[:level]
          stack.pop
        end
        
        stack.last[:children] << node
        stack.push(node)
      end
      
      return '' if root[:children].empty?

      # Render Tree
      seen_anchors = Hash.new(0)
      render_header_nodes(root[:children], page, seen_anchors)
    end

    def render_header_nodes(nodes, page, seen_anchors)
      html = '<ul class="wiki-page-headers">'
      nodes.each do |node|
        header = node[:title]
        level = node[:level]
        
        base_anchor = header.parameterize
        if seen_anchors.key?(base_anchor)
          count = seen_anchors[base_anchor] += 1
          anchor = "#{base_anchor}-#{count}"
        else
          seen_anchors[base_anchor] = 0
          anchor = base_anchor
        end

        has_children = node[:children].any?
        
        html << '<li class="'
        html << '">'
        
        html << '<div class="node-label-container">'
        if has_children
            html << '<span class="expand-icon"></span>'
        else
             html << '<span class="expand-icon-spacer"></span>' 
        end

        html << "<a href=\"#{Rails.application.routes.url_helpers.project_wiki_page_path(page.project, page.title, anchor: anchor)}\" class=\"wiki-header-link wiki-header-h#{level}\" data-anchor=\"#{anchor}\" data-header-text=\"#{header}\">#{header}</a>"
        html << '</div>'
        
        if has_children
            html << render_header_nodes(node[:children], page, seen_anchors)
        end
        
        html << '</li>'
      end
      html << '</ul>'
      html
    end

    private

    def get_display_title(page)
      display_title = page.pretty_title
      if page.content
        # Try to find a H1 in text
        # Markdown: # Header or #Header
        if match = page.content.text.match(/^#\s+(.+)$/)
          display_title = match[1].strip
        # Textile: h1. Header
        elsif match = page.content.text.match(/^h1\.\s+(.+)$/)
          display_title = match[1].strip
        end
      end
      display_title
    end

    # Smart path tailored to user request:
    # 1. Overview (standard)
    # 2. Activity (if Overview not present/wanted - hard to detect, but we assume project_path handles redirects or we check permissions?)
    #    Actually Redmine's project_path IS the overview. 
    #    If the user has NO permission for overview (unlikely) or module is hidden...
    # We will try to rely on Redmine's default. 
    # But if we want to be explicit about Priority:
    # If standard project_path results in 403 or 404, we can't know here.
    # We will stick to project_path as primary. 
    # However, if we want to support "Activity as fallback", we'd need to check if user can view overview.
    # allowed_to?(:view_project, project) usually covers Overview.
    
    def render_subnav_icon(type)
      icon_id = type == :folder ? 'icon--folder' : 'icon--wiki-page'
      # Use dynamic path to the localized asset
      svg_path = image_path("icons.svg", plugin: "redmine_subnavigation")
      
      "<svg class=\"subnav-icon subnav-icon-#{type}\" aria-hidden=\"true\"><use href=\"#{svg_path}##{icon_id}\"></use></svg>"
    end

    def smart_project_path(project)
      # Check if user has permission to see the project (Overview)
      if User.current.allowed_to?(:view_project, project)
         return project_path(project)
      end

      # Fallbacks if Overview is technically accessible but "empty"? (Can't check easily)
      # Or if user just lacks permission for Overview but has others? (Rare config)
      
      # 2. Activity
      if project.module_enabled?(:activity) # Activity module always exists? It's a pseudo-module often.
         return project_activity_path(project)
      end
      
      # 3. Issues
      if project.module_enabled?(:issue_tracking) && User.current.allowed_to?(:view_issues, project)
         return project_issues_path(project)
      end
      
      # 4. Wiki
      if project.module_enabled?(:wiki) && User.current.allowed_to?(:view_wiki_pages, project)
         return project_wiki_path(project)
      end
      
      # Default
      project_path(project)
    end
  end
end
