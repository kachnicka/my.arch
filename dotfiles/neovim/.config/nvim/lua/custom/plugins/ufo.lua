return {
  'kevinhwang91/nvim-ufo',
  event = 'BufReadPost',
  dependencies = { 'kevinhwang91/promise-async' },
  config = function()
    vim.o.foldenable = true
    vim.o.foldcolumn = '1'
    vim.o.foldlevel = 99
    vim.o.foldlevelstart = 99
    vim.o.fillchars = 'eob: ,fold: ,foldopen:,foldsep: ,foldclose:'

    -- foldingRange capability is advertised in lsp.lua; ufo picks it up automatically
    require('ufo').setup()

    vim.keymap.set('n', '<leader>zz', 'za', { desc = 'Fold toggle' })
    vim.keymap.set('n', '<leader>zo', 'zR', { desc = 'Open all folds' })
  end,
}
