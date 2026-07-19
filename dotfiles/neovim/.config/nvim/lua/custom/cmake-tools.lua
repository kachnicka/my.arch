require('cmake-tools').setup {
    cmake_show_disabled_build_presets = false,
    cmake_executor = {
        name = 'quickfix',
        opts = {
            show = 'always',
            auto_close_when_success = true,
            position = 'belowright',
            size = 12,
        },
    },
}

-- Keep quickfix open after a successful build if warnings were emitted.
-- Plugin's auto_close_when_success only checks exit code; this patch inspects
-- the populated quickfix list and skips the close when any warning entry exists.
vim.defer_fn(function()
    local qf_mod = require('cmake-tools.quickfix')
    local _orig_close = qf_mod.close
    qf_mod.close = function(opts)
        local has_warning = false
        for _, entry in ipairs(vim.fn.getqflist()) do
            if entry.valid == 1 and (entry.type == 'W'
                or (entry.text and entry.text:lower():find('warning'))) then
                has_warning = true
                break
            end
        end
        if not has_warning then
            _orig_close(opts)
        end
    end
end, 0)

vim.keymap.set('n', '<leader>cg', '<cmd>CMakeGenerate<CR>', { desc = '[C]Make [G]enerate' })
vim.keymap.set('n', '<leader>cG', '<cmd>CMakeGenerate!<CR>', { desc = '[C]Make Clean [G]enerate' })

vim.keymap.set('n', '<leader>cp', '<cmd>CMakeSelectBuildPreset<CR>', { desc = '[C]Make Select Build [P]reset' })

vim.keymap.set('n', '<leader>cr', '<cmd>CMakeRun<CR>', { desc = '[C]Make [R]un' })
vim.keymap.set('n', '<leader>cd', '<cmd>CMakeDebug<CR>', { desc = '[C]Make [D]ebug' })

vim.keymap.set('n', '<leader>cb', '<cmd>CMakeBuild<CR>', { desc = '[C]Make [B]uild' })
vim.keymap.set('n', '<leader>cB', '<cmd>CMakeBuild!<CR>', { desc = '[C]Make Clean [B]uild' })

vim.keymap.set('n', '<leader>cs', '<cmd>CMakeStopExecutor<CR>', { desc = '[C]Make [S]top executor' })
vim.keymap.set('n', '<leader>co', '<cmd>CMakeOpenExecutor<CR>', { desc = '[C]Make [O]pen executor' })

vim.keymap.set('n', '<leader>cj', '<cmd>cnext<CR>', { desc = '[C]Make [j]next warning' })
vim.keymap.set('n', '<leader>ck', '<cmd>cprev<CR>', { desc = '[C]Make [k]prev warning' })
vim.keymap.set('n', '<leader>cq', '<cmd>copen<CR>', { desc = '[C]Make [q]uickfix open' })
