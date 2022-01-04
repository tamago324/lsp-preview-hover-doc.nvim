local util = vim.lsp.util
local lsp = vim.lsp
local a = vim.api
local float_win = require("lsp_preview_hover_doc.win")
local History = require("lsp_preview_hover_doc.history")
local config = require("lsp_preview_hover_doc.config")

local M = {}

-- タブごとの情報
local context = {
  -- preview_bufnr
  -- preview_win
  -- history
}

local get_current_context = function()
  local tabnr = a.nvim_get_current_tabpage()
  if context[tabnr] == nil then
    context[tabnr] = {}
  end
  return context[tabnr]
end

local get_current_tab_preview_bufnr = function()
  -- 現在のタブのプレビュー用バッファを習得する
  local ctx = get_current_context()
  if ctx.preview_bufnr == nil then
    ctx.preview_bufnr = a.nvim_create_buf(false, true)
    a.nvim_buf_set_option(ctx.preview_bufnr, "filetype", "markdown")
  end

  return ctx.preview_bufnr
end

-- preview が表示されているか
local get_win = function(preview_bufnr)
  for _, w in ipairs(a.nvim_tabpage_list_wins(a.nvim_get_current_tabpage())) do
    if a.nvim_win_get_buf(w) == preview_bufnr then
      return w
    end
  end

  return nil
end

-- 内容が同じかどうか
local equal_preview_doc = function(bufnr, new_lines)
  return vim.deep_equal(a.nvim_buf_get_lines(bufnr, 0, -1, true), new_lines)
end

local is_active = function(bufnr)
  return #vim.tbl_keys(vim.lsp.buf_get_clients(bufnr)) > 0
end

-- :h lsp-handler
local handler = function(_, result, _, _)
  if not (result and result.contents) then
    return
  end
  local markdown_lines = lsp.util.convert_input_to_markdown_lines(result.contents)
  markdown_lines = lsp.util.trim_empty_lines(markdown_lines)
  if vim.tbl_isempty(markdown_lines) then
    M.close()
    return
  end

  local ctx = get_current_context()

  local preview_bufnr = get_current_tab_preview_bufnr()
  if
    ctx.preview_win ~= nil
    and a.nvim_win_is_valid(ctx.preview_win)
    and equal_preview_doc(preview_bufnr, markdown_lines)
  then
    -- 内容が同じだったらフォーカスを移動させる
    M.focus()
    return
  end
  a.nvim_buf_set_lines(preview_bufnr, 0, -1, false, markdown_lines)
  ctx.history:add(markdown_lines)

  local cwin = vim.api.nvim_get_current_win()

  if get_win(preview_bufnr) == nil then
    ctx.preview_win = float_win.open_float_win(preview_bufnr)
  end

  a.nvim_win_set_buf(ctx.preview_win, preview_bufnr)
  -- a.nvim_win_call(ctx.preview_win, function()
  --   a.nvim_command("silent normal! gg")
  -- end)
  a.nvim_set_current_win(ctx.preview_win)
  a.nvim_command("silent normal! gg")
  a.nvim_set_current_win(cwin)

  -- cursor moved を設定する
  float_win._setup_CursorMoved(preview_bufnr)
end

function M.open_or_focus()
  local ctx = get_current_context()
  -- まだ、表示したことないなら終わり
  if ctx.preview_bufnr == nil then
    return
  end

  if get_win(ctx.preview_bufnr) == nil then
    ctx.preview_win = float_win.open_float_win(ctx.preview_bufnr)
  else
    M.focus()
  end
end

function M.request_hover_open_or_focus()
  if not is_active(0) then
    pprint("disabled")
    return
  end

  local ctx = get_current_context()
  if ctx.history == nil then
    ctx.history = History.new()
  end

  local params = util.make_position_params()
  vim.lsp.buf_request(0, "textDocument/hover", params, handler)
end

function M.close()
  local ctx = get_current_context()
  local win = ctx.preview_win
  if win ~= nil and a.nvim_win_is_valid(win) then
    -- a.nvim_win_close(win, true)
    a.nvim_win_hide(win)
  end
end

-- プレビューにフォーカスする
function M.focus()
  local ctx = get_current_context()
  local win = ctx.preview_win
  a.nvim_set_current_win(win)
end

-- 前のドキュメントを表示する
function M.show_prev()
  local ctx = get_current_context()
  local markdown_lines = ctx.history:prev()

  if ctx.preview_bufnr == nil or (not a.nvim_buf_is_valid(ctx.preview_bufnr)) then
    return
  end

  a.nvim_buf_set_lines(ctx.preview_bufnr, 0, -1, false, markdown_lines)
end

-- 次のドキュメントを表示する
function M.show_next()
  local ctx = get_current_context()
  local markdown_lines = ctx.history:next()

  if ctx.preview_bufnr == nil or (not a.nvim_buf_is_valid(ctx.preview_bufnr)) then
    return
  end

  a.nvim_buf_set_lines(ctx.preview_bufnr, 0, -1, false, markdown_lines)
end

---@param prefs lsp_preview_hover_doc.config.values
function M.setup(prefs)
  config.set_default_values(prefs)
end

return M
