local M = {}

local target

local function herdr_bin()
  for _, bin in ipairs { 'herdr', '/run/host/usr/bin/herdr' } do
    if vim.fn.executable(bin) == 1 then
      return bin
    end
  end
end

local function herdr(args)
  if vim.env.HERDR_ENV ~= '1' or not (vim.env.HERDR_PANE_ID and vim.env.HERDR_TAB_ID and vim.env.HERDR_WORKSPACE_ID) then
    return nil, 'nvim is not running inside a herdr pane'
  end
  local bin = herdr_bin()
  if not bin then
    return nil, 'herdr binary not found'
  end
  local res = vim.system(vim.list_extend({ bin }, args), { text = true }):wait()
  if res.code ~= 0 then
    return nil, vim.trim(res.stderr ~= '' and res.stderr or res.stdout)
  end
  local ok, decoded = pcall(vim.json.decode, res.stdout)
  return ok and decoded or {}
end

local function other_panes()
  local out, err = herdr { 'pane', 'list', '--workspace', vim.env.HERDR_WORKSPACE_ID }
  if not out then
    return nil, err
  end
  local panes = {}
  for _, p in ipairs(out.result and out.result.panes or {}) do
    if p.pane_id ~= vim.env.HERDR_PANE_ID then
      panes[#panes + 1] = p
    end
  end
  table.sort(panes, function(a, b)
    local sa, sb = a.tab_id == vim.env.HERDR_TAB_ID, b.tab_id == vim.env.HERDR_TAB_ID
    if sa ~= sb then
      return sa
    end
    return a.pane_id < b.pane_id
  end)
  return panes
end

local function choose(on_choice)
  local panes, err = other_panes()
  if not panes then
    return vim.notify(err, vim.log.levels.WARN)
  end
  local same_tab = vim.tbl_filter(function(p)
    return p.tab_id == vim.env.HERDR_TAB_ID
  end, panes)
  if #same_tab == 1 then
    target = same_tab[1].pane_id
    return on_choice(target)
  end
  if #panes == 0 then
    return vim.notify('No other herdr pane in this workspace', vim.log.levels.WARN)
  end
  vim.ui.select(panes, {
    prompt = 'Send to pane',
    format_item = function(p)
      local where = p.tab_id == vim.env.HERDR_TAB_ID and 'this tab' or p.tab_id
      return string.format('%s  (%s, %s)', p.terminal_title_stripped or p.pane_id, where, p.pane_id)
    end,
  }, function(p)
    if p then
      target = p.pane_id
      on_choice(target)
    end
  end)
end

local function send(text)
  local function deliver(pane)
    local _, err = herdr { 'pane', 'send-text', pane, text }
    if err then
      target = nil
      return vim.notify('herdr send-text: ' .. err, vim.log.levels.WARN)
    end
    vim.notify('Sent to ' .. pane .. ': ' .. vim.trim(text))
  end
  if target then
    deliver(target)
  else
    choose(deliver)
  end
end

local function reference(first, last)
  local path = vim.api.nvim_buf_get_name(0)
  if vim.bo.buftype ~= '' or path == '' then
    vim.notify('Not a file buffer', vim.log.levels.WARN)
    return nil
  end
  if first == last then
    return string.format('%s:%d ', path, first)
  end
  return string.format('%s:%d-%d ', path, first, last)
end

function M.send_line()
  local line = vim.api.nvim_win_get_cursor(0)[1]
  local ref = reference(line, line)
  if ref then
    send(ref)
  end
end

function M.send_selection()
  local a, b = vim.fn.line 'v', vim.fn.line '.'
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'nx', false)
  local ref = reference(math.min(a, b), math.max(a, b))
  if ref then
    send(ref)
  end
end

function M.pick()
  target = nil
  choose(function(pane)
    vim.notify('Agent pane: ' .. pane)
  end)
end

return M
