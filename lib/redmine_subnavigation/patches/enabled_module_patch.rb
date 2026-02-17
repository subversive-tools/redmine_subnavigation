module RedmineSubnavigation
  module Patches
    module EnabledModulePatch
      extend ActiveSupport::Concern

      included do
        # Callbacks removed in favor of ProjectPatch
      end
      
      # Methods removed

    end
  end
end
