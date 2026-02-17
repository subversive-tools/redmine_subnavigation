# Check settings
mode = Setting.plugin_redmine_subnavigation['sidebar_mode']
puts "Current Sidebar Mode: #{mode}"

# Ensure we are in the correct mode
if mode != 'project_wiki'
  puts "Use 'project_wiki' mode for this test."
  Setting.plugin_redmine_subnavigation = Setting.plugin_redmine_subnavigation.merge('sidebar_mode' => 'project_wiki')
  puts "Switched to 'project_wiki' mode."
end

# Find or create projects
parent = Project.find_by(identifier: 'test-parent') || Project.create!(name: 'Test Parent', identifier: 'test-parent')
child = Project.find_by(identifier: 'test-child') || Project.create!(name: 'Test Child', identifier: 'test-child', parent_id: parent.id)

# Reset state
parent.enabled_module_names = parent.enabled_module_names - ['subnavigation']
child.enabled_module_names = child.enabled_module_names - ['subnavigation']
parent.save!
child.save!

puts "Initial state: Parent: #{parent.module_enabled?('subnavigation')}, Child: #{child.module_enabled?('subnavigation')}"

# Enable on parent
puts "Enabling on parent..."
parent.enabled_module_names = parent.enabled_module_names + ['subnavigation']
parent.save!

# Check child
child.reload
puts "After Enable: Parent: #{parent.module_enabled?('subnavigation')}, Child: #{child.module_enabled?('subnavigation')}"

if child.module_enabled?('subnavigation')
  puts "SUCCESS: Child enabled."
else
  puts "FAILURE: Child NOT enabled."
end

# Disable on parent
puts "Disabling on parent..."
parent.enabled_module_names = parent.enabled_module_names - ['subnavigation']
parent.save!

# Check child
child.reload
puts "After Disable: Parent: #{parent.module_enabled?('subnavigation')}, Child: #{child.module_enabled?('subnavigation')}"

if !child.module_enabled?('subnavigation')
  puts "SUCCESS: Child disabled."
else
  puts "FAILURE: Child NOT disabled."
end
