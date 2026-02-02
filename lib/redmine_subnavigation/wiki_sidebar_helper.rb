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
      return '' unless project.wiki

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
    def render_project_tree(current_project)
        # Get root project
        root = current_project.root
        
        # We need to render the tree starting from root
        # Ideally we only render the branches relevant to the current project context or all visible?
        # User said "levels above for nested projects".
        # Let's render the full tree of the Root Project's descendants.
        
        # Get all descendants visible to user
        # This might be heavy if there are thousands. Assuming RedmineMini context -> manageable.
        projects = [root] + root.descendants.visible.to_a
        
        # Build hierarchy
        html = '<ul>'
        html << render_project_node(root, current_project)
        html << '</ul>'
        html
    end
    
    def render_project_node(project, current_active_project)
       html = '<li class="' 
       html << ' expanded' if project.is_ancestor_of?(current_active_project) || project == current_active_project
       html << '">'
       
       # Project Link
       is_active = project == current_active_project
       # Using a class to style it distinctively?
       html << link_to(project.name, project_path(project), class: "wiki-page-link type-project #{is_active ? 'project-active' : ''}")
       
       # If this is the active project, render its Wiki Tree below (if it has a wiki)
       # UPDATE: User wants to see expand icon if wiki exists, even if not active.
       # So we render the tree (hidden by CSS if not expanded via parent LI)
       if project.module_enabled?(:wiki) && User.current.allowed_to?(:view_wiki_pages, project)
           wiki_html = render_wiki_sidebar_tree(project)
           unless wiki_html.empty?
               html << wiki_html
           end
       end
       
       # Render Children
       children = project.children.visible.to_a
       if children.any?
           html << '<ul>'
           children.each do |child|
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
        html << '<li>'
        html << link_to_page(page)
        html << render_headers(page)
        
        children = pages_by_parent[page.id]
        if children
          html << render_tree(children, pages_by_parent)
        end
        html << '</li>'
      end
      html << '</ul>'
      html
    end

    def link_to_page(page)
      # Basic link, improvements like "active" class can be handled by JS matching URL
      "<a href=\"#{Rails.application.routes.url_helpers.project_wiki_page_path(page.project, page.title)}\" class=\"wiki-page-link type-page\" data-title=\"#{page.title}\">#{page.pretty_title}</a>"
    end

    def render_headers(page)
      return '' unless page.content
      
      text = page.content.text
      # Get max depth from settings, default to 3
      max_depth = (Setting.plugin_redmine_subnavigation['header_max_depth'] || 3).to_i
      
      headers = []
      
      # Regex for Markdown (## Header)
      # We capture: level (hashes), text
      # We iterate line by line or scan the whole text? 
      # Scan is easier but we need position to sort if we mix markdown/textile (rare but possible).
      # Let's map indexes to sort them correctly if mixed.
      
      # Markdown: # to #####
      text.scan(/^(#{1,5})\s+(.+)$/).each do |match|
        level = match[0].length
        title = match[1].strip
        next if level > max_depth
        headers << { level: level, title: title, offset: Regexp.last_match.begin(0) }
      end
      
      # Textile: h1. to h5.
      text.scan(/^h([1-5])\.\s+(.+)$/).each do |match|
        level = match[0].to_i
        title = match[1].strip
        next if level > max_depth
        headers << { level: level, title: title, offset: Regexp.last_match.begin(0) }
      end

      # Sort by occurrence in text
      headers.sort_by! { |h| h[:offset] }
      
      return '' if headers.empty?

      html = '<ul class="wiki-page-headers">'
      
      # Track seen anchors to handle duplicates
      seen_anchors = Hash.new(0)

      headers.each do |h|
        header = h[:title]
        level = h[:level]
        
        base_anchor = header.parameterize
        if seen_anchors.key?(base_anchor)
          count = seen_anchors[base_anchor] += 1
          anchor = "#{base_anchor}-#{count}"
        else
          seen_anchors[base_anchor] = 0
          anchor = base_anchor
        end

        html << "<li><a href=\"#{Rails.application.routes.url_helpers.project_wiki_page_path(page.project, page.title, anchor: anchor)}\" class=\"wiki-header-link wiki-header-h#{level}\" data-anchor=\"#{anchor}\">#{header}</a></li>"
      end
      html << '</ul>'
      html
    end
  end
end
