require('cmake-tools').setup {}

vim.keymap.set('n', '<leader>cg', '<cmd>CMakeGenerate<CR>', { desc = '[C]Make [G]enerate' })
vim.keymap.set('n', '<leader>cG', '<cmd>CMakeGenerate!<CR>', { desc = '[C]Make Clean [G]enerate' })

vim.keymap.set('n', '<leader>cp', '<cmd>CMakeSelectBuildPreset<CR>', { desc = '[C]Make Select Build [P]reset' })

vim.keymap.set('n', '<leader>cr', '<cmd>CMakeRun<CR>', { desc = '[C]Make [R]un' })
vim.keymap.set('n', '<leader>cd', '<cmd>CMakeDebug<CR>', { desc = '[C]Make [D]ebug' })

vim.keymap.set('n', '<leader>cb', '<cmd>CMakeBuild<CR>', { desc = '[C]Make [B]uild' })
vim.keymap.set('n', '<leader>cB', '<cmd>CMakeBuild!<CR>', { desc = '[C]Make Clean [B]uild' })

vim.keymap.set('n', '<leader>cs', '<cmd>CMakeStopExecutor<CR>', { desc = '[C]Make [S]top executor' })
vim.keymap.set('n', '<leader>co', '<cmd>CMakeOpenExecutor<CR>', { desc = '[C]Make [O]pen executor' })
