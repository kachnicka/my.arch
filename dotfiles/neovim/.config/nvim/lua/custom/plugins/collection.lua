return {
  'tpope/vim-sleuth',
  {
    'numToStr/Comment.nvim',
    opts = {},
    config = function()
      require('Comment').setup()
      local api = require 'Comment.api'
      local toggleCommentLine = function()
        api.toggle.linewise.current()
        vim.api.nvim_feedkeys('j0', 'n', false)
      end
      vim.keymap.set('n', '<C-/>', toggleCommentLine, { desc = 'Comment Line and Go to Next' })
      vim.keymap.set('n', '<C-_>', toggleCommentLine, { desc = 'Comment Line and Go to Next' })

      local toggleCommentVisual = function()
        local esc = vim.api.nvim_replace_termcodes('<ESC>', true, false, true)
        vim.api.nvim_feedkeys(esc, 'nx', false)
        api.toggle.linewise(vim.fn.visualmode())
        vim.api.nvim_feedkeys('j0', 'n', false)
      end
      vim.keymap.set('x', '<C-/>', toggleCommentVisual, { desc = 'Comment Visual and Go to Next' })
      vim.keymap.set('x', '<C-_>', toggleCommentVisual, { desc = 'Comment Visual and Go to Next' })
    end,
  },
  {
    'lewis6991/gitsigns.nvim',
    opts = {
      signs = {
        add = { text = '+' },
        change = { text = '~' },
        delete = { text = '_' },
        topdelete = { text = '‾' },
        changedelete = { text = '~' },
      },
    },
  },
  {
    'folke/todo-comments.nvim',
    event = 'VimEnter',
    dependencies = { 'nvim-lua/plenary.nvim' },
    opts = { signs = false },
  },
}
