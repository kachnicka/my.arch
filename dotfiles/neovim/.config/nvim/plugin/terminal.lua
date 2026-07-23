-- Terminal buffer hygiene.
--
-- Left-padding columns (signcolumn / number / relativenumber / statuscolumn /
-- foldcolumn / cursorline) force a full Neovim redraw whenever their width
-- changes.  In a streaming terminal — e.g. cmake-tools.nvim's CMakeRun
-- executor — statuscol.nvim's relativenumber segment changes width on every
-- appended line, and nvim-ufo's foldcolumn reserves an extra cell.  Each
-- width change triggers UPD_NOT_VALID, which surfaces visually as a constant
-- one-character left/right "wiggle" while output streams.
--
-- Neovim >= 0.10 disables number / relativenumber / signcolumn in terminal
-- buffers by default, but plugins (statuscol.nvim, gitsigns, ufo) re-enable
-- them.  Pin them off explicitly on TermOpen so the terminal window stays a
-- single fixed-width text region.
vim.api.nvim_create_autocmd('TermOpen', {
  group = vim.api.nvim_create_augroup('terminal-no-left-padding', { clear = true }),
  callback = function()
    vim.opt_local.signcolumn = 'no'
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    vim.opt_local.statuscolumn = ''
    vim.opt_local.foldcolumn = '0'
    vim.opt_local.cursorline = false
    vim.opt_local.cursorcolumn = false
  end,
})
