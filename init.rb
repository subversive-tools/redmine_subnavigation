Redmine::Plugin.register :redmine_subnavigation do
  name 'Subnavigation'
  author 'Stefan Mischke'
  description 'Provides a comprehensive sidebar navigation tree for projects, subprojects, wiki pages, and wiki headings.'
  version '0.3.2'
  url 'https://github.com/modoq/redmine_subnavigation'
  author_url 'https://github.com/modoq'

  settings default: {
    'sidebar_mode' => 'wiki', # 'none', 'wiki', 'project_wiki'
    'header_max_depth' => '3'
  }, partial: 'settings/subnav_settings'

  project_module :subnavigation do
    permission :view_subnavigation, { }
  end
end

require_relative 'lib/redmine_subnavigation/wiki_sidebar_helper'
require_relative 'lib/redmine_subnavigation/hooks'

