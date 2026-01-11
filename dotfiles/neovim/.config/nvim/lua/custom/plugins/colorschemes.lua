return {
  'f4z3r/gruvbox-material.nvim',
  lazy = false,
  priority = 1000,
  init = function()
    vim.cmd.colorscheme 'gruvbox-material'
    vim.api.nvim_set_hl(0, 'DiffText', { bg = '#35505c' })
  end,
}
