return {
  {
    'seblyng/roslyn.nvim',
    ft = 'cs',
    opts = {
      filewatching = 'auto',
      broad_search = false,
      lock_target = false,
    },
    init = function()
      vim.env.ROSLYN_LANGUAGE_SERVER_DAEMON_KEEPALIVE = '0'
      vim.lsp.config('roslyn', {
        settings = {
          ['csharp|inlay_hints'] = {
            csharp_enable_inlay_hints_for_implicit_object_creation = true,
            csharp_enable_inlay_hints_for_implicit_variable_types = true,
            csharp_enable_inlay_hints_for_lambda_parameter_types = true,
            csharp_enable_inlay_hints_for_types = true,
            dotnet_enable_inlay_hints_for_indexer_parameters = true,
            dotnet_enable_inlay_hints_for_literal_parameters = true,
            dotnet_enable_inlay_hints_for_object_creation_parameters = true,
            dotnet_enable_inlay_hints_for_other_parameters = true,
            dotnet_enable_inlay_hints_for_parameters = true,
            dotnet_suppress_inlay_hints_for_parameters_that_differ_only_by_suffix = true,
            dotnet_suppress_inlay_hints_for_parameters_that_match_argument_name = true,
            dotnet_suppress_inlay_hints_for_parameters_that_match_method_intent = true,
          },
          ['csharp|completion'] = {
            dotnet_show_completion_items_from_unimported_namespaces = true,
          },
          ['csharp|formatting'] = {
            dotnet_organize_imports_on_format = true,
          },
          ['csharp|code_lens'] = {
            dotnet_enable_references_code_lens = true,
          },
          ['navigation'] = {
            dotnet_navigate_to_decompiled_sources = true,
          },
        },
      })
    end,
    config = function(_, opts)
      require('roslyn').setup(opts)
      vim.lsp.commands['roslyn.client.peekReferences'] = function(command)
        local uri, pos = unpack(command.arguments)
        vim.lsp.util.show_document({ uri = uri, range = { start = pos, ['end'] = pos } }, 'utf-16', { focus = true })
        require('fzf-lua').lsp_references()
      end
    end,
  },
}
