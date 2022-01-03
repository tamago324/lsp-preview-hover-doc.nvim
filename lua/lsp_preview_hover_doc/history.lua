-- hover_doc の履歴を管理するためのオブジェクト (タブごとに作成する想定)

local History = {}

function History.new()
  local obj = {
    items = {},
    -- 現在の位置
    idx = 1,
  }
  return setmetatable(obj, { __index = History })
end

-- 履歴に追加する
function History.add(self, markdown_lines)
  -- もし、存在していれば削除してから、先頭に追加する
  for i, v in ipairs(self.items) do
    if vim.deep_equal(v, markdown_lines) then
      table.remove(self.items, i)
    end
  end
  table.insert(self.items, markdown_lines)
  self.idx = #self.items
end

-- 1つ後ろに戻す
function History.prev(self)
  if self.idx > 1 then
    self.idx = self.idx - 1
  end
  return self.items[self.idx]
end

-- 1つ前に進める
function History.next(self)
  if self.idx < #self.items then
    self.idx = self.idx + 1
  end
  return self.items[self.idx]
end

return History
