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
    -- rounded borders for all floats (hover, signature, diagnostics) via native 0.11+ option
    vim.o.winborder = 'rounded'

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
        if client and client:supports_method 'textDocument/documentHighlight' then
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

        if client and client:supports_method 'textDocument/inlayHint' then
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
    -- advertise foldingRange so nvim-ufo can use LSP folds
    capabilities.textDocument.foldingRange = {
      dynamicRegistration = false,
      lineFoldingOnly = true,
    }

    local servers = {
      clangd = {
        cmd = {
          'clangd',
          '--background-index',
          '--clang-tidy',
          '--header-insertion=never',
          '--completion-style=detailed',
          '--function-arg-placeholders=true',
          '--fallback-style=llvm',
          '--experimental-modules-support',
        },
        -- Only start clangd when compile_commands.json exists in project root.
        -- Previously used config.enable (dead code — native vim.lsp ignores it).
        root_dir = function(bufnr, on_dir)
          local root = vim.fs.root(bufnr, { 'compile_commands.json' })
          if root then on_dir(root) end
        end,
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
      ruff = {
        init_options = {
          settings = {
            organizeImports = true,
            fixAll = true,
            format = { preview = true },
          },
        },
      },
      ty = {
        settings = {
          ty = {
            showSyntaxErrors = false,
          },
        },
      },
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

    vim.lsp.log.set_level 'off'

    -- Register all server configs (Neovim 0.11+ API).
    -- vim.lsp.config() only registers — does NOT start servers.
    for server_name, server_config in pairs(servers) do
      local config = vim.tbl_deep_extend('force', { capabilities = capabilities }, server_config)
      vim.lsp.config(server_name, config)
    end

    -- Enable all configured servers explicitly (Neovim 0.11+ API).
    -- Previously relied on mason-lspconfig's automatic_enable side effect.
    vim.lsp.enable(vim.tbl_keys(servers))
  end,
}
