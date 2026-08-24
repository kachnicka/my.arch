return {
  'nvim-treesitter/nvim-treesitter',
  branch = 'main',
  lazy = false,
  build = ':TSUpdate',
  config = function()
    -- [[ Configure Treesitter ]] See `:help nvim-treesitter`
    -- main branch: plugin = parser installer only. Highlight/indent = native Neovim API.
    require('nvim-treesitter').setup {}

    -- Install parsers (no-op if already installed)
    require('nvim-treesitter').install {
      'bash', 'c', 'cpp', 'diff', 'glsl', 'html', 'lua', 'luadoc',
      'markdown', 'markdown_inline', 'vim', 'vimdoc',
    }

    -- Enable treesitter highlighting + indentation for filetypes with a parser.
    -- language.inspect() errors when no parser .so is loaded (unlike language.add()
    -- which just registers the name). pcall(start) as belt-and-suspenders.
    -- Matches pattern from nvim-treesitter's own minimal_init, LazyVim, neogit.
    vim.api.nvim_create_autocmd('FileType', {
      group = vim.api.nvim_create_augroup('ts-config', { clear = true }),
      pattern = '*',
      callback = function(args)
        local lang = vim.treesitter.language.get_lang(vim.bo[args.buf].filetype)
        if not lang or not pcall(vim.treesitter.language.inspect, lang) then
          return
        end
        pcall(vim.treesitter.start, args.buf, lang)
        if vim.bo[args.buf].filetype ~= 'ruby' then
          vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end
      end,
    })
  end,
}
