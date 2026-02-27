return {
  {
    "williamboman/mason.nvim",
    build = ":MasonUpdate",
    config = function()
      require("mason").setup()
    end,
  },
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "williamboman/mason.nvim", "neovim/nvim-lspconfig" },
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = {
          "ruby_lsp",
          "ts_ls",
          "kotlin_language_server",
          "lua_ls",
        },
        automatic_enable = true,
      })

      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      -- Apply capabilities to all servers
      vim.lsp.config("*", { capabilities = capabilities })

      -- lua_ls with Neovim-aware settings
      vim.lsp.config("lua_ls", {
        settings = {
          Lua = {
            workspace = { checkThirdParty = false },
            telemetry = { enable = false },
          },
        },
      })

      -- sourcekit comes with Xcode, not Mason
      vim.lsp.enable("sourcekit")
    end,
  },
}
