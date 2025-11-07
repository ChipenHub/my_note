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





需要的依赖

## 依赖分类总结

- **必需**：
  
  - build-essential
  
  - meson, ninja-build, pkg-config
  
  - libnuma-dev

- **强烈推荐**（编译例子和常见驱动需要）：
  
  - libpcap-dev
  
  - libelf-dev
  
  - libbsd-dev

- **可选**（功能扩展）：
  
  - libjansson-dev（telemetry）
  
  - libarchive-dev（归档工具）
  
  - libssl-dev（crypto PMD）
  
  - python3-pyelftools（分析工具）
  
  ```shell
  sudo apt update
  sudo apt install build-essential meson ninja-build pkg-config \
                   libnuma-dev libpcap-dev libelf-dev \
                   libbsd-dev libjansson-dev libarchive-dev \
                   libssl-dev python3-pyelftools
  ```

检查安装是否完成：

```shell
# 这两条都能正常输出而不是报错
pkg-config --cflags libdpdk
pkg-config --libs libdpdk
```



系统配置巨页：写入`vm.nr_hugepages=512   # 2MB页，约1GB`

应用：`sudo sysctl --system`

**或者写进旧版配置文件 （`/etc/sysctl.conf`）**

应用：`sudo sysctl -p`



检查输出：`cat /proc/meminfo | grep Huge`



测试运行 l2fwd：`sudo ./l2fwd-shared -l 0-3 -n 1 -- -p 1 -P`



CMakeFiles:

```cpp
chipen@ubuntu:~$ cat CMakeLists.txt
# 指定 CMake 最低版本要求
cmake_minimum_required(VERSION 3.10)

# 定义项目名称和语言
project(tstack C)

# 查找 pkg-config（因为我们需要用它来获取 DPDK 的信息）
find_package(PkgConfig REQUIRED)

# 使用 pkg-config 查找 libdpdk
pkg_check_modules(DPDK REQUIRED libdpdk)

# 添加可执行文件
add_executable(ustack tstack.c arp.h)

# 链接 DPDK 库并设置编译选项
target_include_directories(ustack PRIVATE ${DPDK_INCLUDE_DIRS})
target_link_libraries(ustack PRIVATE ${DPDK_LIBRARIES})
target_compile_options(ustack PRIVATE ${DPDK_CFLAGS})
```
