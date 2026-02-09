module RedmineSubnavigation
  module Patches
    module ProjectPatch
      extend ActiveSupport::Concern

      included do
        # Alias the original method to wrap it
        alias_method :enabled_module_names_without_subnavigation=, :enabled_module_names=
        alias_method :enabled_module_names=, :enabled_module_names_with_subnavigation=
      end

      def enabled_module_names_with_subnavigation=(module_names)
        # Check if subnavigation is currently enabled but missing from new names (Deactivation)
        if module_enabled?('subnavigation') && module_names && !module_names.include?('subnavigation')
          cascade_disable_subnavigation_if_needed
        end

        # Check if subnavigation is currently disabled but present in new names (Activation)
        # Note: Activation usually works via EnabledModule callbacks, but we can double check here or stick to EnabledModule for creation
        # if !module_enabled?('subnavigation') && module_names && module_names.include?('subnavigation')
        #   # Activation is handled by EnabledModulePatch after_create, so we might not need it here
        # end

        # Call original method
        self.enabled_module_names_without_subnavigation = module_names
      end

      def cascade_disable_subnavigation_if_needed
        mode = Setting.plugin_redmine_subnavigation['sidebar_mode']
        return unless mode == 'project_wiki'

        # Log for debugging
        # Rails.logger.info "RedmineSubnavigation: Cascading disable from ProjectPatch for #{identifier}"

        descendants.each do |subproject|
          if subproject.module_enabled?('subnavigation')
            subproject.enabled_modules.find_by(name: 'subnavigation')&.destroy
          end
        end
      end
    end
  end
end
