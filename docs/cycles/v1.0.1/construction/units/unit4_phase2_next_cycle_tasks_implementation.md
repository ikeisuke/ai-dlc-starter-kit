# 実装記録: Unit 4 Phase 2 - 次サイクルへのタスクリスト管理

## 実装日時
2025-11-28 00:30:00 JST 〜 2025-11-28 01:00:00 JST

## 作成ファイル

### 設計ドキュメント
- docs/cycles/v1.0.1/design-artifacts/domain-models/unit4_phase2_next_cycle_tasks_domain_model.md - ドメインモデル設計
- docs/cycles/v1.0.1/design-artifacts/logical-designs/unit4_phase2_next_cycle_tasks_logical_design.md - 論理設計

### 修正ファイル
- prompts/setup-prompt.md - バックログ確認・記録ステップを追加

### テンプレートファイル
- docs/aidlc/templates/backlog_template.md - バックログテンプレート
- docs/aidlc/templates/backlog_completed_template.md - 完了済みバックログテンプレート

## 修正内容

### prompts/setup-prompt.md

#### 修正1: inception.md生成部分（line 274-287）
「最初に必ず実行すること」に **ステップ0.5: バックログ確認** を追加：

- バックログファイル（`docs/cycles/backlog.md`）の存在確認
- タスクがある場合はユーザーに内容確認を促す
- Intent作成時の参考情報として提供（強制ではない）

#### 修正2: operations.md生成部分（line 491-517）
「AI-DLCサイクル完了」セクションに **ステップ2.5: バックログ記録** を追加：

- 次サイクル以降で対応すべきタスクを集約
- バックログファイルへの追記（存在しない場合はテンプレートから作成）
- 完了タスクの移動（backlog.md → backlog_completed.md）

### テンプレートファイル

#### backlog_template.md
未対応タスクを管理するテンプレート：
- 使い方ガイド
- 「参考情報であり強制ではない」旨を明記

#### backlog_completed_template.md
完了済みタスクの履歴を管理するテンプレート

## テスト結果

### 修正確認テスト
- ✅ inception.md生成部分にバックログ確認ステップが追加されている
- ✅ operations.md生成部分にバックログ記録ステップが追加されている
- ✅ テンプレートファイルが2件作成されている

### 将来のテスト観点
次回setup-prompt.mdでセットアップする際に以下を確認：
1. 生成されたinception.mdにステップ0.5が含まれているか
2. 生成されたoperations.mdにステップ2.5が含まれているか
3. Operations Phase完了時にbacklog.mdが作成されるか
4. Inception Phase開始時にbacklog.mdを参照できるか

## 技術的な決定事項

### バックログファイルの配置
当初はサイクルディレクトリ内（`docs/cycles/{CYCLE}/next_cycle_tasks.md`）を想定していたが、サイクル横断での管理が必要なため、バージョン非依存の場所（`docs/cycles/backlog.md`）に配置。

### 二元管理方式の採用
未対応と完了済みを別ファイルで管理する方式を採用：
- `docs/cycles/backlog.md` - 未対応タスク
- `docs/cycles/backlog_completed.md` - 完了済みタスク（履歴）

これにより：
- 未対応タスクが明確に分かる
- 完了済みタスクの履歴も保持できる
- ファイル管理がシンプル

### 非強制性の設計
バックログは「参考情報」として扱う設計：
- Inception Phase開始時に確認を促すが、採用は任意
- ユーザーがビジネス状況に応じて柔軟に判断できる
- 次サイクルで全く新しいIntentを作成することも可能

## 完了基準の確認

- ✅ 次サイクルタスクリストのテンプレートが作成されている
- ✅ Operations Phase完了時にタスクを記録するフローが追加されている
- ✅ Inception Phase開始時にタスクを読み込むフローが追加されている
- ✅ テストが成功している
- ✅ 実装記録に「完了」が明記されている（このドキュメント）
- 🔄 `progress.md` が更新されている（次のステップで実施）
- 🔄 `history.md` に記録されている（次のステップで実施）
- 🔄 Gitコミットが作成されている（次のステップで実施）

## 状態
**完了**

## 備考
Phase 2の実装により、Unit 4（サイクル管理基盤）全体が完了。サイクル指定方法の改善（Phase 1）と次サイクルへのタスクリスト管理（Phase 2）の両方が実装された。
