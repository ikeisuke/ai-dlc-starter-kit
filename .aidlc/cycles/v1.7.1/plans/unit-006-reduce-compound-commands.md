# Unit 006 計画: 複合コマンド削減

## 概要

**調査結果により方針変更**:
1. `&>/dev/null` を `>/dev/null 2>&1` に置換
2. awk/grep/sed による設定読み取りを `dasel` + AI読み取りに置換
3. 許可リスト設定の改善とガイド更新

## 調査結果

### 1. 承認が求められる原因

| パターン | 承認 | 理由 |
|---------|------|------|
| `command -v gh && gh auth status` | 不要 | 複合コマンド自体は問題なし |
| `ls docs/... && echo X` | 不要 | プロジェクト内パス |
| `2>/dev/null` | 不要 | stderrリダイレクトのみ |
| `>/dev/null` | 不要 | stdoutリダイレクトのみ |
| `>/dev/null 2>&1` | 不要 | 分離記法 |
| **`&>/dev/null`** | **必要** | bash省略記法が問題 |

### 2. 許可リスト設定の改善（実施済み）

`.claude/settings.local.json` を更新:

| 変更前 | 変更後 | 理由 |
|--------|--------|------|
| `tee:*` | `tee -a docs/cycles/*/history/*` | 履歴ファイル限定 |
| `rsync:*` | `rsync * docs/aidlc/{prompts,templates,guides}/` | 同期先限定 |
| `git commit:*` | `git commit -m:*` | amend除外 |
| `git branch:*` | 読み取り系のみ | 削除除外 |
| `git remote:*` | 読み取り系のみ | 削除除外 |
| `curl:*` (ask) | `curl * https://raw.githubusercontent.com/ikeisuke/ai-dlc-starter-kit/*` (allow) | URL限定で許可 |

## 修正対象

### A. `&>/dev/null` → `>/dev/null 2>&1`（4箇所）

| ファイル | 行 |
|---------|-----|
| setup.md | 105, 107 |
| inception.md | 626 |
| construction.md | 663 |

### B. awk/grep/sed → dasel + AI読み取り

| ファイル | 対象 |
|---------|------|
| setup.md | BACKLOG_MODE読み取り |
| inception.md | BACKLOG_MODE読み取り (2箇所) |
| construction.md | BACKLOG_MODE読み取り, MCP_REVIEW_MODE読み取り |
| operations.md | BACKLOG_MODE読み取り (2箇所) |

### C. 推奨許可リストガイド更新

`prompts/package/guides/ai-agent-allowlist.md` を更新

## 実装計画

### Phase 1: 設計・調査（完了）

- [x] 承認が求められる原因の特定
- [x] TOMLパーサー調査（dasel推奨）
- [x] 許可リスト設定の改善

### Phase 2: 実装

1. [x] 許可リスト設定更新（`.claude/settings.local.json`）
2. [ ] `&>/dev/null` を `>/dev/null 2>&1` に置換
3. [ ] awk/grep/sed を dasel + AI読み取りに置換
4. [ ] 推奨許可リストガイド更新
5. [ ] Markdownlint実行
6. [ ] レビュー・承認

---

作成日: 2026-01-11
更新日: 2026-01-11（調査・設定完了、Phase 2開始）
