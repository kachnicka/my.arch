return {
  'stevearc/oil.nvim',
  ---@module 'oil'
  ---@type oil.SetupOpts
  opts = {},
  -- Optional dependencies
  dependencies = { { 'echasnovski/mini.icons', opts = {} } },
  -- dependencies = { "nvim-tree/nvim-web-devicons" }, -- use if prefer nvim-web-devicons
  config = function()
    require('oil').setup {
      keymaps = {
        ['<Esc>'] = { 'actions.close', mode = 'n' },
      },
      view_options = {
        show_hidden = true,
      },
    }
    vim.keymap.set('n', '-', '<cmd>Oil --float<CR>', { desc = 'Open parent dir' })
  end,
}
