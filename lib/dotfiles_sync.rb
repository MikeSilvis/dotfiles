#!/usr/bin/env ruby
# frozen_string_literal: true

require 'fileutils'
require 'optparse'
require 'time'

# Main DotfilesSync class that handles all synchronization operations
class DotfilesSync
  attr_reader :dry_run, :verbose, :force, :backup_dir

  def initialize(options = {})
    @dry_run = options[:dry_run] || false
    @verbose = options[:verbose] || false
    @force = options[:force] || false
    @backup_dir = options[:backup_dir] || "#{ENV['HOME']}/.dotfiles_backup_#{Time.now.strftime('%Y%m%d_%H%M%S')}"
  end

  def run
    puts "🚀 Welcome to Mike's Dotfiles Sync!"
    puts "📁 Backup directory: #{@backup_dir}" unless @dry_run
    puts "🔍 Dry run mode: #{@dry_run}" if @dry_run
    puts

    begin
      install_homebrew
      install_ruby_version_manager
      install_homebrew_packages
      install_oh_my_zsh
      setup_vim
      copy_dotfiles
      install_fonts_and_themes
      install_iterm2_config
      install_editor_configs
      install_xcode_config
      puts "✅ Sync completed successfully!"
    rescue StandardError => e
      puts "❌ Sync failed: #{e.message}"
      puts "💡 Run with --verbose for more details" unless @verbose
      exit 1
    end
  end

  private

  def run_command(command, description = nil)
    puts "🔧 #{description || command}" if @verbose
    return if @dry_run

    system(command) || raise("Command failed: #{command}")
  end

  def install_homebrew
    puts "🍺 Installing Homebrew..."
    return if system('which brew > /dev/null 2>&1')

    run_command(
      '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"',
      'Installing Homebrew'
    )
  end

  def install_ruby_version_manager
    puts "💎 Installing Ruby version manager (rbenv)..."
    return if system('which rbenv > /dev/null 2>&1')

    run_command('brew install rbenv ruby-build', 'Installing rbenv and ruby-build')
    puts "💡 Please add 'eval \"$(rbenv init -)\"' to your shell profile to enable rbenv"
  end

  def install_homebrew_packages
    puts "📦 Installing Homebrew packages..."
    packages = %w[
      git
      vim
      ack
      cmake
      watchman
      go
      node
      bash-git-prompt
    ]

    packages.each do |package|
      next if system("brew list #{package} > /dev/null 2>&1")
      run_command("brew install #{package}", "Installing #{package}")
    end
  end

  def install_oh_my_zsh
    puts "🐚 Installing Oh My Zsh..."
    return if Dir.exist?("#{ENV['HOME']}/.oh-my-zsh")

    run_command(
      'sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended',
      'Installing Oh My Zsh'
    )
  end

  def setup_vim
    puts "📝 Setting up Vim..."
    vim_dir = "#{ENV['HOME']}/.vim"

    unless @dry_run
      FileUtils.rm_rf(vim_dir) if File.exist?(vim_dir)
      FileUtils.mkdir_p("#{vim_dir}/autoload")
      FileUtils.mkdir_p("#{vim_dir}/bundle")
    end

    # Install Pathogen (plugin manager)
    puts "🔌 Installing Pathogen..."
    run_command(
      "curl -LSso #{vim_dir}/autoload/pathogen.vim https://tpo.pe/pathogen.vim",
      "Installing Pathogen"
    )

    # Install Vundle (plugin manager)
    puts "🔌 Installing Vundle..."
    run_command(
      "git clone --depth=1 https://github.com/VundleVim/Vundle.vim.git #{vim_dir}/bundle/Vundle.vim",
      "Installing Vundle"
    )

    # Copy color scheme
    puts "🎨 Copying color scheme..."
    unless @dry_run
      FileUtils.mkdir_p("#{vim_dir}/colors")
      FileUtils.cp('./configs/vim/colors/smyck.vim', "#{vim_dir}/colors/") if File.exist?('./configs/vim/colors/smyck.vim')
    end

    puts "🔄 Please run :PluginInstall in Vim to install plugins"
  end

  def copy_dotfiles
    puts "📋 Copying dotfiles..."

    dotfiles = {
      './configs/shell/bash_profile' => "#{ENV['HOME']}/.bash_profile",
      './configs/shell/zshrc' => "#{ENV['HOME']}/.zshrc",
      './configs/shell/development_profile' => "#{ENV['HOME']}/.development_profile",
      './configs/vim/vimrc' => "#{ENV['HOME']}/.vimrc",
      './configs/git/.gitconfig' => "#{ENV['HOME']}/.gitconfig",
      './configs/git/.gitignore_global' => "#{ENV['HOME']}/.gitignore_global",
      './configs/ssh/config' => "#{ENV['HOME']}/.ssh/config",
      './configs/.inputrc' => "#{ENV['HOME']}/.inputrc",
      './configs/.ackrc' => "#{ENV['HOME']}/.ackrc"
    }

    dotfiles.each do |source, target|
      next unless File.exist?(source)

      if File.exist?(target) && !@dry_run
        puts "💾 Backing up #{File.basename(target)}..."
        FileUtils.mkdir_p(@backup_dir)
        FileUtils.cp(target, "#{@backup_dir}/#{File.basename(target)}")
      end

      # Ensure SSH directory exists and has proper permissions
      if target.include?('.ssh/') && !@dry_run
        FileUtils.mkdir_p(File.dirname(target))
        FileUtils.chmod(0700, File.dirname(target))
      end

      puts "📄 Copying #{File.basename(source)} to #{target}"
      unless @dry_run
        FileUtils.cp(source, target)
        # Set proper permissions for SSH config
        if target.include?('.ssh/')
          FileUtils.chmod(0600, target)
        end
      end
    end
  end

  def install_fonts_and_themes
    puts "🎨 Installing fonts and themes..."
    
    fonts_source = "./configs/fonts"
    fonts_dir = "#{ENV['HOME']}/Library/Fonts"

    # Install fonts
    if Dir.exist?(fonts_source)
      unless @dry_run
        FileUtils.mkdir_p(fonts_dir)
      end

      Dir.glob("#{fonts_source}/*.{ttf,otf,ttc}").each do |font_file|
        font_name = File.basename(font_file)
        target = "#{fonts_dir}/#{font_name}"
        
        if File.exist?(target) && !@dry_run
          puts "⚠️  Font #{font_name} already exists, skipping..."
          next
        end

        puts "📄 Installing font: #{font_name}"
        unless @dry_run
          FileUtils.cp(font_file, target)
        end
      end
    end
  end

  def install_xcode_config
    puts "🔨 Installing Xcode configuration..."
    
    xcode_source = "./configs/xcode"
    return unless Dir.exist?(xcode_source)

    xcode_user_dir = "#{ENV['HOME']}/Library/Developer/Xcode/UserData"
    xcode_prefs_dir = "#{ENV['HOME']}/Library/Preferences"

    unless @dry_run
      FileUtils.mkdir_p(xcode_user_dir)
      FileUtils.mkdir_p("#{xcode_user_dir}/FontAndColorThemes")
      FileUtils.mkdir_p("#{xcode_user_dir}/KeyBindings")
    end

    # Install color themes
    themes_source = "#{xcode_source}/FontAndColorThemes"
    if Dir.exist?(themes_source)
      Dir.glob("#{themes_source}/*.xccolortheme").each do |theme_file|
        theme_name = File.basename(theme_file)
        target = "#{xcode_user_dir}/FontAndColorThemes/#{theme_name}"
        
        if File.exist?(target) && !@dry_run
          puts "⚠️  Xcode theme #{theme_name} already exists, skipping..."
          next
        end

        puts "🎨 Installing Xcode theme: #{theme_name}"
        unless @dry_run
          FileUtils.cp(theme_file, target)
        end
      end
    end

    # Install key bindings
    keybindings_source = "#{xcode_source}/KeyBindings"
    if Dir.exist?(keybindings_source)
      Dir.glob("#{keybindings_source}/*.idekeybindings").each do |keybinding_file|
        keybinding_name = File.basename(keybinding_file)
        target = "#{xcode_user_dir}/KeyBindings/#{keybinding_name}"
        
        if File.exist?(target) && !@dry_run
          puts "💾 Backing up existing Xcode keybindings..."
          FileUtils.cp(target, "#{target}.backup.#{Time.now.strftime('%Y%m%d_%H%M%S')}")
        end

        puts "⌨️  Installing Xcode keybindings: #{keybinding_name}"
        unless @dry_run
          FileUtils.cp(keybinding_file, target)
        end
      end
    end

    # Install find navigator scopes
    scopes_file = "#{xcode_source}/IDEFindNavigatorScopes.plist"
    if File.exist?(scopes_file)
      target = "#{xcode_user_dir}/IDEFindNavigatorScopes.plist"
      
      if File.exist?(target) && !@dry_run
        puts "💾 Backing up existing Xcode find navigator scopes..."
        FileUtils.cp(target, "#{target}.backup.#{Time.now.strftime('%Y%m%d_%H%M%S')}")
      end

      puts "🔍 Installing Xcode find navigator scopes..."
      unless @dry_run
        FileUtils.cp(scopes_file, target)
      end
    end

    # Install Xcode preferences
    prefs_files = [
      "#{xcode_source}/com.apple.dt.Xcode.plist",
      "#{xcode_source}/com.apple.dt.xcodebuild.plist"
    ]

    prefs_files.each do |prefs_file|
      next unless File.exist?(prefs_file)
      
      prefs_name = File.basename(prefs_file)
      target = "#{xcode_prefs_dir}/#{prefs_name}"
      
      if File.exist?(target) && !@dry_run
        puts "💾 Backing up existing Xcode preferences: #{prefs_name}..."
        FileUtils.cp(target, "#{target}.backup.#{Time.now.strftime('%Y%m%d_%H%M%S')}")
      end

      puts "⚙️  Installing Xcode preferences: #{prefs_name}"
      unless @dry_run
        FileUtils.cp(prefs_file, target)
      end
    end

    puts "🔄 Please restart Xcode to apply configuration changes"
  end

  def install_iterm2_config
    puts "🖥️  Installing iTerm2 configuration..."
    
    iterm2_source = "./configs/iterm2"
    return unless Dir.exist?(iterm2_source)

    iterm2_prefs_dir = "#{ENV['HOME']}/Library/Preferences"
    iterm2_support_dir = "#{ENV['HOME']}/Library/Application Support/iTerm2"
    iterm2_dynamic_profiles_dir = "#{iterm2_support_dir}/DynamicProfiles"
    iterm2_color_presets_dir = "#{iterm2_support_dir}/ColorPresets"

    # Install color schemes
    color_files = Dir.glob("#{iterm2_source}/*.itermcolors")
    if !color_files.empty?
      unless @dry_run
        FileUtils.mkdir_p(iterm2_color_presets_dir)
      end

      color_files.each do |color_file|
        color_name = File.basename(color_file)
        target = "#{iterm2_color_presets_dir}/#{color_name}"
        
        puts "🎨 Installing iTerm2 color scheme: #{color_name}"
        unless @dry_run
          FileUtils.cp(color_file, target)
        end
      end
    end

    # Install preferences
    prefs_file = "#{iterm2_source}/iterm2_preferences.plist"
    if File.exist?(prefs_file)
      target = "#{iterm2_prefs_dir}/com.googlecode.iterm2.plist"
      
      if File.exist?(target) && !@dry_run
        puts "💾 Backing up existing iTerm2 preferences..."
        FileUtils.cp(target, "#{target}.backup.#{Time.now.strftime('%Y%m%d_%H%M%S')}")
      end

      puts "⚙️  Installing iTerm2 preferences..."
      unless @dry_run
        FileUtils.cp(prefs_file, target)
      end
    end

    # Install dynamic profiles
    profiles_source = "#{iterm2_source}/profiles"
    if Dir.exist?(profiles_source)
      unless @dry_run
        FileUtils.mkdir_p(iterm2_dynamic_profiles_dir)
      end

      Dir.glob("#{profiles_source}/*.json").each do |profile_file|
        profile_name = File.basename(profile_file)
        target = "#{iterm2_dynamic_profiles_dir}/#{profile_name}"
        
        puts "📋 Installing iTerm2 profile: #{profile_name}"
        unless @dry_run
          FileUtils.cp(profile_file, target)
        end
      end
    end

    puts "🔄 Please restart iTerm2 to apply configuration changes"
  end

  def install_editor_configs
    puts "📝 Installing editor configurations..."
    
    editors_source = "./configs/editors"
    return unless Dir.exist?(editors_source)

    # Install Cursor configuration
    cursor_source = "#{editors_source}/cursor"
    if Dir.exist?(cursor_source)
      cursor_user_dir = "#{ENV['HOME']}/Library/Application Support/Cursor/User"
      
      unless @dry_run
        FileUtils.mkdir_p(cursor_user_dir)
      end

      # Install settings
      settings_file = "#{cursor_source}/settings.json"
      if File.exist?(settings_file)
        target = "#{cursor_user_dir}/settings.json"
        
        if File.exist?(target) && !@dry_run
          puts "💾 Backing up existing Cursor settings..."
          FileUtils.cp(target, "#{target}.backup.#{Time.now.strftime('%Y%m%d_%H%M%S')}")
        end

        puts "⚙️  Installing Cursor settings..."
        unless @dry_run
          FileUtils.cp(settings_file, target)
        end
      end

      # Install keybindings
      keybindings_file = "#{cursor_source}/keybindings.json"
      if File.exist?(keybindings_file)
        target = "#{cursor_user_dir}/keybindings.json"
        
        if File.exist?(target) && !@dry_run
          puts "💾 Backing up existing Cursor keybindings..."
          FileUtils.cp(target, "#{target}.backup.#{Time.now.strftime('%Y%m%d_%H%M%S')}")
        end

        puts "⌨️  Installing Cursor keybindings..."
        unless @dry_run
          FileUtils.cp(keybindings_file, target)
        end
      end

      # Install extensions
      extensions_file = "#{cursor_source}/extensions.txt"
      if File.exist?(extensions_file)
        puts "🔌 Installing Cursor extensions..."
        unless @dry_run
          extensions = File.readlines(extensions_file).map(&:strip).reject(&:empty?)
          extensions.each do |extension|
            puts "  📦 Installing #{extension}..."
            run_command("cursor --install-extension #{extension}", "Installing Cursor extension: #{extension}")
          end
        end
      end
    end

    # Install VSCode configuration
    vscode_source = "#{editors_source}/vscode"
    if Dir.exist?(vscode_source)
      vscode_user_dir = "#{ENV['HOME']}/Library/Application Support/Code/User"
      
      unless @dry_run
        FileUtils.mkdir_p(vscode_user_dir)
      end

      # Install settings
      settings_file = "#{vscode_source}/settings.json"
      if File.exist?(settings_file)
        target = "#{vscode_user_dir}/settings.json"
        
        if File.exist?(target) && !@dry_run
          puts "💾 Backing up existing VSCode settings..."
          FileUtils.cp(target, "#{target}.backup.#{Time.now.strftime('%Y%m%d_%H%M%S')}")
        end

        puts "⚙️  Installing VSCode settings..."
        unless @dry_run
          FileUtils.cp(settings_file, target)
        end
      end

      # Install extensions
      extensions_file = "#{vscode_source}/extensions.txt"
      if File.exist?(extensions_file)
        puts "🔌 Installing VSCode extensions..."
        unless @dry_run
          extensions = File.readlines(extensions_file).map(&:strip).reject(&:empty?)
          extensions.each do |extension|
            puts "  📦 Installing #{extension}..."
            run_command("code --install-extension #{extension}", "Installing VSCode extension: #{extension}")
          end
        end
      end
    end

    puts "🔄 Please restart your editors to apply configuration changes"
  end
end
