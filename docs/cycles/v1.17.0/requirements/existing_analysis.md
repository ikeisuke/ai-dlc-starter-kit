# 既存コード分析 - v1.17.0

## 1. squash-unit.sh（#234, #228）

### 現在の実装
- **パス**: `prompts/package/bin/squash-unit.sh`
- **方式**: `git reset --soft BASE` （1件時は `--amend`）/ jj squash
- **オプション**: `--cycle`, `--message`（必須）, `--vcs`（必須）, `--unit`, `--base`, `--dry-run`
- **起点検出**: `feat: [CYCLE]...` or `chore: [CYCLE]...Phase完了` パターン
- **制限**: HEAD（最新Unit）のみsquash可能。過去Unitの事後squashは非対応

### commit-flow.md の現状
- **Inception Phase完了コミット**: squash未対応。直接 `git add -A && git commit` のみ
- **Squash統合フロー**: Unit完了時のみ対応（設定確認→ユーザー確認→中間コミット→squash実行）
- Inception Phase用のsquashステップなし

### 変更箇所
- `commit-flow.md`: Inception Phase完了コミットにsquash統合フロー追加
- `inception.md`: 完了時手順にsquashステップ参照追加
- `squash-unit.sh`: `--retroactive` オプション追加（GIT_SEQUENCE_EDITOR方式）

## 2. review-flow.md（#231, #226）

### AIレビュー途中のユーザーレビュー移行箇所（#231対象）
4箇所で「人間レビューへ進む」選択肢が存在:
1. **ステップ4**: mode=recommend時の「いいえ」→ 人間レビューへ（これはAIレビュー開始前なので問題なし）
2. **ステップ5 反復後**: 「AIレビューを継続しますか？ / いいえ - 人間レビューへ進む」← **対象**
3. **ステップ5.5 反復後**: 「セルフレビューを継続しますか？ / いいえ - 人間レビューへ進む」← **対象**
4. **ステップ6**: 外部AIレビュー続行不能時の選択肢（これはフォールバックなので問題なし）

→ ステップ5とステップ5.5の継続確認で「人間レビューへ進む」を除去

### セルフレビューフォールバック（#226対象）
- **ステップ5.5**: 同一コンテキスト内でセルフレビューを実施
- 変更: Taskツール等でサブエージェントを起動し、コンテキスト分離してレビュー実行

## 3. PR作成テンプレート（新規: PRレビュアビリティ向上）

### construction.md（Unit PR）
- 現状: Unit概要 / 変更内容 / テスト結果
- 追加: 要件・受け入れ基準 / AIレビュー結果サマリ

### operations.md（サイクルPR）
- 現状: Summary / Test plan / Closes
- 追加: Intent概要・受け入れ基準 / 全体修正概要 / レビューサマリファイルへのリンク

### レビューサマリファイル
- 新規: AIレビュー実施時にサマリファイルを生成・蓄積
- 保存先（暫定）: `docs/cycles/{{CYCLE}}/construction/units/{NNN}-review-summary.md`
- 生成タイミング: AIレビュー完了時（review-flow.md のレビュー完了ステップ）

## 4. 用語変更（#230）

### 対象ファイル（prompts/package/配下）
| ファイル | 出現数 |
|---------|--------|
| prompts/common/review-flow.md | 約20箇所 |
| prompts/common/rules.md | 1箇所 |
| prompts/common/commit-flow.md | 2箇所 |
| prompts/inception.md | 1箇所 |
| prompts/construction.md | 1箇所 |
| prompts/operations.md | 1箇所 |
| prompts/CLAUDE.md | 1箇所 |
| prompts/lite/inception.md | 1箇所 |
| prompts/lite/construction.md | 1箇所 |

### 置換パターン
- 「人間レビュー」→「ユーザーレビュー」
- 「人間に承認」→「ユーザーに承認」
- 「人間に提示」→「ユーザーに提示」
- 「人間の承認」→「ユーザーの承認」
