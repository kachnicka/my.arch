return {
  'f4z3r/gruvbox-material.nvim',
  lazy = false,
  priority = 1000,
  init = function()
    vim.cmd.colorscheme 'gruvbox-material'
  end,
}
