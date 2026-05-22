#!/bin/bash
#
# Copyright (C) 2026 zhangpan <zhangpan@kylinos.cn>
# All rights reserved, distributed under the GPL-2.0-or-later license
# 一键创建 KDE Merge Request 分支并推送
#
# 用法:
# 支持 KIO 和 Dolphin
#   ./create_mr.sh new <BUG_ID> --repo=kio|dolphin
#   ./create_mr.sh push <BUG_ID> --repo=kio|dolphin
#   ./create_mr.sh amend <BUG_ID> --repo=kio|dolphin
#   ./create_mr.sh test <MR_ID> --repo=kio|dolphin [--compile] [--test]
#
# 例如:
#   ./create_mr.sh new 469598 --repo=kio
#   ./create_mr.sh push 509162 --repo=dolphin
#   ./create_mr.sh amend 509162 --repo=dolphin
#   ./create_mr.sh test 80 --repo=kio
#   ./create_mr.sh test 80 --repo=kio --compile
#   ./create_mr.sh test 80 --repo=kio --compile --test

set -e

ACTION=$1
ID=$2
REPO=""
COMPILE=false
RUN_TESTS=false
# 你的 KDE GitLab 用户名
USERNAME="zhangpan"

# 解析参数
for arg in "$@"; do
  case $arg in
    --repo=kio)
      REPO="kio"
      ;;
    --repo=dolphin)
      REPO="dolphin"
      ;;
    --compile)
      COMPILE=true
      ;;
    --test)
      RUN_TESTS=true
      ;;
  esac
done

if [ -z "$ID" ] || [ -z "$REPO" ]; then
  echo "用法:"
  echo "  $0 new <BUG_ID> --repo=kio|dolphin"
  echo "  $0 push <BUG_ID> --repo=kio|dolphin"
  echo "  $0 amend <BUG_ID> --repo=kio|dolphin"
  echo "  $0 test <MR_ID> --repo=kio|dolphin [--compile] [--test]"
  exit 1
fi

# 检查 git-extras 是否安装（test 动作需要）
if [ "$ACTION" == "test" ] && ! command -v git-mr &> /dev/null; then
  echo "错误: git-mr 未安装。请先安装 git-extras:"
  echo "  Debian/Ubuntu/KDE Neon: sudo apt install git-extras"
  echo "  Fedora: sudo dnf install git-extras"
  echo "  Arch Linux (AUR): git clone https://aur.archlinux.org/git-extras.git && cd git-extras && makepkg -si"
  echo "  Manjaro: pamac build git-extras"
  echo "  openSUSE Tumbleweed: sudo zypper install git-mr"
  exit 1
fi

if [ "$ACTION" == "test" ]; then
  MR_ID=$ID
  if [ "$REPO" == "kio" ]; then
    MR_URL="https://invent.kde.org/kde/kio/-/merge_requests/${MR_ID}"
    REPO_PATH="${HOME}/kde/src/kio"
  elif [ "$REPO" == "dolphin" ]; then
    MR_URL="https://invent.kde.org/kde/dolphin/-/merge_requests/${MR_ID}"
    REPO_PATH="${HOME}/kde/src/dolphin"
  else
    echo "未知仓库: $REPO"
    exit 1
  fi
else
  BUG_ID=$ID
  BRANCH="work/bug-${BUG_ID}"
  # 编码分支名（/ 变成 %2F）
  ENCODED_BRANCH=$(echo ${BRANCH} | sed 's/\//%2F/g')

  # 仓库对应的 MR 链接（你的个人仓库）
  if [ "$REPO" == "kio" ]; then
    MR_URL="https://invent.kde.org/${USERNAME}/kio/-/merge_requests/new?merge_request%5Bsource_branch%5D=${ENCODED_BRANCH}"
  elif [ "$REPO" == "dolphin" ]; then
    MR_URL="https://invent.kde.org/${USERNAME}/dolphin/-/merge_requests/new?merge_request%5Bsource_branch%5D=${ENCODED_BRANCH}"
  else
    echo "未知仓库: $REPO"
    exit 1
  fi
fi

if [ "$ACTION" == "new" ]; then
  echo ">>> 更新 upstream/master ..."
  git fetch upstream
  git checkout master
  git rebase upstream/master

  echo ">>> 创建新分支: ${BRANCH}"
  git checkout -B ${BRANCH} upstream/master
  echo ">>> 已创建新分支 ${BRANCH}，请修改代码后再运行:"
  echo "    $0 push ${BUG_ID} --repo=${REPO}"

elif [ "$ACTION" == "push" ]; then
  echo ">>> 添加修改 ..."
  git add .

  echo ">>> 创建 commit (进入编辑器编辑 message)..."
  git commit --date="$(date -R)" -e -m "$(git log -1 --pretty=%B 2>/dev/null | sed '/^BUG:/d')" -m "BUG: ${BUG_ID}" || true

  echo ">>> 推送到 origin/${BRANCH} ..."
  git push -u origin ${BRANCH} -f

  echo ">>> 完成！现在去 KDE GitLab 创建 Merge Request："
  echo "    ${MR_URL}"

elif [ "$ACTION" == "amend" ]; then
  echo ">>> 添加修改 ..."
  git add .

  echo ">>> amend commit (进入编辑器修改 message)..."
  git commit --amend --reset-author --date="$(date -R)" -e -m "$(git log -1 --pretty=%B | sed '/^BUG:/d')" -m "BUG: ${BUG_ID}" || true

  echo ">>> 推送到 origin/${BRANCH} (强制更新)..."
  git push -u origin ${BRANCH} -f

  echo ">>> 完成！MR 分支已更新。"

elif [ "$ACTION" == "test" ]; then
  echo ">>> 进入源码目录: ${REPO_PATH}"
  cd "${REPO_PATH}"

  echo ">>> 检出 Merge Request #${MR_ID} ..."
  git mr ${MR_ID}

  if [ "$COMPILE" == "true" ]; then
    echo ">>> 编译 ${REPO} ..."
    kde-builder ${REPO} --no-src --no-include-dependencies

    if [ "$RUN_TESTS" == "true" ]; then
      echo ">>> 运行测试 ..."
      cd "${HOME}/kde/build/kde/applications/${REPO}"
      source prefix.sh
      ctest --output-on-failure
    fi
  fi

  echo ">>> 完成！Merge Request #${MR_ID} 已检出。"
  echo "    MR 页面: ${MR_URL}"
  if [ "$COMPILE" == "false" ]; then
    echo "    提示: 使用 --compile 参数可自动编译，--test 参数可运行测试"
  fi

else
  echo "未知动作: $ACTION"
  exit 1
fi
