puts  'Welcome Mike!'

# Folders
# One day...
#%w[vim].each do |symlink|
  #puts "copying folder #{symlink}"
  #`rm -rf ~/.#{symlink}`
  #`ln -s #{symlink}  ~/.#{symlink}`
#end

# Files
%w[bash_profile gitconfig vimrc git-prompt.sh].each do |symlink|
  puts "copying file #{symlink}"
  `rm ~/.#{symlink}`
  `cp files/#{symlink}  ~/.#{symlink}`
end


# VIM settings
if `which mvim`.empty?
	puts 'macvim is not installed... this might take a while'
	`brew install macvim`
  `brew linkapps`
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

puts 'reloading bash profile'
`source ~/.bash_profile`

puts 'success!'
