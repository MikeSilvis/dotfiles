puts 'Welcome Mike to your new Dotfiles!'

if `which brew`.empty?
  puts 'homebrew not installed... this could take a while'
  `ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"`
end

if `which rvm`.empty?
  puts 'rvm not installed...'
  `curl -sSL https://get.rvm.io | bash -s stable`
  `rvm get head`
end
