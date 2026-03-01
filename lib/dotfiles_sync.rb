#!/usr/bin/env ruby
# frozen_string_literal: true

require 'fileutils'
require 'optparse'
require 'time'
require 'json'
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

    @actions = { installed: [], configured: [], skipped: [], warnings: [] }
    @current_section = nil
    @section_header_printed = false
  end

  # Standalone entry point for bin/cleanup-sims
  def cleanup_sims
    section("Simulator Cleanup") { cleanup_simulators }
  end

  # Standalone entry point for bin/cleanup-space (all pruning: Homebrew, Xcode, simulators, Docker)
  def cleanup_disk
    section("Disk Cleanup") { cleanup_disk_space }
  end

  def run
    log "Welcome to Mike's Personal Dotfiles Sync!"
    log "Backup directory: #{@backup_dir}" unless @dry_run
    log "Dry run mode: #{@dry_run}" if @dry_run
    log "Mode: #{work_mode? ? 'WORK' : 'PERSONAL'}"

    begin
      section("System Dependencies") { install_system_dependencies }
      section("Dotfiles") { copy_personal_dotfiles }
      section("Neovim") { install_neovim_config }
      section("Fonts & Themes") { install_fonts_and_themes }
      section("iTerm2") { install_iterm2_config }
      section("Ghostty") { install_ghostty_config }
      section("Editor Configs") { install_editor_configs }
      section("AI Skills") { install_ai_skills }
      section("MCP Servers") { install_mcp_servers }
      section("Xcode") { install_xcode_config }
      section("Disk Cleanup") { cleanup_disk_space }

      print_summary
      log "Sync complete."
    rescue StandardError => e
      log "Sync failed: #{e.message}"
      log "Run with --verbose for more details" unless @verbose
      exit 1
    end
  end

  private

  # Always shown (banner, warnings, errors, summary)
  def log(msg)
    puts msg
  end

  # Verbose only (checking, already installed, backups)
  def log_detail(msg)
    return unless @verbose

    ensure_section_header
    puts msg
  end

  # Shown in default mode, triggers section header
  def log_change(msg)
    ensure_section_header
    puts "  + #{msg}"
  end

  # Wraps a phase — only prints header if something inside calls log_change
  def section(name)
    @current_section = name
    @section_header_printed = false
    yield
    @current_section = nil
  end

  # Prints section header on first log_change/log_detail within a section
  def ensure_section_header
    return if @section_header_printed || @current_section.nil?

    @section_header_printed = true
    puts "\n[ #{@current_section} ]"
  end

  def print_summary
    puts "\n=== Summary ==="
    if @actions[:installed].empty? && @actions[:configured].empty? && @actions[:warnings].empty?
      puts "  Everything already up to date."
    else
      puts "  Installed: #{@actions[:installed].join(', ')}" unless @actions[:installed].empty?
      puts "  Configured: #{@actions[:configured].join(', ')}" unless @actions[:configured].empty?
      @actions[:warnings].each { |w| puts "  Warning: #{w}" } unless @actions[:warnings].empty?
    end
    puts
  end

  def work_mode?
    @work_mode ||= Dir.exist?(File.expand_path("~/Development/config_files"))
  end

  def install_system_dependencies
    if work_mode?
      log_detail "  Skipping Homebrew/Zsh install (topsoil handles these on work machines)"
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
    check_and_install_neovim_deps
    install_mise_config
    setup_touch_id_sudo
  end

  def check_and_install_homebrew
    log_detail "  Checking Homebrew..."

    unless system("which brew > /dev/null 2>&1")
      log_change "Installing Homebrew"
      @actions[:installed] << "Homebrew"
      unless @dry_run
        system('/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"')
        ENV['PATH'] = "/opt/homebrew/bin:/usr/local/bin:#{ENV['PATH']}"
      end
    else
      log_detail "  Homebrew already installed"
    end
  end

  def check_and_install_zsh
    log_detail "  Checking zsh..."

    unless system("which zsh > /dev/null 2>&1")
      log_change "Installing zsh"
      @actions[:installed] << "zsh"
      run_command("brew install zsh", "Installing zsh")

      current_shell = ENV['SHELL']
      unless current_shell&.include?('zsh')
        log_change "Setting zsh as default shell"
        unless @dry_run
          zsh_path = `which zsh`.strip
          system("sudo chsh -s #{zsh_path} #{ENV['USER']}")
        end
      end
    else
      log_detail "  zsh already installed"
    end
  end

  def check_and_install_mise
    log_detail "  Checking mise..."

    unless system("which mise > /dev/null 2>&1")
      log_change "Installing mise"
      @actions[:installed] << "mise"
      run_command("brew install mise", "Installing mise")
    else
      log_detail "  mise already installed"
    end
  end

  def install_mise_config
    mise_source = "./configs/mise/config.toml"
    return unless File.exist?(mise_source)

    mise_config_dir = "#{ENV['HOME']}/.config/mise"
    target = "#{mise_config_dir}/config.toml"

    if File.exist?(target) && FileUtils.identical?(mise_source, target)
      log_detail "  mise config already up to date"
      return
    end

    log_change "Updated mise config"
    @actions[:configured] << "mise config"
    unless @dry_run
      FileUtils.mkdir_p(mise_config_dir)
      FileUtils.cp(mise_source, target)
    end
  end

  def setup_touch_id_sudo
    log_detail "  Checking Touch ID for sudo..."

    sudo_local = "/etc/pam.d/sudo_local"
    pam_tid_configured = File.exist?(sudo_local) &&
                         File.read(sudo_local).include?("pam_tid.so")

    if pam_tid_configured
      log_detail "  Touch ID for sudo already configured"
      return
    end

    unless system("brew list pam-reattach > /dev/null 2>&1")
      log_change "Installing pam-reattach"
      @actions[:installed] << "pam-reattach"
      run_command("brew install pam-reattach", "Installing pam-reattach")
    end

    log_change "Configuring Touch ID for sudo"
    @actions[:configured] << "Touch ID sudo"

    unless @dry_run
      sudo_local_content = <<~PAM
        # Touch ID for sudo — managed by dotfiles-sync
        auth       optional       /opt/homebrew/lib/pam/pam_reattach.so
        auth       sufficient     pam_tid.so
      PAM

      IO.popen(["sudo", "tee", sudo_local], "w") do |io|
        io.write(sudo_local_content)
      end
    end
  end

  def check_and_install_oh_my_zsh
    log_detail "  Checking Oh My Zsh..."

    oh_my_zsh_dir = "#{ENV['HOME']}/.oh-my-zsh"
    unless Dir.exist?(oh_my_zsh_dir)
      log_change "Installing Oh My Zsh"
      @actions[:installed] << "Oh My Zsh"
      unless @dry_run
        system('sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended')
      end
    else
      log_detail "  Oh My Zsh already installed"
    end
  end

  def check_and_install_oh_my_posh
    log_detail "  Checking Oh My Posh..."

    unless system("which oh-my-posh > /dev/null 2>&1")
      log_change "Installing Oh My Posh"
      @actions[:installed] << "Oh My Posh"
      run_command("brew install oh-my-posh", "Installing Oh My Posh")
    else
      log_detail "  Oh My Posh already installed"
    end

    setup_oh_my_posh_theme
  end

  def setup_oh_my_posh_theme
    theme_dir = File.expand_path("~/.oh-my-posh/themes")
    theme_file = File.join(theme_dir, "gruvbox.omp.json")
    local_theme = File.join(@dotfiles_dir, "configs/oh-my-posh/themes/gruvbox.omp.json")

    unless File.exist?(local_theme)
      log "  Warning: Local gruvbox theme not found at #{local_theme}"
      @actions[:warnings] << "Oh My Posh theme not found"
      return
    end

    if File.exist?(theme_file) && FileUtils.identical?(local_theme, theme_file)
      log_detail "  Oh My Posh theme already up to date"
      return
    end

    log_change "Updated Oh My Posh theme"
    @actions[:configured] << "Oh My Posh theme"
    unless @dry_run
      FileUtils.mkdir_p(theme_dir) unless Dir.exist?(theme_dir)
      FileUtils.cp(local_theme, theme_file)
    end
  end

  def check_and_install_nerd_fonts
    log_detail "  Checking Nerd Fonts..."

    nerd_font_installed = system("fc-list | grep -i 'meslolg[sl].*nerd' > /dev/null 2>&1") ||
                         Dir.glob("#{ENV['HOME']}/Library/Fonts/MesloLGS*NerdFont*").any? ||
                         Dir.glob("#{ENV['HOME']}/Library/Fonts/MesloLGL*NerdFont*").any?

    if nerd_font_installed
      log_detail "  Nerd Fonts already installed"
    else
      log_detail "  Nerd Fonts will be installed from local font files"
    end
  end

  def check_and_install_docker
    log_detail "  Checking Docker..."

    { "docker" => "Docker CLI", "docker-compose" => "Docker Compose", "colima" => "Colima" }.each do |bin, name|
      if system("which #{bin} > /dev/null 2>&1")
        log_detail "  #{name} already installed"
      else
        log_change "Installing #{name}"
        @actions[:installed] << name
        run_command("brew install #{bin}", "Installing #{name}")
      end
    end
  end

  def check_and_install_jq
    log_detail "  Checking jq..."

    unless system("which jq > /dev/null 2>&1")
      log_change "Installing jq"
      @actions[:installed] << "jq"
      run_command("brew install jq", "Installing jq")
    else
      log_detail "  jq already installed"
    end
  end

  def check_and_install_neovim_deps
    log_detail "  Checking Neovim and dependencies..."

    { "nvim" => "neovim", "fzf" => "fzf", "rg" => "ripgrep", "fd" => "fd" }.each do |bin, formula|
      if system("which #{bin} > /dev/null 2>&1")
        log_detail "  #{formula} already installed"
      else
        log_change "Installing #{formula}"
        @actions[:installed] << formula
        run_command("brew install #{formula}", "Installing #{formula}")
      end
    end
  end

  def check_and_install_ghostty
    log_detail "  Checking Ghostty..."

    unless system("which ghostty > /dev/null 2>&1")
      log_change "Installing Ghostty"
      @actions[:installed] << "Ghostty"
      run_command("brew install --cask ghostty", "Installing Ghostty")
    else
      log_detail "  Ghostty already installed"
    end
  end

  def run_command(command, description = nil)
    puts "  #{description || command}" if @verbose
    return if @dry_run

    system(command) || raise("Command failed: #{command}")
  end

  def copy_personal_dotfiles
    # Files that are always copied regardless of mode
    always_copy = {
      './configs/vim/vimrc' => "#{ENV['HOME']}/.vimrc",
      './configs/git/.gitignore_global' => "#{ENV['HOME']}/.gitignore_global",
      './configs/ssh/config' => "#{ENV['HOME']}/.ssh/config"
    }

    # Files only copied on personal machines (config_files owns these on work machines)
    personal_only = {
      './configs/.inputrc' => "#{ENV['HOME']}/.inputrc",
      './configs/git/.gitconfig_personal' => "#{ENV['HOME']}/.gitconfig"
    }

    dotfiles_to_copy = always_copy
    if work_mode?
      log_detail "  Skipping .inputrc, .gitconfig (config_files owns these on work machines)"
    else
      dotfiles_to_copy = dotfiles_to_copy.merge(personal_only)
    end

    # aliases.zsh is not copied — it's sourced directly from the repo by zshrc

    dotfiles_to_copy.each do |source, target|
      next unless File.exist?(source)

      # Skip unchanged files
      if File.exist?(target) && FileUtils.identical?(source, target)
        log_detail "  #{File.basename(target)} already up to date"
        next
      end

      if File.exist?(target) && !@dry_run
        log_detail "  Backing up #{File.basename(target)}"
        FileUtils.mkdir_p(@backup_dir)
        FileUtils.cp(target, "#{@backup_dir}/#{File.basename(target)}")
      end

      # Ensure SSH directory exists and has proper permissions
      if target.include?('.ssh/') && !@dry_run
        FileUtils.mkdir_p(File.dirname(target))
        FileUtils.chmod(0700, File.dirname(target))
      end

      log_change "Copied #{File.basename(source)}"
      @actions[:configured] << File.basename(target)
      unless @dry_run
        FileUtils.cp(source, target)
        if target.include?('.ssh/')
          FileUtils.chmod(0600, target)
        end
      end
    end

    create_personal_zshrc
  end

  def install_neovim_config
    nvim_source = "#{@dotfiles_dir}/configs/nvim"
    nvim_target = "#{ENV['HOME']}/.config/nvim"

    unless Dir.exist?(nvim_source)
      log "  Warning: Neovim config not found at #{nvim_source}"
      @actions[:warnings] << "Neovim config not found"
      return
    end

    # Check if symlink already points to the right place
    if File.symlink?(nvim_target) && File.readlink(nvim_target) == File.expand_path(nvim_source)
      log_detail "  Neovim config already symlinked"
    else
      log_change "Symlinked Neovim config"
      @actions[:configured] << "Neovim config"
      unless @dry_run
        FileUtils.mkdir_p(File.dirname(nvim_target))
        if File.symlink?(nvim_target)
          File.delete(nvim_target)
        elsif Dir.exist?(nvim_target)
          log_detail "  Backing up existing nvim config"
          FileUtils.mkdir_p(@backup_dir)
          FileUtils.mv(nvim_target, "#{@backup_dir}/nvim")
        end
        FileUtils.ln_sf(File.expand_path(nvim_source), nvim_target)
      end
    end

    # Install and update plugins via lazy.nvim (headless)
    if system("which nvim > /dev/null 2>&1") && !@dry_run
      log_change "Updated Neovim plugins"
      @actions[:configured] << "Neovim plugins"
      system('nvim --headless "+Lazy! update" +qa')
    else
      log_detail "  Neovim not installed or dry run, skipping plugin update"
    end
  end

  def create_personal_zshrc
    variant = work_mode? ? "zshrc_work" : "zshrc_personal"
    zshrc_target = "#{ENV['HOME']}/.zshrc"
    source_path = "#{@dotfiles_dir}/configs/shell/#{variant}"

    expected_content = "# Generated by dotfiles-sync — edit the source file instead:\n# #{source_path}\nsource #{source_path}\n"

    if File.exist?(zshrc_target) && File.read(zshrc_target) == expected_content
      log_detail "  .zshrc already up to date"
      return
    end

    if File.exist?(zshrc_target) && !@dry_run
      log_detail "  Backing up existing .zshrc"
      FileUtils.mkdir_p(@backup_dir)
      FileUtils.cp(zshrc_target, "#{@backup_dir}/.zshrc")
    end

    log_change "Created .zshrc -> #{variant}"
    @actions[:configured] << ".zshrc"
    unless @dry_run
      File.write(zshrc_target, expected_content)
    end
  end

  def install_fonts_and_themes
    fonts_source = "./configs/fonts"
    fonts_dir = "#{ENV['HOME']}/Library/Fonts"

    return unless Dir.exist?(fonts_source)

    unless @dry_run
      FileUtils.mkdir_p(fonts_dir)
    end

    installed_fonts = []

    Dir.glob("#{fonts_source}/*.{ttf,otf,ttc}").each do |font_file|
      font_name = File.basename(font_file)
      target = "#{fonts_dir}/#{font_name}"

      if File.exist?(target) && !@dry_run
        next
      end

      unless @dry_run
        FileUtils.cp(font_file, target)
      end
      installed_fonts << font_name
    end

    if installed_fonts.any?
      log_change "Installed #{installed_fonts.size} font(s)"
      @actions[:configured] << "fonts"
      unless @dry_run
        system("atsutil databases -removeUser > /dev/null 2>&1")
        system("atsutil server -shutdown > /dev/null 2>&1")
        sleep 1
      end
    else
      log_detail "  All fonts already installed"
    end
  end

  def install_xcode_config
    xcode_source = "./configs/xcode"
    return unless Dir.exist?(xcode_source)

    xcode_user_dir = "#{ENV['HOME']}/Library/Developer/Xcode/UserData"

    unless @dry_run
      FileUtils.mkdir_p(xcode_user_dir)
      FileUtils.mkdir_p("#{xcode_user_dir}/FontAndColorThemes")
    end

    themes_source = "#{xcode_source}/FontAndColorThemes"
    return unless Dir.exist?(themes_source)

    installed_themes = []
    Dir.glob("#{themes_source}/*.xccolortheme").each do |theme_file|
      theme_name = File.basename(theme_file)
      target = "#{xcode_user_dir}/FontAndColorThemes/#{theme_name}"

      if File.exist?(target) && !@dry_run
        log_detail "  Xcode theme #{theme_name} already exists"
        next
      end

      log_change "Installing Xcode theme: #{theme_name}"
      installed_themes << theme_name
      unless @dry_run
        FileUtils.cp(theme_file, target)
      end
    end

    @actions[:configured] << "Xcode themes" if installed_themes.any?
  end

  def cleanup_disk_space
    cleanup_homebrew
    cleanup_xcode_derived_data
    cleanup_xcode_archives
    cleanup_simulators
    cleanup_docker
    cleanup_npm_cache
    cleanup_cocoapods_cache
    cleanup_gem
    cleanup_mise
    cleanup_iterm_cache
    cleanup_ghostty_cache
  end

  def cleanup_homebrew
    unless system("which brew > /dev/null 2>&1")
      log_detail "  Skipping Homebrew cleanup (not installed)"
      return
    end

    log_change "Cleaning Homebrew cache and old versions"
    unless @dry_run
      run_command("brew cleanup --prune=all", "Homebrew cleanup")
    end
    @actions[:configured] << "Homebrew cache"
  end

  def cleanup_xcode_derived_data
    derived_data = "#{ENV['HOME']}/Library/Developer/Xcode/DerivedData"
    return unless Dir.exist?(derived_data)

    size = `du -sh "#{derived_data}" 2>/dev/null`.strip.split("\t").first
    log_change "Removing Xcode DerivedData (#{size})"
    unless @dry_run
      FileUtils.rm_rf(derived_data)
    end
    @actions[:configured] << "Xcode DerivedData"
  end

  def cleanup_xcode_archives
    archives = "#{ENV['HOME']}/Library/Developer/Xcode/Archives"
    return unless Dir.exist?(archives)

    size = `du -sh "#{archives}" 2>/dev/null`.strip.split("\t").first
    log_change "Removing Xcode Archives (#{size})"
    unless @dry_run
      FileUtils.rm_rf(archives)
    end
    @actions[:configured] << "Xcode Archives"
  end

  def cleanup_simulators
    unless system("which xcrun > /dev/null 2>&1") && system("which jq > /dev/null 2>&1")
      log_detail "  Skipping simulator cleanup (xcrun or jq not found)"
      return
    end

    latest_runtime = `xcrun simctl list runtimes --json \
      | jq -r '[.runtimes[] | select(.name | startswith("iOS")) | select(.isAvailable == true)] | sort_by(.version) | last | .identifier'`.strip

    if latest_runtime.empty? || latest_runtime == "null"
      log_detail "  No available iOS runtimes found, skipping simulator cleanup"
      return
    end

    keep_iphone = `xcrun simctl list devices --json \
      | jq -r --arg rt "#{latest_runtime}" '.devices[$rt] // [] | map(select(.name | test("iPhone"; "i"))) | first | .udid // empty'`.strip

    keep_ipad = `xcrun simctl list devices --json \
      | jq -r --arg rt "#{latest_runtime}" '.devices[$rt] // [] | map(select(.name | test("iPad"; "i"))) | first | .udid // empty'`.strip

    keep_set = [keep_iphone, keep_ipad].reject(&:empty?).to_set

    all_udids = `xcrun simctl list devices --json \
      | jq -r '.devices | to_entries[] | .value[] | .udid'`.strip.split("\n")

    to_delete = all_udids.reject { |udid| keep_set.include?(udid) }

    if to_delete.empty?
      log_detail "  No extra simulators to clean up"
      return
    end

    log_change "Removing #{to_delete.size} simulator(s) (keeping 1 iPhone + 1 iPad on #{latest_runtime})"
    unless @dry_run
      to_delete.each { |udid| system("xcrun simctl delete #{udid}") }
    end
    @actions[:configured] << "iOS Simulators"
  end

  def cleanup_docker
    unless system("which docker > /dev/null 2>&1")
      log_detail "  Skipping Docker cleanup (docker not found)"
      return
    end

    log_change "Running docker system prune -a -f"
    unless @dry_run
      run_command("docker system prune -a -f", "Docker system prune")
    end
    @actions[:configured] << "Docker"
  end

  def cleanup_npm_cache
    unless system("which npm > /dev/null 2>&1")
      log_detail "  Skipping npm cache cleanup (npm not found)"
      return
    end

    log_change "Cleaning npm cache"
    unless @dry_run
      run_command("npm cache clean --force", "npm cache clean")
    end
    @actions[:configured] << "npm cache"
  end

  def cleanup_cocoapods_cache
    unless system("which pod > /dev/null 2>&1")
      log_detail "  Skipping CocoaPods cache cleanup (pod not found)"
      return
    end

    log_change "Cleaning CocoaPods cache"
    unless @dry_run
      run_command("pod cache clean --all", "CocoaPods cache clean")
    end
    @actions[:configured] << "CocoaPods cache"
  end

  def cleanup_gem
    unless system("which gem > /dev/null 2>&1")
      log_detail "  Skipping gem cleanup (gem not found)"
      return
    end

    log_change "Cleaning old gem versions"
    unless @dry_run
      run_command("gem cleanup", "gem cleanup")
    end
    @actions[:configured] << "Ruby gems"
  end

  def cleanup_mise
    unless system("which mise > /dev/null 2>&1")
      log_detail "  Skipping mise prune (mise not found)"
      return
    end

    log_change "Pruning unused mise runtimes and versions"
    unless @dry_run
      run_command("mise prune -y", "mise prune")
    end
    @actions[:configured] << "mise"
  end

  def cleanup_iterm_cache
    iterm_cache = "#{ENV['HOME']}/Library/Caches/com.googlecode.iterm2"
    return unless Dir.exist?(iterm_cache)

    size = `du -sh "#{iterm_cache}" 2>/dev/null`.strip.split("\t").first
    log_change "Clearing iTerm2 cache (#{size})"
    unless @dry_run
      FileUtils.rm_rf(iterm_cache)
    end
    @actions[:configured] << "iTerm2 cache"
  end

  def cleanup_ghostty_cache
    ghostty_cache = "#{ENV['HOME']}/Library/Caches/com.mitchellh.ghostty"
    ghostty_state = "#{ENV['HOME']}/.local/state/ghostty"
    return unless Dir.exist?(ghostty_cache) || Dir.exist?(ghostty_state)

    to_remove = []
    to_remove << ghostty_cache if Dir.exist?(ghostty_cache)
    to_remove << ghostty_state if Dir.exist?(ghostty_state)

    to_remove.each do |dir|
      size = `du -sh "#{dir}" 2>/dev/null`.strip.split("\t").first
      name = dir.include?("Library/Caches") ? "Ghostty cache" : "Ghostty state (ssh-cache)"
      log_change "Clearing #{name} (#{size})"
      FileUtils.rm_rf(dir) unless @dry_run
    end
    @actions[:configured] << "Ghostty cache" if to_remove.any?
  end

  def install_iterm2_config
    if system("pgrep -q iTerm2")
      log "  Warning: iTerm2 is currently running!"
      log "  Please quit iTerm2 before syncing to avoid preferences being overwritten."
      @actions[:warnings] << "iTerm2 running during sync"
      return unless @force
    end

    iterm2_source = "./configs/iterm2"
    return unless Dir.exist?(iterm2_source)

    plist_source = "#{iterm2_source}/com.googlecode.iterm2.plist"
    plist_target = "#{ENV['HOME']}/Library/Preferences/com.googlecode.iterm2.plist"
    if File.exist?(plist_source)
      if File.exist?(plist_target) && FileUtils.identical?(plist_source, plist_target)
        log_detail "  iTerm2 preferences already up to date"
        return
      end

      log_change "Updated iTerm2 preferences"
      @actions[:configured] << "iTerm2"
      unless @dry_run
        FileUtils.cp(plist_source, plist_target)
        system("defaults", "read", "com.googlecode.iterm2", "> /dev/null 2>&1")
      end
    end
  end

  def install_ghostty_config
    ghostty_source = "./configs/ghostty/config"
    return unless File.exist?(ghostty_source)

    ghostty_config_dir = "#{ENV['HOME']}/.config/ghostty"
    ghostty_target = "#{ghostty_config_dir}/config"

    if File.symlink?(ghostty_target) && File.readlink(ghostty_target) == File.expand_path(ghostty_source)
      log_detail "  Ghostty config already symlinked"
      return
    end

    log_change "Symlinked Ghostty config"
    @actions[:configured] << "Ghostty config"
    unless @dry_run
      FileUtils.mkdir_p(ghostty_config_dir)
      FileUtils.ln_sf(File.expand_path(ghostty_source), ghostty_target)
    end
  end

  def install_editor_configs
    editors_source = "./configs/editors"
    return unless Dir.exist?(editors_source)

    cursor_source = "#{editors_source}/cursor"
    return unless Dir.exist?(cursor_source)

    cursor_user_dir = "#{ENV['HOME']}/Library/Application Support/Cursor/User"

    unless @dry_run
      FileUtils.mkdir_p(cursor_user_dir)
    end

    # Install settings
    settings_file = "#{cursor_source}/settings.json"
    if File.exist?(settings_file)
      target = "#{cursor_user_dir}/settings.json"

      if File.exist?(target) && FileUtils.identical?(settings_file, target)
        log_detail "  Cursor settings already up to date"
      else
        if File.exist?(target) && !@dry_run
          log_detail "  Backing up existing Cursor settings"
          FileUtils.cp(target, "#{target}.backup.#{Time.now.strftime('%Y%m%d_%H%M%S')}")
        end

        log_change "Updated Cursor settings"
        @actions[:configured] << "Cursor settings"
        unless @dry_run
          FileUtils.cp(settings_file, target)
        end
      end
    end

    # Install keybindings
    keybindings_file = "#{cursor_source}/keybindings.json"
    if File.exist?(keybindings_file)
      target = "#{cursor_user_dir}/keybindings.json"

      if File.exist?(target) && FileUtils.identical?(keybindings_file, target)
        log_detail "  Cursor keybindings already up to date"
      else
        if File.exist?(target) && !@dry_run
          log_detail "  Backing up existing Cursor keybindings"
          FileUtils.cp(target, "#{target}.backup.#{Time.now.strftime('%Y%m%d_%H%M%S')}")
        end

        log_change "Updated Cursor keybindings"
        @actions[:configured] << "Cursor keybindings"
        unless @dry_run
          FileUtils.cp(keybindings_file, target)
        end
      end
    end

    # Install extensions
    extensions_file = "#{cursor_source}/extensions.txt"
    if File.exist?(extensions_file)
      unless @dry_run
        extensions = File.readlines(extensions_file).map(&:strip).reject(&:empty?)
        extensions.each do |extension|
          install_cursor_extension(extension)
        end
      end
    end
  end

  def install_ai_skills
    skills_dir = "#{@dotfiles_dir}/configs/ai/skills"
    skill_files = Dir.glob("#{skills_dir}/*.md").sort

    if skill_files.empty?
      log_detail "  No skill files found in #{skills_dir}"
      return
    end

    commands = []
    always_on = []

    skill_files.each do |f|
      if File.read(f).start_with?("---\n")
        commands << f
      else
        always_on << f
      end
    end

    log_detail "  Always-on: #{always_on.map { |f| File.basename(f, '.md') }.join(', ')}" unless always_on.empty?
    log_detail "  Commands:  #{commands.map { |f| File.basename(f, '.md') }.join(', ')}" unless commands.empty?

    unless always_on.empty?
      combined = always_on.map { |f| File.read(f) }.join("\n")
      header = "# AI Skills\n# Auto-generated by dotfiles-sync — edit files in configs/ai/skills/ instead\n\n"

      claude_dir = "#{ENV['HOME']}/.claude"
      claude_target = "#{claude_dir}/CLAUDE.md"
      unless @dry_run
        FileUtils.mkdir_p(claude_dir)
        File.write(claude_target, header + combined)
      end

      cursor_rules_dir = "#{ENV['HOME']}/.cursor/rules"
      cursor_frontmatter = "---\ndescription: Always-on AI skills from dotfiles\nglobs: \nalwaysApply: true\n---\n\n"
      unless @dry_run
        FileUtils.mkdir_p(cursor_rules_dir)
        File.write("#{cursor_rules_dir}/always-on.mdc", cursor_frontmatter + combined)
      end

      log_change "Updated always-on AI skills"
      @actions[:configured] << "AI skills (always-on)"
    end

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

        description = name.tr('-', ' ').capitalize
        if content =~ /\A---\n(.*?\n)---\n/m
          frontmatter = Regexp.last_match(1)
          if frontmatter =~ /^description:\s*(.+)$/
            description = Regexp.last_match(1).strip
          end
        end

        body = content.sub(/\A---\n.*?\n---\n*/m, '')

        prefixed_name = "msilvis:#{name}"
        unless @dry_run
          File.write("#{claude_commands_dir}/#{prefixed_name}.md", body)
        end

        cursor_frontmatter = "---\ndescription: #{description}\nglobs: \nalwaysApply: false\n---\n\n"
        unless @dry_run
          File.write("#{cursor_rules_dir}/#{name}.mdc", cursor_frontmatter + body)
        end
      end

      log_change "Updated #{commands.size} command skill(s)"
      @actions[:configured] << "AI skills (commands)"
    end
  end

  def install_mcp_servers
    config_file = "#{@dotfiles_dir}/configs/ai/mcp-servers.json"
    unless File.exist?(config_file)
      log_detail "  No MCP server config found at #{config_file}"
      return
    end

    config = JSON.parse(File.read(config_file))
    servers = config['mcpServers']

    unless servers.is_a?(Hash) && !servers.empty?
      log_detail "  No MCP servers defined in config"
      return
    end

    resolved = resolve_mcp_placeholders(servers)

    install_mcp_servers_claude(resolved)
    install_mcp_servers_cursor(resolved)

    log_change "Configured #{resolved.size} MCP server(s)"
    @actions[:configured] << "MCP servers"
  end

  def resolve_mcp_placeholders(obj)
    case obj
    when Hash then obj.transform_values { |v| resolve_mcp_placeholders(v) }
    when Array then obj.map { |v| resolve_mcp_placeholders(v) }
    when String then resolve_mcp_string(obj)
    else obj
    end
  end

  def resolve_mcp_string(str)
    str.gsub(/\$\{([^}]+)\}/) do
      var = Regexp.last_match(1)
      if var == 'NPX_PATH'
        npx_path
      elsif var == 'NODE_BIN_DIR'
        node_bin_dir
      elsif ENV.key?(var) && !ENV[var].empty?
        ENV.fetch(var)
      else
        log "  Warning: Environment variable #{var} not set, leaving placeholder"
        @actions[:warnings] << "#{var} not set"
        "${#{var}}"
      end
    end
  end

  def npx_path
    @npx_path ||= begin
      path = `which npx 2>/dev/null`.strip
      if path.empty?
        log "  Warning: npx not found, leaving ${NPX_PATH} placeholder"
        @actions[:warnings] << "npx not found"
        '${NPX_PATH}'
      else
        path
      end
    end
  end

  def node_bin_dir
    @node_bin_dir ||= begin
      path = npx_path
      if path == '${NPX_PATH}'
        '${NODE_BIN_DIR}'
      else
        File.dirname(path)
      end
    end
  end

  def install_mcp_servers_claude(resolved)
    unless system('which claude > /dev/null 2>&1')
      log_detail "  claude CLI not found, skipping Claude Code MCP setup"
      return
    end

    resolved.each do |name, server|
      cmd = claude_mcp_add_args(name, server)
      unless cmd
        log "  Warning: #{name}: unknown server type, skipping"
        @actions[:warnings] << "MCP #{name}: unknown type"
        next
      end

      unless @dry_run
        _stdout, stderr, status = Open3.capture3(*cmd)
        if status.success?
          log_detail "  Claude Code: #{name}"
        else
          log "  Warning: Claude Code: #{name} — #{stderr.strip}"
          @actions[:warnings] << "MCP #{name}: #{stderr.strip}"
        end
      else
        log_detail "  Claude Code: #{name} (dry run)"
      end
    end

    clean_claude_settings_mcp_servers
  end

  def claude_mcp_add_args(name, server)
    args = %w[claude mcp add -s user]

    if server.key?('url')
      args += ['-t', 'http', name, server['url']]
      if server['headers'].is_a?(Hash)
        server['headers'].each do |key, value|
          next if value.to_s.empty?
          args += ['-H', "#{key}: #{value}"]
        end
      end
    elsif server.key?('command')
      args << name
      if server['env'].is_a?(Hash)
        server['env'].each do |key, value|
          args += ['-e', "#{key}=#{value}"]
        end
      end
      args += ['--', server['command']]
      args += server['args'] if server['args'].is_a?(Array)
    else
      return nil
    end

    args
  end

  def clean_claude_settings_mcp_servers
    claude_settings_path = "#{Dir.home}/.claude/settings.json"
    return unless File.exist?(claude_settings_path)

    settings = JSON.parse(File.read(claude_settings_path))
    return unless settings.key?('mcpServers')

    settings.delete('mcpServers')
    unless @dry_run
      File.write(claude_settings_path, "#{JSON.pretty_generate(settings)}\n")
    end
    log_detail "  Removed legacy mcpServers from settings.json"
  end

  def install_mcp_servers_cursor(resolved)
    cursor_mcp_path = "#{Dir.home}/.cursor/mcp.json"
    cursor_dir = File.dirname(cursor_mcp_path)

    output = { 'mcpServers' => resolved }

    unless @dry_run
      FileUtils.mkdir_p(cursor_dir)
      File.write(cursor_mcp_path, "#{JSON.pretty_generate(output)}\n")
    end

    log_detail "  Cursor: #{cursor_mcp_path}"
  end

  def install_cursor_extension(extension)
    stdout, _stderr, status = Open3.capture3("cursor --list-extensions")
    if status.success? && stdout.include?(extension)
      log_detail "    #{extension} already installed"
      return
    end

    begin
      _stdout, stderr, status = Open3.capture3("cursor --install-extension #{extension}")

      if status.success?
        log_change "Installed Cursor extension: #{extension}"
        @actions[:installed] << extension
      elsif stderr.include?("FATAL ERROR") || stderr.include?("Abort trap") || stderr.include?("already installed")
        log "  Warning: #{extension} installation had issues (Cursor internal error)"
        @actions[:warnings] << "Cursor extension #{extension}"
      else
        log "  Warning: Failed to install #{extension}: #{stderr.strip}"
        @actions[:warnings] << "Cursor extension #{extension}"
      end
    rescue StandardError => e
      log "  Warning: Error installing #{extension}: #{e.message}"
      @actions[:warnings] << "Cursor extension #{extension}"
    end
  end
end
