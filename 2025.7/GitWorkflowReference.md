# Git 全流程操作参照表

以下是从创建远程仓库到文件提交的完整 Git 操作流程，以及每个操作的逆向操作。命令基于 Linux 终端环境（如 Ubuntu），假设使用 GitHub 作为远程仓库平台。

## 1. 创建远程仓库
### 正向操作
在 GitHub 上创建远程仓库：
1. 登录 GitHub（`github.com`）。
2. 点击右上角的 `+` -> `New repository`。
3. 填写仓库名称（例如 `socket_practice`）、描述、选择公开/私有，点击 `Create repository`。
4. GitHub 提供仓库地址，例如 `https://github.com/ChipenHub/socket_practice.git` 或 `git@github.com:ChipenHub/socket_practice.git`（SSH）。

### 逆向操作（删除远程仓库）
1. 登录 GitHub，进入目标仓库页面。
2. 点击仓库右上角的 `Settings`。
3. 滚动到页面底部，找到 `Danger Zone`，点击 `Delete this repository`。
4. 输入仓库名称确认删除。

## 2. 初始化本地仓库
### 正向操作
在本地创建并初始化 Git 仓库：
```bash
mkdir socket_practice
cd socket_practice
git init
```
初始化后，当前目录成为 Git 仓库，生成 `.git` 目录。

### 逆向操作（删除本地仓库）
删除本地仓库目录及 `.git` 文件：
```bash
cd ..
rm -rf socket_practice
```
**注意**：这会永久删除本地仓库及其所有文件，请先备份重要数据。

## 3. 绑定远程仓库
### 正向操作
将本地仓库与远程仓库关联：
```bash
git remote add origin https://github.com/ChipenHub/socket_practice.git
```
验证远程仓库是否绑定成功：
```bash
git remote -v
```

### 逆向操作（解除远程仓库绑定）
移除远程仓库的绑定：
```bash
git remote remove origin
```
这会断开本地仓库与远程仓库的关联，但不影响远程仓库内容。

## 4. 创建和修改文件
### 正向操作
创建或修改文件，例如：
```bash
touch reactor.c
echo "int main() { return 0; }" > reactor.c
```
编辑文件内容（使用编辑器如 `nano` 或 `vim`）：
```bash
nano reactor.c
```

### 逆向操作（撤销文件修改）
- **撤销未暂存的修改**：
  ```bash
  git restore reactor.c
  ```
  恢复文件到上次提交的状态。
- **删除新建但未跟踪的文件**：
  ```bash
  rm reactor.c
  ```
- **撤销已暂存但未提交的修改**：
  ```bash
  git restore --staged reactor.c
  ```

## 5. 添加文件到暂存区
### 正向操作
将修改或新文件添加到 Git 暂存区：
```bash
git add reactor.c
```
添加所有更改：
```bash
git add .
```

### 逆向操作（从暂存区移除）
取消暂存文件的更改：
```bash
git restore --staged reactor.c
```
或一次性取消所有暂存：
```bash
git restore --staged .
```

## 6. 提交更改到本地仓库
### 正向操作
提交暂存的更改到本地仓库：
```bash
git commit -m "Add reactor.c with initial code"
```
或直接提交所有已跟踪的更改：
```bash
git commit -a -m "Update all tracked files"
```

### 逆向操作（撤销提交）
- **软撤销最后一次提交（保留更改）**：
  ```bash
  git reset --soft HEAD~1
  ```
  更改回到暂存区，可重新修改或提交。
- **硬撤销最后一次提交（丢弃更改）**：
  ```bash
  git reset --hard HEAD~1
  ```
  **警告**：这会丢弃提交和相关更改，谨慎使用。
- **撤销指定提交**：
  查找提交的哈希值（通过 `git log`），然后：
  ```bash
  git revert <commit-hash>
  ```
  这会创建一个新的提交来撤销指定提交的效果。

## 7. 推送更改到远程仓库
### 正向操作
将本地提交推送到远程仓库的 `master` 分支：
```bash
git push origin master
```
如果远程分支不存在，需设置上游分支：
```bash
git push --set-upstream origin master
```

### 逆向操作（撤销远程提交）
- **将远程分支重置到上一提交**：
  1. 先在本地撤销提交：
     ```bash
     git reset --hard HEAD~1
     ```
  2. 强制推送覆盖远程分支：
     ```bash
     git push origin master --force
     ```
     **警告**：强制推送会覆盖远程仓库历史，可能影响协作者，谨慎使用。
- **通过 revert 撤销远程提交**：
  ```bash
  git revert <commit-hash>
  git push origin master
  ```
  这会创建一个新提交来撤销指定提交，适合协作场景。

## 8. 拉取远程仓库更改
### 正向操作
从远程仓库拉取更新并合并到本地：
```bash
git pull origin master
```
如果有冲突，Git 会提示，需手动解决。

### 逆向操作（撤销拉取的合并）
如果 `git pull` 导致合并冲突或不想要的更改：
- **撤销合并**：
  ```bash
  git merge --abort
  ```
  这会取消合并，恢复到 `git pull` 前的状态。
- **硬重置到指定状态**：
  ```bash
  git reset --hard HEAD
  ```
  恢复到本地最近的提交状态，丢弃拉取的更改。

## 9. 处理冲突（特殊情况）
### 正向操作
如果 `git pull` 或 `git push` 因远程更改导致冲突：
1. 运行 `git pull origin master`，Git 会标记冲突文件。
2. 打开冲突文件，解决标记为 `<<<<<<<`、`=======`、`>>>>>>>` 的部分。
3. 标记冲突解决：
   ```bash
   git add <file>
   ```
4. 完成合并：
   ```bash
   git commit
   ```

### 逆向操作（取消冲突解决）
- **放弃冲突解决**：
  ```bash
  git merge --abort
  ```
  或：
  ```bash
  git reset --hard HEAD
  ```
  这会放弃冲突解决，恢复到合并前的状态。

## 10. 清理未跟踪文件
### 正向操作
删除未跟踪的文件和目录：
```bash
git clean -fd
```
`-f` 表示强制，`-d` 表示删除目录。

### 逆向操作（恢复未跟踪文件）
未跟踪文件被 `git clean` 删除后无法通过 Git 恢复，需从备份（如 Time Machine 或外部存储）手动恢复。

## 注意事项
- **备份重要文件**：在执行 `git reset --hard`、`git push --force` 或 `git clean` 前，确保备份重要数据。
- **协作场景**：避免频繁使用 `--force`，以免覆盖他人提交。
- **查看状态**：随时运行 `git status` 检查当前仓库状态。
- **查看历史**：使用 `git log --oneline --graph --all` 查看提交历史。
- **gitignore**：创建 `.gitignore` 文件忽略不想跟踪的文件（如 `.vscode/`）：
  ```bash
  echo ".vscode/" > .gitignore
  git add .gitignore
  git commit -m "Add .gitignore"
  ```