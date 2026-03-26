# Unit 005 計画: Session Continuity

## 概要

セッション中断時の作業状態自動保存（session-state.md生成）と再開時の状態復元を正式にサポートする。

## 変更対象ファイル

1. **`prompts/package/prompts/common/compaction.md`** - session-state.md生成ステップを追加
2. **`prompts/package/prompts/common/context-reset.md`** - session-state.md生成・復元手順を追加（明示中断指示もここでハンドリング）
3. **`prompts/package/prompts/inception.md`** - 再開時のsession-state.md読み込みステップを追加
4. **`prompts/package/prompts/construction.md`** - 再開時のsession-state.md読み込みステップを追加
5. **`prompts/package/prompts/operations.md`** - 再開時のsession-state.md読み込みステップを追加

## 設計方針

### session-state.md の位置づけ

- 進捗情報の**上位セット**（フェーズ固有の進捗源を包含）
- 保存先: `docs/cycles/{{CYCLE}}/{phase}/session-state.md`（phaseはinception/construction/operations）
- 進捗源との二重管理を避けるため、session-state.mdは各フェーズの進捗源を参照しつつ追加情報を補完する構成

### session-state.md の必須記録項目（I/O契約）

以下のフィールドは**必須**。生成側・読込側で同一の構造を前提とする。

```markdown
# Session State

## メタ情報
- schema_version: 1
- saved_at: [ISO 8601形式の日時]
- source_phase_step: [保存時のフェーズ/ステップ]

## 基本情報
- サイクル: {{CYCLE}}
- フェーズ: {{PHASE}}
- 現在のステップ: [ステップ名/番号]

## 完了済みステップ
[フェーズ固有の進捗源から取得した完了ステップ一覧]

## 未完了タスク
[現在進行中のタスク、残作業の詳細]

## 次のアクション
[再開時に最初に実行すべきこと]

## コンテキスト情報（任意）
[中断時点で保持していた重要なコンテキスト（変数値、判断理由等）]
```

**読込時のバリデーション**:
- `schema_version` が存在し値が `1` であること（不一致時はフォールバック）
- `saved_at` が存在すること（鮮度判定に使用）
- 必須セクション（メタ情報、基本情報、完了済みステップ、未完了タスク、次のアクション）が全て存在すること
- いずれかの必須セクションが欠落している場合は破損とみなしフォールバック

### 生成タイミング（トリガー定義）

session-state.mdの生成は以下の3種類のイベントで発火する:

1. **コンパクション時**（compaction.md）: 自動要約前にsession-state.mdを生成
2. **コンテキストリセット時**（context-reset.md）: リセット前にsession-state.mdを生成
3. **明示的中断指示時**（context-reset.md）: ユーザーが「中断したい」「ここで止める」等の発言をした場合も、context-reset.mdの対応手順に従いsession-state.mdを生成する（context-reset.mdのトリガー条件に明示中断指示を含める）

生成ロジックは**common側に一本化**し、各フェーズプロンプトは「生成を呼び出すポイント」のみを持つ。

### フェーズ別の復元元インターフェース

フォールバック時の進捗復元元はフェーズごとに異なる:

| フェーズ | session-state.md（優先） | フォールバック復元元 |
|---------|------------------------|-------------------|
| Inception | `inception/session-state.md` | `inception/progress.md` |
| Construction | `construction/session-state.md` | Unit定義ファイル（`story-artifacts/units/*.md`）の「実装状態」セクション |
| Operations | `operations/session-state.md` | `operations/progress.md` |

### フォールバック動作

- **session-state.md生成失敗時**: 警告を表示し、既存の進捗源による復元に頼る（処理継続）
- **session-state.md不在時の再開**: フェーズ固有の進捗源から復元（新規インストール環境との互換性）
- **session-state.md破損時**（必須セクション欠落）: 警告を表示し、フェーズ固有の進捗源から復元

## 実装計画

### ステップ1: compaction.md の変更

手順3（プロンプト・進捗の再読み込み）の前に「session-state.md生成」ステップを挿入:
- 現在のフェーズ・ステップ・進捗をsession-state.mdに書き出す（上記I/O契約に従う）
- 生成失敗時は警告表示のみで処理を継続

### ステップ2: context-reset.md の変更

- 対応手順の「3. 履歴記録」の後に「session-state.md生成」ステップを追加
- トリガー条件にユーザーの明示的な中断指示（「中断したい」「ここで止める」等）を追加
- 継続用プロンプトにsession-state.mdの存在を前提とした復元手順を追記

### ステップ3: inception.md の変更

初期チェック（フェーズ再開検出時）にsession-state.md読み込みステップを追加:
- `docs/cycles/{{CYCLE}}/inception/session-state.md` の存在確認
- 存在すれば読込バリデーション（schema_version、必須セクション確認）を実施し、中断時点から再開
- 不在またはバリデーション失敗ならprogress.mdから復元（既存動作）

### ステップ4: construction.md の変更

同様に初期チェックにsession-state.md読み込みステップを追加:
- `docs/cycles/{{CYCLE}}/construction/session-state.md` の存在確認
- フォールバックはUnit定義ファイルの「実装状態」セクション（既存動作）

### ステップ5: operations.md の変更

同様に初期チェックにsession-state.md読み込みステップを追加:
- `docs/cycles/{{CYCLE}}/operations/session-state.md` の存在確認

## 完了条件チェックリスト

- [x] compaction.mdにsession-state.md生成ステップが追加されている
- [x] context-reset.mdにsession-state.md生成・復元手順が追加されている
- [x] context-reset.mdのトリガー条件に明示的な中断指示が含まれている
- [x] inception.mdの再開時にsession-state.md読み込みが行われる
- [x] construction.mdの再開時にsession-state.md読み込みが行われる（フォールバックはUnit定義ファイル）
- [x] operations.mdの再開時にsession-state.md読み込みが行われる
- [x] session-state.mdの必須記録項目にschema_version, saved_at, source_phase_stepが含まれている
- [x] 読込時のバリデーション（schema_version確認、必須セクション存在確認）が定義されている
- [x] session-state.md生成失敗・不在・破損時のフォールバックがフェーズ別に記載されている
- [x] 生成ロジックがcommon側に一本化されている
