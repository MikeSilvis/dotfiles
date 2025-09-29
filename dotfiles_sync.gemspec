# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = "dotfiles_sync"
  spec.version       = "1.0.0"
  spec.authors       = ["Mike Silvis"]
  spec.email         = ["mike@example.com"]

  spec.summary       = "Mike's dotfiles synchronization tool"
  spec.description   = "A Ruby tool to synchronize dotfiles, editor configurations, fonts, and development tools across machines"
  spec.homepage      = "https://github.com/msilvis/dotfiles"
  spec.license       = "MIT"

  spec.files         = Dir.glob("{bin,lib,configs,docs}/**/*") + %w[README.md LICENSE]
  spec.bindir        = "bin"
  spec.executables   = ["dotfiles-sync"]
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 2.7.0"

  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rubocop", "~> 1.0"

  spec.metadata = {
    "homepage_uri" => spec.homepage,
    "source_code_uri" => spec.homepage,
    "changelog_uri" => "#{spec.homepage}/blob/main/CHANGELOG.md",
    "documentation_uri" => "#{spec.homepage}/blob/main/README.md"
  }
end
