-- Detect Podfile and podspec as Ruby
vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
  pattern = { "Podfile", "*.podspec" },
  callback = function()
    vim.bo.filetype = "ruby"
  end,
})

-- Enable word wrap at word boundaries for markdown files
vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function()
    vim.wo.wrap = true
    vim.wo.linebreak = true
  end,
})
