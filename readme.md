# Mike's Personal Dotfiles

A simplified collection of personal development environment configurations for macOS, designed to work seamlessly with Square's development toolchain.

## 🚀 Quick Start

### Prerequisites
- macOS (tested on macOS 12+)
- Square development environment setup (compost mobile)
- Ruby (for the installer script)
- Git

### Installation

1. **First, set up Square's development environment:**
   ```bash
   cd ~/Development/topsoil
   ./compost mobile
   ```

2. **Clone and sync your personal dotfiles:**
   ```bash
   git clone https://github.com/msilvis/dotfiles.git ~/Developer/dotfiles
   cd ~/Developer/dotfiles
   ./bin/dotfiles-sync
   ```
   
   **Note**: After this first run, you can use `sync` from anywhere!
   
   **This sync only handles personal settings** - it doesn't install system dependencies that compost mobile already handles.

3. **Configure environment variables:**
   ```bash
   cp configs/env.template ~/.env
   # Edit ~/.env with your actual values
   ```

4. **Restart your terminal** or run:
   ```bash
   source ~/.zshrc
   ```

## 📁 Repository Structure

```
dotfiles/
├── configs/                 # Configuration files
│   ├── vim/                # Vim configuration
│   │   ├── vimrc          # Main vim configuration
│   │   └── vim/           # Vim plugins and colors
│   ├── shell/             # Shell configurations
│   │   ├── bash_profile   # Bash configuration
│   │   ├── development_profile # Development aliases and functions
│   │   └── zshrc          # Zsh configuration
│   ├── git/               # Git configurations
│   │   ├── gitconfig      # Git global configuration
│   │   └── gitignore_global # Global gitignore rules
│   ├── ssh/               # SSH configurations
│   │   └── config         # SSH client configuration
│   ├── inputrc            # Readline configuration
│   ├── ackrc              # Ack search tool configuration
│   ├── fonts/             # Custom fonts
│   ├── themes/            # Xcode and iTerm2 themes
│   │   └── xcode/         # Xcode color themes
│   ├── iterm2/            # iTerm2 configuration
│   │   ├── *.itermcolors  # Color schemes
│   │   └── profiles/      # Dynamic profiles
│   ├── editors/           # Editor configurations
│   │   └── cursor/        # Cursor settings & extensions
│   └── env.template       # Environment variables template
├── bin/                   # Executable scripts
│   └── dotfiles-sync      # Main sync executable
├── lib/                   # Ruby library code
│   └── dotfiles_sync.rb   # Main sync class
├── docs/                  # Documentation
└── .gitignore            # Git ignore rules
```

## 🛠️ What Gets Installed

### Personal Settings Only
This dotfiles sync focuses on personal configurations and assumes you've already run `compost mobile` for system dependencies.

### Personal Configurations
- **Shell Configuration** - Personal zshrc that sources Square's config first
- **Development Profile** - Personal aliases and functions
- **Vim Configuration** - Personal vimrc with plugins and color scheme
- **Git Configuration** - Personal gitconfig and gitignore_global
- **SSH Configuration** - Personal SSH client configuration
- **Editor Settings** - Cursor personal settings and extensions
- **iTerm2 Configuration** - Personal color schemes and profiles
- **Xcode Configuration** - Personal color themes and preferences
- **Fonts** - Personal font collection

### System Dependencies (Handled by compost mobile)
- **Homebrew** - Package manager
- **Ruby/RVM** - Ruby version management
- **Development Tools** - Git, Java, Android tools, Bazel, etc.
- **Square Environment** - Square-specific tools and configurations

### iTerm2 Configuration
- **Color Schemes**: Smyck, Tokyo Night, and other popular themes
- **Development Profile**: Optimized for development work
- **Custom Preferences**: Font settings, window behavior, and more

### Editor Configuration
- **Cursor**: Settings, keybindings, and extensions
- **Automatic Installation**: All extensions installed automatically

### Additional Configurations
- **Git**: Global gitconfig and gitignore_global
- **SSH**: SSH client configuration with proper permissions
- **Readline**: Inputrc for enhanced command line editing
- **Ack**: Search tool configuration

### Shell Features
- **Oh My Zsh** with plugins (theme disabled in favor of Oh My Posh)
- **Oh My Posh** with Gruvbox theme for beautiful, functional prompts
- **NVM** for Node.js version management
- **Mise** (asdf alternative) for tool version management
- **Vi mode** for command line editing

## ⚙️ Configuration

### Integration with Square's Config

This dotfiles setup follows Square's recommended pattern for personal configurations:

1. **Square's config is loaded first** - The generated `.zshrc` sources Square's configuration
2. **Personal settings are added below** - Your customizations are added after Square's config
3. **Override pattern** - Personal settings can override Square's defaults when needed

The generated `.zshrc` structure:
```bash
#######################################################
# load Square specific zshrc; please don't change this bit.
#######################################################
source ~/Development/config_files/square/zshrc
#######################################################

###########################################
# Feel free to make your own changes below.
###########################################

# Your personal configurations go here...
```

### Environment Variables

Copy `configs/env.template` to `~/.env` and fill in your values:

```bash
# Apple Developer Configuration
export DEVELOPMENT_TEAM_ID='YOUR_TEAM_ID_HERE'
export APPLE_DEVELOPER_EMAIL='your.email@example.com'

# Apple Pay Merchant IDs
export PROD_APPLE_MERCHANT_ID='merchant.com.yourname.squareup.apple-pay'
export SANDBOX_APPLE_MERCHANT_ID='merchant.com.yourname.squareup.apple-pay'
```

### Shell Configuration

The configuration supports both bash and zsh:

- **Bash**: Uses `~/.bash_profile` which sources personal configs
- **Zsh**: Uses `~/.zshrc` with Oh My Zsh plugins and Oh My Posh Gruvbox theme

### Oh My Posh Configuration

The terminal prompt uses the official Oh My Posh Gruvbox theme:

- **Theme**: [Gruvbox](https://github.com/JanDeDobbeleer/oh-my-posh/blob/main/themes/gruvbox.omp.json) (warm, muted colors)
- **Features**: Git integration, directory display, user@host info, exit status
- **Configuration**: Loaded directly from the official Oh My Posh repository

To change themes or customize the prompt, modify the Oh My Posh configuration in `~/.zshrc`:

```bash
# Current configuration
PROMPT='$(oh-my-posh print primary --config https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/gruvbox.omp.json)'

# To use a different theme, replace the URL with another theme:
# PROMPT='$(oh-my-posh print primary --config https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/theme-name.omp.json)'
```

### Vim Configuration

Modern Vim setup with:
- **Vundle and Pathogen** for plugin management
- **Smyck** color scheme
- Language-specific settings for Ruby, JavaScript, TypeScript, Swift
- Git integration and linting support

## 🔧 Sync Options

The sync tool supports several options:

```bash
# Basic sync
./bin/dotfiles-sync

# Dry run (see what would be done)
./bin/dotfiles-sync --dry-run

# Verbose output
./bin/dotfiles-sync --verbose

# Force sync (skip confirmations)
./bin/dotfiles-sync --force

# Custom backup directory
./bin/dotfiles-sync --backup-dir ~/my_backup

# Show help
./bin/dotfiles-sync --help
```

### 🚀 Convenient Sync Function

**First Time Setup**: Run `./bin/dotfiles-sync` once to install the `sync()` function.

After installation, you can use the `sync()` function from anywhere:

```bash
# Run sync from any directory
sync

# Common sync operations with aliases
sync-dry        # Dry run
sync-verbose    # Verbose output
sync-force      # Force sync
sync-help       # Show help

# Pass any arguments to the sync script
sync --dry-run --verbose

# Check dotfiles repository status
dotfiles-status
```

## 🚨 Safety Features

- **Automatic backups** of existing configurations
- **Dry-run mode** to preview changes
- **Error handling** with detailed error messages

## 🏗️ Ruby Gem Structure

This dotfiles repository is structured as a proper Ruby gem:

- **`bin/dotfiles-sync`** - Executable script
- **`lib/dotfiles_sync.rb`** - Main library class
- **`dotfiles_sync.gemspec`** - Gem specification
- **`Gemfile`** - Development dependencies
- **`Rakefile`** - Common tasks (test, lint, install)
- **`spec/`** - RSpec test suite

### Development

```bash
# Install development dependencies
bundle install

# Run tests
bundle exec rspec

# Run linting
bundle exec rubocop

# Run all checks
bundle exec rake check

# Install gem locally
bundle exec rake install
```

## 🏢 Square-Specific Features

This configuration includes several Square development tools and workflows:

- **Square aliases** and functions
- **Bazel** build system integration
- **iOS development** tools and workflows
- **Git workflows** optimized for Square's branching strategy

## 🔄 Migration to New Machine

### Before Migration
1. **Export your current environment:**
   ```bash
   # Export your current .env (if you have one)
   cp ~/.env ~/env_backup
   
   # Note any custom configurations in:
   # - ~/.aliases
   # - ~/.localaliases
   ```

### After Migration
1. **Set up Square's development environment first:**
   ```bash
   cd ~/Development/topsoil
   ./compost mobile
   ```

2. **Clone and sync your personal dotfiles:**
   ```bash
   git clone https://github.com/msilvis/dotfiles.git ~/Developer/dotfiles
   cd ~/Developer/dotfiles
   ./bin/dotfiles-sync
   ```

3. **Restore your environment variables:**
   ```bash
   cp ~/env_backup ~/.env
   ```

4. **Restart your terminal** or run:
   ```bash
   source ~/.zshrc
   ```

## 🐛 Troubleshooting

### Common Issues

**Cursor Extension Installation:**
All Cursor extensions are installed automatically during sync. If any extensions fail to install, you can use the `install-extensions` function in your development profile to retry.

**Vim plugins not loading:**
```bash
# Reinstall vim-plug
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

# Install plugins
vim +PlugInstall +qall
```

**Shell not recognizing new commands:**
```bash
# Reload shell configuration
source ~/.zshrc  # or ~/.bash_profile
```

**Git prompt not showing:**
```bash
# Install bash-git-prompt
brew install bash-git-prompt
```

### Getting Help

1. **Check the logs** - run with `--verbose` for detailed output
2. **Verify file paths** - ensure all referenced files exist
3. **Check permissions** - ensure you have write access to home directory
4. **Review backups** - check the backup directory for original files

## 🔄 Updates

To update your dotfiles:

```bash
cd ~/Developer/dotfiles
git pull origin main
ruby scripts/install.rb
```

## 📝 Customization

### Adding New Aliases
Add them to `configs/shell/ms_bash_profile`:

```bash
# Your custom aliases
alias myalias='mycommand'
```

### Adding New Vim Plugins
Edit `configs/vim/vimrc` and add plugins in the `call plug#begin()` section:

```vim
Plug 'author/plugin-name'
```

Then run `:PlugInstall` in Vim.

### Adding New Environment Variables
Add them to `configs/env.template` and your local `~/.env` file.

## 🔧 Additional Setup (Optional)

For a complete development environment, you may also want to:

- **Install Vim plugins**: Run `:PluginInstall` in Vim after first sync
- **Set up SSH keys**: Add your SSH keys to `~/.ssh/` (not synced for security)
- **Configure Git user**: Set your name and email in git config
- **Install additional tools**: Consider tools like `tmux`, `fzf`, `ripgrep`, etc.
- **Set up language-specific tools**: Node.js versions, Python environments, etc.

## 📚 Documentation

- [Fonts Guide](docs/fonts.md) - Font installation and usage
- [iTerm2 Configuration](docs/iterm2-configuration.md) - iTerm2 setup guide
- [Editor Configuration](docs/editor-configuration.md) - Cursor setup guide
- [Migration Guide](docs/migration-guide.md) - New PC setup instructions
- [Zshrc Analysis](docs/zshrc-analysis.md) - Zsh configuration details

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test the installation script
5. Submit a pull request

## 📞 Support

For issues specific to this dotfiles configuration, please open an issue on GitHub.

For Square-specific development questions, consult your team's documentation or Slack channels.