# フェーズ別レビュー観点定義

このドキュメントは、AI-DLC の各フェーズにおけるAIDLC固有のレビュー観点を定義する。後続サイクルでのフェーズ別レビュースキル実装の設計基盤として使用する。

## 概要

AI-DLC のレビュースキルはタイミングベースの9スキル（reviewing-inception-intent, reviewing-inception-stories, reviewing-inception-units, reviewing-construction-plan, reviewing-construction-design, reviewing-construction-code, reviewing-construction-integration, reviewing-operations-deploy, reviewing-operations-premerge）で構成される。本ドキュメントでは、AI-DLC手法固有の観点を各フェーズごとに定義する。

## Inception Phase

### 実装済み観点（v1.28.0）

以下の観点は `reviewing-inception-units` スキルの SKILL.md に追加済み。

| チェック対象 | チェック項目 | 重要度 |
|-------------|------------|--------|
| Intent-Unit整合性 | Intentの「含まれるもの」に対応するUnitが存在するか | 高 |
| Intent-Unit整合性 | Unitの責務がIntentのスコープを逸脱していないか | 高 |
| Intent-Unit整合性 | Intentの「除外されるもの」に該当する作業がUnitに含まれていないか | 中 |
| Intent-Unit整合性 | 全Unitの責務の合計がIntentのスコープをカバーしているか | 中 |
| 意思決定記録充足性 | decisions.md が存在するか（意思決定があった場合） | 低 |
| 意思決定記録充足性 | 各記録に必須項目（背景、選択肢、決定、トレードオフと判断根拠）が含まれているか | 中 |
| 意思決定記録充足性 | 選択肢のメリット・デメリットが記載されているか | 低 |
| 意思決定記録充足性 | トレードオフ（得たもの・犠牲にしたもの）と判断根拠が具体的に記載されているか | 中 |
| 意思決定記録充足性 | 記録漏れの可能性がないか | 低 |

### 将来追加候補

| チェック対象 | チェック項目 | 重要度 |
|-------------|------------|--------|
| ストーリー-Issue整合性 | ユーザーストーリーと関連Issueの要件が一致しているか | 中 |
| PRFAQ品質 | PRFAQがIntentの価値提案を正確に反映しているか | 低 |

## Construction Phase

### 提案観点（後続サイクルで実装予定）

| チェック対象 | チェック項目 | 重要度 |
|-------------|------------|--------|
| 設計-実装整合性 | ドメインモデル設計のエンティティ・値オブジェクトが実装に反映されているか | 高 |
| 設計-実装整合性 | 論理設計のコンポーネント構成が実装と一致しているか | 高 |
| 設計-実装整合性 | 設計で定義したインターフェースが実装で守られているか | 中 |
| テストカバレッジ充足性 | Unit定義の完了条件に対応するテストが存在するか | 高 |
| テストカバレッジ充足性 | ユーザーストーリーの受け入れ基準がテストでカバーされているか | 中 |
| コミット粒度 | コミットがステップ単位で適切に分割されているか | 低 |
| コミット粒度 | コミットメッセージが変更内容を適切に反映しているか | 低 |

## Operations Phase

### 提案観点（後続サイクルで実装予定）

| チェック対象 | チェック項目 | 重要度 |
|-------------|------------|--------|
| リリース準備完了 | 全Unitの実装状態が「完了」または「取り下げ」であるか | 高 |
| リリース準備完了 | CHANGELOG が更新されているか（changelog=true の場合） | 中 |
| リリース準備完了 | バージョン番号が正しく更新されているか | 中 |
| ドキュメント更新完全性 | 変更に対応するドキュメント更新が行われているか | 中 |
| ドキュメント更新完全性 | テンプレートの変更が索引に反映されているか | 低 |
| バックログ処理 | Construction Phase で登録されたバックログが確認されているか | 中 |
| バックログ処理 | 対応済みバックログが適切にクローズされているか | 低 |

## レビュースキルとの関係

| フェーズ | 対応スキル | 実装状態 |
|---------|-----------|---------|
| Inception | reviewing-inception-intent, reviewing-inception-stories, reviewing-inception-units | v2.1.0 でタイミングベース化。AIDLC 固有観点は reviewing-inception-units に実装済み |
| Construction | reviewing-construction-plan, reviewing-construction-design, reviewing-construction-code, reviewing-construction-integration | v2.1.0 でタイミングベース化。code に security 統合、integration は設計乖離確認に変更 |
| Operations | reviewing-operations-deploy, reviewing-operations-premerge | v2.1.0 で新規追加 |

## 更新履歴

- v1.28.0: 初版作成。Inception Phase の AIDLC 固有観点を定義・実装。Construction/Operations Phase は提案段階。
