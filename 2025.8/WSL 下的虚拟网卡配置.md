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
