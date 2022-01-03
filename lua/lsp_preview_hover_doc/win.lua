local a = vim.api
local config = require("lsp_preview_hover_doc.config")

local _opts = {
  height = function()
    if not config.values.win_opts or not config.values.win_opts.height then
      return 20
    end
    return config.values.win_opts.height
  end,
  scrolloff = vim.o.scrolloff,
}

local calc_preview_opt_top = function()
  local statusline_height = 1
  local border_weight = 2
  return vim.o.lines - _opts.height() - vim.o.cmdheight - statusline_height - border_weight
end

--- Return a table with highlighted borderchars.
---   { {'=', highlight }, {'|', highlight}, ... }
---@param borderchars table
---@param highlight string
---@return table
local make_border_opts = function(borderchars, highlight)
  return vim.tbl_map(function(char)
    return { char, highlight }
  end, borderchars)
end

-- プレビューのオプションを作成する
local make_default_win_opts = function()
  local width = vim.o.columns - 2
  local height = _opts.height()
  local top = calc_preview_opt_top()
  local left = 1

  return {
    relative = "editor",
    row = top,
    col = left,
    width = width,
    height = height,
    zindex = 30,
    border = make_border_opts({
      "+",
      "─",
      "+",
      "│",
      "+",
      "─",
      "+",
      "│",
    }, "Normal"),
  }
end

local show_cursorline = function()
  -- 画面上でのウィンドウの上の位置
  local win_top_in_editor = vim.fn.win_screenpos(vim.fn.winnr())[1]
  -- window 内での位置
  local cursorline_in_win = vim.fn.winline()
  -- 画面上でのカーソル位置
  local cursorline_in_editor = win_top_in_editor + cursorline_in_win

  -- ┌────────────────────────────────────────────────────┐
  -- │┌──────────────────────────────────────────────────┐│ ▲                               ▲
  -- ││                                                  ││ │                               │
  -- ││                                                  ││ │ win_top_in_editor             │
  -- ││                                                  ││ │(ウィンドウの上の位置)         │
  -- │└──────────────────────────────────────────────────┘│ ▼                               │
  -- │┌──────────────────────────────────────────────────┐│ ▲                               │  cursorline_in_editor
  -- ││                                                  ││ │                               │ (画面上でのカーソル位置)
  -- ││                                                  ││ │ cursorline_in_win             │
  -- ││┌────────────────────────────────────────────────┐││ │(ウィンドウ内でのカーソル位置) │
  -- │││Current Window                                  │││ │                               │
  -- │││                                                │││ │                               │
  -- │││ Cursor Position                                │││ ▼                               ▼
  -- │││──────|─────────────────────────────────────────│││
  -- │││                                                │││
  -- │││                                                │││
  -- │││                                                │││
  -- │││                                                │││
  -- │││                                                │││
  -- │││ Preview Window                                 │││
  -- ││└────────────────────────────────────────────────┘││
  -- │└──────────────────────────────────────────────────┘│
  -- └────────────────────────────────────────────────────┘

  -- 画面上でのカーソル位置がプレビューの上の位置よりも下にあったら、scrolloff 分だけ上に移動する
  local preview_top = calc_preview_opt_top()
  if cursorline_in_editor > preview_top then
    -- XXX: 調整の 1 だけど、 なんでだろう...
    local scroll_up_cnt = cursorline_in_editor - preview_top + _opts.scrolloff - 2
    for _ = 1, scroll_up_cnt do
      a.nvim_feedkeys(a.nvim_replace_termcodes("<C-e>", true, false, true), "n", true)
    end
  elseif cursorline_in_editor >= preview_top - _opts.scrolloff then
    -- もし、プレビューを表示したら scrolloff 以下になってしまったら、その分だけ scroll する
    local scroll_up_cnt = preview_top - cursorline_in_editor - 3
    for _ = 1, scroll_up_cnt do
      a.nvim_feedkeys(a.nvim_replace_termcodes("<C-e>", true, false, true), "n", true)
    end
  end
end

-- カレントタブにプレビューがあるか
local exists_preview_in_current_tab = function()
  for _, w in ipairs(a.nvim_list_wins()) do
    local res = vim.F.npcall(a.nvim_win_get_var, w, "preview_float_doc_window")
    if res ~= nil and res then
      return true
    end
  end

  return false
end

-- プレビューにかぶっていたらスクロールする
local _scroll_duplicated_preview = function()
  local is_preview_win = vim.F.npcall(a.nvim_win_get_var, 0, "preview_float_doc_window")
  if is_preview_win ~= nil or is_preview_win then
    -- もし、preview window なら、何もせずに終わり
    return
  end

  if not exists_preview_in_current_tab() then
    return
  end

  show_cursorline()
end

-- それっぽく スクロールしたいな...
local _setup_CursorMoved = function(bufnr)
  local tabnr = a.nvim_get_current_tabpage()
  -- 閉じたら、もとに戻す
  a.nvim_exec(
    string.format(
      [[
  augroup lsp-preview-hover-doc-%d
    autocmd!
    autocmd CursorMoved * lua require('lsp_preview_hover_doc/win')._scroll_duplicated_preview()
    autocmd WinClosed <buffer=%d> ++once lua require('lsp_preview_hover_doc/win')._onWinClosed(%d)
  augroup END
  ]],
      tabnr,
      bufnr,
      tabnr
    ),
    false
  )
end

-- 消す
local _onWinClosed = function(tabnr)
  -- 閉じたら、もとに戻す
  a.nvim_exec(
    string.format(
      [[
  augroup lsp-preview-hover-doc-%d
    autocmd!
  augroup END
  ]],
      tabnr
    ),
    false
  )
end

local open_float_win = function(bufnr)
  local win_opts = vim.tbl_deep_extend("force", make_default_win_opts(), config.values.win_opts or {})
  local win = a.nvim_open_win(bufnr, false, win_opts)

  a.nvim_win_set_var(win, "preview_float_doc_window", true)

  show_cursorline()

  a.nvim_win_set_option(win, "winhl", "Normal:LspPreviewHoverDocFloatNormal,EndOfBuffer:LspPreviewHoverDocFloatNormal")

  config.values.on_init_in_preview_window(bufnr)

  return win
end

return {
  open_float_win = open_float_win,
  _scroll_duplicated_preview = _scroll_duplicated_preview,
  _onWinClosed = _onWinClosed,
  _setup_CursorMoved = _setup_CursorMoved,
}
