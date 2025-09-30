#!/usr/bin/env ruby
# frozen_string_literal: true

require 'fileutils'
require 'optparse'
require 'time'
require 'open3'

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
    puts "🚀 Welcome to Mike's Personal Dotfiles Sync!"
    puts "📁 Backup directory: #{@backup_dir}" unless @dry_run
    puts "🔍 Dry run mode: #{@dry_run}" if @dry_run
    puts "💡 This sync will install system dependencies and personal settings."
    puts

    begin
      install_system_dependencies
      copy_personal_dotfiles
      install_fonts_and_themes
      install_iterm2_config
      install_editor_configs
      install_xcode_config
      puts "✅ Personal settings sync completed successfully!"
      puts "💡 You may need to restart your terminal or run 'source ~/.zshrc' to apply changes."
    rescue StandardError => e
      puts "❌ Sync failed: #{e.message}"
      puts "💡 Run with --verbose for more details" unless @verbose
      exit 1
    end
  end

  private

  def install_system_dependencies
    puts "🔧 Checking and installing system dependencies..."
    
    check_and_install_homebrew
    check_and_install_zsh
    check_and_install_oh_my_zsh
    check_and_install_oh_my_posh
    check_and_install_nerd_fonts
  end

  def check_and_install_homebrew
    puts "🍺 Checking Homebrew installation..."
    
    unless system("which brew > /dev/null 2>&1")
      puts "📦 Installing Homebrew..."
      unless @dry_run
        system('/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"')
        # Add Homebrew to PATH for current session
        ENV['PATH'] = "/opt/homebrew/bin:/usr/local/bin:#{ENV['PATH']}"
      end
    else
      puts "✅ Homebrew already installed"
    end
  end

  def check_and_install_zsh
    puts "🐚 Checking zsh installation..."
    
    unless system("which zsh > /dev/null 2>&1")
      puts "📦 Installing zsh via Homebrew..."
      run_command("brew install zsh", "Installing zsh")
      
      # Set zsh as default shell if not already
      current_shell = ENV['SHELL']
      unless current_shell&.include?('zsh')
        puts "🔄 Setting zsh as default shell..."
        unless @dry_run
          zsh_path = `which zsh`.strip
          system("sudo chsh -s #{zsh_path} #{ENV['USER']}")
        end
      end
    else
      puts "✅ zsh already installed"
    end
  end

  def check_and_install_oh_my_zsh
    puts "🎨 Checking Oh My Zsh installation..."
    
    oh_my_zsh_dir = "#{ENV['HOME']}/.oh-my-zsh"
    unless Dir.exist?(oh_my_zsh_dir)
      puts "📦 Installing Oh My Zsh..."
      unless @dry_run
        system('sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended')
      end
    else
      puts "✅ Oh My Zsh already installed"
    end
  end

  def check_and_install_oh_my_posh
    puts "✨ Checking Oh My Posh installation..."
    
    unless system("which oh-my-posh > /dev/null 2>&1")
      puts "📦 Installing Oh My Posh via Homebrew..."
      run_command("brew install oh-my-posh", "Installing Oh My Posh")
    else
      puts "✅ Oh My Posh already installed"
    end
  end

  def check_and_install_nerd_fonts
    puts "🎨 Checking Nerd Fonts installation..."
    
    # Check if MesloLGL Nerd Font is installed
    nerd_font_installed = system("fc-list | grep -i 'meslolgl.*nerd' > /dev/null 2>&1") || 
                         Dir.glob("#{ENV['HOME']}/Library/Fonts/MesloLGL*NerdFont*").any?
    
    unless nerd_font_installed
      puts "📦 Installing Nerd Fonts via Homebrew..."
      run_command("brew tap homebrew/cask-fonts", "Adding font cask tap")
      run_command("brew install --cask font-meslo-lg-nerd-font", "Installing MesloLGL Nerd Font")
    else
      puts "✅ Nerd Fonts already installed"
    end
  end

  def run_command(command, description = nil)
    puts "🔧 #{description || command}" if @verbose
    return if @dry_run

    system(command) || raise("Command failed: #{command}")
  end

  def copy_personal_dotfiles
    puts "📋 Copying personal dotfiles..."

    # Only copy personal configuration files that don't conflict with Square's setup
    personal_dotfiles = {
      './configs/shell/development_profile' => "#{ENV['HOME']}/.development_profile",
      './configs/vim/vimrc' => "#{ENV['HOME']}/.vimrc",
      './configs/git/.gitconfig' => "#{ENV['HOME']}/.gitconfig",
      './configs/git/.gitignore_global' => "#{ENV['HOME']}/.gitignore_global",
      './configs/ssh/config' => "#{ENV['HOME']}/.ssh/config",
      './configs/.inputrc' => "#{ENV['HOME']}/.inputrc",
      './configs/.ackrc' => "#{ENV['HOME']}/.ackrc"
    }

    personal_dotfiles.each do |source, target|
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

    # Handle zshrc specially - create a personal version that sources Square's config
    create_personal_zshrc
  end

  def create_personal_zshrc
    puts "🐚 Creating personal zshrc that works with Square's config..."

    zshrc_target = "#{ENV['HOME']}/.zshrc"
    zshrc_source = './configs/shell/zshrc'

    # Backup existing zshrc if it exists
    if File.exist?(zshrc_target) && !@dry_run
      puts "💾 Backing up existing .zshrc..."
      FileUtils.mkdir_p(@backup_dir)
      FileUtils.cp(zshrc_target, "#{@backup_dir}/.zshrc")
    end

    unless @dry_run
      # Create the personal zshrc that follows Square's override pattern
      File.open(zshrc_target, 'w') do |f|
        f.puts "#######################################################"
        f.puts "# load Square specific zshrc; please don't change this bit."
        f.puts "#######################################################"
        f.puts "source ~/Development/config_files/square/zshrc"
        f.puts "#######################################################"
        f.puts ""
        f.puts "###########################################"
        f.puts "# Feel free to make your own changes below."
        f.puts "###########################################"
        f.puts ""
        f.puts "# load the aliases in config_files files (optional)"
        f.puts "source ~/Development/config_files/square/aliases"
        f.puts ""
        f.puts "[[ -f \"$HOME/.aliases\" ]] && source \"$HOME/.aliases\""
        f.puts "[[ -f \"$HOME/.localaliases\" ]] && source \"$HOME/.localaliases\""
        f.puts ""
        
        # Add the personal configuration from the source file
        if File.exist?(zshrc_source)
          File.readlines(zshrc_source).each do |line|
            # Skip the header comments and add the personal config
            next if line.start_with?('# =============================================================================')
            next if line.start_with?('# Mike\'s Optimized Zsh Configuration')
            next if line.start_with?('# Performance optimized configuration')
            next if line.start_with?('# Key optimization:')
            next if line.strip.empty?
            
            f.puts line
          end
        end
      end
    end

    puts "📄 Created personal .zshrc that sources Square's config first"
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
            install_cursor_extension(extension)
          end
        end
      end
    end

    # VSCode configuration removed - using Cursor only

    puts "🔄 Please restart your editors to apply configuration changes"
  end


  def install_cursor_extension(extension)
    # Check if extension is already installed
    stdout, stderr, status = Open3.capture3("cursor --list-extensions")
    if status.success? && stdout.include?(extension)
      puts "    ✅ #{extension} already installed"
      return
    end

    # Try to install the extension with error handling
    begin
      stdout, stderr, status = Open3.capture3("cursor --install-extension #{extension}")
      
      if status.success?
        puts "    ✅ Successfully installed #{extension}"
      else
        # Check if it's a Cursor internal error
        if stderr.include?("FATAL ERROR") || stderr.include?("Abort trap") || stderr.include?("already installed")
          puts "    ⚠️  #{extension} installation had issues (Cursor internal error)"
          puts "    💡 You can manually install it later with: cursor --install-extension #{extension}"
        else
          puts "    ❌ Failed to install #{extension}: #{stderr.strip}"
        end
      end
    rescue StandardError => e
      puts "    ⚠️  Error installing #{extension}: #{e.message}"
      puts "    💡 You can manually install it later with: cursor --install-extension #{extension}"
    end
  end
end
