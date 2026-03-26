# Unit 4: Lite版案内追加 - 実装計画

## 概要
サイクルセットアップ完了メッセージにLite版の案内を追加

---

## 簡易実装先確認

### 1. 対象ファイルの分類

| ファイル | 分類 | 新規/修正 |
|----------|------|-----------|
| `prompts/setup-cycle.md` | ツール側 | 修正 |

### 2. 実装内容

**現状**: 「8. 完了メッセージ」にはFull版のInception Phaseのみ案内
**変更**: Lite版のInception Phaseも選択肢として追加

```markdown
## 次のステップ: Inception Phase の開始

新しいセッションで以下を実行してください：

**Full版**（推奨: 新機能・大きな変更）:
```
以下のファイルを読み込んで、サイクル [バージョン] の Inception Phase を開始してください：
docs/aidlc/prompts/inception.md
```

**Lite版**（バグ修正・小さな変更）:
```
以下のファイルを読み込んで、サイクル [バージョン] の Inception Phase (Lite) を開始してください：
docs/aidlc/prompts/lite/inception.md
```
```

---

## 完了基準

- [ ] prompts/setup-cycle.md の完了メッセージにLite版案内追加
- [ ] ビルド成功（該当なし）
- [ ] テストパス（該当なし）
