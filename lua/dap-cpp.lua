local M = {}

local dap = require('dap')

---@class PluginConfiguration

---@type PluginConfiguration
local internal_global_config = {}

local default_config = {
  cpptools_path = vim.fn.stdpath('data') .. '/cpptools/extension/debugAdapters/bin/OpenDebugAD7',
  configurations = {},
}

-- https://github.com/leoluz/nvim-dap-go/blob/5511788255c92bdd845f8d9690f88e2e0f0ff9f2/lua/dap-go.lua#L34-L42
---@param prompt string
local function ui_input_list(prompt)
  return coroutine.create(function(dap_run_co)
    local args = {}
    vim.ui.input({ prompt = prompt }, function(input)
      args = vim.split(input or '', ' ')
      coroutine.resume(dap_run_co, args)
    end)
  end)
end

local function get_arguments()
  return ui_input_list('Args: ')
end

local function default_build()
  return { 'g++', '-g', '-O0', vim.fn.expand('%'), '-o', vim.fn.expand('%:r') }
end

local function setup_adapter(plugin_config)
  dap.adapters.gdbdbg = {
    type = 'executable',
    command = 'gdb',
    args = { '-i', 'dap' },
    enrich_config = function(config, on_config)
      local final_config = vim.deepcopy(config)
      local build_command = config.build or default_build()
      vim.fn.system(build_command)
      -- vim.fn.system({ 'g++', '-g', '-O0', vim.fn.expand('%'), '-o', vim.fn.expand('%:r') })
      on_config(final_config)
    end,
  }

  dap.adapters.cppdbg = { -- for vscode cpp debug
    id = 'cppdbg',
    type = 'executable',
    command = plugin_config.cpptools_path,
    enrich_config = function(config, on_config)
      local final_config = vim.deepcopy(config)
      local build_command = config.build or default_build()
      vim.fn.system(build_command)
      on_config(final_config)
    end,
  }
end

local function setup_dap_configurations(plugin_config)
  dap.configurations.cpp = dap.configurations.cpp or {}
  local common_configurations = {
    {
      name = 'g++ - Build and debug active file',
      type = 'cppdbg',
      request = 'launch',
      program = '${fileDirname}/${fileBasenameNoExtension}',
      build = default_build(),
      cwd = '${fileDirname}',
    },
    {
      name = 'g++ - Build and debug active file with arguments',
      type = 'cppdbg',
      request = 'launch',
      program = '${fileDirname}/${fileBasenameNoExtension}',
      cwd = '${fileDirname}',
      build = default_build(),
      args = get_arguments,
    },
    {
      name = 'g++ - Build and debug active file (gdb dap)',
      type = 'gdbdbg',
      request = 'launch',
      program = '${fileDirname}/${fileBasenameNoExtension}',
      build = default_build(),
    },
  }

  vim.list_extend(dap.configurations.cpp, common_configurations)
  vim.list_extend(dap.configurations.cpp, plugin_config.configurations)
end

function M.setup(opts)
  internal_global_config = vim.tbl_deep_extend('force', default_config, opts or {})
  setup_adapter(internal_global_config)
  setup_dap_configurations(internal_global_config)
end

function M.get_config()
  return internal_global_config
end

return M
