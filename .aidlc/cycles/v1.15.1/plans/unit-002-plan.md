# Unit 002 計画: AIDLC専用レビュースキル作成

## 概要

Inception Phase成果物（Intent、ユーザーストーリー、Unit定義）を専用の観点でレビューする `reviewing-inception` スキルを作成し、レビューフローに統合する。

## 変更対象ファイル

### 新規作成

1. `prompts/package/skills/reviewing-inception/SKILL.md` - スキル定義本体
2. `prompts/package/skills/reviewing-inception/references/session-management.md` - セッション管理ガイド（既存スキルと同一内容）

### 既存ファイル更新

3. `prompts/package/prompts/common/review-flow.md` - CallerContextマッピングテーブルと有効なレビュー種別テーブルの更新
4. `prompts/package/prompts/common/ai-tools.md` - レビュースキル一覧テーブルに `reviewing-inception` 追加
5. `prompts/package/guides/skill-usage-guide.md` - 利用可能なスキル一覧テーブルに `reviewing-inception` 追加

## 実装計画

### Phase 1: 設計

#### ステップ1: ドメインモデル設計

- `reviewing-inception` スキルのレビュー観点を定義
- inception.md の各ステップに定義されている「Inception固有のレビュー観点」を体系化:
  - **Intent品質**: 目的・狙いの明確性、スコープ定義、曖昧表現チェック
  - **ユーザーストーリー品質**: INVEST原則準拠、受け入れ基準の具体性・検証可能性、ユーザー視点の価値
  - **Unit定義品質**: Unit分割の適切性（独立性・凝集性）、依存関係の正確性、見積もり妥当性、実装順序整合性

#### ステップ2: 論理設計

- SKILL.md の構造設計（既存スキル形式に準拠）
- review-flow.md への追加内容設計:
  - CallerContextマッピングテーブルにInception Phase の3タイミングを具体的にマッピング:
    - Intent承認前 → inception
    - ユーザーストーリー承認前 → inception
    - Unit定義承認前 → inception
  - 履歴記録テンプレートの `--phase` 部分を呼び出し元に応じた変数にするか、Inception用の補足を追加

#### ステップ3: 設計レビュー

### Phase 2: 実装

#### ステップ4: コード生成

- `SKILL.md` 作成（YAML frontmatter + レビュー観点 + 実行コマンド + セッション継続）
- `references/session-management.md` 配置（既存スキルと同一内容のコピー）
- `review-flow.md` 更新:
  - 「有効なレビュー種別とスキル名」テーブルに `inception` 行追加
  - 「CallerContextマッピングテーブル」にInception Phase 3行追加（Intent承認前、ユーザーストーリー承認前、Unit定義承認前 → inception）
  - 履歴記録テンプレートの `--phase` を `{{PHASE}}` 変数に変更し、呼び出し元フェーズに応じた値を設定する説明を追加
- `ai-tools.md` 更新: レビュースキルテーブルに「Inceptionレビュー」行を追加
- `skill-usage-guide.md` 更新: レビュースキルテーブルに「Inceptionレビュー」行を追加

#### ステップ5: テスト生成

- スキルの呼び出し形式が既存スキルと整合するか確認
- review-flow.md の更新箇所が他の既存フローと矛盾しないか確認
- ai-tools.md, skill-usage-guide.md の更新が実態と一致するか確認

#### ステップ6: 統合とレビュー

- AIレビュー実施
- 全ファイルの整合性確認

## 完了条件チェックリスト

- [ ] `reviewing-inception` スキル定義ファイルの作成（SKILL.md）
- [ ] Intent、ユーザーストーリー、Unit定義のレビュー観点定義
- [ ] `review-flow.md` のCallerContextマッピングテーブル更新
- [ ] 有効なレビュー種別テーブルへの追加
- [ ] `ai-tools.md` のレビュースキル一覧更新
- [ ] `skill-usage-guide.md` の利用可能スキル一覧更新
