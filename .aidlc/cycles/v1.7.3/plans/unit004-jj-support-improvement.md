# Unit 004: jjサポートの改善 - 実行計画

## 概要

Issue #49 および #61 に基づき、jjサポートの課題を改善します。jjユーザーがAI-DLCをスムーズに利用できるよう、ドキュメントを充実させます。

## 関連Issue

- #49: jjサポートの課題と改善案
- #61: AI-DLC Starter Kit における Jujutsu（jj）連携の整理

## 対象ファイル

**編集対象**（メタ開発のため `prompts/package/` を編集）:

- `prompts/package/guides/jj-support.md`

**注意**: `docs/aidlc/` は Operations Phase の rsync でコピーされるため、直接編集しません。

## Phase 1: 設計

### ドメインモデル設計

jjサポートガイドはドキュメントのみのUnitのため、簡略化した設計を行います。

- **対象**: ドキュメント構造の設計
- **成果物**: `docs/cycles/v1.7.3/design-artifacts/domain-models/jj-support-improvement_domain_model.md`

### 論理設計

追加セクションの構成と内容を設計します。

- **成果物**: `docs/cycles/v1.7.3/design-artifacts/logical-designs/jj-support-improvement_logical_design.md`

## Phase 2: 実装

### 実装内容

1. **重要な警告の追加**（#61）
   - 「bookmarkは自動で進まない」警告を目立つ位置に配置
   - Unit境界でのbookmark操作の重要性を強調

2. **「作業開始時」セクションの追加**（#49, #61）
   - チェックリスト形式で確認事項を記載
   - jjコマンド例を記載
   - Unit開始時: cycle/vX.X.X 上に新しい change を作る

3. **「作業終了時」セクションの追加**（#49, #61）
   - チェックリスト形式で確認事項を記載
   - jjコマンド例を記載
   - Unit完了時: commit → cycle ブックマークを進める → push

4. **推奨設定の追加**（#49）
   - `auto-local-bookmark = true` の設定を追記
   - 設定の効果と注意点を説明

5. **ワンコマンド化のガイド**（#61、可能なら）
   - Unit完了操作をまとめる方法を提案

### 完了条件

- [ ] 「bookmarkは自動で進まない」警告が目立つ位置に記載されている
- [ ] `jj-support.md` に「作業開始時」セクションが存在する
- [ ] `jj-support.md` に「作業終了時」セクションが存在する
- [ ] 各セクションにjjコマンド例が1つ以上記載されている
- [ ] 推奨設定（auto-local-bookmark）が記載されている
- [ ] Unit境界でのbookmark操作が明示的にガイドされている

## テスト

- Markdownlint によるドキュメント検証
- 手動確認: セクション構成の妥当性

## リスク・注意点

- AI-DLCのブランチ戦略の抜本的見直しは対象外（中期課題）
- ドキュメント改善のみのため、コード変更なし
- AIプロンプトの分岐対応は中期課題として記録
