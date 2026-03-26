# Intent（開発意図）

## プロジェクト名

AI-DLC Starter Kit v1.13.1

## 開発の目的

v1.13.0リリース後に発見された以下のカテゴリの問題を修正する：

1. **バグ修正**: suggest-version.shがalpha/betaサフィックスなしのバージョン（例: v2.0.0）でエラーとなる問題
2. **ワークフロー改善**: Operations PhaseのPRマージ後にgit checkout mainが失敗する問題、Unit完了時のコミット漏れ、旧形式バックログ移行の毎サイクル実行
3. **ドキュメント・テンプレート強化**: AskUserQuestion機能の活用ガイド不足、論理設計テンプレートのスクリプトインターフェース記載ガイド欠如、アップグレード案内メッセージの誤り
4. **機能追加**: アップグレード処理（setup-prompt.md）のスキル化

## ターゲットユーザー

AI-DLC Starter Kitを使用する開発者（主にメタ開発として自身のリポジトリでテスト・運用）

## ビジネス価値

- suggest-version.shのバグ修正により、プレリリースサフィックスなしのバージョンでもサイクル作成が可能になる
- PRマージ後のcheckout失敗を防止し、Operations Phase完了手順がスムーズになる
- Unit完了時のコミット確認により、作業漏れを防止
- AskUserQuestion機能の活用により、選択肢がある場面でのユーザー体験が向上
- アップグレード処理のスキル化により、「/upgrade」で簡単にアップグレードを開始可能

## 成功基準

| 基準 | 判定方法 |
|------|---------|
| `docs/aidlc/bin/suggest-version.sh` がalpha/betaなしバージョンで動作 | `v2.0.0` ブランチで `suggest-version.sh` を実行し、エラーなく出力が得られる |
| PRマージ手順の改善 | `operations.md` のリリース準備セクションに「progress.md更新をコミットしてからマージ」の手順が明記されている |
| AskUserQuestion使用ガイド | `CLAUDE.md` に「必ず使用すべき場面」として最低3項目以上のリストがある |
| Unit完了時コミット確認 | `construction.md` の「Unit完了時の必須作業」に `git status` 確認ステップがある |
| スクリプトインターフェース設計ガイド | `logical_design_template.md` に「## スクリプトインターフェース設計」見出しと、成功時出力/エラー時出力/使用コマンドのサブセクションがある |
| 旧形式バックログ移行の移動 | `inception.md` に「旧形式バックログ移行」ステップが存在せず、`setup-prompt.md` のアップグレードセクションに同等の処理がある |
| アップグレード案内メッセージ | `setup-prompt.md` の完了メッセージに「start inception」または「インセプション進めて」が含まれる |
| アップグレードスキル | `docs/aidlc/skills/upgrade/SKILL.md` が存在し、`/upgrade` コマンドの使用方法が記載されている |

## 期限とマイルストーン

パッチリリース（v1.13.1）。Construction Phase完了後、速やかにOperations Phaseへ移行しリリースする。
（具体的な日付指定はパッチリリースの性質上設けない。各Unitの完了をもって進捗を管理する）

## 制約事項

- 既存の動作を壊さない後方互換性を維持
- 大きな設計変更は行わない（パッチリリース相当）
- メタ開発（自身のリポジトリで開発・テスト）

## スコープ

### 含まれるもの

| Issue | 概要 | 対象ファイル | カテゴリ |
|-------|------|-------------|---------|
| #161 | suggest-version.shがalpha/betaなしバージョンでエラー | `docs/aidlc/bin/suggest-version.sh` | バグ修正 |
| #167 | PRマージ後のcheckout失敗対策 | `docs/aidlc/prompts/operations.md` | ワークフロー改善 |
| #168 | AskUserQuestion機能の使用率向上 | `docs/aidlc/prompts/CLAUDE.md` | ドキュメント強化 |
| #166 | Unit完了時のコミット忘れ防止 | `docs/aidlc/prompts/construction.md` | ワークフロー改善 |
| #165 | 論理設計テンプレートにスクリプトインターフェース詳細 | `docs/aidlc/templates/logical_design_template.md` | テンプレート強化 |
| #163 | 旧形式バックログ移行をアップグレード処理に移動 | `docs/aidlc/prompts/inception.md`, `prompts/setup-prompt.md` | ワークフロー改善 |
| #160 | アップグレード後の案内メッセージ更新 | `prompts/setup-prompt.md` | ドキュメント修正 |
| #133(部分) | アップグレード処理のスキル化 | `docs/aidlc/skills/upgrade/SKILL.md`（新規）, `AGENTS.md`への参照追加 | 機能追加 |

### #133(部分)の詳細

Issue #133「各スクリプトをSkills化」のうち、**アップグレード処理（setup-prompt.md）のスキル化のみ**を対象とする。

**対象**:
- `prompts/setup-prompt.md` のアップグレードフローをスキルとして呼び出し可能にする
- `/upgrade` コマンドでアップグレードを開始できるようにする

**対象外**（別サイクルで対応）:
- `env-info.sh` のスキル化
- `check-gh-status.sh` のスキル化
- `check-backlog-mode.sh` のスキル化
- `write-history.sh` のスキル化
- その他のスクリプトのスキル化

### 含まれないもの

- #133の他の項目（上記「対象外」参照）
- 新規機能の大規模追加
- 破壊的変更

## 不明点と質問（Inception Phase中に記録）

[Question] #133について、アップグレード処理（setup-prompt.md）のスキル化のみを対象とする理解で正しいですか？
[Answer] はい、アップグレードのみを今回のスコープとする。他のスクリプト（env-info.sh等）のスキル化は別サイクルで対応。
