# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

task default: :spec

desc "Run RuboCop"
task :rubocop do
  sh "bundle exec rubocop"
end

desc "Run all checks"
task :check => [:rubocop, :spec]

desc "Install the gem locally"
task :install do
  sh "gem build dotfiles_sync.gemspec"
  sh "gem install dotfiles_sync-*.gem"
end

desc "Uninstall the gem"
task :uninstall do
  sh "gem uninstall dotfiles_sync"
end
