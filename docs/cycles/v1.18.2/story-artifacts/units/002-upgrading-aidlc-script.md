# Unit: upgrading-aidlcスキルのスクリプト化・PR分離・許可自動化

## 概要
upgrading-aidlcスキルのアップグレード処理をスクリプト化し、アップグレード用ブランチ・PRの自動分離を実現する。SKILL.md内の$()パターンも排除し、Claude Codeの許可プロンプトを不要にする。

## 含まれるユーザーストーリー
- ストーリー 2: upgrading-aidlcスキルのスクリプト化 (#256)
- ストーリー 3: upgrading-aidlcのPR分離とBash許可自動化 (#213, #212)

## 責務
- `upgrade-aidlc.sh`スクリプトの新規作成（バージョン更新・設定マイグレーション・rsync同期を一括実行）
- `--dry-run`オプション対応
- 異常系ハンドリング（サブスクリプト失敗時の出力、冪等性保証）
- SKILL.mdの更新（スクリプト呼び出し方式に変更）
- アップグレード用ブランチ作成・PR自動作成フローの追加
- SKILL.md内の`$(ghq root)`, `$(read-config.sh ...)`パターンの排除
- `resolve-starter-kit-path.sh`を活用したパス解決

## 境界
- setup-prompt.mdの機能変更は行わない
- 既存のsync-package.sh, migrate-config.sh, check-setup-type.shの内部変更は行わない
- スクリプト内部の$()は制約なし（Claude Codeの許可対象外）

## 依存関係

### 依存する Unit
- Unit 001: $()パターン排除（依存理由: SKILL.md内の$()排除ルールがUnit 001で定義されるため、ルールに準拠する必要がある）

### 外部依存
- gh CLI（PR作成。未認証時はスキップ）
- ghq（パス解決のフォールバック）

## 非機能要件（NFR）
- **パフォーマンス**: アップグレード全体が1分以内に完了すること
- **セキュリティ**: スクリプト内で外部入力のバリデーションを実施
- **信頼性**: 途中失敗後の再実行で追加差分が発生しないこと（冪等性）

## 技術的考慮事項
- 正本は`prompts/package/skills/upgrading-aidlc/`
- スクリプト配置: `prompts/package/skills/upgrading-aidlc/bin/upgrade-aidlc.sh`
- 既存スクリプトの出力形式（key:value）に統一
- ブランチ名: `upgrade/vX.X.X`
- gh未認証時・ネットワークエラー時はwarning出力でスキップ

## 実装優先度
Medium

## 見積もり
2-3セッション

## 関連Issue
- #256
- #213
- #212

---
## 実装状態

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
