README.md

# KDE MR 自动化工具（create_mr）

一键创建、提交、更新 KDE 项目 Merge Request 分支，支持 Dolphin / KIO，简化上游贡献流程。

## 功能

- 自动基于 upstream/master 创建 bug 修复分支

- 自动提交代码并推送到个人仓库

- 自动生成 MR 创建链接

- 支持 amend 单 commit 持续更新

- 支持检出他人 MR 进行测试、编译

- 全局命令，任意目录可用

## 安装步骤（必须按顺序执行）

```bash

# 1. 先清理错误的软链接（必须）

sudo rm -f /usr/local/bin/create_mr.sh

# 2. 把脚本复制到系统目录（无后缀，更优雅）

sudo cp ~/code/sh/upload_kde_mr/upload_kde_mr/create_mr.sh /usr/local/bin/create_mr

# 3. 添加可执行权限（必须）

sudo chmod +x /usr/local/bin/create_mr

# 4. 验证是否全局可用

create_mr

```

出现用法提示即安装成功！

## 更新脚本（修改脚本后执行）

```bash

sudo cp ~/code/sh/upload_kde_mr/upload_kde_mr/create_mr.sh /usr/local/bin/create_mr

```

## 使用示例

### 通用格式

```bash

create_mr <动作> <BUG_ID> --repo=<dolphin|kio>

```

### KIO 项目

```bash

# 创建新分支

create_mr new 505197 --repo=kio

# 修改代码后提交并推送

create_mr push 505197 --repo=kio

```

### Dolphin 项目

```bash

# 创建新分支

create_mr new 510469 --repo=dolphin

# 修改代码后提交并推送

create_mr push 510469 --repo=dolphin

```

### 后续修改（保持单 commit，更新 MR）

```bash

# Dolphin

create_mr amend 509150 --repo=dolphin

# KIO

create_mr amend 508438 --repo=kio

```

### 测试他人的 Merge Request

```bash

# 检出 MR（仅检出，不编译）

create_mr test 80 --repo=kio

# 检出并编译

create_mr test 80 --repo=kio --compile

# 检出、编译并运行测试

create_mr test 80 --repo=kio --compile --test

# Dolphin 项目

create_mr test 42 --repo=dolphin --compile

```

## 支持的动作

- new    从最新上游 master 创建 bug 分支

- push   提交修改并推送到远程，生成 MR 链接

- amend  追加修改到上一个 commit，强制更新远程分支

- test   检出他人的 Merge Request 进行测试

## 测试 Merge Request 流程

1. 使用 `create_mr test <MR_ID> --repo=<仓库>` 检出 MR

2. 编译软件：`kde-builder <项目> --no-src --no-include-dependencies`

3. 运行测试：`cd ~/kde/build/kde/applications/<项目> && source prefix.sh && ctest --output-on-failure`

4. 在 MR 页面报告测试结果

## 注意

- 必须提前配置好 KDE GitLab 密钥和 git 用户名

- 所有 MR 保持单 commit，方便上游审查

- 分支名自动生成：work/bug-${BUG_ID}

- 测试他人 MR 时，源码目录默认为 `~/kde/src/<项目名>`

