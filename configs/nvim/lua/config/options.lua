local opt = vim.opt

-- Line numbers
opt.number = true

-- No line wrapping
opt.wrap = false

-- Mouse support
opt.mouse = "a"

-- System clipboard
opt.clipboard = "unnamed"

-- Search
opt.hlsearch = true

-- Tabs / indentation
opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true

-- Visual guides
opt.cursorline = true
opt.colorcolumn = "100"

-- True color support (for gruvbox)
opt.termguicolors = true

-- Always show sign column (avoids layout shift from git signs / diagnostics)
opt.signcolumn = "yes"

-- Faster CursorHold events (used by gitsigns, LSP hover, etc.)
opt.updatetime = 300

-- Splits open in natural directions
opt.splitbelow = true
opt.splitright = true
