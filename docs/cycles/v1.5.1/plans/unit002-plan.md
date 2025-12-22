# Unit 002: 履歴保存タイミングの明確化 - 実行計画

**作成日**: 2025-12-21 22:03:54 JST
**更新日**: 2025-12-21
**Unit**: 002-clarify-history-save-timing

---

## 概要

履歴ファイル（history/*.md）への記録タイミングを設定可能にし、ステップ単位での記録を基本とする。
また、修正があった場合は変更点を履歴に追記する機能を追加する。

---

## 要件

1. **記録頻度の設定**: `aidlc.toml` で記録頻度を選択可能にする
   - `step`（デフォルト）: 各ステップ完了時に記録
   - `unit`: Unit完了時にまとめて記録

2. **差分記録**: ユーザーからの修正依頼があった場合、変更点を履歴に追記
   - 修正がなければ記録しない
   - 修正があれば「修正前 → 修正後」の要点を記録

---

## 作業ステップ

### Phase 1: 設計

#### ステップ 1.1: 設定項目の設計

`aidlc.toml` に追加する設定:
```toml
[rules.history]
frequency = "step"  # "step" | "unit"
```

#### ステップ 1.2: 履歴記録フォーマットの設計

ステップ完了時の記録フォーマット:
```markdown
## YYYY-MM-DD HH:MM:SS

- **フェーズ**: Construction Phase
- **Unit**: [Unit名]
- **ステップ**: [ステップ名]
- **実行内容**: [作業概要]
- **成果物**: [作成・更新したファイル]

### 修正履歴（該当する場合のみ）
- **修正依頼**: [ユーザーからのフィードバック要約]
- **変更点**: [修正前 → 修正後の要点]

---
```

#### ステップ 1.3: 設計レビュー

方針をユーザーに提示し承認を得る

### Phase 2: 実装

#### ステップ 2.1: aidlc.toml テンプレート更新

`prompts/package/templates/aidlc_toml_template.toml` に `[rules.history]` セクション追加

#### ステップ 2.2: 各フェーズのプロンプト更新

以下のファイルを更新:
- `prompts/package/prompts/inception.md`
- `prompts/package/prompts/construction.md`
- `prompts/package/prompts/operations.md`

更新内容:
- 履歴記録タイミングを `aidlc.toml` の設定に従うよう変更
- 修正時の差分記録ルールを追加

#### ステップ 2.3: 統合・確認

- 変更内容の確認
- 実装記録の作成

---

## 成果物

1. 更新されるファイル:
   - `prompts/package/templates/aidlc_toml_template.toml`
   - `prompts/package/prompts/inception.md`
   - `prompts/package/prompts/construction.md`
   - `prompts/package/prompts/operations.md`

2. 作成するファイル:
   - `docs/cycles/v1.5.1/construction/units/002-clarify-history-save-timing_implementation.md`
   - `docs/cycles/v1.5.1/history/construction_unit2.md`

---

## 特記事項

- 修正対象は `prompts/package/` 配下（`docs/aidlc/` は直接編集禁止）
- 関連バックログ: `docs/cycles/backlog/chore-adjust-history-save-timing.md` → 完了後に移動
