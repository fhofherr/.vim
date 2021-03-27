local M = {}

-- Init v:lua.dotfiles.settings namespace, so that other modules
-- in here may add to it.
_G.dotfiles = { settings = {} }

local completion = require("dotfiles.settings.completion")
local galaxyline = require("dotfiles.settings.galaxyline")
local lsp = require("dotfiles.settings.lsp")
local tmux = require("dotfiles.settings.tmux")
local treesitter = require("dotfiles.settings.treesitter")

function M.setup()
    completion.setup()
    galaxyline.setup()
    lsp.setup()
    tmux.setup()
    treesitter.setup()
end

return M
