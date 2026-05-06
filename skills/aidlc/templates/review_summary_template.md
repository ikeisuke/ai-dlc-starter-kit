# レビューサマリ: [対象名]

## 基本情報

- **サイクル**: {{CYCLE}}
- **フェーズ**: [Construction / Inception]
- **対象**: [Unit名 / ステップ名]

<!-- 以下、AIレビュー完了時に Set が追記される -->

---

## Setフォーマット

````markdown
## Set [N]: [YYYY-MM-DD HH:MM:SS]

- **レビュー種別**: [全種別]
- **使用ツール**: [codex / self-review(skill) / self-review(inline)]
- **反復回数**: [1〜5]
- **結論**: [指摘0件 / 指摘対応判断完了]

### 指摘一覧

| # | 重要度 | 内容 | 対応 | バックログ |
|---|--------|------|------|-----------|
| 1 | 高/中/低 | [対象箇所] - [問題事象] | 修正済み / TECHNICAL_BLOCKER(理由) / OUT_OF_SCOPE(理由) | 対応値に応じて: `修正済み` → `-` / `TECHNICAL_BLOCKER` または `OUT_OF_SCOPE` → `#NNN` または `PENDING_MANUAL` または `SECURITY_PRIVATE`（自動起票必須） |

### Round 4 新領域判定（Round 4 以降に到達した場合のみ）

```json
{
  "K_old": ["scripts/lib", "steps/common"],
  "K_new": ["scripts/lib", "steps/common", "templates"],
  "K_diff": ["templates"],
  "rounds_executed": 4
}
```

新領域判定の境界条件・判定手順は `skills/aidlc/steps/common/review-flow.md` の「Round 4 以降の新領域指摘の自動 backlog 化フロー」を参照。
````

---

## 記述例（参考 - 実ファイル作成時は削除）

> **注（v2.5.2 以降）**: 以下の例の `内容` 列に「最大3回の反復制限を追記」など過去サイクルの履歴文言が含まれている場合がある。本サイクル v2.5.2 以降は反復回数上限が **5 回**、完了条件は **(1R clean 特例: Round 1 で指摘ゼロまたは defer 化) OR (最後 2 round 連続で指摘ゼロまたは defer 化)** に改定されている（`review-flow.md` 参照）。例文中の「3 回」表記は当時の上限値の記録であり、現行仕様ではない。

### 良い例

| # | 重要度 | 内容 | 対応 | バックログ |
|---|--------|------|------|-----------|
| 1 | 高 | inception.md のUnit定義テンプレート参照パス - `templates/` と `skills/aidlc/templates/` で不一致 | 修正済み（inception.md L245: パスを `skills/aidlc/templates/` に統一） | - |
| 2 | 中 | review-flow.md のセルフレビュー手順 - 反復回数上限が未定義で無限ループリスク | 修正済み（review-flow.md L470: 最大3回の反復制限を追記） | - |
| 3 | 低 | commit-flow.md のsquashコマンド例 - `--no-edit` オプションが非推奨 | OUT_OF_SCOPE（理由: squash機能の全面改修はUnit 004のスコープ） | #123 |
| 4 | 中 | rules.md の境界ルール - 認証トークンのバリデーション不足 | TECHNICAL_BLOCKER（理由: 外部API仕様が未確定で対応不可） | #456 |
| 5 | 高 | auth-service.js - SQLインジェクション脆弱性 | OUT_OF_SCOPE（理由: 認証基盤の全面改修が必要） | SECURITY_PRIVATE |
| 6 | 中 | config-loader.js - 設定ファイルパス検証不足 | OUT_OF_SCOPE（理由: 次サイクルで対応） | PENDING_MANUAL |

> 上記 #2 の「最大3回の反復制限」は当時の上限値の記録。本サイクル v2.5.2 以降は 5 回上限 + 単一仕様完了条件（`review-flow.md` 参照）。

### 悪い例（NG）

| # | 重要度 | 内容 | 対応 | バックログ |
|---|--------|------|------|-----------|
| 1 | 高 | パスの矛盾 | 修正済み | - |
| 2 | 中 | 反復回数の問題 | 修正済み（注記追加） | - |
| 3 | 低 | 非推奨オプション | OUT_OF_SCOPE（理由: スコープ外） | |

**NG理由**: 対象ファイル・具体的な問題事象・変更内容が不明で、後から参照しても問題と対応を把握できない。バックログ列がOUT_OF_SCOPE時に未記入。

※ 記述ルールの詳細は review-flow.md の「列の記述ガイダンス」を参照。
※ Round 4 以降の新領域判定の記録仕様は review-flow.md の「Round 4 以降の新領域指摘の自動 backlog 化フロー」を参照。
