# Unit 006 実行計画: 設定保存フローの暗黙書き込み防止（デフォルト「いいえ」化 + ユーザー選択必須化）

## 対象Unit

- **Unit 定義**: `.aidlc/cycles/v2.3.5/story-artifacts/units/006-settings-save-flow-explicit-opt-in.md`
- **関連Issue**: #578
- **優先度**: Medium / 見積もり: S（Small）
- **依存する Unit**: なし（独立 Unit）

## 背景・目的

### 現状の問題

3 箇所の「設定保存フロー」（`branch_mode`, `draft_pr`, `merge_method`）で、ユーザーが明確に意図していない状態でも `.aidlc/config.local.toml` に個人設定が書き込まれる可能性がある:

| # | ファイル | 対象キー | 現状の記述 |
|---|---------|---------|----------|
| 1 | `skills/aidlc/steps/inception/01-setup.md` §9-1 | `rules.git.branch_mode` | 「この選択を設定に保存しますか？」→「はい / いいえ」の順、Recommended 指定なし |
| 2 | `skills/aidlc/steps/inception/05-completion.md` §5d-1 | `rules.git.draft_pr` | 同上 |
| 3 | `skills/aidlc/steps/operations/operations-release.md` 設定保存フロー | `rules.git.merge_method` | 同上 |

既存仕様の課題:

- `AskUserQuestion` 必須化の明示がない → `automation_mode=semi_auto` / `full_auto` 時にゲート承認扱いされ自動承認される懸念
- デフォルト選択肢の順序・Recommended 指定がない → 「保存するのが当たり前」という誤認を誘発する可能性
- 3 ファイル間で質問文・選択肢順序・保存先説明が微妙に不揃い

### 本 Unit のゴール

- 3 箇所の設定保存フローを「ユーザー選択」種別として明示し、`AskUserQuestion` を `automation_mode` に関わらず必須化する
- デフォルト選択肢を「いいえ（今回のみ使用）」に変更し、Recommended（先頭）配置
- 「はい（保存する）」を 2 番目に配置
- 3 ファイルで統一フォーマットを採用し、SKILL.md「AskUserQuestion 使用ルール」と整合させる

## スコープ（責務）

Unit 定義「責務」セクションの全項目を本計画のスコープとする。

### 編集対象

1. `skills/aidlc/SKILL.md`「AskUserQuestion 使用ルール」
   - 「ユーザー選択」種別の具体例に「設定保存確認（`branch_mode` / `draft_pr` / `merge_method`）」を追加（または類似の明記）
   - 現行の 3 種別テーブル構造を壊さない
2. `skills/aidlc/steps/inception/01-setup.md` §9-1 設定保存フロー
3. `skills/aidlc/steps/inception/05-completion.md` §5d-1 設定保存フロー
4. `skills/aidlc/steps/operations/operations-release.md` 設定保存フロー

### 3 ステップファイル共通の記述要件

- 「ユーザー選択」種別に該当することを明記（SKILL.md への参照でも可）
- `AskUserQuestion` が必須で `automation_mode` に関わらず自動化対象外であることをインライン注記
- 選択肢順序と Recommended 指定:
  1. 「いいえ（今回のみ使用）(Recommended)」
  2. 「はい（保存する）」
- 質問文の骨格・選択肢ラベル・保存先選択の説明（説明文の文言）を共通フォーマットで揃える
- 「はい」選択時のみ保存先選択（デフォルト: `config.local.toml`、代替: `config.toml`）に続く

### 3 ステップファイル固有の保持条件（共通化しても退行させない）

| ファイル | 対象キー | 本 Unit で**必ず維持**すべき条件 |
|---------|---------|-------------------------------|
| `01-setup.md` §9-1 | `branch_mode` | `branch_mode=ask` で「現在のブランチで続行」を選択した場合は設定保存フロー自体に入らない（保存対象外）。従来仕様を維持 |
| `05-completion.md` §5d-1 | `draft_pr` | 保存値マッピング「`AskUserQuestion` の『はい（作成）』→ `always` / 『いいえ（作成しない）』→ `never`」を維持。`action=ask_user` の場合のみ設定保存フローに入る（`skip_never` / `create_draft_pr` ではスキップ） |
| `operations-release.md` 設定保存フロー | `merge_method` | ユーザーが選んだ値（`merge` / `squash` / `rebase` のいずれか）をそのまま保存。`merge_method=ask` 時のみ設定保存フローに入る |

### 保存先選択の扱い（Unit 定義境界の解釈を明示）

Unit 定義「境界」の『「はい（保存する）」選択時の書き込み先・フォーマット変更（従来通り `config.local.toml` へ書き込み）』は「書き込みフォーマット変更を行わない」という意味と解釈する。保存先選択フロー（デフォルト `config.local.toml`、代替 `config.toml`）**自体は既存仕様として維持**する。本 Unit は opt-in 化（デフォルト「いいえ」+ `AskUserQuestion` 必須化）のみを扱い、保存先選択の 2 択は現状維持する。

### スコープ外

- `scripts/write-config.sh` 自体の挙動変更（呼び出し側のユーザー選択ロジックのみ修正）
- `.aidlc/config.local.toml` の既存エントリへの遡及削除・修正
- 3 箇所以外の設定保存フロー（他箇所があれば別 Issue / 別 Unit で対応）
- `AskUserQuestion` の表示ライブラリ・UI 仕様変更
- 「はい」選択時の書き込み先・フォーマット変更

## 設計で確定すべき論点

1. **SKILL.md への具体例追加方式**:
   - 候補 A: 既存「ユーザー選択」行の「具体例」列に『設定保存確認（branch_mode/draft_pr/merge_method）』を追記
   - 候補 B: 新規セクション「設定保存確認の扱い」を追加して 3 場面を一覧化
   - 推奨: **候補 A**（既存構造を壊さず最小変更で目的達成。設計レビューで確定）
2. **3 ステップファイルの統一フォーマット雛形**:
   - 質問文: 「この選択を設定に保存しますか？」を共通化
   - 注記文: 「本確認は『ユーザー選択』種別のため、`automation_mode` に関わらず `AskUserQuestion` を使用してユーザーに確認する」等の共通定型
   - 選択肢: 「いいえ（今回のみ使用）(Recommended)」「はい（保存する）」の 2 択
   - 保存先: 「はい」選択時にのみ「デフォルト: `config.local.toml`、代替: `config.toml`」を提示
   - 設計フェーズで雛形を確定
3. **`AskUserQuestion` の option.label 表記**:
   - `label` 末尾に `(Recommended)` を付与する方針（Unit 定義の技術的考慮事項に準拠）

## 完了条件チェックリスト

### ファイル変更

- [ ] `skills/aidlc/SKILL.md` の「AskUserQuestion 使用ルール」に 3 場面（設定保存確認）を具体例として明記
- [ ] `skills/aidlc/steps/inception/01-setup.md` §9-1 の設定保存フロー記述を統一フォーマットに更新
- [ ] `skills/aidlc/steps/inception/05-completion.md` §5d-1 の設定保存フロー記述を統一フォーマットに更新
- [ ] `skills/aidlc/steps/operations/operations-release.md` の設定保存フロー記述を統一フォーマットに更新

### 整合性

- [ ] 3 ステップファイルで質問文・選択肢順序・保存先説明が統一フォーマットに揃っていること
- [ ] SKILL.md の具体例追記と 3 ステップファイルの記述が整合していること
- [ ] 「はい」選択時の書き込み動作が既存仕様と変わっていないこと
- [ ] `draft_pr` の保存値マッピング（はい→`always` / いいえ→`never`）が維持されていること
- [ ] `branch_mode` の「現在のブランチで続行」選択時は設定保存フローに入らない（従来仕様）ことが維持されていること
- [ ] `merge_method` は選択値（merge/squash/rebase）をそのまま保存する仕様が維持されていること
- [ ] 保存先選択フロー（デフォルト `config.local.toml`、代替 `config.toml`）が本 Unit で変更されていないこと

### 挙動マトリクス（目視確認）

**A. デフォルト選択とユーザー応答**

| automation_mode | 選択肢 Enter（デフォルト） | 「はい（保存する）」明示選択 |
|----------------|------------------------|-------------------------|
| manual | いいえ（今回のみ使用）→ 保存せず続行 | 保存先選択（local/project） → 書き込み |
| semi_auto | いいえ（今回のみ使用）→ 保存せず続行 | 保存先選択（local/project） → 書き込み |
| full_auto | いいえ（今回のみ使用）→ 保存せず続行 | 保存先選択（local/project） → 書き込み |

**B. AskUserQuestion 必須化の確認（対話種別が正しくマッピングされていること）**

| automation_mode | 設定保存確認の起動形態 | 期待 |
|----------------|--------------------|-----|
| manual | `AskUserQuestion` | テキスト出力代替不可 |
| semi_auto | `AskUserQuestion` | ゲート承認として `auto_approved` されない |
| full_auto | `AskUserQuestion` | 全自動フローでも `AskUserQuestion` が起動し、ユーザー選択なしで自動保存されない |

- [ ] 3 ステップファイルで上記マトリクス A / B が成立することを目視確認
- [ ] 特に `automation_mode=full_auto` / `semi_auto` でも `AskUserQuestion` を経由することを各ステップファイル記述で確認

### テスト・検証

- [ ] Markdown 構文確認（見出し・表・箇条書き崩れなし）
- [ ] 実動作確認: **Inception Phase** で `branch_mode` / `draft_pr` の 2 場面、**Operations Phase** で `merge_method` の 1 場面（合計 3 場面）を通るケースで、`AskUserQuestion` が起動しデフォルトが「いいえ（今回のみ使用）(Recommended)」に配置されていることを目視確認（可能な範囲で）
- [ ] markdownlint 実行（`markdown_lint=false` ならスキップ）

### 完了基準

- [ ] 計画レビュー Codex 承認（auto_approved）
- [ ] 設計レビュー Codex 承認（auto_approved）
- [ ] コードレビュー Codex 承認（auto_approved）
- [ ] 統合レビュー Codex 承認（auto_approved）
- [ ] 設計・実装整合性チェック完了
- [ ] Unit 定義ファイルの実装状態を「完了」に更新
- [ ] 履歴記録（`/write-history`）完了
- [ ] squash 完了 → commit 完了

## 依存 / 前提

- Unit 001-005 と独立（依存なし）
- 外部スクリプト変更なし（`write-config.sh` の呼び出しインターフェースは既存のまま）
- 既存プロジェクトの `config.local.toml` には影響しない（既存エントリは残る）

## リスクと対策

| リスク | 影響 | 対策 |
|--------|------|------|
| 3 ファイルの更新が不揃いで統一フォーマットが崩れる | 中 | 設計フェーズで雛形を策定し、実装レビューで 3 ファイル同期を確認 |
| `AskUserQuestion` 必須化の注記が曖昧で `automation_mode=full_auto` 時に自動化される誤解が残る | 中 | 注記を「`automation_mode=full_auto` を含む全モードで `AskUserQuestion` が起動する」と明示。SKILL.md の既存ルールに明示的に参照リンク |
| 既存ユーザーが「いいえ」デフォルトで意図しない非保存に流れる | 低 | デフォルト Enter で「保存しない」動作となるが、それが Issue #578 の要求そのもの。ユーザーに「今回のみ使用」を明示することで誤解を避ける |
| 「はい」選択時の保存先選択（local/project）の既存仕様が壊れる | 低 | 保存先選択フローは変更しない。現行の「デフォルト `config.local.toml`、代替 `config.toml`」仕様を維持 |
| SKILL.md の既存テーブル構造を壊す | 中 | 候補 A（具体例列への追記）を採用し、行の追加・列の削除を行わない |

## スコープ外（Unit 定義「境界」セクション準拠）

- `scripts/write-config.sh` 自体の挙動変更
- `.aidlc/config.local.toml` の既存エントリへの遡及的削除・修正
- 3 箇所以外の設定保存フロー
- `AskUserQuestion` 表示ライブラリ・UI 仕様の変更
- 「はい（保存する）」選択時の書き込み先・フォーマット変更

## 参照

- Unit 定義: `.aidlc/cycles/v2.3.5/story-artifacts/units/006-settings-save-flow-explicit-opt-in.md`
- Issue: #578
- 関連ファイル:
  - `skills/aidlc/SKILL.md`（「AskUserQuestion 使用ルール」）
  - `skills/aidlc/steps/inception/01-setup.md`
  - `skills/aidlc/steps/inception/05-completion.md`
  - `skills/aidlc/steps/operations/operations-release.md`
  - `skills/aidlc/scripts/write-config.sh`（変更なし、参照のみ）
