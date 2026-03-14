# Unit 002 計画: エラーハンドリング方針統一

## 概要

CLIスクリプト（10ファイル）のエラー出力を `error:<code>:<message>` 形式に統一し、プロンプト側のエラーパースを安定化する。

## エラーAPI契約仕様

### 出力形式

```text
error:<code>:<message>
```

- **出力先**: stdout（プロンプト側がパースするため）
- **終了コード**: `!= 0`（エラー時は必ず非ゼロで終了）
  - `1`: バリデーションエラー・入力エラー
  - `2`: 操作エラー・外部依存エラー
- **code**: ケバブケース（`[a-z0-9-]+`）。スクリプト固有のエラー識別子
- **message**: 人間向けの説明文（単一行のみ、改行禁止）。コロン `:` を含んでもよい（パーサーは最初の2つのコロンで分割）

### パース規則（プロンプト側）

```text
行が "error:" で始まる場合:
  フィールド1（固定）: "error"
  フィールド2（コード）: 最初のコロンから2番目のコロンまで
  フィールド3（メッセージ）: 2番目のコロン以降すべて
```

- 旧形式 `error:<code>`（メッセージなし）も後方互換として読み取り可能

### ステータスAPIとの棲み分け

| API種別 | 用途 | 出力先 | 終了コード |
|---------|------|--------|-----------|
| エラーAPI (`error:...`) | 処理失敗の通知 | stdout | `!= 0` |
| ステータスAPI (`key:value`) | 正常系の状態報告 | stdout | `0` |

**対象外基準**: `check-gh-status.sh` と `check-backlog-mode.sh` はエラーを返さずステータスのみ報告するスクリプトのため、エラーAPI統一の対象外。これらは常に終了コード `0` で `key:value` 形式のステータスを返す。

### レイヤー責務

| レイヤー | 責務 | 成果物 |
|---------|------|--------|
| 出力整形層（共通関数） | `error:<code>:<message>` の組み立てと出力 | `prompts/package/lib/validate.sh` 内の `emit_error` 関数（rsync で `docs/aidlc/lib/validate.sh` にコピーされる） |
| 呼び出し層（各スクリプト） | エラーコードとメッセージを指定して `emit_error` を呼び出す | 各 `.sh` ファイル |
| 消費層（プロンプト） | 出力を上記パース規則で解析し、エラー時の分岐処理を実行 | プロンプト `.md` ファイル |

## 変更対象ファイル

### スクリプト（エラー出力の更新）

| スクリプト | 現在の形式 | 作業量 |
|-----------|-----------|--------|
| `docs/aidlc/bin/write-history.sh` | 混在（`error:<code>` と `error:<msg>`） | 中 |
| `docs/aidlc/bin/setup-branch.sh` | 独自 `output()` 関数 | 中 |
| `docs/aidlc/bin/read-config.sh` | `Error:` (大文字E) | 小 |
| `docs/aidlc/bin/init-cycle-dir.sh` | `[error]` 括弧形式 | 中 |
| `docs/aidlc/bin/suggest-version.sh` | `error: ` (スペース付き) | 小 |
| `docs/aidlc/bin/check-open-issues.sh` | 新形式準拠済み | 確認のみ |
| `docs/aidlc/bin/check-gh-status.sh` | ステータスAPI（対象外） | 確認のみ |
| `docs/aidlc/bin/check-backlog-mode.sh` | ステータスAPI（対象外） | 確認のみ |
| `docs/aidlc/bin/cycle-label.sh` | 混在（新形式 + `Error:`） | 小 |
| `docs/aidlc/bin/label-cycle-issues.sh` | 新形式準拠済み | 確認のみ |

### プロンプト（エラーパースの更新）

| ファイル | 内容 |
|---------|------|
| `prompts/package/prompts/operations-release.md` | validate-git.sh出力のパース |
| `prompts/package/prompts/inception.md` | setup-branch.sh出力のパース |
| `prompts/package/prompts/common/commit-flow.md` | squash関連のエラーパース |

## 実装計画

### Phase 1: 設計

1. **ドメインモデル設計**: エラーコード体系の定義（コード命名規則、カテゴリ）、共通関数 `emit_error` の仕様
2. **論理設計**: 各スクリプトの変更仕様（旧→新のマッピング）、プロンプト側パース規則の統一仕様

### Phase 2: 実装

1. **コード生成**: `prompts/package/lib/validate.sh` に `emit_error` 共通関数を追加し、各スクリプトのエラー出力を移行
   - 既に準拠済みのスクリプト（check-open-issues.sh, label-cycle-issues.sh）は確認のみ
   - ステータスAPI専用スクリプト（check-gh-status.sh, check-backlog-mode.sh）は対象外として現行動作維持を確認
2. **プロンプト更新**: エラーパース箇所を新形式に対応（旧形式 `error:<code>` の読み取り互換も維持）
3. **テスト**: 各スクリプトのエラーケースを実行確認

## 完了条件チェックリスト

- [ ] 対象スクリプトのエラー出力を新形式 `error:<code>:<message>` に更新
- [ ] エラーコードのケバブケース統一
- [ ] プロンプト内のエラーパース箇所の更新（旧形式の読み取り互換を維持）
