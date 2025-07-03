# frozen_string_literal: true

# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Create sample tasks
tasks_data = [
  { title: 'Buy groceries', description: 'Milk, eggs, bread, and fruit', completed: false, action_category: 'do' },
  { title: 'Read a book', description: 'Finish reading the current novel', completed: false, action_category: 'do' },
  { title: 'Workout', description: '30 minutes of cardio', completed: false, action_category: 'do' },
  { title: 'Call mom', description: 'Check in and say hello', completed: false, action_category: 'delegate' },
  { title: 'Clean the house', description: 'Vacuum and dust living room', completed: false, action_category: 'delegate' },
  { title: 'Write journal', description: 'Reflect on the day', completed: false, action_category: 'defer' },
  { title: 'Plan weekend trip', description: 'Research destinations', completed: false, action_category: 'defer' },
  { title: 'Pay bills', description: 'Electricity and internet', completed: false, action_category: 'do' },
  { title: 'Water plants', description: 'Check all indoor plants', completed: false, action_category: 'do' },
  { title: 'Organize desk', description: 'Sort papers and tidy up', completed: false, action_category: 'do' }
]

tasks_data.each do |task_attrs|
  Task.find_or_create_by!(title: task_attrs[:title]) do |task|
    task.description = task_attrs[:description]
    task.completed = task_attrs[:completed]
    task.action_category = task_attrs[:action_category]
  end
end

puts "Created #{Task.count} tasks"
