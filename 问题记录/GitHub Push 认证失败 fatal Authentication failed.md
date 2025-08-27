# **GitHub Push 认证失败 "fatal: Authentication failed"**

## 一、问题背景

在 Windows 系统中，我使用 **HTTPS 协议** 绑定了 GitHub 远程仓库（例如 `https://github.com/ChipenHub/DS_practice.git`），并能正常执行 `git push`、`git pull` 等操作。当迁移到 Linux 系统后，再次尝试推送代码时，出现了以下错误：

```bash
fatal: Authentication failed for 'https://github.com/ChipenHub/DS_practice.git/'
```

## 二、问题分析

1. **协议差异**
   
   - 在 Windows 上，Git 支持使用 Git Credential Manager (GCM) 保存 GitHub 账号和密码（或 Token），因此可以透明地用 HTTPS 协议进行认证。
   
   - 在 Linux 上，若没有配置 GCM 或凭证缓存，则 Git 会要求手动输入用户名和密码。由于 GitHub **已经禁用密码认证**（2021 年 8 月起），必须使用 **Personal Access Token (PAT)** 或 **SSH**。

2. **根本原因**
   
   - Linux 环境中没有配置凭证助手（如 GCM）。
   
   - HTTPS 协议需要手动输入 GitHub Token，每次推送都很不方便。
   
   - 因此最佳实践是改用 **SSH 公钥认证**，一次配置即可长期使用。

## 三、解决方案思路

- 将远程仓库从 HTTPS 改为 SSH 协议（`git@github.com:...`）。

- 在 Linux 上生成 SSH 密钥，并绑定到 GitHub 账号。

- 验证 SSH 连接是否成功，确保可以免密码推送代码。

## 四、解决步骤

### 1. 检查现有远程仓库配置

```bash
git remote -v
```

输出示例（原本是 HTTPS）：

```
origin  https://github.com/ChipenHub/DS_practice.git (fetch)
origin  https://github.com/ChipenHub/DS_practice.git (push)
```

### 2. 生成 SSH 密钥

在 Linux 上执行以下命令（建议用邮箱作为注释）：

```bash
ssh-keygen -t ed25519 -C "chipen@mail.com"
```

若系统不支持 `ed25519`，则使用 RSA：

```bash
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
```

- 生成后默认存放在：
  
  ```
  ~/.ssh/id_ed25519
  ~/.ssh/id_ed25519.pub
  ```

### 3. 添加 SSH 私钥到 ssh-agent

启动 `ssh-agent` 并添加私钥：

```bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
```

### 4. 将公钥添加到 GitHub

查看公钥内容：

```bash
cat ~/.ssh/id_ed25519.pub
```

复制输出内容，然后到 GitHub 网站：  
**Settings → SSH and GPG keys → New SSH key → 粘贴公钥 → Save**

### 5. 修改远程仓库地址为 SSH

```bash
git remote set-url origin git@github.com:ChipenHub/DS_practice.git
```

确认修改结果：

```bash
git remote -v
```

输出应为：

```
origin  git@github.com:ChipenHub/DS_practice.git (fetch)
origin  git@github.com:ChipenHub/DS_practice.git (push)
```

### 6. 测试 SSH 连接

```bash
ssh -T git@github.com
```

成功输出类似：

```
Hi ChipenHub! You've successfully authenticated, but GitHub does not provide shell access.
```

### 7. 推送代码

现在即可正常使用：

```bash
git push origin main
```

---

## 五、结果与总结

- **问题原因**：Linux 下使用 HTTPS 方式推送 GitHub 仓库时，没有凭证缓存，GitHub 又禁用了密码认证，导致 `Authentication failed`。

- **解决办法**：改用 SSH 公钥认证，在 Linux 上生成密钥并绑定到 GitHub，修改远程地址后即可免密推送。

- **反思**：
  
  - HTTPS 协议在多平台下需要额外的 Token 管理工具，而 SSH 一次配置即可长期稳定使用。
  
  - 建议统一使用 SSH 协议来管理 GitHub 仓库，尤其是在 Linux、服务器等环境中。
