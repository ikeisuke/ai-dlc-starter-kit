# Intent（開発意図）

## プロジェクト名
AI-DLC Starter Kit v1.23.1

## 開発の目的
v1.23.0のリファクタリングの続きとして、ドキュメント改善・バグ修正・セットアップ処理の整理を行う。特にセットアップ処理は将来の完全スキル化（`setup-prompt.md` を `aidlc-setup` スキルに吸収）に向けた最終整理を実施する。

## ターゲットユーザー
AI-DLCスターターキットの利用者および開発者

## ビジネス価値
- ドキュメントの正確性向上による利用者の混乱防止
- バグ修正によるセットアップ体験の改善
- セットアップ処理の整理により、次サイクルでの完全スキル化が容易になる
- 混在していた機能（session-state.md）の分離による保守性向上

## スコープ

### 対応Issue
- #356: docs: commit-flow.mdのsquash --message-fileパス表記を明確化
- #355: docs: READMEに名前付きサイクル（Named Cycle）の説明を追加
- #351: bugfix: aidlc-setup.sh が status:success でも exit code 1 を返す

### Issue外の対応項目
- Inception Phaseステップ18（session-state.md復元）の削除: 2つの機能が混在していた名残を解消
- セットアップ処理（setup-prompt.md）のリファクタリング: 次サイクルでの完全スキル化に向けた整理

### 除外事項
- セットアップ処理の完全スキル化自体（次サイクル以降）
- フロー・機能の仕組み変更

## 成功基準
- commit-flow.mdのsquashパス表記が明確化されている
- READMEに名前付きサイクルの説明が追加されている
- aidlc-setup.shがstatus:success時にexit code 0を返す
- Inception Phaseのステップ18（session-state.md復元）が削除されている
- セットアップ処理の整理が完了している（判定条件: setup-prompt.mdの責務が明確に分類され、aidlc-setupスキルへの移管対象と残存項目が文書化されている）
- 仕組みそのもの（フロー・機能）は変更されていない
- 既存セットアップフローの主要シナリオ（初回・アップグレード・サイクル開始）が既存の動作を維持している
- コンパクション対応のsession-state.md生成経路に変更がないこと

## 期限とマイルストーン
パッチリリースのため、1サイクルで完了

## 制約事項
- 仕組みそのものは変更しない（リファクタリングと整理のみ）
- コンパクション対応のsession-state.md生成機能は残す（`compaction.md` / `session-continuity.md` 管轄）
- セットアップ処理のスキル化自体は次サイクル以降で実施（今回は整理まで）
- メタ開発の意識: プロンプト・テンプレートの修正は `prompts/package/` を編集すること

## 不明点と質問（Inception Phase中に記録）

[Question] session-state.mdのInception Phase固有チェック（ステップ18）を削除する範囲は？
[Answer] ステップ18のセッション復元チェック全体を削除。2つの機能が混在していたため。コンパクション対応はcompaction.md/session-continuity.mdで管理されているので残す。

[Question] セットアップ処理リファクタリングの方向性は？
[Answer] setup-prompt.mdを完全にaidlc-setupスキルに吸収する方向。今回はその前の最終整理。

[Question] 今回のスコープに含めるIssueは？
[Answer] #356（commit-flow.mdパス表記）、#355（README名前付きサイクル）、#351（aidlc-setup.sh exit code）の3件。
