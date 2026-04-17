# Unit: config.toml.template の ai_author デフォルトを空文字に変更

## 概要

`skills/aidlc-setup/templates/config.toml.template` の `ai_author` 既定値を `"Claude <noreply@anthropic.com>"` から空文字 `""` に変更する。あわせて同ファイルのコメントを「空なら自動検出」と整合させる。さらに `skills/aidlc/config/config.toml.example` のサンプル値・コメントも新既定に揃える。新規 setup 時に自動検出フローが setup 直後から機能するようにすることが目的。

## 含まれるユーザーストーリー

- ストーリー 4: setup 直後から ai_author 自動検出が機能する（#577）

## 責務

- `skills/aidlc-setup/templates/config.toml.template` の `ai_author` 行の既定値を `""` に変更
- 同ファイルの `# - デフォルト: "Claude <noreply@anthropic.com>"` コメントを `# - デフォルト: ""（空なら自動検出）` に変更
- `skills/aidlc/config/config.toml.example` の `ai_author` サンプル値・コメントを空文字既定に整合させる（コメントアウト例示 or 空文字リテラル）
- 新規 `aidlc setup` 実行後の `config.toml` で `ai_author` が空のままとなり、`commit-flow.md` の自動検出フローが起動することを動作確認
- `ai_author × ai_author_auto_detect` の 3 パターン（空×true / 空×false / 明示値×任意）が `commit-flow.md` の挙動と一貫していることを目視確認
- `空 × true` 分岐内の既存フォールバック挙動を維持することを確認:
  - 自己認識失敗時はユーザー確認フローへ遷移（`commit-flow.md` 既存仕様）
  - 自動検出失敗かつユーザー確認も拒否された場合、Co-Authored-By なしでコミット続行（従来仕様）
  - 環境変数優先順位（自己認識 → 環境変数 → ユーザー確認）は変更しない

## 境界

- 実装対象外:
  - 既存プロジェクトの `.aidlc/config.toml` 実ファイルへの遡及変更（ユーザーが手動で書き換える運用）
  - `skills/aidlc/config/defaults.toml` / `skills/aidlc-setup/config/defaults.toml` の変更（既に `""` のため変更不要）
  - `skills/aidlc-setup/scripts/migrate-config.sh` の変更（既に `""` のため変更不要）
  - `commit-flow.md` 自動検出フロー自体の変更（本 Unit は既定値変更のみ）
  - `ai_author_auto_detect` 既定値の変更（`true` のまま維持）
  - 旧既定値で setup 済みのプロジェクトの自動マイグレーション

## 依存関係

### 依存する Unit

- なし（独立 Unit、Unit 001-004 と論理的にも実装的にも独立）

### 外部依存

- なし

## 非機能要件（NFR）

- **パフォーマンス**: 影響なし（テンプレート既定値の変更のみ）
- **セキュリティ**: 影響なし（識別情報の取り扱い方針は既存）
- **スケーラビリティ**: N/A
- **可用性**: 既存プロジェクトへの影響なし（新規 setup のみに影響）

## 技術的考慮事項

- **ファイル整合性**: `config.toml.template` と `config.toml.example` の双方を同時に更新することで、「テンプレートから生成される設定」と「ユーザーが参照するサンプル」が常に一致する運用を保つ
- **コメント同期**: `config-merge.md` や `commit-flow.md` の ai_author 言及箇所と矛盾がないかを目視確認する（ドキュメント整合性）
- **動作確認手順**: `/tmp` 等に新規プロジェクトを作成し `aidlc setup` を実行、生成された `config.toml` で `ai_author = ""` となっていることを確認。続けて `git commit` が走る想定のダミー Construction 実行で自動検出フローの起動を確認する手順を設計フェーズで整備する
- **markdownlint**: 本 Unit は TOML ファイル 2 箇所の変更のみ。既存の `run-markdownlint.sh` 対象外

## 関連Issue

- #577

## 実装優先度

Medium

## 見積もり

**XS（Extra Small）** - TOML 2 ファイル（`config.toml.template`, `config.toml.example`）の該当 2-3 行の変更のみ。動作確認手順整備を含めても変更範囲は最小。

---
## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
- **エクスプレス適格性**: -
- **適格性理由**: -
