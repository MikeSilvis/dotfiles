return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  event = { "BufReadPost", "BufNewFile" },
  config = function()
    require("nvim-treesitter.configs").setup({
      ensure_installed = {
        "ruby", "typescript", "tsx", "javascript",
        "kotlin", "swift", "lua",
        "json", "yaml", "html", "css",
        "sql", "prisma", "dockerfile",
        "bash", "vim", "vimdoc", "markdown",
      },
      highlight = { enable = true },
      indent = { enable = true },
    })
  end,
}
