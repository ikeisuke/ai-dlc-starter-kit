# Construction Phase 履歴: Unit 04

## 2026-05-10T20:08:45+09:00

- **フェーズ**: Construction Phase
- **Unit**: 04-dasel-read-config-unification（dasel 直接呼び出しの read-config.sh 経由統一 + 規約追記）
- **ステップ**: Unit完了
- **実行内容**: ## 概要

Unit 004「dasel 直接呼び出しの read-config.sh 経由統一 + 規約追記」を完了。AI エージェントが `.aidlc/config.toml` 読取で `dasel -f <file> '<key>'`（dasel CLI v3 の不正フラグ）を誤生成しがちな問題に対し、(1) AI プロンプトの dasel 直接呼び出しを `scripts/read-config.sh` 経由に統一、(2) `rules-core.md` に dasel CLI v3 制約と禁止呼び出しパターンを明文化、(3) `.aidlc/rules.md` の「スキル間依存ルール」に公開 API スクリプト層の例外を 1 行追記、の 3 軸で構造的予防を実施。

## 主要な変更

| ファイル | 変更内容 |
|---------|---------|
| `skills/aidlc/steps/inception/02-preparation.md` | 不正フラグ `dasel -f` 3 行を `bash scripts/read-config.sh` 経由（単一キー × 3 呼び出し）に置換 + exit code 注釈追加 |
| `skills/aidlc-feedback/steps/feedback.md` | `cat ... \| dasel ...` を `[[ -f .aidlc/config.toml ]]` 先行チェック + `bash skills/aidlc/scripts/read-config.sh`（リポジトリルート相対）に置換 + exit 0/1/2 ハンドリング追加 |
| `skills/aidlc/steps/common/rules-core.md` | 「## 設定読み込み【重要】」直下に H3 サブセクション 2 つ（dasel 呼び出し規約（CLI v3）/ 禁止呼び出しパターン）を追加 |
| `.aidlc/rules.md` | 「### スキル間依存ルール」に公開 API スクリプト層の例外行を 1 行追記 |

## 採用案（ハイブリッド方針）

- 必須置換 A: `dasel -f` 不正フラグを実際に使っている箇所のみ置換（02-preparation.md）
- 推奨置換 B: 正しい構文だが規約統一のため置換（feedback.md）
- 対象外 C: 既存構文 compliant + 早期判定段階の例外として規約で予防（01-detect.md は変更しない）

## 設計上の決定事項

- 公開 API スクリプト層: `read-config.sh` をスキル間依存ルールの例外として `.aidlc/rules.md` 本体に明記し、上位ルールと詳細ルール（`rules-core.md`）の優先順位を明確化
- 呼び出し記法: aidlc スキル内 = スキルベース相対 / 他スキル = リポジトリルート相対 / 検証 = リポジトリルート相対の 3 区分で固定
- 早期判定段階の恒久例外: `aidlc-setup/01-detect.md` の dasel 呼び出しは「`.aidlc/config.toml` 自身の存在検証段階」として恒久的に例外化（技術的負債ではない）

## レビュー結果

| レビュー種別 | ツール | round 数 | 指摘解消状況 |
|------------|-------|---------|------------|
| 計画レビュー（reviewing-construction-plan） | codex | 3 | 5 + 1 + 0 件 / unresolved 0 |
| 設計レビュー（reviewing-construction-design） | codex | 3 | 4 + 2 + 0 件 / unresolved 0 |
| コードレビュー（reviewing-construction-code） | codex | 2 | 1 + 0 件 / unresolved 0 |
| 統合レビュー（reviewing-construction-integration） | codex | 2 | 2 + 0 件 / unresolved 0 |

## 完了条件達成証跡

- markdownlint: 4 files / 0 errors
- anti-pattern 残存（`dasel -f`）: rules-core.md 説明用以外で 0 件
- 置換完了（02-preparation.md / feedback.md）: dasel コマンド呼び出し 0 件
- 対象外 01-detect.md: `git diff` で未変更（0 lines）
- スモークテスト 3 キー: rules.feedback.enabled = "true"（exit 0）/ github_projects.* = exit 1（キー不在、正常）
- 既存 bats（regression 確認）: tests/config-defaults/template-removed-keys.bats 18 件 ok
- 規約セクション存在: rules-core.md L20（dasel 呼び出し規約） / L53（禁止呼び出しパターン）
- 公開 API 例外: .aidlc/rules.md L37 で確認

## 関連 Issue / 決定

- Issue #689 解消（dasel CLI v3 の `-f` フラグ誤生成の構造的予防）
- 関連決定: DR-004（修正方針は Construction Phase で確定 → 本 Unit で確定）
- 関連 Unit: Unit 003 / Unit 005（推奨依存元、本 Unit 完了で `read-config.sh` 経由実装を選択しやすくなる）

## AIレビュー完了

対象タイミング: 統合とレビュー

---
