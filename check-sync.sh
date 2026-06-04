#!/bin/bash
# check-sync.sh — 检查 fund-sync-bot 最新 run 结果，有更新则输出通知文本
# 由 Hermes cronjob 调用，stdout 作为通知内容

set -e

REPO="qwqq1/fund-sync-bot"
WORKFLOW="sync.yml"

# 获取最新 completed run
RUN=$(gh run list \
  --repo "$REPO" \
  --workflow "$WORKFLOW" \
  --status completed \
  --limit 1 \
  --json databaseId,conclusion,createdAt \
  2>/dev/null || echo '{}')

if [ -z "$RUN" ] || [ "$RUN" = "{}" ] || [ "$RUN" = "[]" ]; then
  exit 0
fi

RUN_ID=$(echo "$RUN" | jq -r '.[0].databaseId // empty')
CONCLUSION=$(echo "$RUN" | jq -r '.[0].conclusion // empty')

if [ -z "$RUN_ID" ]; then
  exit 0
fi

# 如果上次通知的 run ID 一样，跳过（避免重复通知）
STATE_FILE="/opt/data/cron/fund-sync-last-run-id"
LAST_ID=""
if [ -f "$STATE_FILE" ]; then
  LAST_ID=$(cat "$STATE_FILE")
fi

if [ "$RUN_ID" = "$LAST_ID" ]; then
  exit 0
fi

# 记录本次 run ID
mkdir -p /opt/data/cron
echo "$RUN_ID" > "$STATE_FILE"

# 成功 → 下载 artifact 拿通知文本
if [ "$CONCLUSION" = "success" ]; then
  # 检查有没有 sync-notification artifact
  ARTIFACTS=$(gh api "repos/$REPO/actions/runs/$RUN_ID/artifacts" \
    --jq '.artifacts[] | select(.name=="sync-notification") | .id' 2>/dev/null || true)

  if [ -n "$ARTIFACTS" ]; then
    # 有更新，下载通知
    TMPDIR=$(mktemp -d)
    gh run download "$RUN_ID" \
      --repo "$REPO" \
      --name sync-notification \
      --dir "$TMPDIR" \
      2>/dev/null || true

    if [ -f "$TMPDIR/sync_notify.txt" ]; then
      cat "$TMPDIR/sync_notify.txt"
      rm -rf "$TMPDIR"
      exit 0
    fi
    rm -rf "$TMPDIR"
  fi

  # 没有 artifact = 无更新，静默
  exit 0

elif [ "$CONCLUSION" = "failure" ]; then
  echo "❌ 基估宝同步工作流失败，请检查: https://github.com/$REPO/actions/runs/$RUN_ID"
  exit 0
fi

exit 0
