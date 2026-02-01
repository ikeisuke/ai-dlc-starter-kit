# Unit 003 計画: Setup/Inception統合（通常版）

## 概要

Setup PhaseとInception Phaseを統合し、1回のプロンプト読み込みでサイクル開始からUnit定義まで完了できるようにする。

## パス体系の説明

**メタ開発ルール**: このプロジェクトでは `prompts/package/` を編集し、Operations Phaseのrsyncで `docs/aidlc/` にコピーされる。

- **編集対象**: `prompts/package/prompts/` 配下
- **rsync後の参照先**: `docs/aidlc/prompts/` 配下
- **リダイレクト先**: rsync後のパス（`docs/aidlc/prompts/setup-inception.md`）を案内

## 変更対象ファイル

すべて `prompts/package/prompts/` 配下（メタ開発ルールに従う）:

| ファイル | 変更種別 | 概要 |
|---------|---------|------|
| `setup-inception.md` | 新規作成 | 統合版プロンプト |
| `setup.md` | 更新 | リダイレクトメッセージに置き換え |
| `inception.md` | 更新 | リダイレクトメッセージに置き換え |
| `AGENTS.md` | 更新 | 簡略指示に「start setup-inception」を追加 |

## 参照確認対象ファイル

既存の `setup.md` / `inception.md` を参照している箇所を確認し、必要に応じて更新:

| ファイル | 確認内容 |
|---------|---------|
| `prompts/package/prompts/AGENTS.md` | 簡略指示テーブル、推奨ワークフロー |
| `README.md` | 使用方法の記載（あれば） |
| `prompts/package/prompts/construction.md` | バックトラックセクション |
| `prompts/package/prompts/operations.md` | 次サイクルへの案内 |

## 実装計画

### Phase 1: 設計

#### ステップ1: ドメインモデル設計

統合版プロンプトの構成を設計:
- setup.mdとinception.mdの重複排除
- フロー統合（サイクル作成 → Intent → ストーリー → Unit定義）
- 設定階層化機能（Unit 001/002）への案内

#### ステップ2: 論理設計

ファイル構成と依存関係を定義:
- 統合版プロンプトの各セクション配置
- リダイレクトファイルのフォーマット
- AGENTS.mdの更新箇所

#### ステップ3: 設計レビュー

AIレビューとユーザー承認

### Phase 2: 実装

#### ステップ4: コード生成

1. `setup-inception.md` 作成
   - setup.mdの環境確認・サイクル作成セクション
   - inception.mdのIntent・ストーリー・Unit定義セクション
   - Unit 001/002の設定階層化への案内追加

2. `setup.md` リダイレクト化
   ```markdown
   # Setup Phase

   このプロンプトは統合版に移行しました。

   以下のプロンプトを読み込んでください:
   `docs/aidlc/prompts/setup-inception.md`
   ```

3. `inception.md` リダイレクト化
   ```markdown
   # Inception Phase

   このプロンプトは統合版に移行しました。

   以下のプロンプトを読み込んでください:
   `docs/aidlc/prompts/setup-inception.md`
   ```

4. `AGENTS.md` 更新
   - 「セットアップインセプション」「start setup-inception」を追加
   - 推奨ワークフローを更新

#### ステップ5: テスト生成

この変更はプロンプトファイルのみのため、手動検証で確認:
- 統合版プロンプトの読み込み確認
- フロー完遂の確認

#### ステップ6: 統合とレビュー

AIレビューとユーザー承認

## 完了条件チェックリスト

- [x] 統合版プロンプト（setup-inception.md）の作成
- [x] 旧版setup.md/inception.mdのリダイレクト化
- [x] AGENTS.mdの簡略指示更新
- [x] Unit 001/002の設定階層化機能の案内を統合プロンプトに含める
- [x] 参照確認対象ファイルの確認・更新
  - [x] construction.md - Inception Phase参照、サイクル不存在時案内を更新
  - [x] operations.md - Inception Phase参照、サイクル不存在時案内を更新
  - [x] lite/inception.md - Full版参照を更新、説明追加
- [x] リダイレクト先パス（docs/aidlc/prompts/setup-inception.md）の正当性確認
