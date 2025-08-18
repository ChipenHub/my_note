## **SSH 登录失败（publickey）问题总结**

1. **现象**
   
   - `ssh user@IP` 提示：
     
     ```
     Permission denied (publickey).
     ```
   
   - 表示 SSH 只接受公钥认证，而没有允许密码登录。

2. **原因**
   
   - 新建虚拟机（尤其 cloud-init/Ubuntu Server），默认禁用密码登录，只允许公钥。
   
   - `sshd_config` 或 `/etc/ssh/sshd_config.d/50-cloud-init.conf` 中存在：
     
     ```
     PasswordAuthentication no
     ```
   
   - 用户未设置密码，即使启用 `PasswordAuthentication yes` 也无法用密码登录。

3. **排查步骤**
   
   - 查看最终生效配置：
     
     ```bash
     sshd -T | grep passwordauthentication
     ```
     
     如果输出 `no`，说明配置还未生效。
   
   - 确认用户有密码：
     
     ```bash
     sudo passwd 用户名
     ```
   
   - 确认 SSH 服务已重启且无错误：
     
     ```bash
     sudo systemctl restart ssh
     sudo systemctl status ssh
     ```

4. **解决方法**
   
   - **方法 A（短期）**：修改 `50-cloud-init.conf`，把
     
     ```
     PasswordAuthentication no
     ```
     
     改成
     
     ```
     PasswordAuthentication yes
     ```
   
   - **方法 B（推荐，长期有效）**：新建文件 `/etc/ssh/sshd_config.d/99-local.conf`，写入：
     
     ```
     PasswordAuthentication yes
     PubkeyAuthentication yes
     ```
     
     因为 `99-local.conf` 优先级最高，不会被 cloud-init 覆盖。
   
   - 重启 ssh 服务后，使用新设置的密码即可登录。

5. **验证**
   
   - 在宿主机执行：
     
     ```powershell
     ssh user@虚拟机IP
     ```
     
     出现密码提示即可。
   
   - 如果仍失败，检查日志：
     
     ```bash
     journalctl -xeu ssh
     tail -n 50 /var/log/auth.log
     ```
