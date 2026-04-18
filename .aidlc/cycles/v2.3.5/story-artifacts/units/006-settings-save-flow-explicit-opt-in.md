# Unit: 設定保存フローの暗黙書き込み防止（デフォルト「いいえ」化 + ユーザー選択必須化）

## 概要

`rules.git.branch_mode` / `rules.git.draft_pr` / `rules.git.merge_method` の 3 箇所の設定保存フローで、`.aidlc/config.local.toml` への暗黙的な書き込みを防止する。インタラクション種別を「ユーザー選択」に明示化し、`AskUserQuestion` を `automation_mode` に関わらず必須化する。デフォルト選択肢を「いいえ（今回のみ使用）」に変更し、意図的な保存のみが実行される体制に改める。

## 含まれるユーザーストーリー

- ストーリー 5: 設定保存フローで意図しない暗黙書き込みが発生しない（#578）

## 責務

- `skills/aidlc/SKILL.md`（または共通ルールドキュメント）の「AskUserQuestion 使用ルール」に、以下 3 場面を「ユーザー選択」種別として明記
  - `rules.git.branch_mode` の保存（`steps/inception/01-setup.md`）
  - `rules.git.draft_pr` の保存（`steps/inception/05-completion.md`）
  - `rules.git.merge_method` の保存（`steps/operations/operations-release.md`）
- 上記 3 ステップファイルの設定保存フロー記述を更新:
  - `AskUserQuestion` を必須化（`automation_mode=semi_auto` / `full_auto` でも自動承認されないことを明記）
  - デフォルト選択肢を「いいえ（今回のみ使用）」に変更し、Recommended（先頭）配置
  - 「はい（保存する）」を 2 番目に配置
- 3 ファイルで質問文・選択肢順序・保存先既定の説明を統一フォーマットで揃える
- 挙動マトリクス（manual / semi_auto / full_auto × デフォルト Enter / 明示的「はい」選択）が受け入れ基準通りに動作することを目視確認

## 境界

- 実装対象外:
  - `scripts/write-config.sh` 自体の挙動変更（呼び出し側のユーザー選択ロジックのみ修正）
  - `.aidlc/config.local.toml` の既存エントリへの遡及的削除・修正
  - 3 箇所以外の設定保存フロー（存在すれば別 Issue / 別 Unit で対応）
  - `AskUserQuestion` 表示ライブラリ・UI 仕様の変更
  - 「はい（保存する）」選択時の書き込み先・フォーマット変更（従来通り `config.local.toml` へ書き込み）

## 依存関係

### 依存する Unit

- なし（独立 Unit）

### 外部依存

- なし

## 非機能要件（NFR）

- **パフォーマンス**: 影響なし（対話フローの選択肢順序変更のみ）
- **セキュリティ**: 個人設定の暗黙書き込み防止によりプロジェクト共有設定と個人設定の境界が明確化
- **スケーラビリティ**: N/A
- **可用性**: 既存の「はい（保存する）」選択時の書き込み動作は変更なし。下位互換維持

## 技術的考慮事項

- **3 ファイル同期更新の原則**: SKILL.md「AskUserQuestion 使用ルール」の記述と 3 ステップファイルの記述は同期して更新する（片方だけの更新は整合性違反）
- **統一フォーマットの策定**: 3 ファイルで完全なテキスト一致までは求めないが、同一のユーザー体験となる記述（質問文の骨格、選択肢ラベル、保存先説明）を共通化する。フォーマット雛形は設計フェーズで策定
- **テキスト表現の再利用**: 既存の `branch_mode` / `draft_pr` / `merge_method` それぞれの既存フローを参考に、共通部分と固有部分を分離して記述
- **automation_mode 挙動の明示**: `full_auto` でも `AskUserQuestion` 必須となる旨を、各ステップファイル内でインライン注記（読み手が SKILL.md を参照せずとも誤解しないため）
- **Recommended ラベル**: `AskUserQuestion` の option ラベル末尾に `(Recommended)` を付与する規約を採用
- **既存の SKILL.md 記述との整合**: 既存の「AskUserQuestion 使用ルール」テーブルに 3 場面を追加する形を想定。テーブル構造を壊さない

## 関連Issue

- #578

## 実装優先度

Medium

## 見積もり

**S（Small）** - SKILL.md 1 ファイルと 3 ステップファイルの記述書き換え。統一フォーマット策定と 3 ファイルへの適用が中心作業。変更範囲は中程度。

---
## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 完了
- **開始日**: 2026-04-18
- **完了日**: 2026-04-18
- **担当**: Claude Code + Codex
- **エクスプレス適格性**: -
- **適格性理由**: -
