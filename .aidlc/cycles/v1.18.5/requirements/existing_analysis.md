# 既存コード分析

## #274: upgrade-aidlc.sh worktreeメタ開発時のrsync同期漏れ

### 原因

`resolve_starter_kit_root()` 関数（L122-191）のTier 2メタ開発モード検出:

```
if [[ "$SCRIPT_DIR" == */prompts/package/skills/*/bin ]]; then
    cd "$SCRIPT_DIR/../../../../.." && pwd
```

worktree環境（`.worktree/dev/prompts/package/skills/*/bin`）でもこのパターンにマッチし、5階層上がworktreeルートに解決される。結果、rsyncソースが`/.worktree/dev/prompts/package/`（古いコピー）になる。

### 影響範囲

- `upgrade-aidlc.sh`のrsync同期全体（prompts, templates, skills, bin, guides）
- v1.18.4で実際にconstruction.md、operations.md、session-titleの同期漏れが発生

### 修正方針

- worktree環境を検出し、STARTER_KIT_ROOTを適切に解決する
- 環境変数`AIDLC_STARTER_KIT_PATH`のエスケープハッチは既存

---

## #273: コンパクション後のセミオートモード引き継ぎ強化

### 現状

`compaction.md`に以下の手順が記載済み:
1. `read-config.sh rules.automation.mode` で再取得
2. `semi_auto`確認後、自動継続
3. グローバルフォールバック条件に該当時はユーザー報告

### 問題点

1. **暗黙的な引き継ぎ**: コンパクションサマリに`automation_mode=semi_auto`が明示されない
2. **ゲートロジックとの接続不足**: compaction.mdからrules.mdのゲート判定ロジックへの参照がない
3. **状態の永続化なし**: progress.mdや履歴に`automation_mode`状態のチェックポイントがない
4. **フォールバック条件の不明確さ**: どのような状況でフォールバックが発生するか詳細がない

### 修正方針

- コンパクション後の状態確認チェックポイントを強化
- `automation_mode`をコンテキスト保持必須情報に追加
- ゲートロジックへの明示的参照を追加

---

## #272: ローカルバックログ無効時にファイル作成・探索しない

### 問題箇所一覧

| ファイル | 行 | 操作 | モードチェック |
|---------|-----|------|-------------|
| inception.md | L295 | `ls docs/cycles/backlog/` | なし |
| inception.md | L549 | `ls docs/cycles/backlog/` | なし |
| inception.md | L578 | `ls -R docs/cycles/backlog-completed/` | なし |
| inception.md | L580 | `cat docs/cycles/backlog-completed.md` | なし |
| construction.md | L249 | `ls docs/cycles/backlog/` | なし |
| operations.md | L408 | `ls docs/cycles/backlog/` | なし |
| operations.md | L415 | `mkdir backlog-completed/` | なし |
| operations.md | L418 | `mv backlog files` | なし |

### 正しく処理しているファイル

- `init-cycle-dir.sh`: issue-only時にbacklogディレクトリ作成をスキップ
- `review-flow.md`: OUT_OF_SCOPEバックログ登録時にモード判定あり
- `agents-rules.md`: モード参照は正しい

### 削除対象ファイル

- `docs/cycles/backlog-completed.md`（1ファイル）
- `docs/cycles/backlog-completed/`（54ファイル）

### 修正方針

- 上記8箇所に`backlog_mode`チェックを追加
- `issue-only`の場合はローカルファイル操作をスキップ
- 既存のローカルバックログファイルを削除
