# Unit 003 計画: Setup/Inception統合（通常版）

## 概要

Setup PhaseとInception Phaseを統合し、1回のプロンプト読み込みでサイクル開始からUnit定義まで完了できるようにする。

## 変更対象ファイル

すべて `prompts/package/prompts/` 配下（メタ開発ルールに従う）:

| ファイル | 変更種別 | 概要 |
|---------|---------|------|
| `setup-inception.md` | 新規作成 | 統合版プロンプト |
| `setup.md` | 更新 | リダイレクトメッセージに置き換え |
| `inception.md` | 更新 | リダイレクトメッセージに置き換え |
| `AGENTS.md` | 更新 | 簡略指示に「start setup-inception」を追加 |

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

- [ ] 統合版プロンプト（setup-inception.md）の作成
- [ ] 旧版setup.md/inception.mdのリダイレクト化
- [ ] AGENTS.mdの簡略指示更新
- [ ] Unit 001/002の設定階層化機能の案内を統合プロンプトに含める
