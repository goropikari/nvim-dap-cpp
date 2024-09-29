local M = {}

local dap = require('dap')

---@class PluginConfiguration
---@field cpptools table<string,string>
---@field configurations table

---@type PluginConfiguration
---@diagnostic disable-next-line
local internal_global_config = {}

local default_config = {
  cpptools = {
    path = vim.fn.stdpath('data') .. '/cpptools/extension/debugAdapters/bin/OpenDebugAD7',
    version = 'latest',
    platform = 'linux-x64',
    -- {
    --   "win32-x64": "Windows x64",
    --   "win32-arm64": "Windows ARM",
    --   "linux-x64": "Linux x64",
    --   "linux-arm64": "Linux ARM64",
    --   "linux-armhf": "Linux ARM32",
    --   "darwin-x64": "macOS Intel",
    --   "darwin-arm64": "macOS Apple Silicon",
    --   "alpine-x64": "Alpine Linux 64 bit",
    --   "alpine-arm64": "Alpine Linux ARM64",
    --   "win32-ia32": "Windows ia32"
    -- }
  },
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
  if vim.bo.filetype == 'cpp' then
    return { 'g++', '-g', '-O0', vim.fn.expand('%'), '-o', vim.fn.expand('%:r') }
  elseif vim.bo.filetype == 'c' then
    return { 'gcc', '-g', '-O0', vim.fn.expand('%'), '-o', vim.fn.expand('%:r') }
  end
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
    command = plugin_config.cpptools.path,
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
      name = 'Build and debug active file',
      type = 'cppdbg',
      request = 'launch',
      program = '${fileDirname}/${fileBasenameNoExtension}',
      build = default_build(),
      cwd = '${fileDirname}',
    },
    {
      name = 'Build and debug active file with arguments',
      type = 'cppdbg',
      request = 'launch',
      program = '${fileDirname}/${fileBasenameNoExtension}',
      cwd = '${fileDirname}',
      build = default_build(),
      args = get_arguments,
    },
    {
      name = 'Build and debug active file (gdb dap)',
      type = 'gdbdbg',
      request = 'launch',
      program = '${fileDirname}/${fileBasenameNoExtension}',
      build = default_build(),
    },
  }

  vim.list_extend(dap.configurations.cpp, common_configurations)
  vim.list_extend(dap.configurations.cpp, plugin_config.configurations)

  dap.configurations.c = dap.configurations.c or {}
  vim.list_extend(dap.configurations.c, dap.configurations.cpp)
end

function M.setup(opts)
  internal_global_config = vim.tbl_deep_extend('force', default_config, opts or {})
  setup_adapter(internal_global_config)
  setup_dap_configurations(internal_global_config)
end

function M.get_config()
  return internal_global_config
end

local plenary_ok, async = pcall(require, 'plenary.async')
if plenary_ok then
  local async_system = async.wrap(vim.system, 3)

  local function get_cpptools_versions()
    local obj = async_system({ 'curl', '-L', 'https://api.github.com/repos/microsoft/vscode-cpptools/releases' })
    local versions = {}
    for _, v in ipairs(vim.json.decode(obj.stdout)) do
      _, _, v = string.find(v.tag_name, '(%d+.%d+.%d+)')
      table.insert(versions, v)
    end
    return versions
  end

  local function _install_cpptools(version)
    local publisher = 'ms-vscode'
    local platform = internal_global_config.cpptools.platform
    local url = string.format(
      'http://%s.gallery.vsassets.io/_apis/public/gallery/publisher/%s/extension/cpptools/%s/assetbyname/Microsoft.VisualStudio.Services.VSIXPackage?targetPlatform=%s',
      publisher,
      publisher,
      version,
      platform
    )
    async_system({ 'curl', '-L', url, '-o', vim.fn.stdpath('data') .. '/cpptools.vsix' })
    async_system({ 'unzip', '-o', '-d', vim.fn.stdpath('data') .. '/cpptools', vim.fn.stdpath('data') .. '/cpptools.vsix' })
    async_system({ 'chmod', '+x', vim.fn.stdpath('data') .. '/cpptools/extension/debugAdapters/bin/OpenDebugAD7' })
  end

  function M.install_cpptools(version)
    local ver = version or internal_global_config.cpptools.version
    vim.notify('installing cpptools ' .. internal_global_config.cpptools.version)
    async.void(function()
      if ver == 'latest' then
        ver = get_cpptools_versions()[1]
      end
      _install_cpptools(ver)
      vim.notify('installed cpptools')
    end)()
  end
end

return M
