# Migration Guide: Moving to a New PC

This guide will help you migrate your development environment to a new Mac, ensuring you don't lose any important configurations or tools.

## 📋 Pre-Migration Checklist

### 1. Export Current Environment

Before migrating, gather information about your current setup:

```bash
# Export Homebrew packages
brew bundle dump --file=~/brew_packages.txt

# Export npm global packages
npm list -g --depth=0 > ~/npm_global_packages.txt

# Export pip packages (if you use Python)
pip freeze > ~/pip_packages.txt

# Export Ruby gems (if you use RVM/rbenv)
gem list > ~/ruby_gems.txt

# Export your current environment variables
env > ~/current_env.txt
```

### 2. Backup Important Files

```bash
# Create backup directory
mkdir -p ~/migration_backup

# Backup your current dotfiles
cp -r ~/Developer/dotfiles ~/migration_backup/dotfiles_backup

# Backup environment files
cp ~/.env ~/migration_backup/ 2>/dev/null || true
cp ~/.aliases ~/migration_backup/ 2>/dev/null || true
cp ~/.localaliases ~/migration_backup/ 2>/dev/null || true

# Backup Square-specific configs
cp -r ~/Development/config_files ~/migration_backup/ 2>/dev/null || true

# Backup Xcode settings
cp -r ~/Library/Developer/Xcode/UserData ~/migration_backup/ 2>/dev/null || true

# Backup SSH keys
cp -r ~/.ssh ~/migration_backup/ 2>/dev/null || true

# Backup GPG keys
cp -r ~/.gnupg ~/migration_backup/ 2>/dev/null || true
```

### 3. Document Custom Configurations

Make note of any custom configurations you've made:

- Custom aliases in `~/.aliases` or `~/.localaliases`
- Custom environment variables in `~/.env`
- Square-specific configurations
- Any manual tool installations
- Custom Xcode settings or themes

## 🚀 New PC Setup

### 1. Initial System Setup

1. **Update macOS** to the latest version
2. **Install Xcode Command Line Tools**:
   ```bash
   xcode-select --install
   ```
3. **Set up your Apple ID** and iCloud
4. **Configure basic system preferences**

### 2. Install Dotfiles

1. **Clone the repository**:
   ```bash
   git clone https://github.com/msilvis/dotfiles.git ~/Developer/dotfiles
   cd ~/Developer/dotfiles
   ```

2. **Run the sync tool**:
   ```bash
   ./bin/dotfiles-sync
   ```

3. **Configure environment variables**:
   ```bash
   cp configs/env.template ~/.env
   # Edit ~/.env with your actual values
   ```

### 3. Restore Custom Configurations

1. **Restore environment variables**:
   ```bash
   # Copy your custom .env file
   cp ~/migration_backup/.env ~/.env
   ```

2. **Restore custom aliases**:
   ```bash
   # Copy custom alias files
   cp ~/migration_backup/.aliases ~/.aliases 2>/dev/null || true
   cp ~/migration_backup/.localaliases ~/.localaliases 2>/dev/null || true
   ```

3. **Restore Square configurations**:
   ```bash
   # Copy Square-specific configs
   cp -r ~/migration_backup/config_files ~/Development/ 2>/dev/null || true
   ```

4. **Restore SSH keys**:
   ```bash
   # Copy SSH keys
   cp -r ~/migration_backup/.ssh ~/.ssh 2>/dev/null || true
   chmod 700 ~/.ssh
   chmod 600 ~/.ssh/id_*
   ```

5. **Restore GPG keys**:
   ```bash
   # Copy GPG keys
   cp -r ~/migration_backup/.gnupg ~/.gnupg 2>/dev/null || true
   chmod 700 ~/.gnupg
   ```

### 4. Install Additional Tools

1. **Install Homebrew packages**:
   ```bash
   # If you have a Brewfile
   brew bundle install --file=~/migration_backup/brew_packages.txt
   ```

2. **Install Node.js packages**:
   ```bash
   # Install global npm packages
   cat ~/migration_backup/npm_global_packages.txt | grep -v '^├\|^└' | awk '{print $2}' | xargs npm install -g
   ```

3. **Install Python packages**:
   ```bash
   # Install pip packages
   pip install -r ~/migration_backup/pip_packages.txt
   ```

4. **Install Ruby gems**:
   ```bash
   # Install Ruby gems
   cat ~/migration_backup/ruby_gems.txt | awk '{print $1}' | xargs gem install
   ```

### 5. Configure Development Tools

1. **Set up Git**:
   ```bash
   git config --global user.name "Your Name"
   git config --global user.email "your.email@example.com"
   ```

2. **Configure SSH for Git**:
   ```bash
   # Test SSH connection
   ssh -T git@github.com
   ```

3. **Set up GPG signing** (if you use it):
   ```bash
   # Import GPG keys
   gpg --import ~/.gnupg/private-keys-v1.d/*
   
   # Configure Git to use GPG
   git config --global user.signingkey YOUR_GPG_KEY_ID
   git config --global commit.gpgsign true
   ```

### 6. Install Additional Fonts and Themes

1. **Install fonts and themes**:
   ```bash
   ruby scripts/install_fonts_and_themes.rb
   ```

2. **Configure terminal fonts**:
   - Open Terminal preferences
   - Set font to "Meslo LG L Regular for Powerline" or "Source Code Pro"
   - Set size to 14-16pt

3. **Configure Xcode theme**:
   - Open Xcode
   - Go to Preferences > Fonts & Colors
   - Select "Silly" theme (or your preferred theme)

## 🔍 Verification Steps

### 1. Test Shell Configuration

```bash
# Restart terminal or source configs
source ~/.zshrc

# Test that aliases work
gs  # Should show git status
gcm "test"  # Should commit with message

# Test that functions work
monday  # Should run your Monday workflow
```

### 2. Test Development Tools

```bash
# Test Homebrew
brew doctor

# Test Ruby
ruby --version
rbenv versions

# Test Node.js
node --version
npm --version

# Test Git
git --version
git config --list
```

### 3. Test Square-Specific Tools

```bash
# Test Square tools (if applicable)
sq --version
bazel --version

# Test that Square configs are loaded
echo $USE_SQUINTER_PRECOMMIT
```

### 4. Test Vim Configuration

```bash
# Open vim and test plugins
vim +PlugStatus +qall

# Test that color scheme loads
vim +colorscheme +qall
```

## 🚨 Troubleshooting

### Common Issues

**Shell not recognizing commands:**
```bash
# Reload shell configuration
source ~/.zshrc
```

**Fonts not appearing:**
```bash
# Clear font cache
sudo atsutil databases -remove
# Restart applications
```

**SSH keys not working:**
```bash
# Check permissions
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_*

# Test connection
ssh -T git@github.com
```

**Environment variables not loading:**
```bash
# Check .env file exists and is readable
ls -la ~/.env
cat ~/.env
```

### Getting Help

1. **Check the logs** - run installer with `--verbose`
2. **Verify file paths** - ensure all referenced files exist
3. **Check permissions** - ensure you have proper file permissions
4. **Review backups** - check your migration backup directory

## 📝 Post-Migration Tasks

### 1. Update Documentation

- Update any hardcoded paths in your configurations
- Update your team about your new machine
- Update any CI/CD configurations if needed

### 2. Test Workflows

- Test your daily development workflows
- Test Square-specific build processes
- Test deployment processes

### 3. Clean Up

- Remove migration backup files after confirming everything works
- Update your dotfiles repository with any new customizations
- Commit and push any changes to your dotfiles

## 🔄 Future Migrations

To make future migrations easier:

1. **Keep your dotfiles updated** with any new customizations
2. **Document any manual installations** in your dotfiles
3. **Use the installer's dry-run mode** to test changes
4. **Regularly backup your custom configurations**

## 📞 Support

If you encounter issues during migration:

1. Check this guide's troubleshooting section
2. Review the main README.md
3. Check your migration backup for reference
4. Open an issue in the dotfiles repository if needed
