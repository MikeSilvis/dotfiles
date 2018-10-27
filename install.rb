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

puts 'Installing New Homebrew extensions'
%w[ack vim].each do |plugin|
  if `brew ls --versions #{plugin}`.empty?
    puts "#{plugin} not installed..."
    `brew install #{plugin}`
    `brew linkapps`
  end
end

puts 'Configuring Vim'
`rm -rf ~/.vim`
`mkdir ~/.vim`
`mkdir -p ~/.vim/autoload ~/.vim/bundle`

puts 'Installing Pathogen'
`curl -LSso ~/.vim/autoload/pathogen.vim https://tpo.pe/pathogen.vim`

puts 'Copying Colors'
`cp -r ./files/vim/colors ~/.vim/colors`

puts 'Adding plugins'

plugins = [
  ['https://github.com/ctrlpvim/ctrlp.vim.git', 'ctrlp'],
  ['https://github.com/scrooloose/nerdtree.git', 'nerdtree'],
  ['https://github.com/vim-syntastic/syntastic.git', 'syntastic'],
  ['https://github.com/tomtom/tlib_vim.git', 'tlib'],
  ['https://github.com/MarcWeber/vim-addon-mw-utils.git', 'vim-addon-nw-utils'],
  ['https://github.com/garbas/vim-snipmate.git', 'vim-snipmate'],
]


plugins.each do |extension|
  `git clone --depth=1 #{extension[0]} ~/.vim/bundle/#{extension[1]}`
end

puts 'Copying config files'
dotfiles = %w[
  vimrc
  bash_profile
]

dotfiles.each do |file|
  `cp ~/dotfiles/files/#{file} ~/.#{file}`
end

puts 'Success!'
