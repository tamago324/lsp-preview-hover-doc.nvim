local defaults_values = {
  on_init_in_preview_window = function() end,
  win_opts = {},
}

---@class lsp_preview_hover_doc.config
---@field values lsp_preview_hover_doc.config.values
local config = {}

---@class lsp_preview_hover_doc.config.values
---@field on_init_in_preview_window function
---@field win_opts table
config.values = {}

---@class lsp_preview_hover_doc.config.values.win_opts
---@field height number

---@param opts lir.config.values
function config.set_default_values(opts)
  config.values = vim.tbl_deep_extend("force", defaults_values, opts or {})
end

return config
