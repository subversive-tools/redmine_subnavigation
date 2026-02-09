module RedmineSubnavigation
  module Patches
    module EnabledModulePatch
      extend ActiveSupport::Concern

      included do
        after_create :cascade_enable_subnavigation
        before_destroy :cascade_disable_subnavigation
      end

      def cascade_enable_subnavigation
        return unless name == 'subnavigation'
        
        mode = Setting.plugin_redmine_subnavigation['sidebar_mode']
        return unless mode == 'project_wiki'
        
        return unless project

        project.descendants.each do |subproject|
          unless subproject.module_enabled?('subnavigation')
            subproject.enabled_modules.create(name: 'subnavigation')
          end
        end
      end

      def cascade_disable_subnavigation
        return unless name == 'subnavigation'
        return unless Setting.plugin_redmine_subnavigation['sidebar_mode'] == 'project_wiki'
        return unless project

        project.descendants.each do |subproject|
          if subproject.module_enabled?('subnavigation')
            # Use destroy instead of delete to ensure callbacks fire for subprojects too
            subproject.enabled_modules.find_by(name: 'subnavigation')&.destroy
          end
        end
      end
    end
  end
end
