# Load Redmine test helper
require File.expand_path(File.dirname(__FILE__) + '/../../../test/test_helper')

module RedmineSubnavigation
  class TestCase < ActiveSupport::TestCase
    include ::Redmine::I18n
    
    def setup
      User.current = nil
    end
  end
end
