return {
  'tpope/vim-fugitive',
  config = function()
    -- require 'custom.fugitive'
    vim.keymap.set('n', '<leader>gg', vim.cmd.Git, { desc = '[G]it' })
  end,
}
