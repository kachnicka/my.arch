return {
  'windwp/nvim-autopairs',
  event = 'InsertEnter',
  config = function()
    require('nvim-autopairs').setup {}
    -- blink.cmp handles auto-brackets natively via accept.auto_brackets.
    -- Old cmp.event:on('confirm_done') handler removed — incompatible with blink.
  end,
}
