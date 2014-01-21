puts  'welcome Mike!'

# Folders
# One day...
#%w[vim].each do |symlink|
  #puts "symlinking folder #{symlink}"
  #`rm -rf ~/.#{symlink}`
  #`ln -s #{symlink}  ~/.#{symlink}`
#end

# Files
%w[vimrc bash_profile gitconfig vimrc git-prompt.sh].each do |symlink|
  puts "symlinking file #{symlink}"
  `rm ~/.#{symlink}`
  `cp files/#{symlink}  ~/.#{symlink}`
end

puts 'success!'
