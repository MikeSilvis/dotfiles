puts  'Welcome Mike!'

# Folders
# One day...
#%w[vim].each do |symlink|
  #puts "copying folder #{symlink}"
  #`rm -rf ~/.#{symlink}`
  #`ln -s #{symlink}  ~/.#{symlink}`
#end

# Files
%w[bash_profile gitconfig vimrc git-prompt.sh xvimrc].each do |symlink|
  puts "copying file #{symlink}"
  `rm ~/.#{symlink}`
  `cp files/#{symlink}  ~/.#{symlink}`
end


if `which brew`.empty?
  puts 'homebrew not installed... this could take a while'
  `ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"`
end

# VIM settings
if `which mvim`.empty?
	puts 'macvim is not installed... this might take a while'
	`brew install macvim`
  `brew linkapps`
end

if `which rvm`.empty?
  puts 'rvm not installed...'
  `curl -sSL https://get.rvm.io | bash -s stable`
end

if !File.exists?(File.expand_path("~/.vim"))
  puts 'janus is not installed...'
  `curl -Lo- https://bit.ly/janus-bootstrap | bash`
  `git clone https://github.com/gmarik/vundle.git ~/.vim/bundle/vundle`
  `vim +BundleInstall +qall`
end

puts 'copying vim setup'
`rm ~/.vimrc`
`cat files/vimrc > ~/.vim/janus/vim/vimrc`
`ln -s ~/.vim/janus/vim/vimrc ~/.vimrc`

puts 'success!'
