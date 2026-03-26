# ドメインモデル: Inceptionプロンプト名前付きサイクル統合

## 概要

Inception Phaseプロンプトにおける名前付きサイクルフローのドメインモデル。このUnitはプロンプト（AI指示文書）の変更のみであり、実行可能コードの変更は含まない。

## ドメインオブジェクト

### コンテキスト変数

| 変数名 | 型 | 設定タイミング | 説明 |
|--------|-----|---------------|------|
| `cycle_mode` | `"default" \| "named" \| "ask"` | ステップ5.5 | `rules.cycle.mode` から読み取り |
| `cycle_name` | `string \| ""` | ステップ5.5（named/ask時） | サイクル名（未設定時は空文字） |
| `{{CYCLE}}` | `string` | ステップ6 | `[name]/vX.Y.Z` or `vX.Y.Z` |

### サイクル名バリデーションルール

```text
正規表現: ^[a-z0-9][a-z0-9-]{0,63}$
禁止名: backlog, backlog-completed
禁止パターン: ^v[0-9] で始まる名前
```

### フローの状態遷移

```text
ステップ5.5
  ├─ mode=default → cycle_name="" → ステップ6（従来フロー）
  ├─ mode=named → 名前入力 → バリデーション → cycle_name設定 → ステップ6（名前付きフロー）
  └─ mode=ask → ユーザー選択
       ├─ 「名前付き」→ mode=namedフロー
       └─ 「通常」→ mode=defaultフロー
```

## バージョン提案フロー（名前付き時）

```text
suggest-version.sh実行
  → all_cycles取得
  → AIが all_cycles から ${cycle_name}/v* をフィルタ
  → 最新バージョンを特定
    ├─ 既存あり → patch/minor/major再計算 → ユーザーに提案
    └─ 既存なし → v1.0.0を提案
  → ユーザー選択/入力
  → {{CYCLE}} = ${cycle_name}/${version} で組み立て
  → 重複チェック（all_cyclesのカンマ分割トークン完全一致）
```

## 影響範囲

- **変更**: `prompts/package/prompts/inception.md` のみ
- **依存**: Unit 001（`rules.cycle.mode`設定）、Unit 002（スクリプト群の名前付き対応）
- **非変更**: スクリプト本体、設定ファイル、他フェーズプロンプト
