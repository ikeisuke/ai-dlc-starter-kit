# Unit: 非SemVerサイクル命名対応

## 概要
suggest-version.shが非SemVerサイクルも認識できるようにし、Inception Phaseのバージョン決定フローに自由入力（カスタム名）の選択肢を追加する。

## 含まれるユーザーストーリー
- ストーリー 6: suggest-version.shの非SemVer対応 (#217-B)

## 関連Issue
- #217

## 責務
- `suggest-version.sh` に `get_all_cycles()` 関数を追加（全サイクルディレクトリ列挙）
- 出力に `all_cycles:` 行を追加
- Inception Phase ステップ6に「カスタム名を入力する」選択肢を追加
- 重複チェック（既存サイクルとの名前衝突検出）

## 境界
- 既存のSemVerバージョン提案フロー（patch/minor/major）は変更しない
- `init-cycle-dir.sh` と `setup-branch.sh` は既に非SemVer名を受け付けるため変更不要
- バックログ表示は含まない（Unit 004で対応済み）

## 依存関係

### 依存する Unit
- Unit 004: サイクルバージョン決定コンテキスト表示（依存理由: 同じ `inception.md` ステップ6を修正するため、コンテキスト表示の追加が先に完了している必要がある）

### 外部依存
- なし

## 非機能要件（NFR）
- **パフォーマンス**: 該当なし
- **セキュリティ**: 該当なし
- **スケーラビリティ**: 該当なし
- **可用性**: 該当なし

## 技術的考慮事項
- `suggest-version.sh` の `get_all_cycles()` は `docs/cycles/` 配下のディレクトリを列挙し、非サイクルディレクトリ（`backlog`, `backlog-completed`, `rules.md` 等）を除外する
- サイクル名判定ルール: `backlog`, `backlog-completed` を除外。それ以外のディレクトリ名をサイクル名として扱う
- 出力形式: `all_cycles:v1.18.2,v1.18.3,feature-auth,...`（カンマ区切り）
- Inception Phase ステップ6で `all_cycles` を使って重複チェック
- `prompts/package/prompts/inception.md` と `prompts/package/bin/suggest-version.sh` の両方を修正

## 実装優先度
Medium

## 見積もり
小〜中（スクリプト拡張 + プロンプト修正）

---
## 実装状態

- **状態**: 完了
- **開始日**: 2026-03-03
- **完了日**: 2026-03-03
- **担当**: AI
