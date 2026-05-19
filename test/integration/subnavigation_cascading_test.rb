require File.expand_path('../../test_helper', __FILE__)

class SubnavigationCascadingTest < Redmine::IntegrationTest
  fixtures :projects, :users, :roles, :members, :member_roles, :enabled_modules

  def setup
    # ecookbook (id=1) has children in Redmine fixtures
    @parent = Project.find(1)
    @child  = @parent.children.first
    skip "No child project available" unless @child

    EnabledModule.where(name: 'subnavigation').delete_all
    Setting.plugin_redmine_subnavigation =
      Setting.plugin_redmine_subnavigation.merge('sidebar_mode' => 'project_wiki')
  end

  def teardown
    EnabledModule.where(name: 'subnavigation').delete_all
  end

  def test_cascade_enable_adds_module_to_children
    # Insert via SQL to bypass EnabledModule name-validation
    # (module may or may not pass AR validation depending on initialization order)
    ActiveRecord::Base.connection.execute(
      "INSERT INTO enabled_modules (project_id, name) VALUES (#{@parent.id}, 'subnavigation')"
    )
    @parent.reload
    assert @parent.module_enabled?('subnavigation'), "Parent should have subnavigation after insert"

    @parent.cascade_enable_subnavigation_if_needed

    @child.reload
    assert @child.module_enabled?('subnavigation'),
           "Child should have subnavigation enabled after cascade_enable"
  end

  def test_cascade_disable_removes_module_from_children
    # Seed both parent and child
    [@parent, @child].each do |p|
      ActiveRecord::Base.connection.execute(
        "INSERT INTO enabled_modules (project_id, name) VALUES (#{p.id}, 'subnavigation')"
      )
    end
    @parent.reload
    @child.reload

    assert @parent.module_enabled?('subnavigation')
    assert @child.module_enabled?('subnavigation')

    @parent.cascade_disable_subnavigation_if_needed

    @child.reload
    assert !@child.module_enabled?('subnavigation'),
           "Child should have subnavigation disabled after cascade_disable"
  end

  def test_no_cascade_in_wiki_mode
    Setting.plugin_redmine_subnavigation =
      Setting.plugin_redmine_subnavigation.merge('sidebar_mode' => 'wiki')

    ActiveRecord::Base.connection.execute(
      "INSERT INTO enabled_modules (project_id, name) VALUES (#{@parent.id}, 'subnavigation')"
    )
    @parent.reload

    @parent.cascade_enable_subnavigation_if_needed

    @child.reload
    assert !@child.module_enabled?('subnavigation'),
           "Child should NOT inherit subnavigation in 'wiki' mode"
  end
end
