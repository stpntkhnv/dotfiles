return {
  'mistweaverco/kulala.nvim',
  ft = 'http',
  keys = {
    { '<leader>hr', function() require('kulala').run() end, desc = '[H]TTP [R]un request' },
    { '<leader>ha', function() require('kulala').run_all() end, desc = '[H]TTP run [A]ll requests' },
    { '<leader>hp', function() require('kulala').jump_prev() end, desc = '[H]TTP [P]revious request' },
    { '<leader>hn', function() require('kulala').jump_next() end, desc = '[H]TTP [N]ext request' },
    { '<leader>hi', function() require('kulala').inspect() end, desc = '[H]TTP [I]nspect current request' },
    { '<leader>ht', function() require('kulala').toggle_view() end, desc = '[H]TTP [T]oggle body/headers' },
    { '<leader>hc', function() require('kulala').copy() end, desc = '[H]TTP [C]opy as cURL' },
    { '<leader>he', function() require('kulala').set_selected_env() end, desc = '[H]TTP select [E]nvironment' },
  },
  opts = {
    default_view = 'body',
    default_env = 'dev',
    debug = false,
  },
}
