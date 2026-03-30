# 論理設計: 簡略指示「AIDLCアップデート」追加

## Unit情報

- **Unit名**: 簡略指示「AIDLCアップデート」追加
- **Unit番号**: 008
- **関連Issue**: #69

## 変更対象ファイル

- `prompts/package/prompts/AGENTS.md`

## 変更内容

### 変更箇所

1. 「フェーズ簡略指示」セクションのテーブルに新規行を追加
2. テーブル列名「対応フェーズ」を「対応処理」に変更（アップグレードはフェーズではないため）
3. Lite版テーブルの列名も同様に「対応処理」に変更（整合性のため）

### 変更前（抜粋）

```markdown
| 指示 | 対応フェーズ |
|------|-------------|
| 「インセプション進めて」「start inception」 | Inception Phase |
| 「コンストラクション進めて」「start construction」 | Construction Phase |
| 「オペレーション進めて」「start operations」 | Operations Phase |
| 「セットアップ」「start setup」 | Setup（新規サイクル開始） |
```

### 変更後（抜粋）

```markdown
| 指示 | 対応処理 |
|------|----------|
| 「インセプション進めて」「start inception」 | Inception Phase |
| 「コンストラクション進めて」「start construction」 | Construction Phase |
| 「オペレーション進めて」「start operations」 | Operations Phase |
| 「セットアップ」「start setup」 | Setup（新規サイクル開始） |
| 「AIDLCアップデート」「update aidlc」「start upgrade」 | アップグレード（環境更新） |
```

## 設計判断

### 指示パターンの選定理由

1. **「AIDLCアップデート」**: 日本語で直感的に理解できる表現
2. **「update aidlc」**: 英語で簡潔な表現
3. **「start upgrade」**: 既存パターン「start xxx」との一貫性

### 除外した表現

- 「AIDLCアップデートして」: メインの「AIDLCアップデート」で包含可能（AIが自然言語として解釈）
- 「upgrade」単体: 曖昧さを避けるため

### setupとupgradeの混乱防止

| 指示 | 目的 | 読み込むファイル |
|------|------|-----------------|
| `start setup` / 「セットアップ」 | 新規サイクル開始 | `docs/aidlc/prompts/setup.md` |
| `start upgrade` / 「AIDLCアップデート」 | 環境更新 | `prompts/setup-prompt.md` |

**注意**: 両者は「start」で始まるが、目的とファイルが異なる。テーブル内の説明で区別を明示する。

## 影響範囲

- `prompts/package/prompts/AGENTS.md`（ソースオブトゥルース）
- `docs/aidlc/prompts/AGENTS.md`（Operations Phaseでrsyncされる）
- 既存機能への影響なし（列名変更は意味の明確化のみ）
