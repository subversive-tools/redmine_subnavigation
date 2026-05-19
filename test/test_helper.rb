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

# Ensure Redmine's test fixtures are loadable (Rails 6.1 uses fixture_path=, Rails 7 uses fixture_paths=)
_redmine_fixtures = File.expand_path("../../../test/fixtures", __dir__)
if ActiveSupport::TestCase.respond_to?(:fixture_paths=)
  ActiveSupport::TestCase.fixture_paths = [_redmine_fixtures]
else
  ActiveSupport::TestCase.fixture_path = _redmine_fixtures
end
