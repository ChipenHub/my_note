## **第一部分：Windows 虚拟网卡创建指南**

### **1. 原理**

在 Windows 里，“虚拟网卡”本质是由网络驱动在系统网络栈中创建的一个 **软件网卡接口**。它的作用和物理网卡类似，只不过不直接连接到物理硬件，而是通过内核网络驱动与宿主机网络进行交换。  
常见用途：

- **虚拟机网络**（VMware、Hyper-V、VirtualBox）

- **VPN 客户端**

- **网络测试 / 隔离环境**

- **网桥/中继/Host-only 网络**

Windows 下虚拟网卡依赖的机制主要有：

- **NDIS 驱动模型**（Network Driver Interface Specification）——所有网卡驱动基于它实现

- **虚拟交换机 / 虚拟网桥**（Hyper-V vSwitch、VMware vSwitch）

- **TAP/TUN 驱动**（常用于 VPN）

---

### **2. 创建虚拟网卡的几种方法**

#### 方法 A：使用 Hyper-V 创建（适合 WSL2）

**原理**：Hyper-V 创建虚拟交换机时，会自动在 Windows 系统生成一个 `vEthernet (交换机名)` 的虚拟网卡。

**步骤：**

1. 启用 Hyper-V（需要 Windows 专业版/企业版）：
   
   - 控制面板 → 程序 → 启用或关闭 Windows 功能 → 勾选 **Hyper-V**、**虚拟机平台**、**适用于 Linux 的 Windows 子系统**。
   
   - 重启系统。

2. 打开 **Hyper-V 管理器** → 虚拟交换机管理器。

3. 新建交换机：
   
   - **外部**：桥接到物理网卡，可直接访问局域网。
   
   - **内部**：仅宿主机与虚拟机互通。
   
   - **专用**：仅虚拟机间互通。

4. 应用后，Windows 会多出一个 `vEthernet (交换机名)` 网卡。

---

#### 方法 B：创建 Loopback 适配器（Host-only 常用）

**原理**：Loopback 是微软提供的测试网卡，数据不会离开本机，常用于调试/虚拟机 Host-only 模式。

**步骤：**

1. 按下 `Win + X` → 选择“设备管理器”。

2. 菜单栏 → 操作 → 添加过时硬件。

3. 选择“手动从列表中选择硬件” → 网络适配器。

4. 厂商选“Microsoft” → 选择“Microsoft KM-TEST Loopback Adapter”。

5. 完成后，网络设置中会出现一块新的虚拟网卡。

---

#### 方法 C：使用第三方工具（SoftEther / OpenVPN）

**原理**：这些软件自带 TAP/TUN 驱动，可创建虚拟以太网接口，流量由软件控制。

**SoftEther 创建步骤**：

1. 安装 SoftEther VPN Client。

2. 打开 SoftEther 管理器 → 添加虚拟网卡。

3. 选择 TAP 模式，即可在系统中生成一块可用的虚拟网卡。

---

#### 方法 D：PowerShell 创建 Hyper-V 内部交换机（命令行）

```powershell
New-VMSwitch -SwitchName "HostOnlySwitch" -SwitchType Internal
```

创建后，Windows 会出现 `vEthernet (HostOnlySwitch)` 网卡。

---

## **第二部分：WSL2 网卡原理 & 切换方法**

- **原理**：  
  WSL2 内部是 Hyper-V 虚拟机，默认连接到 `vEthernet (WSL)`（NAT 模式）。  
  IP 网段常见为 `172.27.240.0/20`，Windows 端作为 NAT 网关。

- **切换方法**：
  
  1. 创建新的 Hyper-V 虚拟交换机（桥接、Host-only）。
  
  2. 使用 PowerShell：
     
     ```powershell
     Get-VMNetworkAdapter -VMName "WSL"
     Connect-VMNetworkAdapter -VMName "WSL" -SwitchName "HostOnlySwitch"
     ```
  
  3. 重启 WSL：
     
     ```bash
     wsl --shutdown
     wsl
     ```

---

## **第三部分：WSL 使用虚拟网卡跑通 DPDK**

**目标**

- 在 Windows 上创建一块虚拟网卡

- 让 WSL2 使用它

- 在 WSL2 内绑定该虚拟网卡给 DPDK

- 跑通一个 DPDK 示例（如 `l2fwd`）

---

### **1. 前提条件**

- Windows 10/11 专业版 + Hyper-V

- 已安装 WSL2（Ubuntu 20.04/22.04）

- 已安装 DPDK 25.03（或你已有的版本）

- 已创建 **Host-only 或外部桥接** 虚拟网卡

---

### **2. 绑定虚拟网卡到 WSL**

1. 在 Windows **Hyper-V 管理器**创建一个 `HostOnlySwitch`，绑定到 Loopback Adapter（或者桥接到物理网卡）。

2. 用 PowerShell 把 WSL2 虚拟机连接到这个交换机：
   
   ```powershell
   Connect-VMNetworkAdapter -VMName "WSL" -SwitchName "HostOnlySwitch"
   ```

3. 重启 WSL：
   
   ```bash
   wsl --shutdown
   wsl
   ```

4. 在 WSL 内查看：
   
   ```bash
   ip addr
   ```
   
   应该能看到 `eth1`（新网卡）。

---

### **3. 配置 DPDK HugePage**

```bash
sudo mkdir -p /mnt/huge
sudo mount -t hugetlbfs nodev /mnt/huge
echo 1024 | sudo tee /proc/sys/vm/nr_hugepages
```

---

### **4. 编译 DPDK 并加载 igb_uio**

```bash
cd ~/dpdk-25.03
meson build
ninja -C build

sudo modprobe uio
sudo insmod build/kernel/linux/igb_uio/igb_uio.ko
```

---

### **5. 绑定虚拟网卡到 DPDK**

先找到新网卡的 PCI 地址：

```bash
dpdk-devbind.py --status
```

输出示例：

```
0000:03:00.0 'Virtio network device'
```

绑定：

```bash
sudo dpdk-devbind.py --bind=igb_uio 0000:03:00.0
```

---

### **6. 运行 DPDK 示例程序**

以 L2fwd 为例：

```bash
sudo ./build/examples/dpdk-l2fwd -l 0-1 -n 4 -- -q 1 -p 0x1
```

**预期输出：**

```
EAL: Detected 2 lcore(s)
EAL: Probing PCI devices...
L2FWD: entering main loop on lcore 0
L2FWD: entering main loop on lcore 1
Port 0: MAC 00:15:5D:01:02:03
L2FWD: RX from port 0
L2FWD: TX to port 0
```

---

### **7. 实验效果验证**

- **数据回环**：在宿主机/另一台机器 ping 虚拟网卡的 IP（如 Host-only 模式的 192.168.200.2），观察 DPDK 是否收发包。

- **性能测试**：  
  在宿主机运行 `iperf3`：
  
  ```bash
  iperf3 -c 192.168.200.2 -t 10
  ```
  
  DPDK 会显示收到的包数和转发情况。

---

### **最终效果**

- WSL 内部成功识别并绑定 Windows 创建的虚拟网卡到 DPDK 驱动（igb_uio）。

- DPDK 程序（l2fwd）能正常收发数据包。

- 数据流完全走虚拟网卡，和物理网卡隔离，方便实验和性能测试。

## 常见问题以及解答

### 修改配置文件的全局性及低耦合操作

修改 `%USERPROFILE%\.wslconfig` 文件（例如添加 `networkingMode=mirrored`）是全局性的。它位于用户目录下，影响所有 WSL2 实例（即所有安装的 Linux 发行版），因为 .wslconfig 是 WSL2 的全局配置文件，主要用于设置内核、网络模式、内存等系统级参数。这意味着如果你有多个发行版（如 Ubuntu 和 Debian），这个更改会同时应用到所有它们，导致潜在的兼容性问题或意外行为。

有没有耦合度更低的操作？是的，WSL 支持一些 per-distribution（每个发行版独立）的配置方式，这些方式不会影响全局其他实例，耦合度较低。以下是具体选项：

- **使用 /etc/wsl.conf 文件（per-distribution）**：这个文件位于每个 WSL 发行版的根目录下（例如，在 Ubuntu 中是 `/etc/wsl.conf`），用于设置特定发行版的启动行为、自动挂载等。虽然它不支持直接设置 `networkingMode=mirrored`（这是全局的），但你可以结合其他方式实现类似效果。例如：
  
  - 添加 `[network]` 部分来配置 hostname 或生成 resolv.conf（DNS 设置），这可以间接影响网络行为，而不影响其他发行版。
  - 示例：在 Ubuntu 的 `/etc/wsl.conf` 中添加：
    
    ```
    [network]
    generateResolvConf = false  # 禁用自动 DNS 配置，允许手动设置
    ```
    
    然后在 Ubuntu 中手动编辑 `/etc/resolv.conf` 来自定义 DNS。这是低耦合的，只影响当前发行版。
  - 局限：不支持直接添加网卡，但适合细粒度网络调整。

- **端口转发（netsh interface portproxy）**：这是一个 Windows 侧的操作，非常低耦合，因为它不修改 WSL 配置，只在主机上创建端口代理规则。可以针对特定发行版的 IP 地址设置，不影响全局网络模式。
  
  - 示例：在 PowerShell（管理员模式）运行：
    
    ```
    netsh interface portproxy add v4tov4 listenport=你的端口 listenaddress=0.0.0.0 connectport=WSL中的端口 connectaddress=$(wsl -d Ubuntu hostname -I)
    ```
    
    这相当于为特定发行版 "绑定" 一个网络通道，而不改变 WSL 的核心网络栈。适用于暴露服务到 LAN，而耦合度低（易撤销：`netsh interface portproxy delete ...`）。

- **其他低耦合社区方法**：如果需要更高级的接口添加，可以使用第三方工具如 WSLAttachSwitch（GitHub 项目），它允许附加自定义 Hyper-V 交换机到特定 WSL 实例，而不全局修改配置。但这不是官方支持，可能有稳定性风险。

这些方式的耦合度较低，因为它们要么是 per-instance，要么不涉及修改 WSL 的 VM 配置。如果你有多个发行版，优先用 wsl.conf 或 port proxy 避免全局影响。

### Windows 创建虚拟网卡为什么需要虚拟交换机？它们的关系、用途

在 Windows 的 Hyper-V 环境中，创建虚拟网卡（Virtual Network Adapter）和虚拟交换机（Virtual Switch）是紧密相关的，不能孤立存在。下面详细解释：

#### 它们的关系

- **虚拟交换机是虚拟网卡的必要基础**：虚拟网卡不能独立工作，它必须连接到一个虚拟交换机来处理网络流量。虚拟交换机充当 "桥梁" 或 "路由器"，负责将虚拟网卡的流量转发到物理网络、其他 VM 或主机。简单说，虚拟网卡是 "端点"（VM 的网络接口），而虚拟交换机是 "中心枢纽"（管理所有端点的连接和流量）。
- **为什么需要先创建交换机**：Hyper-V 的设计是层级的——交换机定义网络拓扑（例如外部访问、内部隔离），然后网卡才能 "插入" 这个拓扑。没有交换机，网卡就无法路由数据包（类似于物理网卡需要连接到交换机或路由器）。当你创建虚拟网卡时，Hyper-V 会要求指定一个交换机，否则操作失败。这确保了网络的安全性和可管理性，避免孤立网卡导致的混乱。
- **创建过程**：先用 `New-VMSwitch` 创建交换机，然后用 `Add-VMNetworkAdapter` 添加网卡并连接到交换机。WSL2 默认使用一个隐藏的 "WSL" 交换机（NAT 类型），这就是为什么直接修改受限。

#### 各自的用途

- **虚拟交换机（Virtual Switch）的用途**：
  
  - 创建虚拟网络环境，支持三种类型：
    - **External**：桥接到物理网卡，允许 VM 访问外部网络（如互联网），用途：生产环境中的 VM 联网。
    - **Internal**：仅主机和 VM 间通信，不连外部，用途：测试隔离网络或主机-VM 内部服务。
    - **Private**：仅 VM 间通信，不连主机，用途：多 VM 模拟私有 LAN。
  - 整体用途：管理流量转发、VLAN 分割、安全策略（如 ACL），类似于物理交换机，但软件实现。Hyper-V 用它来模拟复杂网络拓扑，提高虚拟化灵活性。

- **虚拟网卡（Virtual Network Adapter）的用途**：
  
  - 为 VM 提供网络接口，支持 MAC 地址分配、带宽限制、VLAN 等。
  - 用途：允许 VM 发送/接收数据包，实现互联网访问、文件共享、服务暴露等。没有网卡，VM 就无法联网；但网卡依赖交换机来 "激活" 其功能。
  - 示例：在 VM 中，它表现为 eth0/eth1 等接口，用于配置 IP、路由等。

总之，交换机是 "网络基础设施"，网卡是 "接入设备"，前者定义规则，后者执行连接。这种设计确保了 Hyper-V 的可扩展性和安全性。

### 如何将新创建的虚拟网卡连接到 WSL2

基于官方文档和社区反馈，我认为直接将自定义虚拟网卡连接到 WSL2 VM 不受 Microsoft 官方支持，因为 WSL2 的 Hyper-V VM 是系统管理的，受保护的（不允许用户直接修改其网络适配器）。强制操作可能导致不稳定或网络中断。但有几种可行的方式，从低风险到高级，优先推荐官方兼容的方法：

1. **推荐首选：启用镜像模式（Mirrored Mode）来自动镜像 Windows 网卡**（低风险，全局但有效）：
   
   - 这会将 Windows 的所有网络接口（包括你新创建的虚拟网卡）镜像到 WSL2 的 Ubuntu 中，作为额外接口出现（e.g., eth1）。
   - 步骤：
     1. 编辑 `%USERPROFILE%\.wslconfig`：
        
        ```
        [wsl2]
        networkingMode=mirrored
        ```
     2. 重启 WSL：`wsl --shutdown`。
     3. 在 Ubuntu 中运行 `ip addr` 查看新接口。如果你的新虚拟网卡连接到 Windows 的某个交换机，它会自动出现在 WSL2 中。
     4. 配置 Hyper-V 防火墙允许入站：以管理员运行 PowerShell `Set-NetFirewallHyperVVMSetting -Name '{40E0AC32-46A5-438A-A0B2-2B479E8F2E90}' -DefaultInboundAction Allow`。
   - 优点：无需直接连接 Hyper-V，兼容性好，支持 IPv6 和 LAN。缺点：全局影响所有 WSL 实例。

2. **低耦合替代：使用端口转发连接自定义网卡**（per-instance，无需修改 VM）：
   
   - 如果你的新虚拟网卡用于特定服务，创建端口代理来 "桥接" 流量。
   - 步骤：
     1. 确保新虚拟网卡在 Windows 中可见（e.g., 通过 Hyper-V Manager 创建并连接到交换机）。
     2. 获取 WSL IP：`wsl -d Ubuntu hostname -I`。
     3. 在 PowerShell：`netsh interface portproxy add v4tov4 listenport=端口 listenaddress=新网卡的IP connectport=WSL端口 connectaddress=WSL IP`。
   - 这相当于间接连接，而不触碰 WSL VM。适用于暴露 Ubuntu 服务到新网卡。

3. **高级社区方法：使用第三方工具附加自定义交换机**（有风险，但低耦合）：
   
   - 如果需要直接附加，试用 GitHub 项目如 WSLAttachSwitch 或类似脚本。它允许创建自定义 Hyper-V 交换机（e.g., `New-VMSwitch -Name "CustomSwitch" -SwitchType Internal`），然后附加到 WSL VM。
   - 步骤（参考社区）：
     1. 创建交换机：PowerShell `New-VMSwitch -Name "HostOnlySwitch" -SwitchType Internal`。
     2. 使用工具如 https://github.com/dantmnf/WSLAttachSwitch 运行脚本附加到 WSL。
     3. 重启 WSL，在 Ubuntu 中配置新接口。
   - 注意：这绕过官方限制，可能在 Windows 更新后失效。测试前备份 WSL。

总体建议：从镜像模式开始，如果不行再试端口转发。避免直接运行 Hyper-V 命令如 `Connect-VMNetworkAdapter`，因为会失败或破坏 WSL。如果你遇到具体错误，提供详情我可以细调。
