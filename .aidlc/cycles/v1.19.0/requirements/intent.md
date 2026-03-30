# Intent（開発意図）

## プロジェクト名

AI-DLC v1.19.0 - Amazon AIDLCエッセンス取り込み + jjサポート整理

## 開発の目的

Amazon AIDLCリポジトリ（awslabs/aidlc-workflows）の調査結果から、本プロジェクトに不足している概念・仕組みを取り込み、AI-DLCの品質とワークフロー効率を向上させる。併せて、別リポジトリに移植済みのjjサポート関連処理を本体から削除し、コードベースを整理する。

## ターゲットユーザー

AI-DLCスターターキットを利用する開発者およびAIエージェント

## ビジネス価値

- **AIの過信防止**: Overconfidence Prevention原則を明文化し、AIが不確実な判断を避け質問する文化を強化（#218-1）
- **成果物の適正化**: Depth Levels概念により、シンプルなタスクに過剰な成果物を作らず効率的に開発できる（#218-2）
- **既存プロジェクト対応の強化**: Reverse Engineeringステージにより、brownfieldプロジェクトへのAI-DLC適用をより構造的にサポート（#218-3）
- **セッション継続の信頼性向上**: Session Continuityにより、長時間タスクのセッション中断・再開を正式にサポートし、コンテキスト喪失によるやり直しを防止（#218-10）
- **コードベースの簡素化**: jjサポート関連処理の削除により、保守対象を削減（#276）

## 成功基準

- **#218-1（Overconfidence Prevention）**: `prompts/package/prompts/common/` に過信防止原則が追記され、AIが「確信度が低い場合は推測せず質問する」ルールが全フェーズ共通ルールに組み込まれていること
- **#218-2（Depth Levels）**: `docs/aidlc.toml` に `[rules.depth_level]` 設定が追加され、Inception/Construction/Operations の各フェーズプロンプトがDepth Level（minimal/standard/comprehensive）に応じて成果物の詳細度を調整するロジックを含むこと
- **#218-3（Reverse Engineering）**: Inception Phase のステップ2（既存コード分析）が Reverse Engineeringステージとして強化され、構造解析・パターン検出・技術スタック推定を含む体系的な分析手順がプロンプトに組み込まれていること
- **#218-10（Session Continuity）**: セッション中断時に `docs/cycles/{{CYCLE}}/{phase}/session-state.md` が生成され、再開時にそのファイルを読み込んで前回の状態を復元できること。具体的には:
  - 生成トリガー: コンテキストリセット提示時、ユーザーの明示的な中断指示時
  - 必須記録項目: サイクル番号、フェーズ、現在のステップ、完了済みステップ一覧、未完了タスク、次のアクション
  - 復元手順: 再開プロンプト実行時にsession-state.mdを自動読み込みし、中断時点のステップから作業を再開できること
- **#276（jjサポート削除）**: `prompts/package/` 配下のjjサポート関連ファイル（`skills/versioning-with-jj/` ディレクトリ全体）が削除されていること。`prompts/package/prompts/common/rules.md` からjjサポート参照が除去されていること。`docs/aidlc.toml` の `[rules.jj]` セクションは設定として残るが、`enabled = true` の場合に「jjサポートはv1.19.0で削除されました。versioning-with-jjスキルを別途インストールしてください」と警告が表示されること

### 効果検証の方針

本サイクルはプロンプト・概念レベルの改善が中心であり、定量的な計測基盤が存在しないため、定量KPI（所要時間短縮率等）は設定しない。代わりに、以下の定性的検証を次サイクル以降で実施する:

- **Overconfidence Prevention**: 次サイクルのConstruction PhaseでAIが不確実な判断時に質問するケースが増えるか確認
- **Depth Levels**: minimalレベルでシンプルなタスクの成果物量が削減されるか確認
- **Session Continuity**: 実際のセッション中断・再開時にコンテキスト喪失なく作業継続できるか確認
- **Reverse Engineering**: brownfieldプロジェクトでのInception Phase実行時に構造解析が体系的に行われるか確認

## スコープ

### 対象

- Overconfidence Prevention原則の導入（共通ルールへの追記）
- Depth Levels概念の導入（設定・全フェーズプロンプト対応）
- Reverse Engineeringステージの強化（Inception Phase プロンプト改修）
- Session Continuityの強化（状態保存・復元の仕組み構築）
- jjサポート関連処理の削除（スキル・プロンプト参照の除去、警告メッセージの追加）

### 対象外

- #218の残りの取り込み候補（#4 Audit Trail, #5 Security Extension, #6 Content Validation, #7 Workflow Planning, #8 マルチプラットフォーム, #9 Error Handling, #11 Terminology）
- jjサポート機能の移植先リポジトリの作業
- #271（session-titleのWSL2対応）
- #31（GitHub Projects連携）

## 期限とマイルストーン

特に期限なし。1サイクル内で完了を目指す。

## 制約事項

- プロンプト・テンプレートの修正は `prompts/package/` を編集すること（`docs/aidlc/` は直接編集禁止）
- Amazon AIDLCの概念を参照元として活用するが、ライセンス（MIT-0）に準拠し、独自の実装として組み込む

### 後方互換性

| 変更項目 | 影響対象 | 互換方針 | 移行手順 |
|---------|---------|---------|---------|
| Overconfidence Prevention | 全フェーズの共通ルール | 追加のみ。既存動作への変更なし | なし（プロンプト追記） |
| Depth Levels | 全フェーズプロンプト、aidlc.toml | デフォルト `standard` で現行動作と同等。破壊的変更なし | 設定未追加の場合はstandardとして動作 |
| Reverse Engineering | Inception Phase ステップ2 | 既存のステップ2（brownfieldのみ）を拡張。greenfieldスキップは維持 | なし |
| Session Continuity | コンテキストリセットフロー | 既存のcompaction/リセット指示を発展。既存フローは維持しつつsession-state.md生成を追加 | なし |
| jjサポート削除 | `[rules.jj]` 設定利用者 | スキルファイル削除、設定キーは残存。`enabled=true` 時に警告表示 | 別リポジトリのversioning-with-jjスキルをインストール |

## 不明点と質問（Inception Phase中に記録）

（対話を通じて不明点を明確化し、このセクションに記録していく）
