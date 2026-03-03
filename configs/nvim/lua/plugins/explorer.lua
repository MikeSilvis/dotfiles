return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
    },
    cmd = "Neotree",
    keys = {
      { "<C-b>", "<cmd>Neotree toggle<cr>", desc = "Toggle File Explorer" },
      { "<C-0>", "<cmd>Neotree toggle<cr>", desc = "Toggle File Explorer" },
      { "<C-S-j>", "<cmd>Neotree reveal<cr>", desc = "Reveal File in Explorer" },
    },
    opts = {
      filesystem = {
        filtered_items = {
          visible = true,
        },
      },
    },
  },
}
