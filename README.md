# nvim-dap-cpp

[nvim-dap][1] plugin for c, cpp.

## Installation

[`lazy.nvim`][3]

```lua
{
  'goropikari/nvim-dap-cpp',
  dependencies = {
    'mfussenegger/nvim-dap',
    'nvim-lua/plenary.nvim',
},
  opts = {
    cpptools = {
      path = vim.fn.stdpath('data') .. '/cpptools/extension/debugAdapters/bin/OpenDebugAD7',
      -- for installation command
      version = 'latest',
      platform = 'linux-x64',
    },
    configurations = {},
  },
  ft = { 'c', 'cpp' },
}
```

Install cpptools

```lua
lua require('dap-cpp').install_cpptools()
```

## Setup development environment for this plugin

```bash
npm install -g @devcontainers/cli
devcontainer up --workspace-folder=.
devcontainer exec --workspace-folder=. bash

nvim
```

[1]: https://github.com/mfussenegger/nvim-dap
[2]: https://marketplace.visualstudio.com/items?itemName=ms-vscode.cpptools
[3]: https://github.com/folke/lazy.nvim
