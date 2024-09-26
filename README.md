# nvim-dap-cpp

[nvim-dap][1] plugin for c, cpp.

## setup
Download cpptools vsix from [marketplace][2].

```bash
mv {downloaded/cpptools.vsix} ~/.local/share/nvim/cpptools-linux.vsix
cd ~/.local/share/nvim
unzip cpptools-linux.vsix -d cpptools
chmod +x ./cpptools/extension/debugAdapters/bin/OpenDebugAD7
```

## Installation

[`lazy.nvim`][3]

```lua
{
  'goropikari/nvim-dap-cpp',
  dependencies = { 'mfussenegger/nvim-dap' },
  opts = {
    cpptools = {
      path = vim.fn.stdpath('data') .. '/cpptools/extension/debugAdapters/bin/OpenDebugAD7',
    },
    configurations = {},
  },
  ft = { 'c', 'cpp' },
}
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
