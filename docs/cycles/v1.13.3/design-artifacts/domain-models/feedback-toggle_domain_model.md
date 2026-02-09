# ドメインモデル: フィードバック送信機能オン/オフ設定

## 概要

`docs/aidlc.toml` の `[rules.feedback].enabled` 設定によりフィードバック送信機能の有効/無効を制御する。AIプロンプト（AGENTS.md）が設定を読み取り、無効時はフィードバック導線全体をブロックする。

**重要**: このドメインモデル設計では**コードは書かず**、構造と責務の定義のみを行います。実装はImplementation Phase（コード生成ステップ）で行います。

## 値オブジェクト（Value Object）

### FeedbackEnabled

- **属性**: enabled: string - `docs/aidlc/bin/read-config.sh` から取得した設定値
- **不変性**: 設定ファイルから読み取った値は判定処理中に変更されない
- **等価性**: 文字列 `"false"` と完全一致する場合のみ「無効」、それ以外はすべて「有効」
- **デフォルト**: `"true"`（`docs/aidlc/bin/read-config.sh --default "true"` により設定未定義時に返される）

## ドメインサービス

### FeedbackGateService

- **責務**: フィードバック送信機能の有効/無効判定を行い、導線を制御する
- **操作**:
  - `checkEnabled()`: `docs/aidlc/bin/read-config.sh rules.feedback.enabled --default "true"` を実行し、結果が `"false"` と完全一致するか判定
    - `"false"` → 無効: ブロックメッセージ「この機能は無効化されています」を表示し終了
    - それ以外 → 有効: 既存のフィードバック送信フローに進む

## 設定構造

### `[rules.feedback]` セクション

```toml
[rules.feedback]
# フィードバック送信機能設定
# enabled: true | false
# - true: フィードバック送信機能を有効化（デフォルト）
# - false: フィードバック送信機能を無効化（企業利用時のセキュリティ対策）
enabled = true
```

### 設定の読み込み優先順位

`docs/aidlc/bin/read-config.sh` の既存マージルール（local > base > global）に従う（ストーリー要件の最小保証は local > base）：

1. `docs/aidlc.toml.local`（最高優先度）
2. `docs/aidlc.toml`（中間優先度）
3. `~/.aidlc/config.toml`（最低優先度）

### フォールバック仕様

| 設定状態 | `docs/aidlc/bin/read-config.sh` 出力 | 判定結果 |
|----------|----------------------|----------|
| `enabled = true` | `"true"` | 有効 |
| `enabled = false` | `"false"` | **無効** |
| キー未定義 | `"true"`（`--default` による） | 有効 |
| 不正値（例: `"abc"`） | `"abc"` | 有効（`"false"` 完全一致ではない） |

## ユビキタス言語

- **フィードバック送信**: AI-DLCスターターキットに対するフィードバック（改善提案・バグ報告等）をGitHub Issueとして送信する機能
- **導線ブロック**: フィードバック送信に関わるすべてのステップ（ヒアリング、Issue作成、URL案内）を実行しないこと
- **フォールバック**: 設定値が不正または未定義の場合に安全なデフォルト値に戻ること

## 不明点と質問（設計中に記録）

[Question] 不正値時のフォールバックロジック
[Answer] `false` 完全一致のみ無効化、それ以外はすべて有効として扱う（安全側に倒す設計）
