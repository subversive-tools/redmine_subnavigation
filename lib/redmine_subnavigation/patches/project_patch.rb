module RedmineSubnavigation
  module Patches
    module ProjectPatch


      def enabled_modules=(modules)
        # 'modules' is an array of EnabledModule objects (new or existing)
        # We extract names to compare
        new_names = modules.map(&:name).map(&:to_s)
        
        # Check current state (from DB/association)
        # We check if subnavigation is currently enabled
        was_enabled = module_enabled?('subnavigation')
        will_be_enabled = new_names.include?('subnavigation')

        if was_enabled && !will_be_enabled
          cascade_disable_subnavigation_if_needed
        elsif !was_enabled && will_be_enabled
          cascade_enable_subnavigation_if_needed
        end

        super
      end
      
      def cascade_disable_subnavigation_if_needed
        mode = Setting.plugin_redmine_subnavigation['sidebar_mode']
        Rails.logger.info "[Subnavigation] Cascading disable. Mode: #{mode}"
        return unless mode == 'project_wiki'

        descendants.each do |subproject|
          if subproject.module_enabled?('subnavigation')
            Rails.logger.info "[Subnavigation] Disabling for subproject #{subproject.identifier}"
            subproject.enabled_modules.find_by(name: 'subnavigation')&.destroy
          end
        end
      end

      def cascade_enable_subnavigation_if_needed
        mode = Setting.plugin_redmine_subnavigation['sidebar_mode']
        Rails.logger.info "[Subnavigation] Cascading enable. Mode: #{mode}"
        return unless mode == 'project_wiki'

        descendants.each do |subproject|
          unless subproject.module_enabled?('subnavigation')
            Rails.logger.info "[Subnavigation] Enabling for subproject #{subproject.identifier}"
            subproject.enabled_modules.create(name: 'subnavigation')
          end
        end
      end
    end
  end
end
