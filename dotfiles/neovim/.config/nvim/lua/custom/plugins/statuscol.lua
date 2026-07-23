return {
  'luukvbaal/statuscol.nvim',
  config = function()
    local builtin = require 'statuscol.builtin'
    require('statuscol').setup {
      -- relculright = true,
      -- Terminal buffers stream output; the relativenumber segment changes
      -- width per appended line and forces a full redraw (visible as a
      -- one-char left/right "wiggle").  Skip statuscol for terminal filetypes
      -- (the TermOpen autocmd in plugin/terminal.lua pins the column to '' as
      -- a belt-and-braces fallback).
      ft_ignore = { 'terminal', 'cmake_tools_terminal' },
      segments = {
        -- { text = { '%C' }, click = 'v:lua.ScFa' },
        { text = { '%s' }, click = 'v:lua.ScSa' },
        {
          text = { builtin.lnumfunc, ' ' },
          condition = { true, builtin.not_empty },
          click = 'v:lua.ScLa',
        },
        { text = { builtin.foldfunc, ' ' }, click = 'v:lua.ScFa' },
      },
    }
  end,
}
