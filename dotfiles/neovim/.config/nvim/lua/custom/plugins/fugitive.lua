return {
  'tpope/vim-fugitive',
  config = function()
    -- Keep the fugitive status window at ~16% width, but grow it to fit the
    -- longest status line (e.g. long paths in unstaged changes) so nothing
    -- gets truncated. Capped at 50% of the screen. winfixwidth protects it
    -- from equalalways resizing the diff windows on a second dd.
    local function resize_fugitive(win)
      local buf = vim.api.nvim_win_get_buf(win)
      local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
      local content_w = 0
      for _, l in ipairs(lines) do
        local w = vim.fn.strdisplaywidth(l)
        if w > content_w then
          content_w = w
        end
      end
      -- getwininfo().textoff = exact gutter width (sign + fold + number
      -- columns managed by statuscol.nvim). Without this, long lines wrap.
      local gutter = (vim.fn.getwininfo(win)[1] or {}).textoff or 0
      local min_w = math.floor(vim.o.columns * 0.16)
      local max_w = math.floor(vim.o.columns * 0.50)
      local target = math.min(math.max(min_w, content_w + gutter), max_w)
      vim.api.nvim_win_set_width(win, target)
    end

    vim.api.nvim_create_autocmd('FileType', {
      pattern = 'fugitive',
      callback = function(args)
        local win = vim.fn.bufwinid(args.buf)
        if win == -1 then
          return
        end
        vim.wo[win].winfixwidth = true
        -- Defer: fugitive may still be populating the buffer at FileType time.
        vim.schedule(function()
          if vim.api.nvim_win_is_valid(win) then
            resize_fugitive(win)
          end
        end)
      end,
    })

    -- Re-fit on refresh (stage/unstage/commit changes the path list).
    vim.api.nvim_create_autocmd('User', {
      pattern = 'FugitiveChanged',
      callback = function()
        for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
          local b = vim.api.nvim_win_get_buf(w)
          if vim.bo[b].filetype == 'fugitive' then
            resize_fugitive(w)
          end
        end
      end,
    })

    -- True if a fugitive status window is already visible in the current tab.
    local function fugitive_open()
      for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        local b = vim.api.nvim_win_get_buf(w)
        if vim.bo[b].filetype == 'fugitive' then
          return true
        end
      end
      return false
    end

    vim.keymap.set('n', '<leader>gg', function()
      if not fugitive_open() then
        vim.cmd 'only' -- close all other splits, keep one buffer
      end
      vim.cmd 'topleft vertical Git' -- open status window on the left
    end, { desc = '[G]it (left 16%)' })

    -- Stage the currently diffed file (cursor in working side), close its diff
    -- partner (fugitive:// index version), leave the working file visible as
    -- the "current version", then focus the fugitive status window with cursor
    -- on the first file line under the "Unstaged" header.
    vim.keymap.set('n', '<leader>gs', function()
      -- 1. Stage current file (also fires FugitiveChanged -> status refresh)
      vim.cmd 'Gwrite'

      -- 2. Close the diff partner: fugitive:// buffer that is not the status window.
      for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        local b = vim.api.nvim_win_get_buf(w)
        local name = vim.api.nvim_buf_get_name(b)
        if vim.startswith(name, 'fugitive://') and vim.bo[b].filetype ~= 'fugitive' then
          pcall(vim.api.nvim_win_close, w, false)
          break
        end
      end

      -- 3. Focus the fugitive status window (reopen on the left if it was replaced).
      local fugitive_win
      for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        local b = vim.api.nvim_win_get_buf(w)
        if vim.bo[b].filetype == 'fugitive' then
          fugitive_win = w
          break
        end
      end
      if not fugitive_win then
        vim.cmd 'topleft vertical Git'
      else
        vim.api.nvim_set_current_win(fugitive_win)
      end

      -- 4. Cursor on first file line under the "Unstaged" header.
      if vim.fn.search('^Unstaged', 'w') > 0 then
        vim.cmd 'normal! j'
      end
    end, { desc = '[G]it [s]tage current + focus next' })
  end,
}
