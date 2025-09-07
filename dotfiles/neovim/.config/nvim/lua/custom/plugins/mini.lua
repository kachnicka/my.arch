return {
  'echasnovski/mini.nvim',
  config = function()
    --  - va)  - [V]isually select [A]round [)]paren
    --  - yinq - [Y]ank [I]nside [N]ext [']quote
    --  - ci'  - [C]hange [I]nside [']quote
    require('mini.ai').setup { n_lines = 500 }

    -- Add/delete/replace surroundings (brackets, quotes, etc.)
    -- - saiw) - [S]urround [A]dd [I]nner [W]ord [)]Paren
    -- - sd'   - [S]urround [D]elete [']quotes
    -- - sr)'  - [S]urround [R]eplace [)] [']
    require('mini.surround').setup()

    local statusline = require 'mini.statusline'
    statusline.setup { use_icons = vim.g.have_nerd_font }
    ---@diagnostic disable-next-line: duplicate-set-field
    statusline.section_location = function()
      return '%2l:%-2v'
    end

    local og_section_fileinfo = statusline.section_fileinfo
    ---@diagnostic disable-next-line: duplicate-set-field
    statusline.section_fileinfo = function(args)
      local cmake_status = function()
        local cmake = require 'cmake-tools'

        if not cmake.is_cmake_project() then
          return ''
        end

        return string.format('⚙ %s [%s]   ', cmake.get_launch_target(), cmake.get_build_type())
      end

      return cmake_status() .. og_section_fileinfo(args)
    end
  end,
}
