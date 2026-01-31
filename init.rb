Redmine::Plugin.register :redmine_subnav do
  name 'Redmine Subnav'
  author 'Stefan Mischke'
  description 'Adds a collapsible sidebar for Wiki navigation'
  version '1.0.0'
  url 'https://github.com/modoq/redmine_subnav'
  author_url 'https://github.com/modoq'

  settings default: {
    'sidebar_mode' => 'wiki' # 'none', 'wiki', 'project_wiki'
  }, partial: 'settings/subnav_settings'
end

require_relative 'lib/redmine_subnav/hooks'
require_relative 'lib/redmine_subnav/wiki_sidebar_helper'

