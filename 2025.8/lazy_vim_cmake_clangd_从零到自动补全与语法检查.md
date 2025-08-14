# 目标

把一台全新机器（Windows/WSL 或 Ubuntu）从 “没有 Neovim” 配到 “在 LazyVim 中，能基于 **CMakeLists.txt** 自动生成编译数据库 `compile_commands.json`，让 **clangd** 做语法检查、代码跳转、智能补全，并且可一键 **生成/编译/运行/调试**”。

---

## 一、术语与路线图

- **Neovim**：编辑器本体。
- **lazy.nvim**：插件管理器。
- **LazyVim**：基于 lazy.nvim 的现成配置（省去大量手搓配置）。
- **clangd**：C/C++ LSP 服务器，提供补全/跳转/诊断；它依赖 `compile_commands.json` 来知道你的 **include 路径、宏、编译选项**。
- **CMake**：构建系统；通过打开 `CMAKE_EXPORT_COMPILE_COMMANDS` 选项即可生成 `compile_commands.json`。
- **cmake-tools.nvim**：Neovim 的 CMake 集成插件，可在编辑器里 **生成/编译/运行**，还能**自动软链/复制** `compile_commands.json` 到工程根目录，方便 clangd 读取。

**路线图**：

1. 装 Neovim → 2) 装 LazyVim（自带 lazy.nvim）→ 3) 系统依赖（CMake/Clang/工具）→ 4) 在 LazyVim 启用 C/C++ & CMake 支持 → 5) 生成 `compile_commands.json`（CMake 或 Bear）→ 6) 在 Neovim 内编译/运行/调试 → 7) 验证与排错。

---

## 二、安装 Neovim

> 需要 Neovim **0.10+**（建议最新稳定版）。

### A. Ubuntu / WSL(Ubuntu)

```bash
# 推荐使用官方 PPA 安装最新稳定版
sudo apt update
sudo apt install -y software-properties-common
sudo add-apt-repository -y ppa:neovim-ppa/stable
sudo apt update
sudo apt install -y neovim

# 验证版本
nvim --version
```

### B. Windows（原生）

1. 到 Neovim Releases 下载并安装（MSI/Zip）。
2. 安装后在 PowerShell/CMD 执行 `nvim --version` 验证。

> **建议**：Windows 下做 C/C++ 更省心的方式是 **WSL (Ubuntu)**，把代码放在 WSL 的 Linux 路径（`/home/<you>/...`），在 WSL 里装工具链并运行 `nvim`。

---

## 三、系统依赖（C/C++ & CMake）

### Ubuntu / WSL

```bash
sudo apt update
sudo apt install -y git curl build-essential cmake ninja-build pkg-config \
  clang clangd gdb bear ripgrep fd-find unzip

# 某些发行版只有 clangd-XX，可选：
# sudo apt install -y clangd-18   # 例
# sudo update-alternatives --install /usr/bin/clangd clangd /usr/bin/clangd-18 100
```

### Windows（原生）

- 装 **LLVM/Clang**（包含 clangd）、**CMake**、**Ninja**、**Git**。
- 或通过 **winget**：

```powershell
winget install LLVM.LLVM
winget install Kitware.CMake
winget install Ninja-build.Ninja
winget install Git.Git
```

---

## 四、安装 LazyVim（含 lazy.nvim）

> LazyVim 自带了合理的 LSP/UI/键位等基础配置。我们基于它扩展 C/C++ 与 CMake。

### Linux / macOS / WSL

```bash
# 1) 备份旧配置（强烈建议）
mv ~/.config/nvim{,.bak}
mv ~/.local/share/nvim{,.bak}
mv ~/.local/state/nvim{,.bak}
mv ~/.cache/nvim{,.bak}

# 2) 克隆 Starter
git clone https://github.com/LazyVim/starter ~/.config/nvim
rm -rf ~/.config/nvim/.git

# 3) 启动一次，自动拉插件
nvim

# 4) 进入后运行健康检查（首次加载完插件再执行）
:LazyHealth
```

### Windows（PowerShell）

```powershell
Move-Item $env:LOCALAPPDATA\nvim $env:LOCALAPPDATA\nvim.bak -ErrorAction SilentlyContinue
Move-Item $env:LOCALAPPDATA\nvim-data $env:LOCALAPPDATA\nvim-data.bak -ErrorAction SilentlyContinue

git clone https://github.com/LazyVim/starter $env:LOCALAPPDATA\nvim
Remove-Item $env:LOCALAPPDATA\nvim\.git -Recurse -Force

nvim
```

> 如果你更喜欢“从零”配置，也可以直接在 `~/.config/nvim/lua/config/lazy.lua` 里按 **lazy.nvim** 官方文档自举并添加插件；本教程以 LazyVim Starter 为例。

---

## 五、启用 C/C++ 与 CMake 支持（LazyVim Extras）

LazyVim 提供 **Extras**，一键导入 C/C++ 与 CMake 的整套配置：

1. 打开 Neovim，执行：
   
   ```vim
   :LazyExtras
   ```
2. 勾选并导入：
   - **lang.clangd**（为 C/C++ 配好 treesitter、clangd、clangd-extensions、nvim-cmp 等）
   - **lang.cmake**（为 CMake 配好 treesitter、neocmake、cmake-tools.nvim 等）
3. 保存并重启 Neovim（或 `:Lazy sync`）。

> **手动方式（可选）**：若你不想用 `:LazyExtras`，也可在 `~/.config/nvim/lua/plugins/` 新建 `extras.lua`，写入：

```lua
return {
  { import = "lazyvim.plugins.extras.lang.clangd" },
  { import = "lazyvim.plugins.extras.lang.cmake" },
}
```

重启后 `:Lazy` 即会安装/激活相关插件。

---

## 六、用 Mason 安装工具（LSP/调试/格式化）

在 Neovim 中：

```vim
:Mason        " 打开 Mason UI
```

安装（或确认已安装）：

- **clangd**（C/C++ LSP）
- **codelldb**（C/C++ 调试适配器，配合 `nvim-dap` 使用）
- **cmakelang / cmakelint**（CMake 语法高亮/诊断，可选）

> 也可以使用系统自带的 `clangd`。若同时存在 Mason 版与系统版，通常无需强制切换；如需指定，可在 `lspconfig` 的 `cmd` 里给出绝对路径。

---

## 七、让 clangd 读懂你的工程（生成 compile\_commands.json）

### 方法 1：**纯 CMake**（推荐，最稳）

在工程根目录运行：

```bash
# 以单独的 build 目录为例（推荐）
cmake -S . -B build -G Ninja -DCMAKE_EXPORT_COMPILE_COMMANDS=ON -DCMAKE_BUILD_TYPE=Debug
cmake --build build -j

# 让 clangd 在工程根就能“看见”
ln -sf build/compile_commands.json ./
```

> 解释：`CMAKE_EXPORT_COMPILE_COMMANDS=ON` 会让 CMake 在 **build 目录** 生成 `compile_commands.json`。clangd 会从源文件向上查找该文件；软链到根目录最省心。

### 方法 2：**cmake-tools.nvim 自动化**（省时）

安装并启用 `cmake-tools.nvim` 后，它默认在 `CMakeGenerate` 时加上 `-DCMAKE_EXPORT_COMPILE_COMMANDS=1`，并可自动**软链/复制** `compile_commands.json` 到工程根：

- 全局配置（LazyVim 的 CMake Extra 已处理，以下为示意）

```lua
require("cmake-tools").setup({
  cmake_regenerate_on_save = true,
  cmake_generate_options = { "-DCMAKE_EXPORT_COMPILE_COMMANDS=1" },
  cmake_compile_commands_options = {
    action = "soft_link",   -- 可选：soft_link | copy | lsp | none
    target = vim.loop.cwd(), -- 软链/复制到工程根
  },
})
```

- 在 Neovim 里执行：

```vim
:CMakeGenerate     " 首次配置（或改完 CMakeLists.txt）
:CMakeBuild        " 编译
:CMakeRun          " 运行（可配目标）
```

> 配置/构建目录一般默认为 `out/<BuildType>`；可用 `:CMakeSelectBuildType`、`:CMakeSelectKit`、`:CMakeSelectBuildTarget` 等命令切换。

### 方法 3：**非 CMake 项目**（或遗留 Makefile）

用 **Bear** 录制编译命令：

```bash
bear -- make -j
# 生成 compile_commands.json 于当前目录
```

---

## 八、在 Neovim 里“像 IDE 一样”工作

> 前提：`compile_commands.json` 已就位；打开工程后 clangd 应自动附着。

- **检查 LSP 状态**：
  
  ```vim
  :LspInfo
  ```
  
  看到 `clangd` attached 即正常。

- **常用键位（LazyVim 默认）**：
  
  - `gd` 跳转定义，`gr` 引用，`gD` 声明，`K` 悬停文档。
  - `<leader>ca` 代码动作，`[d`/`]d` 诊断导航。
  - `<leader>ch` 在源/头文件间切换（clangd-extensions）。

- **补全**：由 `nvim-cmp` + `clangd` 提供；在输入时自动弹出。

- **格式化 & 代码规范**：
  
  - clangd 默认启用 `--clang-tidy`（LazyVim Clangd Extra 已设）；在工程根放 `.clang-tidy`、`.clang-format` 即可生效。

- **生成/编译/运行/调试**（cmake-tools.nvim + nvim-dap + codelldb）：
  
  - `:CMakeGenerate` / `:CMakeBuild` / `:CMakeRun`
  - 调试：执行 `:CMakeDebug`，或 `:DapContinue`；若提示可执行文件路径，选择 `build` 目录下的目标产物。

---

## 九、验证流程（一步步自测）

1. 新建最小工程（见附录）。
2. `cmake -S . -B build -DCMAKE_EXPORT_COMPILE_COMMANDS=ON && ln -sf build/compile_commands.json .`
3. 打开 `nvim .`，等待插件加载完成。
4. `:LspInfo` 看到 `clangd` attached。
5. 在 `main.cpp` 输入 `std::`，应出现补全；跳转 `gd`/`gr` 正常；保存时无异常诊断。
6. `:CMakeGenerate` → `:CMakeBuild` → （可选）`:CMakeRun`/`:CMakeDebug`。

---

## 十、常见问题排查（FAQ）

- **没有补全/跳转**：
  
  - 检查 `:LspInfo` 是否有 `clangd`；若没有，多半是 `compile_commands.json` 未就位或工程根识别有误。
  - 软链 `ln -sf build/compile_commands.json .` 到工程根；或在 clangd 启动参数加 `--compile-commands-dir=build`（高阶用法，通常不必）。

- **找不到系统头/第三方头**：
  
  - 确保 `compile_commands.json` 中的编译命令包含正确的 `-I`/`-isystem`/`--sysroot` 等；对 CMake 项目，通常由 toolchain/preset 自动解决。

- **多构建目录/多配置（Debug/Release）**：
  
  - 推荐只对**当前工作配置**软链 `compile_commands.json` 到根目录；切换 BuildType 后重新生成/更新软链。

- **Windows 原生编译**：
  
  - 用 MSVC 时建议改用 `clang-cl`/`clang` 或确保 `clangd` 的 `--query-driver` 覆盖你的编译器路径（涉及复杂度较高，WSL 更省心）。

- **clangd 版本太旧**：
  
  - 用发行版仓库装到新版本（如 `clangd-18/19/20`），或到 LLVM 官方仓库安装新版；必要时用 `update-alternatives` 设为默认。

- **CMake Presets**：
  
  - `cmake-tools.nvim` 支持 `CMakePresets.json`，建议集中管理工具链、生成器、变量与构建目录，团队协作更一致。

---

## 十一、最小可运行示例

```text
hello-cpp/
├─ CMakeLists.txt
├─ main.cpp
```

**CMakeLists.txt**

```cmake
cmake_minimum_required(VERSION 3.16)
project(hello-cpp LANGUAGES CXX)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
add_executable(hello main.cpp)
```

**main.cpp**

```cpp
#include <iostream>
#include <vector>

int main() {
  std::vector<int> v{1,2,3};
  std::cout << "size=" << v.size() << "\n";
  return 0;
}
```

**生成与软链**

```bash
cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Debug
cmake --build build -j
ln -sf build/compile_commands.json .
```

打开 `nvim`，应当具备补全/跳转/诊断；`:CMakeRun` 能直接运行。

---

## 十二、可选增强

- **更强的错误列表/任务面板**：`stevearc/overseer.nvim`（cmake-tools 可集成）。
- **更丝滑的终端**：`akinsho/toggleterm.nvim`（cmake-tools 可集成）。
- **测试框架**：`nvim-neotest/neotest` + `nvim-neotest/neotest-google-test` 等。
- **代码片段**：`L3MON4D3/LuaSnip` + C/C++ 片段库。
- **UI 与导航**：`telescope.nvim` / `flash.nvim` / `trouble.nvim` 等。

---

## 十三、键位备忘（与 LazyVim 默认保持一致）

- `gd` 定义，`gD` 声明，`gr` 引用，`gi` 实现，`K` 悬停。
- `<leader>ca` 代码动作，`<leader>cr` 重命名。
- `<leader>ch` 源/头切换（clangd-extensions）。
- `]d` / `[d` 诊断导航。
- `:CMakeGenerate` / `:CMakeBuild` / `:CMakeRun` / `:CMakeDebug`。

---

**到这里，你已经完成：**

- Neovim + LazyVim 装好并健康；
- C/C++ + CMake 支持（Treesitter/LSP/诊断/补全/调试）齐活；
- `compile_commands.json` 自动生成且被 clangd 读取；
- 在 Neovim 里能一键生成/编译/运行/调试。
