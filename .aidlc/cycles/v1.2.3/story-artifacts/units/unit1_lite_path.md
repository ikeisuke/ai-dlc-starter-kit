# Unit 1: Lite版パス解決安定化

## 概要
Lite版プロンプトでファイルパスを明確化し、AIがファイルを迷わず見つけられるようにする。

## 対象ストーリー
- US-1: Lite版パス解決の安定化

## 依存関係
なし

## 修正対象ファイル

| ファイル | 変更内容 |
|----------|----------|
| `docs/aidlc/prompts/lite/inception.md` | パス解決ガイドセクション追加 |
| `docs/aidlc/prompts/lite/construction.md` | パス解決ガイドセクション追加 |
| `docs/aidlc/prompts/lite/operations.md` | パス解決ガイドセクション追加 |

## 修正内容

### 追加するセクション（各Lite版プロンプトの冒頭）

```markdown
## パス解決ガイド【重要】

**サイクルディレクトリ構造**:
```
docs/cycles/v1.2.3/          ← サイクルルート
├── inception/
│   └── progress.md          ← Inception Phase進捗
├── construction/
│   ├── progress.md          ← Construction Phase進捗
│   └── units/               ← 実装記録
├── operations/
│   └── progress.md          ← Operations Phase進捗
├── requirements/            ← Intent等
├── story-artifacts/         ← ユーザーストーリー、Unit定義
├── design-artifacts/        ← 設計ドキュメント
├── plans/                   ← 計画ファイル
└── history.md               ← 履歴
```

**最初に確認すべきファイル**:
1. `docs/cycles/{{CYCLE}}/[phase]/progress.md` で現在の進捗を確認
2. progress.mdに記載されたパスに従ってファイルにアクセス
```

## 受け入れ基準
- [ ] Lite版プロンプトに具体的なパス例が記載されている
- [ ] サイクルディレクトリ構造の説明が追加されている

## 見積もり
小（プロンプト修正のみ）
