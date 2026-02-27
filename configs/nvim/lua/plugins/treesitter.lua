return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  event = { "BufReadPost", "BufNewFile" },
  main = "nvim-treesitter.configs",
  opts = {
    ensure_installed = {
      "ruby", "typescript", "tsx", "javascript",
      "kotlin", "swift", "lua",
      "json", "yaml", "html", "css",
      "sql", "prisma", "dockerfile",
      "bash", "vim", "vimdoc", "markdown",
    },
    highlight = { enable = true },
    indent = { enable = true },
  },
}
