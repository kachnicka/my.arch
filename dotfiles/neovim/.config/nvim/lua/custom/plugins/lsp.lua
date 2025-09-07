return {
  'neovim/nvim-lspconfig',
  dependencies = {
    { 'williamboman/mason.nvim', config = true },
    { 'williamboman/mason-lspconfig.nvim', opts = {} },
    { 'WhoIsSethDaniel/mason-tool-installer.nvim', opts = {} },
    { 'j-hui/fidget.nvim', opts = { progress = { display = { render_limit = 16 } } } },
    { 'folke/lazydev.nvim', opts = { library = { plugins = { 'nvim-lspconfig' } } } },
  },
  config = function()
    vim.lsp.handlers['textDocument/hover'] = vim.lsp.with(vim.lsp.handlers.hover, { border = 'rounded' })
    vim.lsp.handlers['textDocument/signatureHelp'] = vim.lsp.with(vim.lsp.handlers.signature_help, { border = 'rounded' })

    vim.api.nvim_create_autocmd('LspAttach', {
      group = vim.api.nvim_create_augroup('user-lsp-attach', { clear = true }),
      callback = function(event)
        local map = function(keys, func, desc)
          vim.keymap.set('n', keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
        end
        map('gd', require('telescope.builtin').lsp_definitions, '[G]oto [D]efinition')
        map('gr', require('telescope.builtin').lsp_references, '[G]oto [R]eferences')
        map('gI', require('telescope.builtin').lsp_implementations, '[G]oto [I]mplementation')
        map('<leader>D', require('telescope.builtin').lsp_type_definitions, 'Type [D]efinition')
        map('<leader>ds', require('telescope.builtin').lsp_document_symbols, '[D]ocument [S]ymbols')
        map('<leader>ws', require('telescope.builtin').lsp_dynamic_workspace_symbols, '[W]orkspace [S]ymbols')
        map('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')
        map('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction')
        map('K', vim.lsp.buf.hover, 'Hover Documentation')
        map('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')

        local client = vim.lsp.get_client_by_id(event.data.client_id)
        if client and client.supports_method 'textDocument/documentHighlight' then
          local highlight_augroup = vim.api.nvim_create_augroup('user-lsp-highlight', { clear = false })
          vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
            buffer = event.buf,
            group = highlight_augroup,
            callback = vim.lsp.buf.document_highlight,
          })
          vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
            buffer = event.buf,
            group = highlight_augroup,
            callback = vim.lsp.buf.clear_references,
          })
        end

        if client and client.supports_method 'textDocument/inlayHint' then
          map('<leader>th', function()
            vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf }, { bufnr = event.buf })
          end, '[T]oggle Inlay [H]ints')
        end

        vim.api.nvim_create_autocmd('LspDetach', {
          group = vim.api.nvim_create_augroup('user-lsp-detach', { clear = true }),
          callback = function(event2)
            vim.lsp.buf.clear_references()
            vim.api.nvim_clear_autocmds { group = 'user-lsp-highlight', buffer = event2.buf }
          end,
        })
      end,
    })

    local capabilities = vim.lsp.protocol.make_client_capabilities()
    capabilities = vim.tbl_deep_extend('force', capabilities, require('cmp_nvim_lsp').default_capabilities())

    --   local servers = {
    --     clangd = {
    --       keys = {
    --         { '<leader>cR', '<cmd>ClangdSwitchSourceHeader<cr>', desc = 'Switch Source/Header (C/C++)' },
    --       },
    --       root_dir = function(fname)
    --         return require('lspconfig.util').root_pattern(
    --           'Makefile',
    --           'configure.ac',
    --           'configure.in',
    --           'config.h.in',
    --           'meson.build',
    --           'meson_options.txt',
    --           'build.ninja',
    --           '.clangd',
    --           '.clang-format'
    --         )(fname) or require('lspconfig.util').root_pattern('compile_commands.json', 'compile_flags.txt')(fname) or require('lspconfig.util').find_git_ancestor(
    --           fname
    --         )
    --       end,
    --       capabilities = {
    --         offsetEncoding = { 'utf-16' },
    --       },
    --       cmd = {
    --         'clangd',
    --         '--background-index',
    --         '--clang-tidy',
    --         '--header-insertion=never',
    --         '--completion-style=detailed',
    --         '--function-arg-placeholders',
    --         '--fallback-style=llvm',
    --         '--experimental-modules-support',
    --       },
    --       init_options = {
    --         usePlaceholders = true,
    --         completeUnimported = true,
    --         clangdFileStatus = true,
    --       },
    --     },
    --     glsl_analyzer = {
    --       cmd = { 'glsl_analyzer' },
    --       filetypes = { 'glsl', 'vert', 'tesc', 'tese', 'frag', 'geom', 'comp', 'rgen', 'rint', 'rahit', 'rchit', 'rmiss', 'rcall', 'mesh', 'task' },
    --       single_file_support = { true },
    --     },
    --     slang = {
    --       filetypes = { 'hlsl', 'shaderslang', 'slang' },
    --       root_dir = function(fname)
    --         return require('lspconfig.util').root_pattern '.clang-format'(fname)
    --       end,
    --     },
    --     pyright = {},
    --     lua_ls = {
    --       -- cmd = {...},
    --       -- filetypes = { ...},
    --       -- capabilities = {},
    --       settings = {
    --         Lua = {
    --           completion = {
    --             callSnippet = 'Replace',
    --           },
    --           -- You can toggle below to ignore Lua_LS's noisy `missing-fields` warnings
    --           -- diagnostics = { disable = { 'missing-fields' } },
    --         },
    --       },
    --     },
    --   }
    --
    --   require('mason').setup()
    --
    --   -- Ensure tools are installed
    --   local ensure_installed = vim.tbl_keys(servers or {})
    --   vim.list_extend(ensure_installed, { 'stylua' })
    --   require('mason-tool-installer').setup { ensure_installed = ensure_installed }
    --
    --   -- Mason-lspconfig setup without handlers
    --   require('mason-lspconfig').setup {}
    -- end,

    local servers = {
      clangd = {
        cmd = {
          'clangd',
          '--background-index',
          '--clang-tidy',
          '--header-insertion=never',
          '--completion-style=detailed',
          '--function-arg-placeholders',
          '--fallback-style=llvm',
          '--experimental-modules-support',
        },
        root_markers = {
          '.clangd',
          '.clang-format',
          'compile_commands.json',
          '.git',
        },
      },
      glsl_analyzer = {
        cmd = { 'glsl_analyzer' },
        filetypes = { 'glsl', 'vert', 'tesc', 'tese', 'frag', 'geom', 'comp', 'rgen', 'rint', 'rahit', 'rchit', 'rmiss', 'rcall', 'mesh', 'task' },
        single_file_support = true,
      },
      slang = {
        cmd = { 'slangd' },
        filetypes = { 'hlsl', 'shaderslang', 'slang' },
        root_markers = { '.clang-format' },
      },
      pyright = {},
      lua_ls = {
        settings = {
          Lua = {
            completion = { callSnippet = 'Replace' },
          },
        },
      },
    }

    -- Mason setup
    require('mason').setup()

    -- Ensure tools are installed
    local ensure_installed = vim.tbl_keys(servers or {})
    vim.list_extend(ensure_installed, { 'stylua' })
    require('mason-tool-installer').setup { ensure_installed = ensure_installed }

    -- Setup LSP servers using Neovim 0.11 APIs
    for server_name, server_config in pairs(servers) do
      local config = vim.tbl_deep_extend('force', { capabilities = capabilities }, server_config)
      config.root_markers = server_config.root_dir and { server_config.root_dir(vim.fn.expand '%:p') } or nil
      config.enable = function(client, bufnr)
        if server_name == 'clangd' then
          return vim.fn.filereadable(vim.fn.getcwd() .. '/compile_commands.json') == 1
        end
        return true
      end
      vim.lsp.config(server_name, config)
      require('mason-lspconfig').setup {}
    end
  end,
}
