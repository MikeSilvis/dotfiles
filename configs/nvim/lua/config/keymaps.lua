local map = vim.keymap.set

-- Clear search highlighting
map("n", "<Leader><Space>", ":noh<CR>", { desc = "Clear search highlight" })

-- Git blame (updated from legacy :Gblame)
map("n", "<leader>gb", ":Git blame<CR>", { desc = "Git blame" })


-- Telescope
map("n", "<C-p>", function()
  require("telescope.builtin").find_files()
end, { desc = "Find files" })

map("n", "<leader>rg", function()
  require("telescope.builtin").live_grep()
end, { desc = "Live grep" })

map("n", "<C-S-f>", function()
  require("telescope.builtin").live_grep()
end, { desc = "Live grep" })

map("n", "<leader>f", function()
  require("telescope.builtin").live_grep()
end, { desc = "Live grep" })

map("n", "<leader>b", "<cmd>Neotree toggle<cr>", { desc = "Toggle File Explorer" })

-- Terminal (horizontal split below)
map("n", "<leader>t", "<cmd>below split | terminal<cr>", { desc = "Open terminal below" })
map("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- LSP keymaps (set when an LSP server attaches)
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("UserLspKeymaps", { clear = true }),
  callback = function(ev)
    local opts = { buffer = ev.buf }
    map("n", "gd", vim.lsp.buf.definition, opts)
    map("n", "gr", vim.lsp.buf.references, opts)
    map("n", "K", vim.lsp.buf.hover, opts)
    map("n", "<leader>rn", vim.lsp.buf.rename, opts)
    map("n", "<leader>ca", vim.lsp.buf.code_action, opts)
  end,
})
