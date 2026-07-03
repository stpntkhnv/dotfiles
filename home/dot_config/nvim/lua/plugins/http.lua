-- Keys are scoped to .http buffers (ft = 'http' on each key): outside them
-- the <leader>R mappings simply don't exist, so nothing clashes with git etc.
return {
  'mistweaverco/kulala.nvim',
  ft = 'http',
  keys = {
    { '<leader>Rr', function() require('kulala').run() end, ft = 'http', desc = '[R]EST [R]un request' },
    { '<leader>Ra', function() require('kulala').run_all() end, ft = 'http', desc = '[R]EST run [A]ll requests' },
    { '<leader>Rp', function() require('kulala').jump_prev() end, ft = 'http', desc = '[R]EST [P]revious request' },
    { '<leader>Rn', function() require('kulala').jump_next() end, ft = 'http', desc = '[R]EST [N]ext request' },
    { '<leader>Ri', function() require('kulala').inspect() end, ft = 'http', desc = '[R]EST [I]nspect current request' },
    { '<leader>Rt', function() require('kulala').toggle_view() end, ft = 'http', desc = '[R]EST [T]oggle body/headers' },
    { '<leader>Rc', function() require('kulala').copy() end, ft = 'http', desc = '[R]EST [C]opy as cURL' },
    { '<leader>Re', function() require('kulala').set_selected_env() end, ft = 'http', desc = '[R]EST select [E]nvironment' },
  },
  opts = {
    default_view = 'body',
    default_env = 'dev',
    debug = false,
  },
}
