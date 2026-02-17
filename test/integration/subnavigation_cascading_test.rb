require File.expand_path('../../test_helper', __FILE__)

class SubnavigationCascadingTest < Redmine::IntegrationTest
  fixtures :projects, :users, :roles, :members, :member_roles, :enabled_modules

  def setup
    @parent = Project.find(1) # econtrol
    @child = Project.find(3) # econtrol / subproject1
    
    # Ensure clean state
    @parent.enabled_module_names = @parent.enabled_module_names - ['subnavigation']
    @child.enabled_module_names = @child.enabled_module_names - ['subnavigation']
    
    # Set mode to project_wiki
    Setting.plugin_redmine_subnavigation = Setting.plugin_redmine_subnavigation.merge('sidebar_mode' => 'project_wiki')
  end

  def test_cascading_enable
    # Enable on parent
    @parent.enabled_module_names = @parent.enabled_module_names + ['subnavigation']
    @parent.save!
    
    # Reload child
    @child.reload
    
    assert @parent.module_enabled?('subnavigation'), "Parent should have subnavigation enabled"
    assert @child.module_enabled?('subnavigation'), "Child should have subnavigation enabled via cascade"
  end

  def test_cascading_disable
    # Enable both first
    @parent.enabled_module_names = @parent.enabled_module_names + ['subnavigation']
    @parent.save!
    @child.reload
    assert @child.module_enabled?('subnavigation')

    # Disable on parent
    @parent.enabled_module_names = @parent.enabled_module_names - ['subnavigation']
    @parent.save!
    
    # Reload child
    @child.reload
    
    assert !@parent.module_enabled?('subnavigation'), "Parent should have subnavigation disabled"
    assert !@child.module_enabled?('subnavigation'), "Child should have subnavigation disabled via cascade"
  end
  
  def test_no_cascade_in_wiki_mode
    # Set mode to wiki only
    Setting.plugin_redmine_subnavigation = Setting.plugin_redmine_subnavigation.merge('sidebar_mode' => 'wiki')
    
    # Enable on parent
    @parent.enabled_module_names = @parent.enabled_module_names + ['subnavigation']
    @parent.save!
    
    # Reload child
    @child.reload
    
    assert @parent.module_enabled?('subnavigation')
    assert !@child.module_enabled?('subnavigation'), "Child should NOT have subnavigation enabled in wiki mode"
  end
end
