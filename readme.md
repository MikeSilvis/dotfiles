# Mike's Dotfiles

A comprehensive collection of development environment configurations for macOS, optimized for iOS development with Square's toolchain.

## 🚀 Quick Start

### Prerequisites
- macOS (tested on macOS 12+)
- Ruby (for the installer script)
- Git

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/msilvis/dotfiles.git ~/Developer/dotfiles
   cd ~/Developer/dotfiles
   ```

2. **Run the sync tool:**
   ```bash
   ./bin/dotfiles-sync
   ```

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
│   ├── fonts/             # Custom fonts
│   ├── themes/            # Xcode and iTerm2 themes
│   │   └── xcode/         # Xcode color themes
│   ├── iterm2/            # iTerm2 configuration
│   │   ├── *.itermcolors  # Color schemes
│   │   └── profiles/      # Dynamic profiles
│   ├── editors/           # Editor configurations
│   │   ├── cursor/        # Cursor settings & extensions
│   │   └── vscode/        # VSCode settings & extensions
│   └── env.template       # Environment variables template
├── bin/                   # Executable scripts
│   └── dotfiles-sync      # Main sync executable
├── lib/                   # Ruby library code
│   └── dotfiles_sync.rb   # Main sync class
├── docs/                  # Documentation
└── .gitignore            # Git ignore rules
```

## 🛠️ What Gets Installed

### Core Tools
- **Homebrew** - Package manager
- **rbenv** - Ruby version manager (replaces RVM)
- **vim-plug** - Modern Vim plugin manager (replaces Vundle/Pathogen)

### Development Tools
- Go, Node.js, npm
- ack, vim, cmake, watchman
- bash-git-prompt for enhanced Git status

### Vim Plugins
- **File Management**: NERDTree, CtrlP
- **Git Integration**: vim-fugitive, vim-gitgutter
- **Language Support**: TypeScript, Kotlin, Swift, JSON, Ruby on Rails
- **Productivity**: SuperTab, NERDCommenter, ALE (linting)

### iTerm2 Configuration
- **Color Schemes**: Smyck, Tokyo Night, and other popular themes
- **Development Profile**: Optimized for development work
- **Custom Preferences**: Font settings, window behavior, and more

### Editor Configuration
- **Cursor**: Settings, keybindings, and extensions
- **VSCode**: Settings and extensions
- **Automatic Installation**: All extensions installed automatically

### Shell Features
- **Oh My Zsh** with Agnoster theme
- **Antigen** for additional plugins
- **NVM** for Node.js version management
- **Mise** (asdf alternative) for tool version management
- **Vi mode** for command line editing

## ⚙️ Configuration

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
- **Zsh**: Uses `~/.zshrc` with Oh My Zsh and Antigen plugins

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
   # Export installed packages
   brew bundle dump
   npm list -g --depth=0 > npm_global_packages.txt
   
   # Export your current .env (if you have one)
   cp ~/.env ~/env_backup
   ```

2. **Note any custom configurations** in:
   - `~/.aliases`
   - `~/.localaliases`
   - Square-specific configs in `~/Development/config_files/square/`

### After Migration
1. **Run the installer** as described above
2. **Restore your environment variables** from backup
3. **Install additional packages** if needed
4. **Verify Square-specific configurations** are working

## 🐛 Troubleshooting

### Common Issues

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

## 📚 Documentation

- [Fonts Guide](docs/fonts.md) - Font installation and usage
- [iTerm2 Configuration](docs/iterm2-configuration.md) - iTerm2 setup guide
- [Editor Configuration](docs/editor-configuration.md) - Cursor/VSCode setup guide
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