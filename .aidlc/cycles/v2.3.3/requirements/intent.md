# Intent（開発意図）

## プロジェクト名

ai-dlc-starter-kit

## 開発の目的

**主目的**: v2.3.2までに蓄積した3件のバグ/改善とGitHub Actions セキュリティアラート4件を修正する。

1. **#563 SKILL.mdのパス解決ルール不足（bug）**: SKILL.mdの「パス解決」セクションが `steps/` と `scripts/` のみ明記しており、`config/`・`templates/`・`guides/`・`references/` が欠落。プリフライトチェック等でスキル内リソースパスを参照する際に偽陰性の警告が発生する
2. **#564 write-config.shのレガシーエイリアス重複書き込み（bugfix）**: config.tomlにレガシーエイリアスキー（例: `rules.branch.mode`）が存在する場合、write-config.shが正規キー（`rules.git.branch_mode`）を重複追加し、ファイル内に矛盾する設定が共存する
3. **#566 05-completion.mdの設定保存フロー読み飛ばし（improvement）**: ステップ5dにaction分岐と設定保存フローの2責務が同居し、PR作成実行に意識が移ると設定保存フローが読み飛ばされる構造的問題
4. **code-scanning: GitHub Actions permissions不足（security）**: `.github/workflows/pr-check.yml` と `.github/workflows/migration-tests.yml` のワークフロージョブにpermissionsブロックが未定義（アラート #1, #3, #5, #6）

## ターゲットユーザー

AI-DLC Starter Kitを使用する開発者およびAIエージェント

## ビジネス価値

- スキル内リソースパスの誤解決による偽陰性警告を解消し、プリフライトチェックの信頼性を向上
- 設定ファイルの一貫性を保ち、手動編集時の混乱を防止
- ステップ構造の改善により、AIエージェントのワークフロー遵守率を向上
- GitHub Actions のセキュリティベストプラクティスに準拠し、最小権限原則を適用

## 成功基準

- SKILL.mdのパス解決ルールが `config/`・`templates/`・`guides/`・`references/` を含む
- write-config.shがレガシーエイリアス存在時に重複書き込みしない
- 05-completion.mdの設定保存フローが独立ステップとして分離されている
- 対象2ワークフロー（pr-check.yml, migration-tests.yml）内の全ジョブに必要最小限のpermissionsが定義され、今回対象のcode-scanningアラート4件（#1, #3, #5, #6）が解消される

## 含まれるもの

- `skills/aidlc/SKILL.md` のパス解決ルール修正
- `skills/aidlc/scripts/write-config.sh` のレガシーエイリアス検出・更新ロジック追加
- `skills/aidlc/steps/inception/05-completion.md` の設定保存フロー構造改善
- `.github/workflows/pr-check.yml` へのpermissionsブロック追加
- `.github/workflows/migration-tests.yml` へのpermissionsブロック追加

## 含まれないもの

- 新機能の追加（バックログ#554, #552, #545等は対象外）
- config.tomlのスキーマ変更
- 既存テストの大幅な変更

## 期限とマイルストーン

パッチリリース（小規模修正のため1サイクルで完了見込み）

## 制約事項

- 後方互換性を維持すること（write-config.shの修正は既存設定を壊さない）
- 既存の `steps/` / `scripts/` のパス解決挙動を維持すること（パス解決ルール拡張は追加のみ）
- 対象ワークフローの既存ジョブが権限不足で失敗しないこと（permissions追加は最小権限で設定）
- メタ開発の意識: 主対象は `skills/aidlc/` 配下（スキル側）。ただし本サイクルではセキュリティ修正として `.github/workflows/*.yml` も対象に含む
- SKILL.md本文500行以内の制約を維持

## 不明点と質問（Inception Phase中に記録）

特になし（全Issue内容が明確に定義済み）
