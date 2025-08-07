## **Samba 使用手册**

### 1. **Samba 简介**

Samba 是一个开源的实现 SMB 协议的软件，允许不同操作系统之间共享文件和打印机。它支持 **Windows** 系统、**Linux** 系统、**Unix** 系统之间的共享，支持 **SMB1**、**SMB2** 和 **SMB3** 协议版本。

通过 Samba，你可以在 Windows 和 Linux 系统之间轻松共享文件和目录。

### 2. **安装 Samba**

1. **安装 Samba 服务**
    在 Ubuntu 或 Debian 系统中，你可以通过以下命令安装 Samba：

   ```bash
   sudo apt update
   sudo apt install samba
   ```

   在 CentOS 或 Red Hat 系统中，使用以下命令：

   ```bash
   sudo yum install samba samba-client samba-common
   ```

2. **检查 Samba 版本**
    安装完成后，你可以通过以下命令检查 Samba 的版本：

   ```bash
   samba --version
   ```

### 3. **配置 Samba**

Samba 的配置文件通常位于 `/etc/samba/smb.conf`。你需要编辑这个文件来设置共享目录、权限等。

1. **编辑配置文件**
    打开 `/etc/samba/smb.conf` 文件：

   ```bash
   sudo nano /etc/samba/smb.conf
   ```

2. **配置共享目录**

   在文件的最后添加你想共享的目录。例如，要共享 `/home/chipen/share` 目录，配置如下：

   ```ini
   [share]
   path = /home/chipen/share
   available = yes
   valid users = chipen
   read only = no
   browsable = yes
   public = yes
   writable = yes
   ```

   - `[share]`：共享的名称，你在网络中看到的名称。
   - `path`：你想要共享的本地目录路径。
   - `valid users`：允许访问共享的用户（这里是 `chipen`）。
   - `read only = no`：允许写入文件。如果设置为 `yes`，则该共享是只读的。
   - `writable = yes`：如果为 `yes`，允许写入数据。
   - `public = yes`：设置为 `yes`，任何人都能访问。

3. **创建共享目录**

   如果你配置了共享目录，但该目录还不存在，你需要创建该目录：

   ```bash
   mkdir -p /home/chipen/share
   chmod 777 /home/chipen/share
   ```

   - `chmod 777` 赋予该目录所有权限，确保所有用户都可以读写。

### 4. **配置 Samba 用户**

Samba 需要创建专门的用户来管理文件共享的访问权限。你可以使用以下命令为 Samba 配置一个用户：

1. **添加系统用户**
    如果你还没有 `chipen` 用户，你可以创建该用户：

   ```bash
   sudo useradd chipen
   sudo passwd chipen
   ```

2. **为 Samba 添加用户**
    然后为该用户添加 Samba 访问权限：

   ```bash
   sudo smbpasswd -a chipen
   ```

   你将被要求输入该用户的 Samba 密码。确保输入的密码与系统的用户密码一致。

3. **启用 Samba 用户**
    启用用户后，运行以下命令：

   ```bash
   sudo smbpasswd -e chipen
   ```

### 5. **启动 Samba 服务**

1. **启动并启用 Samba 服务**

   你需要启动 Samba 服务，使其在启动时自动启动：

   ```bash
   sudo systemctl start smbd
   sudo systemctl enable smbd
   ```

2. **检查 Samba 服务状态**

   你可以检查 Samba 服务是否运行：

   ```bash
   sudo systemctl status smbd
   ```

### 6. **访问 Samba 共享**

1. **在 Windows 上访问 Samba 共享**

   在 Windows 系统中，你可以通过以下步骤访问共享文件夹：

   - 打开 **文件资源管理器**。
   - 在地址栏中输入 `\\<Linux_IP>\<share_name>`，例如：`\\192.168.1.100\share`。
   - 当你被要求时，输入你在 `Samba` 中配置的用户名和密码。

2. **在 Linux 上访问 Samba 共享**

   你可以使用 `smbclient` 或通过文件管理器访问 Samba 共享：

   - 使用命令行：

     ```bash
     smbclient //192.168.1.100/share -U chipen
     ```

   - 通过文件管理器，在地址栏中输入 `smb://<Linux_IP>/share`，例如：`smb://192.168.1.100/share`。

### 7. **常见 Samba 配置项**

以下是一些常见的 Samba 配置项，帮助你进一步自定义 Samba 共享。

- **设置最大连接数**：

  ```ini
  max connections = 10
  ```

  允许最多 10 个连接。

- **禁用访客访问**：

  ```ini
  guest ok = no
  ```

- **设置共享目录为只读**：

  ```ini
  read only = yes
  ```

- **限制用户访问**：

  ```ini
  valid users = user1, user2
  ```

### 8. **安全性注意事项**

- **防火墙设置**：确保防火墙允许 Samba 相关端口（如 445 和 139）。

  ```bash
  sudo ufw allow samba
  ```

- **文件权限**：确保共享的目录和文件具有正确的权限，避免非法访问。

- **加密**：为了安全性，可以启用 SMB 3.0 加密功能，尤其是在不信任的网络环境中。

### 9. **常见问题排查**

| **问题**                    | **原因**              | **解决方法**                                |
| --------------------------- | --------------------- | ------------------------------------------- |
| Samba 共享无法访问          | 服务未启动            | 启动 Samba 服务 `sudo systemctl start smbd` |
| 无法连接到共享              | 用户权限未设置        | 使用 `smbpasswd` 为 Samba 用户设置密码      |
| Windows 无法访问 Samba 共享 | 防火墙阻止 Samba 端口 | 使用 `sudo ufw allow samba` 打开 Samba 端口 |
| 权限不足，无法读取共享文件  | 文件权限不足          | 使用 `chmod` 更改共享目录的权限             |

### 10. **总结**

Samba 是一种强大的工具，可以轻松实现 Linux 和 Windows 系统之间的文件共享。通过安装、配置并启动 Samba 服务，你可以将文件夹共享到网络上，让其他计算机（包括 Windows 和 Linux 系统）可以访问。配置过程中需要设置共享的目录、配置 Samba 用户、管理权限等。通过命令行或文件管理器，用户可以方便地访问 Samba 共享。

如果你遇到问题，可以参考常见问题排查表，检查 Samba 服务状态、网络配置和防火墙设置，确保一切设置正确。