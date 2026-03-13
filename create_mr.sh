#!/bin/bash
# 一键创建 KDE Merge Request 分支并推送
# 支持 KIO 和 Dolphin
#
# 用法:
#   ./create_mr.sh new <BUG_ID> --repo=kio|dolphin
#   ./create_mr.sh push <BUG_ID> --repo=kio|dolphin
#   ./create_mr.sh amend <BUG_ID> --repo=kio|dolphin
#
# 例如:
#   ./create_mr.sh new 469598 --repo=kio
#   ./create_mr.sh push 509162 --repo=dolphin
#   ./create_mr.sh amend 509162 --repo=dolphin

set -e

ACTION=$1
BUG_ID=$2
REPO=""
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
  esac
done

if [ -z "$BUG_ID" ] || [ -z "$REPO" ]; then
  echo "用法:"
  echo "  $0 new <BUG_ID> --repo=kio|dolphin"
  echo "  $0 push <BUG_ID> --repo=kio|dolphin"
  echo "  $0 amend <BUG_ID> --repo=kio|dolphin"
  exit 1
fi

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

else
  echo "未知动作: $ACTION"
  exit 1
fi
