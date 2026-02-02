Redmine::Plugin.register :redmine_subnavigation do
  name 'Subnavigation'
  author 'Stefan Mischke'
  description 'Provides a comprehensive sidebar navigation tree for projects, subprojects, wiki pages, and wiki headings.'
  version '0.2.0'
  url 'https://github.com/modoq/redmine_subnavigation'
  author_url 'https://github.com/modoq'

  settings default: {
    'sidebar_mode' => 'wiki' # 'none', 'wiki', 'project_wiki'
  }, partial: 'settings/subnav_settings'
end

require_relative 'lib/redmine_subnavigation/wiki_sidebar_helper'
require_relative 'lib/redmine_subnavigation/hooks'

