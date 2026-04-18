# Unit 005 実行計画: config.toml.template の ai_author デフォルトを空文字に変更

## 対象Unit

- **Unit 定義**: `.aidlc/cycles/v2.3.5/story-artifacts/units/005-ai-author-template-default-empty.md`
- **関連Issue**: #577
- **優先度**: Medium / 見積もり: XS（Extra Small）
- **依存する Unit**: なし（Unit 001-004 と論理的・実装的に独立）

## 背景・目的

### 現状の不一致

`defaults.toml` と `migrate-config.sh` は `ai_author = ""` に統一されているが、`config.toml.template`（setup 時に配置されるファイル）と `config.toml.example`（サンプル）だけが旧既定 `"Claude <noreply@anthropic.com>"` のまま残っている。

| ファイル | 現在値 | 本 Unit 後の値 |
|---------|-------|--------------|
| `skills/aidlc/config/defaults.toml` | `""` | 変更なし |
| `skills/aidlc-setup/config/defaults.toml` | `""` | 変更なし |
| `skills/aidlc-setup/scripts/migrate-config.sh` | `""` | 変更なし |
| **`skills/aidlc-setup/templates/config.toml.template`** | `"Claude <noreply@anthropic.com>"` | `""` |
| **`skills/aidlc/config/config.toml.example`** | `"Claude <noreply@anthropic.com>"` | `""` |

### 本 Unit のゴール

新規 `aidlc setup` 実行直後の `config.toml` で `ai_author = ""` となり、`commit-flow.md` の自動検出フロー（自己認識 → 環境変数 → ユーザー確認）が setup 直後から機能するようにする。

## スコープ（責務）

Unit 定義「責務」セクションの全項目を本計画のスコープとする。

- `skills/aidlc-setup/templates/config.toml.template`:
  - `ai_author = "Claude <noreply@anthropic.com>"` → `ai_author = ""`
  - コメント `# - デフォルト: "Claude <noreply@anthropic.com>"` → `# - デフォルト: ""（空なら自動検出）`
- `skills/aidlc/config/config.toml.example`:
  - `ai_author = "Claude <noreply@anthropic.com>"` → `ai_author = ""`（空文字リテラル、候補 A に確定済み）
- 動作確認:
  - 新規 setup 後の `config.toml` で `ai_author = ""` となることを確認
  - `ai_author × ai_author_auto_detect` 3 パターンの挙動が `commit-flow.md` と一貫していることを目視確認

## 変更対象ファイル

- `skills/aidlc-setup/templates/config.toml.template`（コメント行 + 値行の 2 箇所）
- `skills/aidlc/config/config.toml.example`（値行 1 箇所、場合によってコメント追加）

## 設計で確定すべき論点

1. **`config.toml.example` の表現形式**（**方針確定: 候補 A**）:
   - 採用: 値行を `ai_author = ""` のリテラルに変更（template・defaults.toml・migrate-config.sh と同じ形式）
   - 確定理由: 「5 ファイル全て `ai_author = ""` に揃う」状態を維持することで、ユーザーが比較・理解しやすく、かつ setup 直後の自動検出起動条件（空文字）が `.example` を見ても明確。設計フェーズでもこの方針を再確認する
   - 設計レビューでは候補 A の詳細（コメント付与の要否）のみ論点として残す

2. **`config.toml.example` のコメント追加有無**:
   - template 側にはコメント 3 行（項目説明）が既に存在するが、`.example` にはコメントなしの 1 行のみ
   - 方針: `.example` は必要最小限にとどめ、既存スタイルに揃える（本 Unit では**コメントは追加しない**）
   - 設計レビューで確定

3. **他ドキュメントとの整合性**:
   - `config-merge.md`, `commit-flow.md` など ai_author の言及箇所と矛盾がないかを目視確認する
   - 追加の文書更新が発生した場合は本 Unit に含める判断を設計で行う

## 完了条件チェックリスト

### ファイル変更

- [ ] `skills/aidlc-setup/templates/config.toml.template` の `ai_author = "Claude <noreply@anthropic.com>"` を `ai_author = ""` に変更
- [ ] 同ファイルのコメント行 `# - デフォルト: "Claude <noreply@anthropic.com>"` を `# - デフォルト: ""（空なら自動検出）` に変更
- [ ] `skills/aidlc/config/config.toml.example` の `ai_author` 値を `ai_author = ""` に変更

### 整合性

- [ ] `defaults.toml`（aidlc 側 / aidlc-setup 側）、`migrate-config.sh`、template、example の 5 ファイルで `ai_author = ""` が揃っていることを確認
- [ ] `commit-flow.md` の自動検出フロー（空 × true / 空 × false / 明示値 × 任意）が本 Unit の変更で壊れていないことを目視確認
- [ ] `空 × true` 分岐内の既存フォールバック（自己認識失敗 → 環境変数 → ユーザー確認、最終的にユーザー拒否時は Co-Authored-By なしで続行）が維持されていることを目視確認

### テスト・検証

- [ ] 新規 setup 動作確認（`/tmp` 等で新規 `aidlc setup` を実行し、生成された `config.toml` で `ai_author = ""` かつ `ai_author_auto_detect = true` となることを確認）
- [ ] 自動検出フロー起動の実証（新規 setup 直後の `config.toml` を用いて `commit-flow.md` の ai_author 分岐判定箇所を読み、`ai_author = "" × ai_author_auto_detect = true` のパスが「自己認識 → 環境変数 → ユーザー確認」の自動検出フローに入ることを論理的に確認。可能ならダミー commit を実行して分岐が起動することを目視確認）
- [ ] markdownlint は TOML ファイル変更のため対象外（`run-markdownlint.sh` は markdown のみ）

### 完了基準

- [ ] 計画レビュー Codex 承認（auto_approved）
- [ ] 設計レビュー Codex 承認（auto_approved）
- [ ] コードレビュー Codex 承認（auto_approved）
- [ ] 統合レビュー Codex 承認（auto_approved）
- [ ] Unit 定義ファイルの実装状態を「完了」に更新
- [ ] 履歴記録（`/write-history`）完了
- [ ] squash 完了 → commit 完了

## 依存 / 前提

- Unit 001-004 と独立（依存なし）
- 外部スクリプト変更なし（本 Unit は TOML 2 ファイルのテキスト変更のみ）
- 既存プロジェクトへの遡及変更なし（新規 setup のみが影響対象）

## リスクと対策

| リスク | 影響 | 対策 |
|--------|------|------|
| template と example の値が不一致のまま残る | 中 | 設計フェーズで両ファイルの値・コメント方針を明記し、実装レビューで両方変更済みを確認 |
| 旧既定で setup 済みプロジェクトが自動更新されない | 低（仕様通り） | Unit 定義「境界」で除外済み。必要なユーザーは手動で `config.toml` を書き換える運用 |
| `commit-flow.md` の既存フォールバック動作が意図せず変わる | 中 | `commit-flow.md` を変更しない。目視確認で既存仕様維持を担保 |
| 動作確認が不十分で自動検出フローの起動を実証できない | 中 | 新規 setup（`/tmp` 配下）を実行し `ai_author = ""` / `ai_author_auto_detect = true` を確認。加えて `commit-flow.md` の ai_author 分岐判定箇所を読解し、可能ならダミー commit により自動検出フロー起動を目視確認する |

## スコープ外（Unit 定義「境界」セクション準拠）

- 既存プロジェクトの `.aidlc/config.toml` 実ファイルへの遡及変更（ユーザーが手動対応）
- `skills/aidlc/config/defaults.toml` / `skills/aidlc-setup/config/defaults.toml` の変更（既に `""`）
- `skills/aidlc-setup/scripts/migrate-config.sh` の変更（既に `""`）
- `commit-flow.md` 自動検出フロー自体の変更
- `ai_author_auto_detect` 既定値の変更（`true` のまま維持）
- 旧既定値で setup 済みのプロジェクトの自動マイグレーション

## 参照

- Unit 定義: `.aidlc/cycles/v2.3.5/story-artifacts/units/005-ai-author-template-default-empty.md`
- Issue: #577
- 関連ファイル:
  - `skills/aidlc-setup/templates/config.toml.template`
  - `skills/aidlc/config/config.toml.example`
  - `skills/aidlc/config/defaults.toml`
  - `skills/aidlc-setup/config/defaults.toml`
  - `skills/aidlc-setup/scripts/migrate-config.sh`
  - `skills/aidlc/steps/common/commit-flow.md`
