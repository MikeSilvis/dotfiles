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
    @dotfiles_dir = options[:dotfiles_dir] || Dir.pwd
  end

  def cleanup_sims
    puts "🧹 Cleaning up iOS simulators..."
    puts "   Keeping one iPhone + one iPad on the latest iOS runtime."
    puts

    latest_runtime = `xcrun simctl list runtimes --json \
      | jq -r '[.runtimes[] | select(.name | startswith("iOS")) | select(.isAvailable == true)] | sort_by(.version) | last | .identifier'`.strip

    if latest_runtime.empty? || latest_runtime == "null"
      puts "❌ No available iOS runtimes found."
      exit 1
    end

    puts "📱 Latest iOS runtime: #{latest_runtime}"

    keep_iphone = `xcrun simctl list devices --json \
      | jq -r --arg rt "#{latest_runtime}" '.devices[$rt] // [] | map(select(.name | test("iPhone"; "i"))) | first | .udid // empty'`.strip

    keep_ipad = `xcrun simctl list devices --json \
      | jq -r --arg rt "#{latest_runtime}" '.devices[$rt] // [] | map(select(.name | test("iPad"; "i"))) | first | .udid // empty'`.strip

    puts "⚠️  No iPhone simulator found for #{latest_runtime}" if keep_iphone.empty?
    puts "⚠️  No iPad simulator found for #{latest_runtime}" if keep_ipad.empty?
    puts "✅ Keeping iPhone: #{keep_iphone.empty? ? "(none)" : keep_iphone}"
    puts "✅ Keeping iPad:   #{keep_ipad.empty? ? "(none)" : keep_ipad}"
    puts

    keep_set = [keep_iphone, keep_ipad].reject(&:empty?).to_set

    all_udids = `xcrun simctl list devices --json \
      | jq -r '.devices | to_entries[] | .value[] | .udid'`.strip.split("\n")

    deleted = 0
    all_udids.each do |udid|
      next if keep_set.include?(udid)

      puts "🗑️  Deleting #{udid}..."
      system("xcrun simctl delete #{udid}") unless @dry_run
      deleted += 1
    end

    puts
    puts "✅ Done. Deleted #{@dry_run ? "(dry-run) " : ""}#{deleted} simulator(s)."
  end

  def run
    puts "🚀 Welcome to Mike's Personal Dotfiles Sync!"
    puts "📁 Backup directory: #{@backup_dir}" unless @dry_run
    puts "🔍 Dry run mode: #{@dry_run}" if @dry_run
    puts "🖥️  Mode: #{work_mode? ? 'WORK (config_files detected)' : 'PERSONAL'}"
    puts "💡 This sync will install system dependencies and personal settings."
    puts

    begin
      install_system_dependencies
      copy_personal_dotfiles
      install_vim_config
      install_fonts_and_themes
      install_iterm2_config
      install_ghostty_config
      install_editor_configs
      install_ai_skills
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

  def work_mode?
    @work_mode ||= Dir.exist?(File.expand_path("~/Development/config_files"))
  end

  def install_system_dependencies
    puts "🔧 Checking and installing system dependencies..."

    if work_mode?
      puts "⏭️  Skipping Homebrew/Zsh install (topsoil handles these on work machines)"
    else
      check_and_install_homebrew
      check_and_install_zsh
      check_and_install_mise
    end

    check_and_install_oh_my_zsh
    check_and_install_oh_my_posh
    check_and_install_nerd_fonts
    check_and_install_docker
    check_and_install_ghostty
    check_and_install_jq
    install_mise_config
    setup_touch_id_sudo
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

  def check_and_install_mise
    puts "🔧 Checking mise installation..."

    unless system("which mise > /dev/null 2>&1")
      puts "📦 Installing mise via Homebrew..."
      run_command("brew install mise", "Installing mise")
    else
      puts "✅ mise already installed"
    end
  end

  def install_mise_config
    puts "🔧 Installing mise configuration..."

    mise_source = "./configs/mise/config.toml"
    return unless File.exist?(mise_source)

    mise_config_dir = "#{ENV['HOME']}/.config/mise"
    target = "#{mise_config_dir}/config.toml"

    unless @dry_run
      FileUtils.mkdir_p(mise_config_dir)
      FileUtils.cp(mise_source, target)
    end

    puts "✅ mise config installed (auto-trust enabled)"
  end

  def setup_touch_id_sudo
    puts "🔐 Checking Touch ID for sudo..."

    sudo_local = "/etc/pam.d/sudo_local"
    pam_tid_configured = File.exist?(sudo_local) &&
                         File.read(sudo_local).include?("pam_tid.so")

    if pam_tid_configured
      puts "✅ Touch ID for sudo already configured"
      return
    end

    # Ensure pam-reattach is installed (allows Touch ID in tmux/screen)
    unless system("brew list pam-reattach > /dev/null 2>&1")
      puts "📦 Installing pam-reattach (Touch ID support in tmux)..."
      run_command("brew install pam-reattach", "Installing pam-reattach")
    end

    puts "🔐 Configuring Touch ID for sudo via /etc/pam.d/sudo_local..."
    puts "   (This file survives macOS updates, unlike /etc/pam.d/sudo)"

    unless @dry_run
      sudo_local_content = <<~PAM
        # Touch ID for sudo — managed by dotfiles-sync
        auth       optional       /opt/homebrew/lib/pam/pam_reattach.so
        auth       sufficient     pam_tid.so
      PAM

      # Writing to /etc/pam.d requires sudo
      IO.popen(["sudo", "tee", sudo_local], "w") do |io|
        io.write(sudo_local_content)
      end
    end

    puts "✅ Touch ID for sudo configured"
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
    
    # Setup local theme configuration
    setup_oh_my_posh_theme
  end
  
  def setup_oh_my_posh_theme
    puts "🎨 Setting up Oh My Posh theme configuration..."

    theme_dir = File.expand_path("~/.oh-my-posh/themes")
    theme_file = File.join(theme_dir, "gruvbox.omp.json")
    local_theme = File.join(@dotfiles_dir, "configs/oh-my-posh/themes/gruvbox.omp.json")

    unless File.exist?(local_theme)
      puts "⚠️  Local gruvbox theme not found at #{local_theme}"
      return
    end

    # Create theme directory if it doesn't exist
    unless @dry_run
      FileUtils.mkdir_p(theme_dir) unless Dir.exist?(theme_dir)
    end

    # Always copy theme file to ensure it's up to date
    puts "📋 Installing Gruvbox theme locally..."
    unless @dry_run
      FileUtils.cp(local_theme, theme_file)
    end
    puts "✅ Local theme configuration ready"
  end

  def check_and_install_nerd_fonts
    puts "🎨 Checking Nerd Fonts installation..."
    
    # Check if MesloLGS Nerd Font is installed (preferred) or MesloLGL as fallback
    nerd_font_installed = system("fc-list | grep -i 'meslolg[sl].*nerd' > /dev/null 2>&1") ||
                         Dir.glob("#{ENV['HOME']}/Library/Fonts/MesloLGS*NerdFont*").any? ||
                         Dir.glob("#{ENV['HOME']}/Library/Fonts/MesloLGL*NerdFont*").any?
    
    if nerd_font_installed
      puts "✅ Nerd Fonts already installed"
    else
      puts "📝 Nerd Fonts will be installed from local font files during sync"
    end
  end

  def check_and_install_docker
    puts "🐳 Checking Docker installation..."

    unless system("which docker > /dev/null 2>&1")
      puts "📦 Installing Docker CLI via Homebrew..."
      run_command("brew install docker", "Installing Docker CLI")
    else
      puts "✅ Docker CLI already installed"
    end

    unless system("which docker-compose > /dev/null 2>&1")
      puts "📦 Installing Docker Compose via Homebrew..."
      run_command("brew install docker-compose", "Installing Docker Compose")
    else
      puts "✅ Docker Compose already installed"
    end

    unless system("which colima > /dev/null 2>&1")
      puts "📦 Installing Colima (lightweight Docker runtime)..."
      run_command("brew install colima", "Installing Colima")
    else
      puts "✅ Colima already installed"
    end
  end

  def check_and_install_jq
    puts "🔍 Checking jq installation..."

    unless system("which jq > /dev/null 2>&1")
      puts "📦 Installing jq via Homebrew..."
      run_command("brew install jq", "Installing jq")
    else
      puts "✅ jq already installed"
    end
  end

  def check_and_install_ghostty
    puts "👻 Checking Ghostty installation..."

    unless system("which ghostty > /dev/null 2>&1")
      puts "📦 Installing Ghostty via Homebrew..."
      run_command("brew install --cask ghostty", "Installing Ghostty")
    else
      puts "✅ Ghostty already installed"
    end
  end

  def run_command(command, description = nil)
    puts "🔧 #{description || command}" if @verbose
    return if @dry_run

    system(command) || raise("Command failed: #{command}")
  end

  def copy_personal_dotfiles
    puts "📋 Copying personal dotfiles..."

    # Files that are always copied regardless of mode
    always_copy = {
      './configs/vim/vimrc' => "#{ENV['HOME']}/.vimrc",
      './configs/git/.gitignore_global' => "#{ENV['HOME']}/.gitignore_global",
      './configs/ssh/config' => "#{ENV['HOME']}/.ssh/config"
    }

    # Files only copied on personal machines (config_files owns these on work machines)
    personal_only = {
      './configs/.ackrc' => "#{ENV['HOME']}/.ackrc",
      './configs/.inputrc' => "#{ENV['HOME']}/.inputrc",
      './configs/git/.gitconfig_personal' => "#{ENV['HOME']}/.gitconfig"
    }

    dotfiles_to_copy = always_copy
    if work_mode?
      puts "⏭️  Skipping .ackrc, .inputrc, .gitconfig (config_files owns these on work machines)"
    else
      dotfiles_to_copy = dotfiles_to_copy.merge(personal_only)
    end

    # aliases.zsh is not copied — it's sourced directly from the repo by zshrc

    dotfiles_to_copy.each do |source, target|
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

    # Generate a stub zshrc that sources the right variant from the repo
    create_personal_zshrc
  end

  def install_vim_config
    puts "📝 Installing Vim configuration (colors, etc.)..."

    vim_source = "#{@dotfiles_dir}/configs/vim/vim"
    vim_target_dir = "#{ENV['HOME']}/.vim"
    vundle_path = "#{vim_target_dir}/bundle/Vundle.vim"

    if Dir.exist?(vim_source)
      unless @dry_run
        FileUtils.mkdir_p(vim_target_dir)
      end

      Dir.glob("#{vim_source}/**/*").each do |path|
        next if File.directory?(path)

        relative = path.sub(%r{\A#{Regexp.escape(vim_source)}/}, "")
        target = "#{vim_target_dir}/#{relative}"

        if File.exist?(target) && !@dry_run
          puts "  ⏭️  #{relative} already exists, skipping..."
          next
        end

        puts "  📄 #{relative}"
        unless @dry_run
          FileUtils.mkdir_p(File.dirname(target))
          FileUtils.cp(path, target)
        end
      end
    end

    # Install Vundle if not present
    unless Dir.exist?(vundle_path)
      puts "  📦 Installing Vundle..."
      unless @dry_run
        FileUtils.mkdir_p(File.dirname(vundle_path))
        run_command("git clone https://github.com/VundleVim/Vundle.vim.git #{vundle_path}", "Clone Vundle")
      end
    else
      puts "  ✅ Vundle already installed"
    end

    # Install plugins via Vundle (only if vim is available and we have Vundle)
    if Dir.exist?(vundle_path) && system("which vim > /dev/null 2>&1") && !@dry_run
      puts "  🔌 Installing Vim plugins (PluginInstall)..."
      system("vim -c PluginInstall -c qa")
      puts "✅ Vim config and plugins installed."
    else
      puts "✅ Vim config installed."
    end
  end

  def create_personal_zshrc
    variant = work_mode? ? "zshrc_work" : "zshrc_personal"
    puts "🐚 Creating ~/.zshrc stub (sources #{variant} from repo)..."

    zshrc_target = "#{ENV['HOME']}/.zshrc"

    # Backup existing zshrc if it exists
    if File.exist?(zshrc_target) && !@dry_run
      puts "💾 Backing up existing .zshrc..."
      FileUtils.mkdir_p(@backup_dir)
      FileUtils.cp(zshrc_target, "#{@backup_dir}/.zshrc")
    end

    unless @dry_run
      source_path = "#{@dotfiles_dir}/configs/shell/#{variant}"
      File.open(zshrc_target, 'w') do |f|
        f.puts "# Generated by dotfiles-sync — edit the source file instead:"
        f.puts "# #{source_path}"
        f.puts "source #{source_path}"
      end
    end

    puts "📄 Created ~/.zshrc -> #{variant}"
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

      puts "🔄 Refreshing font cache..."
      unless @dry_run
        system("atsutil databases -removeUser > /dev/null 2>&1")
        system("atsutil server -shutdown > /dev/null 2>&1")
        sleep 1
      end
    end
  end

  def install_xcode_config
    puts "🔨 Installing Xcode configuration..."
    
    xcode_source = "./configs/xcode"
    return unless Dir.exist?(xcode_source)

    xcode_user_dir = "#{ENV['HOME']}/Library/Developer/Xcode/UserData"

    unless @dry_run
      FileUtils.mkdir_p(xcode_user_dir)
      FileUtils.mkdir_p("#{xcode_user_dir}/FontAndColorThemes")
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

    puts "✅ Xcode themes installed. Select theme in Xcode > Settings > Themes"
  end

  def install_iterm2_config
    puts "🖥️  Installing iTerm2 configuration..."

    if system("pgrep -q iTerm2")
      puts "⚠️  iTerm2 is currently running!"
      puts "   Please quit iTerm2 before syncing to avoid preferences being overwritten."
      puts "   After sync completes, reopen iTerm2 to load the new configuration."
      return unless @force
    end

    iterm2_source = "./configs/iterm2"
    return unless Dir.exist?(iterm2_source)

    # Install full iTerm2 preferences plist
    plist_source = "#{iterm2_source}/com.googlecode.iterm2.plist"
    plist_target = "#{ENV['HOME']}/Library/Preferences/com.googlecode.iterm2.plist"
    if File.exist?(plist_source)
      puts "📋 Installing iTerm2 preferences plist..."
      unless @dry_run
        FileUtils.cp(plist_source, plist_target)
        system("defaults", "read", "com.googlecode.iterm2", "> /dev/null 2>&1")
      end
    end

    puts "🔄 Please restart iTerm2 to apply configuration changes"
  end

  def install_ghostty_config
    puts "👻 Installing Ghostty configuration..."

    ghostty_source = "./configs/ghostty/config"
    return unless File.exist?(ghostty_source)

    ghostty_config_dir = "#{ENV['HOME']}/.config/ghostty"
    ghostty_target = "#{ghostty_config_dir}/config"

    unless @dry_run
      FileUtils.mkdir_p(ghostty_config_dir)
      FileUtils.ln_sf(File.expand_path(ghostty_source), ghostty_target)
    end

    puts "✅ Ghostty config symlinked: #{ghostty_target}"
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

    puts "🔄 Please restart your editors to apply configuration changes"
  end


  def install_ai_skills
    puts "🤖 Installing AI skills..."

    skills_dir = "#{@dotfiles_dir}/configs/ai/skills"
    skill_files = Dir.glob("#{skills_dir}/*.md").sort

    if skill_files.empty?
      puts "⏭️  No skill files found in #{skills_dir}"
      return
    end

    # Split skills by type:
    #   - Files with YAML frontmatter (---) → slash commands / on-demand rules
    #   - Plain markdown (no frontmatter)   → always-on context
    commands = []
    always_on = []

    skill_files.each do |f|
      if File.read(f).start_with?("---\n")
        commands << f
      else
        always_on << f
      end
    end

    puts "  📄 Always-on: #{always_on.map { |f| File.basename(f, '.md') }.join(', ')}" unless always_on.empty?
    puts "  📄 Commands:  #{commands.map { |f| File.basename(f, '.md') }.join(', ')}" unless commands.empty?

    # ── Always-on skills → CLAUDE.md + alwaysApply Cursor rule ──

    unless always_on.empty?
      combined = always_on.map { |f| File.read(f) }.join("\n")
      header = "# AI Skills\n# Auto-generated by dotfiles-sync — edit files in configs/ai/skills/ instead\n\n"

      # Claude Code: ~/.claude/CLAUDE.md
      claude_dir = "#{ENV['HOME']}/.claude"
      claude_target = "#{claude_dir}/CLAUDE.md"
      unless @dry_run
        FileUtils.mkdir_p(claude_dir)
        File.write(claude_target, header + combined)
      end
      puts "  ✅ Claude Code: #{claude_target} (always-on)"

      # Cursor: ~/.cursor/rules/always-on.mdc
      cursor_rules_dir = "#{ENV['HOME']}/.cursor/rules"
      cursor_frontmatter = "---\ndescription: Always-on AI skills from dotfiles\nglobs: \nalwaysApply: true\n---\n\n"
      unless @dry_run
        FileUtils.mkdir_p(cursor_rules_dir)
        File.write("#{cursor_rules_dir}/always-on.mdc", cursor_frontmatter + combined)
      end
      puts "  ✅ Cursor: always-on.mdc (alwaysApply)"
    end

    # ── Command skills → slash commands + on-demand Cursor rules ──

    unless commands.empty?
      claude_commands_dir = "#{ENV['HOME']}/.claude/commands"
      cursor_rules_dir = "#{ENV['HOME']}/.cursor/rules"
      unless @dry_run
        FileUtils.mkdir_p(claude_commands_dir)
        FileUtils.mkdir_p(cursor_rules_dir)
      end

      commands.each do |skill_file|
        name = File.basename(skill_file, '.md')
        content = File.read(skill_file)

        # Extract description from frontmatter
        description = name.tr('-', ' ').capitalize
        if content =~ /\A---\n(.*?\n)---\n/m
          frontmatter = Regexp.last_match(1)
          if frontmatter =~ /^description:\s*(.+)$/
            description = Regexp.last_match(1).strip
          end
        end

        # Strip YAML frontmatter for the body
        body = content.sub(/\A---\n.*?\n---\n*/m, '')

        # Claude Code: ~/.claude/commands/msilvis:name.md → /msilvis:name
        prefixed_name = "msilvis:#{name}"
        unless @dry_run
          File.write("#{claude_commands_dir}/#{prefixed_name}.md", body)
        end
        puts "  ✅ Claude Code: /#{prefixed_name}"

        # Cursor: ~/.cursor/rules/<name>.mdc (on-demand)
        cursor_frontmatter = "---\ndescription: #{description}\nglobs: \nalwaysApply: false\n---\n\n"
        unless @dry_run
          File.write("#{cursor_rules_dir}/#{name}.mdc", cursor_frontmatter + body)
        end
        puts "  ✅ Cursor: #{name}.mdc (on-demand)"
      end
    end
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
