module RedmineSubnavigation
  module Patches
    module ActivitiesControllerPatch
      def self.prepended(base)
        base.etag do
          # Incorporate plugin settings into the ETag calculation
          settings = Setting.plugin_redmine_subnavigation
          if settings.is_a?(Hash)
            "redmine_subnavigation-v1-#{settings['show_on_globally']}-#{settings['sidebar_mode']}"
          else
            "redmine_subnavigation-v1"
          end
        end
      end
    end
  end
end
