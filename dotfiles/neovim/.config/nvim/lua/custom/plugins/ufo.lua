return {
  'kevinhwang91/nvim-ufo',
  event = 'BufReadPost',
  dependencies = { 'kevinhwang91/promise-async' },
  config = function()
    vim.o.foldenable = true
    vim.o.foldcolumn = '1'
    vim.o.foldlevel = 99
    vim.o.foldlevelstart = 99
    vim.o.fillchars = 'eob: ,fold: ,foldopen:,foldsep: ,foldclose:'

    local capabilities = vim.lsp.protocol.make_client_capabilities()
    capabilities.textDocument.foldingRange = {
      dynamicRegistration = false,
      lineFoldingOnly = true,
    }
    local language_servers = vim.lsp.get_clients()
    for _, ls in ipairs(language_servers) do
      require('lspconfig')[ls].setup {
        capabilities = capabilities,
      }
    end
    require('ufo').setup()

    vim.keymap.set('n', '<leader>zz', 'za', { desc = 'Fold toggle' })
    vim.keymap.set('n', '<leader>zo', 'zR', { desc = 'Open all folds' })
  end,
}
