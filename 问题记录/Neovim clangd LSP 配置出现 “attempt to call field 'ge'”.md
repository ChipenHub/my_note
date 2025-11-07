# Neovim clangd LSP 配置出现 “attempt to call field 'ge'”

## 一、问题发现

在配置 Neovim 使用 `lazy.nvim` 管理插件，并尝试加载 `clangd` LSP 时，启动 Neovim 并打开 C/C++ 文件出现如下报错：

```
Failed to source `/home/chipen/.local/share/nvim/lazy/nvim-lspconfig/plugin/lspconfig.lua`
vim/_editor.lua:341: BufReadPre Autocommands for "*"..script nvim_exec2() called ...
...: attempt to call field 'ge' (a nil value)
```

在尝试使用 `pcall(require, "lspconfig")` 时，返回的值不是期望的 LSP 配置模块，而是一个包含 `set` 和 `del` 函数地址的 table。

---

## 二、问题分析

1. **初步判断**
   
   - 报错信息显示 `"attempt to call field 'ge' (a nil value)"`，说明某个函数调用不存在。
   
   - 初步怀疑是配置文件中有手误，将 `vim.keymap.set` 写成了 `vim.keymap.ge`，或者插件缓存被破坏。

2. **排查插件配置**
   
   - 检查 `~/.config/nvim/lua/plugins/lsp.lua` 文件，确认文件名与模块名一致（全小写 `lsp.lua`）。
   
   - 清理 `~/.local/share/nvim/lazy/nvim-lspconfig` 并重新同步插件，但报错仍然存在。

3. **排查 Neovim 版本**
   
   - 检查 Neovim 版本：`NVIM v0.9.5`。
   
   - 报错堆栈中显示：
     
     ```
     nvim-lspconfig requires Nvim version 0.10, but you are running: 0.9.5
     ```
   
   - 说明问题根源在于 **插件版本与 Neovim 版本不兼容**。
     
     - 最新的 `nvim-lspconfig` 已经要求 Neovim >= 0.10。
     
     - 在 0.9.5 下调用其内部 API（如 `nvim_exec2`）会报错，导致 `"ge"` 之类的函数错误。
   
   - `apt install` 从这个新增的仓库下载安装软件，更新到比官方源更新的版本。    

5- 升级 Neovim 到 >=0.10

```bash
sudo add-apt-repository ppa:neovim-ppa/unstable -y
sudo apt update
sudo apt install neovim -y
```

- `add-apt-repository` 将外部 PPA（Personal Package Archive）注册到系统 APT 源中。

---

## 三、问题解决

**升级 Neovim**

- 使用 PPA 安装 Neovim 0.10+ 或更新版本，满足 `nvim-lspconfig` 的最低版本要求。

- 确认升级后：
  
  ```bash
  nvim --version
  ```
  
  输出为 `NVIM v0.10.x` 或更高。
