# Session Continuity

## session-state.md の生成

セッション中断時に、現在の作業状態を `.aidlc/cycles/{{CYCLE}}/{{PHASE_DIR}}/session-state.md` に保存する。

`{{PHASE_DIR}}` は現在のフェーズに対応するディレクトリ名: `inception` | `construction` | `operations`

以下の構成で生成する:

```markdown
# Session State

## メタ情報
- schema_version: 1
- saved_at: [ISO 8601形式の日時]
- source_phase_step: [現在のフェーズ/ステップ]

## 基本情報
- サイクル: [現在のサイクル]
- フェーズ: [現在のフェーズ]
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

**生成失敗時**: 警告を表示し、処理を継続する。既存のprogress.md・Unit定義ファイルによる復元で対応可能。

## session-state.md の復元

フェーズ再開時に `.aidlc/cycles/{{CYCLE}}/{{PHASE_DIR}}/session-state.md` の存在を確認する。

- **存在する場合**: 読み込み、以下のバリデーションを実施する:
  - `schema_version` が `1` であること
  - 必須セクション（メタ情報、基本情報、完了済みステップ、未完了タスク、次のアクション）が全て存在すること
  - バリデーション成功: 中断時点のステップから作業を再開
  - バリデーション失敗: 警告を表示し、フェーズ固有の進捗源にフォールバック
- **存在しない場合**: フェーズ固有の進捗源から復元（新規インストール環境との互換性）

**フェーズ別の進捗源（フォールバック先）**:

| フェーズ | フォールバック復元元 |
|---------|-------------------|
| Inception | `inception/progress.md` |
| Construction | Unit定義ファイル（`story-artifacts/units/*.md`）の「実装状態」セクション |
| Operations | `operations/progress.md` |

## コンパクション復帰

コンパクション復帰と判定された場合は `steps/common/compaction.md` を読み込む。
