# Unit 011: markdownlint設定対応 - 実装計画

## 概要

markdownlint実行をプロジェクト設定で制御可能にする。

## 対象ファイル

| ファイル | 操作 | 説明 |
|----------|------|------|
| `prompts/package/templates/aidlc_toml_template.toml` | 編集 | `[rules.linting]` セクション追加 |
| `prompts/package/bin/run-markdownlint.sh` | 新規 | 条件分岐込みの実行スクリプト |
| `prompts/package/prompts/construction.md` | 編集 | スクリプト呼び出しに置換 |
| `prompts/package/prompts/operations.md` | 編集 | スクリプト呼び出しに置換 |
| `docs/aidlc.toml` | 編集 | 現サイクル用に設定追加 |

## 実装ステップ

### Phase 1: 設計

1. **ドメインモデル設計**: 設定構造と条件分岐ロジックの設計
2. **論理設計**: プロンプト変更箇所の詳細化
3. **設計レビュー**: ユーザー承認

### Phase 2: 実装

4. **コード生成**:
   - `aidlc_toml_template.toml` に `[rules.linting]` セクション追加
   - `run-markdownlint.sh` スクリプト新規作成
   - `construction.md` のmarkdownlint実行をスクリプト呼び出しに置換
   - `operations.md` のmarkdownlint実行をスクリプト呼び出しに置換
   - `docs/aidlc.toml` に設定追加
5. **統合とレビュー**: AIレビュー、動作確認

## 設定仕様

```toml
[rules.linting]
# markdownlint設定（v1.8.0で追加）
# markdown_lint: true | false
# - true: markdownlint を実行する
# - false: markdownlint をスキップする（デフォルト）
markdown_lint = false
```

## 実行スクリプト（run-markdownlint.sh）

条件分岐ロジックをスクリプト化し、プロンプトからは単純に呼び出す:

```bash
# プロンプトでの呼び出し
docs/aidlc/bin/run-markdownlint.sh {{CYCLE}}
```

## 完了基準

- [ ] `aidlc_toml_template.toml` に `[rules.linting]` セクションが追加されている
- [ ] `run-markdownlint.sh` スクリプトが作成されている
- [ ] `construction.md` がスクリプト呼び出しに置換されている
- [ ] `operations.md` がスクリプト呼び出しに置換されている
- [ ] `docs/aidlc.toml` に設定が追加されている
- [ ] AIレビュー完了
- [ ] 履歴記録完了
- [ ] Gitコミット完了

## 関連Issue

- #67
