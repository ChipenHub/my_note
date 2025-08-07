# DPDK 零基础配置笔记

> DPDK（Data Plane Development Kit，数据面开发工具包）是一个高性能数据包处理库，主要用于绕过 Linux 内核网络协议栈，直接在用户空间对网卡收发的数据进行操作，以此实现极高的数据吞吐。
> DPDK 的核心价值是：**使用轮询 + 巨页内存 + 用户态驱动，提升网络收发性能**。
> 适用场景：高频交易、软件路由器、防火墙、负载均衡器等对网络性能要求极高的系统。

## 基本数据简要解释

+ **igb_uio**：一种用户态网卡驱动模块（Intel 提供的），DPDK 可以通过它绕过内核协议栈直接操作网卡。

+ **vfio-pci**：另一种用户态驱动方式，比 igb_uio 更现代，需开启 IOMMU 支持（虚拟化设备映射）。

+ **hugepages（巨页内存）**：DPDK 用于分配高速大内存的一种机制，常用 2MB 或 1GB 大页，可减少页表开销。

+ **meson**：现代化构建系统（替代传统的 make），DPDK 自 20.11 起全面改用 meson+ninja 构建。

+ **ninja**：与 meson 搭配使用的高效构建工具。

+ **usertools/dpdk-devbind.py**：DPDK 提供的网卡绑定脚本，可切换网卡使用的驱动。

+ **sk_buff**：由网卡抓取数据到协议栈进行解析的一个 buffer

+ **mbuf**：dpdk 识别的数据包。对应 sk_buff。

- **pf_ring**：轻量级数据包捕获工具，适合简单场景，但性能和灵活性不及 DPDK。
- **Netmap**：高性能用户态网络框架，配置较 DPDK 简单，但功能较少。
- **DPDK**：功能最全面，性能最优，但配置复杂，适合高性能需求场景。 
+ **KNI**：内核网络接口，用于接受网卡数据给 DPDK 处理或处理后的数据将数据发送回内核。如将不需要处理的数据直接写回内核。

+ **NIC**：系统正常调用的与网卡沟通的硬件设备。

## DPDK 优化过程（以网卡接受数据到应用程序为例）

```tex
传统内核路径：
网卡 -> DMA -> sk_buff -> 协议栈 -> copy -> 应用程序 (共 2 次拷贝)

DPDK 路径：
网卡 -> DMA (零拷贝) -> mbuf -> DPDK 应用程序 (仅 1 次拷贝)
```

## 环境搭建教程（以 VMware 虚拟网卡 + Ubuntu 24.10 为例）

**VMware 添加独立虚拟网卡用于 DPDK 通信**

虚拟机设置 -> 网路适配器 -> 添加 -> 桥接模式 -> 进入配置文件
-> 将新网卡的 "e1000" 单队列网卡更改为 "vmxnet3" 多队列网卡 -> 配置完成

**巨页设置/挂载**

DPDK需要大页内存来提高性能。
想要访问设置的巨页信息，就必须将巨页文件系统挂载。
**原因**：内核配置文件分配的巨页内存存在于内核中，用户态的 DPDK 只有通过挂载的 `hugetlbfs` 才能访问。

```shell
chipen@ubuntu:~$ tail -1 /etc/sysctl.conf
vm.nr_hugepages = 256	# 设置巨页大小, 条件允许的话, 1024 以上为宜
chipen@ubuntu:~$ sudo sysctl -p 
vm.nr_hugepages = 256
chipen@ubuntu:~$ cat /proc/meminfo | grep Huge	# 查看巨页信息
AnonHugePages:         0 kB
ShmemHugePages:        0 kB
FileHugePages:         0 kB
HugePages_Total:     256
HugePages_Free:      256
HugePages_Rsvd:        0
HugePages_Surp:        0
Hugepagesize:       2048 kB
Hugetlb:          524288 kB
chipen@ubuntu:~$ sudo mkdir -p /mnt/huge	# 挂载巨页
chipen@ubuntu:~$ sudo mount -t hugetlbfs none /mnt/huge
chipen@ubuntu:~$ mount | grep hugetlbfs		# 验证巨页挂载情况
hugetlbfs on /dev/hugepages type hugetlbfs (rw,nosuid,nodev,relatime,pagesize=2M)
```

值得一提的是：目前常见的旧版本 DPDK 中安装只需要简单的选项或脚本配置巨页，vfio，KNI等，最新版本去除了这个功能，使得配置的难度更大了。

**DPDK 绑定虚拟网卡（关键）**

DPDK 程序工作的核心。

```shell
chipen@ubuntu:~/DPDK/dpdk-25.03.tar/dpdk-25.03/usertools$ ./dpdk-devbind.py --status
# 检查当前网卡状态
Network devices using kernel driver
===================================
0000:02:01.0 '82545EM Gigabit Ethernet Controller (Copper) 100f' if=ens33 drv=e1000 unused= *Active*
0000:03:00.0 'VMXNET3 Ethernet Controller 07b0' if=ens160 drv=vmxnet3 unused= # 即将用于绑定的网卡
...
chipen@ubuntu:~/DPDK/dpdk-25.03.tar/dpdk-25.03/usertools$ sudo modprobe vfio-pci # 加载 vfio 模块
chipen@ubuntu:~/DPDK/dpdk-25.03.tar/dpdk-25.03/usertools$ sudo ./dpdk-devbind.py --bind=vfio-pci --noiommu-mode 03:00.0	# 使用 --noiommu-mode 绕过 IOMMU 要求 （虚拟机必要）
Warning: enabling unsafe no IOMMU mode for VFIO drivers	# 提示不安全
chipen@ubuntu:~/DPDK/dpdk-25.03.tar/dpdk-25.03/usertools$ ./dpdk-devbind.py --status
# 绑定完成
Network devices using DPDK-compatible driver
============================================
0000:03:00.0 'VMXNET3 Ethernet Controller 07b0' drv=vfio-pci unused=vmxnet3

Network devices using kernel driver
===================================
0000:02:01.0 '82545EM Gigabit Ethernet Controller (Copper) 100f' if=ens33 drv=e1000 unused=vfio-pci *Active*
chipen@ubuntu:~/DPDK/dpdk-25.03.tar/dpdk-25.03/examples/l2fwd/build$ sudo ./l2fwd-shared -l 0-1 -n 4 -- -p 0x1
EAL: Detected CPU lcores: 4
...	# 测试用例正常执行
Total packets sent:                  0
Total packets received:              0
Total packets dropped:               0
====================================================
```

**注意**：对于 `./l2fwd-shared -l 0-1 -n 4 -- -p 0x1`，其具体含义为；

+ **`-l`** 参数是用来指定 DPDK 程序在哪些 **逻辑核心（CPU 核心）** 上运行的。

+ **`0-1`** 表示使用 **核心 0 和核心 1** 来运行程序。你可以选择使用多个核心来并行处理任务。

+ ### **`-n 4`**

  - **`-n`** 参数是用来指定 **内存通道（memory channel）** 的数量。
  - **`4`** 表示使用 **4 个内存通道**。内存通道类似于多路并行的数据流，增加通道可以提高内存的吞吐量。

- **`-p`** 参数是用来指定 **要使用的网卡端口**，它告诉程序哪些网卡端口需要启用。
- **`0x1`** 是一个 **端口掩码（port mask）**，它表示一个 **二进制数**，用于选择启用哪些网卡端口。
  - **`0x1`** 是 **16 进制** 数字，等价于 **二进制 0001**，表示使用 **端口 0**。
  - 如果你有多个网卡端口，可以用不同的位来表示多个端口，例如：
    - **`0x3`** 表示端口 0 和端口 1（即 0001 | 0010）。
    - **`0x7`** 表示端口 0、端口 1 和端口 2（即 0001 | 0010 | 0100）。

**只有绑定了 DPDK 的网卡才会有逻辑端口！！**

验证（可选）：查看 DPDK 给虚拟网卡分配的端口号。

```shell
# 方法：进入 testpmd，testpmd 是 DPDK 提供的测试工具，可以显示绑定的网卡及其对应的逻辑端口。
chipen@ubuntu:~/DPDK/dpdk-25.03.tar/dpdk-25.03/usertools$ sudo ~/DPDK/dpdk-25.03.tar/dpdk-25.03/build/app/dpdk-testpmd -l 0-1 -n 4 -- -i
EAL: Detected CPU lcores: 4
EAL: Detected NUMA nodes: 1
...
Done
testpmd> show port summary all
Number of available ports: 1
Port MAC Address       Name         Driver         Status   Link
0    00:0C:29:0C:66:1A 0000:03:00.0 net_vmxnet3    up       10 Gbps
^ 可见，当前 PCI 为 0000:03:00.0 的网卡，DPDK 给其分配的端口号为 0。
testpmd> quit	# 退出

Stopping port 0...
...
Done

Bye...
```

 **注意**：目前网上大多数教程都是较老的版本（例如 20.11 或更早）。其依赖的是 `usertools` 下的启动脚本 `dpdk-setup.sh` 交互式步骤。每次开机需要重新执行。对于古老版本可能存在编译器不兼容的问题，特此用最新版本（25.03）编写配置教程仅供入门学习参考。

