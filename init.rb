Redmine::Plugin.register :redmine_subnavigation do
  name 'Subnavigation'
  author 'Stefan Mischke'
  description 'Provides a comprehensive sidebar navigation tree for projects, subprojects, wiki pages, and wiki headings.'
  version '0.5.1'
  url 'https://github.com/modoq/redmine_subnavigation'
  author_url 'https://github.com/modoq'

  settings default: {
    'sidebar_mode' => 'wiki', # 'none', 'wiki', 'project_wiki'
    'header_max_depth' => '3',
    'hide_breadcrumb' => false,
    'sticky_top_menu' => false
  }, partial: 'settings/subnav_settings'

  project_module :subnavigation do
    permission :view_subnavigation, { }
  end
end

require_relative 'lib/redmine_subnavigation/wiki_sidebar_helper'
require_relative 'lib/redmine_subnavigation/hooks'
require_relative 'lib/redmine_subnavigation/patches/enabled_module_patch'
require_relative 'lib/redmine_subnavigation/patches/project_patch'

ActiveSupport::Reloader.to_prepare do
  EnabledModule.send(:include, RedmineSubnavigation::Patches::EnabledModulePatch) unless EnabledModule.included_modules.include?(RedmineSubnavigation::Patches::EnabledModulePatch)
  Project.send(:include, RedmineSubnavigation::Patches::ProjectPatch) unless Project.included_modules.include?(RedmineSubnavigation::Patches::ProjectPatch)
end

