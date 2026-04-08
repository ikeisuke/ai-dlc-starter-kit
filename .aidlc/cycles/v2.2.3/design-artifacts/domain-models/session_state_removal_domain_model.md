# ドメインモデル: session-state.md廃止

## 概要

session-state.mdの生成・復元の責務を全ステップファイルから除去し、セッション復元をprogress.md / Unit定義ファイルに一本化する。

## エンティティ（Entity）

本Unitは既存コードの削除・簡略化タスクのため、新規エンティティの定義はない。変更対象の既存概念を以下に整理する。

### SessionRecovery（セッション復元）

変更前: session-state.md → progress.md / Unit定義の2段階フォールバック
変更後: progress.md / Unit定義のみ（フォールバック不要の直接参照）

- **属性**:
  - recovery_source: enum(progress_md, unit_definitions) - フェーズ別の進捗源
- **振る舞い**:
  - restore(): progress.md / Unit定義から中断ポイントを特定して再開

### ContextReset（コンテキストリセット）

変更前: session-state.md生成 + 継続プロンプト提示
変更後: 履歴記録 + 継続プロンプト提示のみ

### Compaction（コンパクション復帰）

変更前: session-state.mdでフェーズ判定 → 成果物ベースフォールバック
変更後: 成果物ベースのフェーズ判定のみ

## 値オブジェクト（Value Object）

### PhaseProgressSource（フェーズ別進捗源）

| フェーズ | 進捗源 | パス |
|---------|--------|------|
| Inception | progress.md | `inception/progress.md` |
| Construction | Unit定義ファイル | `story-artifacts/units/*.md` の「実装状態」 |
| Operations | progress.md | `operations/progress.md` |

- **不変性**: フェーズと進捗源の対応は固定（session-state.md廃止後も変更なし）
- **等価性**: フェーズ名で判定

## 集約（Aggregate）

### SessionLifecycle（セッションライフサイクル）

- **集約ルート**: SessionRecovery
- **含まれる要素**: ContextReset, Compaction, PhaseProgressSource
- **境界**: セッションの中断・復帰に関わる全ての操作
- **不変条件**: 復元は必ずPhaseProgressSourceで定義された進捗源から行う（session-state.mdは使用しない）

## ドメインサービス

該当なし（既存の復元ロジックを使用）

## 影響範囲マッピング

| 対象ファイル | 除去する責務 | 残す責務 |
|-------------|------------|---------|
| session-continuity.md | session-state.md生成・復元 | コンパクション復帰指示、PhaseProgressSourceテーブル |
| context-reset.md | session-state.md生成、再開説明 | 作業状態確認、履歴記録、継続プロンプト提示 |
| compaction.md | フェーズ判定・再開手順・コンパクション前保存におけるsession-state.md依存全体 | 成果物ベース判定、automation_mode復元、スキル再読み込み |
| inception/01-setup.md | session-state.md生成指示 | 他のセットアップ手順、コンテキストリセット時の継続導線 |
| construction/01-setup.md | session-state.md復元ステップ | Unit定義ベース復元、他のステップ |
| operations/01-setup.md | session-state.md復元ステップ | progress.mdベース復元、他のステップ |
| guides/troubleshooting.md | session-state.md参照 | 他のトラブルシューティング項目 |

## ユビキタス言語

- **session-state.md**: 廃止対象。セッション中断時の作業状態を保存していたファイル
- **progress.md**: Inception/Operations Phaseの進捗管理ファイル（存続）
- **Unit定義ファイル**: Construction Phaseの進捗源。「実装状態」セクションで進捗を管理（存続）
- **コンパクション**: コンテキストウィンドウの自動圧縮。復帰時に設定値の再取得が必要
- **コンテキストリセット**: ユーザー主導のセッション中断・再開

## 不明点と質問（設計中に記録）

なし（要件が明確なため）
