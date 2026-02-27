-- Detect Podfile and podspec as Ruby
vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
  pattern = { "Podfile", "*.podspec" },
  callback = function()
    vim.bo.filetype = "ruby"
  end,
})
