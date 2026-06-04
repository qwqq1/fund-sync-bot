# fund-sync-bot

🔄 自动同步 `qwqq1/real-time-fund` 与上游 `hzm0321/real-time-fund`

## 工作流程

1. 每天北京时间早8点（UTC 0:00）自动运行
2. 拉取上游最新 commit
3. 与 fork 对比，有更新 → 自动 merge + push
4. 冲突时强制覆盖为上游版本
5. 无更新 → 静默

## 手动触发

在 GitHub Actions 页面点击 "Run workflow" 即可。

## 通知

同步成功后通过 Hermes → ntfy(jigubao) → Telegram 通知。
