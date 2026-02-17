Redmine::Plugin.register :redmine_subnavigation do
  name 'Redmine Subnavigation'
  author 'Simon Mischke'
  description 'This plugin adds a subnavigation sidebar to the project page'
  version '0.5.4'
  url 'https://github.com/simonmischke/redmine_subnavigation'
  author_url 'https://github.com/simonmischke'

  settings default: {
    'sidebar_mode' => 'wiki', # 'none', 'wiki', 'project_wiki'
    'header_max_depth' => '3',
    'hide_breadcrumb' => false,
    'sticky_top_menu' => false,
    'show_on_globally' => false
  }, partial: 'settings/subnav_settings'

  project_module :subnavigation do
    permission :view_subnavigation, { }
  end
end

require_relative 'lib/redmine_subnavigation/wiki_sidebar_helper'
require_relative 'lib/redmine_subnavigation/hooks'
require_relative 'lib/redmine_subnavigation/patches/enabled_module_patch'
require_relative 'lib/redmine_subnavigation/patches/project_patch'


# Helper for applying patches
module RedmineSubnavigation
  def self.apply_patches
    unless EnabledModule.included_modules.include?(RedmineSubnavigation::Patches::EnabledModulePatch)
      EnabledModule.send(:include, RedmineSubnavigation::Patches::EnabledModulePatch)
    end

    # Use prepend for ProjectPatch to ensure our logic runs
    # Note: We don't check for inclusion because prepend stacks differently
    Project.send(:prepend, RedmineSubnavigation::Patches::ProjectPatch)

    # Patch ActivitiesController to fix 304 Not Modified caching issue
    require_relative 'lib/redmine_subnavigation/patches/activities_controller_patch'
    unless ActivitiesController.included_modules.include?(RedmineSubnavigation::Patches::ActivitiesControllerPatch)
      ActivitiesController.send(:prepend, RedmineSubnavigation::Patches::ActivitiesControllerPatch)
    end
  end
end

# Apply patches immediately if classes are loaded (e.g. by other plugins)
if defined?(Project) && defined?(EnabledModule)
  RedmineSubnavigation.apply_patches
end

# Ensure patches are re-applied on reload
ActiveSupport::Reloader.to_prepare do
  RedmineSubnavigation.apply_patches
end

