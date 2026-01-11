# Unit 004 計画: セットアッププロンプトパス記録

## 概要

スターターキットセットアップ時に使用したプロンプトのパスを `docs/aidlc.toml` に記録し、Operations Phase完了時のアップグレード案内で参照できるようにする。

## 現状分析

### 既存の実装

`docs/aidlc.toml` には既に以下の設定が存在:
```toml
[paths]
setup_prompt = "prompts/setup-prompt.md"
```

### Unit定義との差異

Unit定義では `[setup].prompt_path` の追加を責務としているが、既存の `[paths].setup_prompt` と重複する。

### 提案: 既存設定の活用

新たに `[setup]` セクションを作成するのではなく、既存の `[paths].setup_prompt` を活用する方針を提案。

**理由**:
- 既に同等の設定が存在するため、重複を避ける
- 既存の設定を利用する方がシンプル
- 後方互換性を維持できる

## パス形式の仕様

### ghq形式パス

環境に依存しないパス形式として `ghq:{host}/{owner}/{repo}/{path}` を採用:

```
ghq:github.com/ikeisuke/ai-dlc-starter-kit/prompts/setup-prompt.md
```

**使用方法**:
```bash
SETUP_PROMPT="ghq:github.com/ikeisuke/ai-dlc-starter-kit/prompts/setup-prompt.md"
FULL_PATH="$(ghq root)/${SETUP_PROMPT#ghq:}"
```

### パス形式の判定

| ケース | パス形式 | 例 |
|--------|----------|-----|
| 同一リポジトリ内 | 相対パス | `prompts/setup-prompt.md` |
| 外部リポジトリ | ghq形式 | `ghq:github.com/owner/repo/path` |

## 実装計画

### Phase 1: 設計

#### ステップ1: ドメインモデル設計
- 設定値の構造定義（既存の `[paths].setup_prompt` を利用）
- パス形式の仕様定義（相対パス / ghq形式）

#### ステップ2: 論理設計
- `prompts/setup-prompt.md` での記録処理フロー
  - セットアップ実行時のパス検出ロジック
  - ghq形式への変換ロジック
- `prompts/package/prompts/operations.md` での参照・表示フロー
  - ghq形式からフルパスへの展開

#### ステップ3: 設計レビュー
- 設計承認を取得

### Phase 2: 実装

#### ステップ4: コード生成
1. `prompts/setup-prompt.md` の修正
   - セットアップ完了時に `docs/aidlc.toml` の `[paths].setup_prompt` を更新する処理
   - 外部リポジトリの場合: `ghq:{host}/{owner}/{repo}/{path}` 形式で記録
   - 同一リポジトリ内: 相対パス形式で記録
   - パス検出ロジック: `ghq root` を基準にリポジトリパスを抽出

2. `prompts/package/prompts/operations.md` の修正
   - 完了メッセージで `[paths].setup_prompt` を参照
   - `[setup-promptのパス]` プレースホルダーを実際の値で置換
   - ghq形式の場合は展開方法も案内

#### ステップ5: テスト生成
- プロンプトベースのため自動テストは対象外
- 動作確認シナリオの作成

#### ステップ6: 統合とレビュー
- 実装記録の作成
- レビュー実施

## 成果物

| ファイル | 種類 |
|----------|------|
| `docs/cycles/v1.7.0/design-artifacts/domain-models/setup_prompt_path_domain_model.md` | ドメインモデル |
| `docs/cycles/v1.7.0/design-artifacts/logical-designs/setup_prompt_path_logical_design.md` | 論理設計 |
| `prompts/setup-prompt.md` | 実装（修正） |
| `prompts/package/prompts/operations.md` | 実装（修正） |
| `docs/cycles/v1.7.0/construction/units/setup_prompt_path_implementation.md` | 実装記録 |

## 見積もり

小（プロンプトファイル2箇所の修正）

## 質問事項

[Question] 既存の `[paths].setup_prompt` を活用する方針でよろしいですか？（新たに `[setup]` セクションを作成するUnit定義とは異なりますが、重複を避けるため）

[Answer] 承認待ち

[Question] ghq形式パス `ghq:{host}/{owner}/{repo}/{path}` で問題ないですか？

[Answer] 承認待ち
