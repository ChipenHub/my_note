# 一、原始问题

| 来源      | 原始命令 / 输出                                    | 关键错误行                                                                                                                                       |
| ------- | -------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------- |
| 1. 启动命令 | `systemctl start docker`                     | → 显示“失败”                                                                                                                                    |
| 2. 查看日志 | `journalctl -xe`                             | `Dependency failed for Docker Application Container Engine.`                                                                                |
| 3. 专用日志 | `sudo journalctl -u docker --no-pager -n 50` | `Dependency failed for Docker Application Container Engine.`<br>`docker.service: Job docker.service/start failed with result 'dependency'.` |
| 4. 状态查询 | `sudo systemctl status docker -l`            | `Active: inactive (dead)`<br>`Dependency failed for Docker Application Container Engine.`                                                   |
| 5. 内核版本 | `uname -r`                                   | `5.15.0-67-generic`                                                                                                                         |
| 6. 附加现象 | `systemctl start sshd` 也失败                   | “类似情况”                                                                                                                                      |

> **注**：用户误写 `sshd`（应为 `ssh.service`），但现象一致。

---

## 二、问题现象归纳

1. **`docker.service` 无法启动**  
2. **失败类型**：`result 'dependency'`（依赖失败）  
3. **依赖链断点**：`docker.service` → `docker.socket`  
4. **`containerd` 正常启动**（排除 containerd 本身问题）  
5. **`ssh.service` 存在同类依赖失败历史**  
6. **用户组缺失是共同诱因**（经修复验证）

---

## 三、根本原因分析（Root Cause Analysis, RCA）

| 层级      | 现象                    | 原因                                | 证据                            |
| ------- | --------------------- | --------------------------------- | ----------------------------- |
| 1. 表象   | `docker.service` 启动失败 | `result 'dependency'`             | `journalctl -u docker`        |
| 2. 直接原因 | `docker.socket` 启动失败  | systemd 单元要求 `SocketGroup=docker` | `systemctl cat docker.socket` |
| 3. 根本原因 | 系统缺少 `docker` 用户组     | `getent group docker` 无输出         | 用户执行后确认                       |
| 4. 触发条件 | 用户组被删除或从未创建           | 常见于：卸载不干净、手动清理、系统精简               | 用户未否认                         |
| 5. 关联现象 | `ssh.service` 曾同类失败   | 缺失 `ssh` 组 → `ssh.socket` 权限错误    | 用户陈述：“加了用户后解决”                |

> **结论**：**`docker` 和 `ssh` 服务均依赖 systemd socket 激活机制，socket 文件权限依赖特定用户组。组缺失 → 权限创建失败 → socket 失败 → service 依赖失败。**

---

## 四、修复方案（已验证有效）

```bash
# 1. 确认组缺失
getent group docker   # 无输出 → 确认

# 2. 创建缺失组
sudo groupadd docker

# 3. 重新加载 systemd
sudo systemctl daemon-reload

# 4. 启动服务
sudo systemctl start docker

# 5. 验证
sudo systemctl status docker   # Active: active (running)
docker ps                      # 正常输出
```

**ssh 修复同理**：

```bash
sudo groupadd ssh
sudo systemctl daemon-reload
sudo systemctl start ssh
```

---

## 五、系统设计原理（为什么需要用户组？）

### 1. **Unix Domain Socket 通信模型**

- Docker 客户端 ↔ `dockerd` 通过 `/run/docker.sock` 通信
- 文件权限：`srw-rw---- 1 root docker`

### 2. **systemd Socket 激活（Socket Activation）**

```ini
# /lib/systemd/system/docker.socket
[Socket]
ListenStream=/run/docker.sock
SocketGroup=docker
SocketMode=0660
```

> **强制要求**：必须存在 `docker` 组，否则 `bind()` 失败。

### 3. **最小权限原则（Least Privilege）**

- 不让所有用户直接 `root` 操作 Docker
- 通过加入 `docker` 组实现 **非 root 权限控制**

---

## 六、关联性分析：Docker 与 SSH 为什么“同病”

| 项目         | Docker                       | SSH              |
| ---------- | ---------------------------- | ---------------- |
| systemd 单元 | `docker.service`             | `ssh.service`    |
| 依赖 socket  | `docker.socket`              | 内部或 `ssh.socket` |
| 要求用户组      | `SocketGroup=docker`         | `Group=ssh` 或自定义 |
| 缺组后果       | 权限错误 → 启动失败                  | 同                |
| 修复方式       | `groupadd` + `daemon-reload` | 同                |

> **本质联系**：**两者均使用 systemd 的“按需 socket 激活”机制，依赖用户组实现权限隔离。**

---

## 七、预防措施（最佳实践）

| 操作        | 命令                                 | 说明                    |
| --------- | ---------------------------------- | --------------------- |
| 卸载 Docker | `sudo apt purge docker.io`         | 自动清理组（部分情况）           |
| 禁止手动删组    | 避免 `delgroup docker`               | 高危操作                  |
| 备份组信息     | `getent group docker > backup.txt` | 迁移/恢复用                |
| 检查单元文件    | `systemctl cat *.socket`           | 提前发现 `SocketGroup` 要求 |

---

## 八、总结结论

1. **问题**：`docker.service` 启动失败，错误码 `dependency`  
2. **原因**：`docker.socket` 要求 `SocketGroup=docker`，但系统无此组  
3. **修复**：`sudo groupadd docker && systemctl daemon-reload && systemctl start docker`  
4. **原理**：systemd socket 激活依赖用户组实现权限控制  
5. **关联**：`ssh.service` 曾因缺 `ssh` 组同理失败  
6. **建议**：避免手动删除系统用户组，卸载软件使用官方方式
