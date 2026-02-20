# frozen_string_literal: true

require "rspec/core/rake_task"
require "rubocop/rake_task"

RSpec::Core::RakeTask.new(:spec)
RuboCop::RakeTask.new

desc "Regenerate .rubocop_todo.yml"
task :rubocop_todo do
  FileUtils.touch(".rubocop_todo.yml")
  sh "bundle exec rubocop --auto-gen-config --auto-gen-only-exclude --exclude-limit 1000"
end

task default: %i[spec rubocop]
