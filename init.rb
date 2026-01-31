Redmine::Plugin.register :redmine_subnavigation do
  name 'Redmine Subnavigation'
  author 'Stefan Mischke'
  description 'Provides a comprehensive sidebar navigation tree for projects, subprojects, wiki pages, and wiki content headings.'
  version '1.0.0'
  url 'https://github.com/modoq/redmine_subnavigation'
  author_url 'https://github.com/modoq'

  settings default: {
    'sidebar_mode' => 'wiki' # 'none', 'wiki', 'project_wiki'
  }, partial: 'settings/subnav_settings'
end

require_relative 'lib/redmine_subnavigation/wiki_sidebar_helper'
require_relative 'lib/redmine_subnavigation/hooks'

