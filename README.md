# lsp-preview-hover-doc.nvim

> experimental.

Display the contents of `textDocument/hover` in a floating window below the editor.


## Requirements

Neovim >= v0.6.0

## Installation

```
Plug 'tamago324/lsp-preview-hover-doc.nvim'
```

## Usage

```lua
local map = function(bufnr, lhs, rhs)
  vim.api.nvim_buf_set_keymap(
    bufnr,
    "n",
    lhs,
    rhs,
    { silent = true, noremap = true }
  )
end

require'nvim-lsp-installer'.on_server_ready(function(server)
  server:setup({ on_attach = function()
    map("n", "L",  [[<Cmd>lua require'lsp_preview_hover_doc'.request_hover_open_or_focus()<CR>]])
    map("n", "H",  [[<Cmd>lua require'lsp_preview_hover_doc'.close()<CR>]])
    map("n", "zl", [[<Cmd>lua require'lsp_preview_hover_doc'.open_or_focus()<CR>]])
  end})
end)

require("lsp_preview_hover_doc").setup({
  on_init_in_preview_window = function(bufnr)
    map(bufnr, "L", "<Cmd>wincmd p<CR>")
    map(bufnr, "H", "<Cmd>wincmd p<CR>")
    map(bufnr, "<Left>", '<Cmd>lua require("lsp_preview_hover_doc").show_prev()<CR>')
    map(bufnr, "<Right>", '<Cmd>lua require("lsp_preview_hover_doc").show_next()<CR>')
  end,
  win_opts = {
    height = 20,
    zindex = 30,
  },
})
```

## Screenshots

![](https://github.com/tamago324/images/blob/master/lsp-preview-hover-doc.nvim/preview.png)


## License

MIT
