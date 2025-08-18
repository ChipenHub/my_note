### 1. **为什么 `make` 报错：`no installation of DPDK found`**

- DPDK 是源码包，你下载的只是源码，还没有编译和安装。

- 你直接去 `examples/helloworld` 下执行 `make`，它会去找系统里安装好的 DPDK 库，但没找到，所以报错。

---

### 2. **为什么需要 `pkg-config`**

- `pkg-config` 用来告诉编译器 DPDK 的头文件路径和库路径。

- 报错 `/bin/sh: 1: pkg-config: not found` 说明你没安装 `pkg-config`。

- 解决：`sudo apt install pkg-config`

---

### 3. **为什么需要 `meson + ninja`**

- 新版 DPDK（20.11+）不再用 `make` 编译库，而是用 **meson/ninja**。

- 流程是：
  
  1. `meson setup build` 生成编译配置。
  
  2. `ninja -C build` 编译生成 `.so` / `.a` 等库。
  
  3. `sudo ninja -C build install` 安装到 `/usr/local/lib`、`/usr/local/include`。
  
  4. `sudo ldconfig` 刷新系统动态库缓存。

---

### 4. **为什么要 `sudo ldconfig`**

- `ldconfig` 会扫描 `/lib`, `/usr/lib`, `/usr/local/lib` 等目录，把库文件路径写进缓存。

- 这样程序运行时才能自动找到 `libdpdk.so`。

- 你的输出显示 `/usr/local/lib` 是合法路径，但因为你还没安装 DPDK，所以里面没东西，所以提示 "Can't stat" 某些目录。

---

### 5. **Python3 依赖**

- DPDK 的编译工具链（meson/ninja）本身需要 Python3。

- Ubuntu 20.04+ 默认就有 Python3，你的系统大概率已经安装了。

- 你可以运行 `python3 --version` 验证。

---

### 6. **正确的编译 DPDK example 流程**

1. 安装依赖：
   
   ```bash
   sudo apt update
   sudo apt install build-essential meson ninja-build pkg-config python3
   ```

2. 编译 DPDK：
   
   ```bash
   cd dpdk-24.11.2
   meson setup build
   ninja -C build
   sudo ninja -C build install
   sudo ldconfig
   ```

3. 编译 example：
   
   ```bash
   cd examples/helloworld
   make
   ```
   
   → 这时 `make` 能找到系统安装的 DPDK 库，就能编译通过。
