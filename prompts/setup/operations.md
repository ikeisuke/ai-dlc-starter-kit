# Operations Phase セットアップ

このファイルは `prompts/setup-prompt.md` から参照されます。

---

## 生成するファイル

### フェーズプロンプト

`prompts/package/prompts/operations.md` を `docs/aidlc/prompts/operations.md` にコピー

### ドキュメントテンプレート

以下のテンプレートを `prompts/package/templates/` から `docs/aidlc/templates/` にコピー:

- deployment_checklist_template.md
- monitoring_strategy_template.md
- distribution_feedback_template.md
- post_release_operations_template.md
- operations_progress_template.md

詳細は setup-init.md のセクション 6.2 を参照。

---

## 使用方法

Operations Phase を開始するには:

```
以下のファイルを読み込んで、サイクル vX.X.X の Operations Phase を開始してください：
docs/aidlc/prompts/operations.md
```
