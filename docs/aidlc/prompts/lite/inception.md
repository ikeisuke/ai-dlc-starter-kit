# Inception Phase プロンプト（Lite版）

## Full版プロンプトの参照【必須】

**まず以下のFull版プロンプトを読み込んでください**:
`docs/aidlc/prompts/inception.md`

Full版の内容を理解した上で、以下の変更点を適用してください。

**注意**: Lite版・Full版でファイルパスは同じです。最初に `docs/cycles/{{CYCLE}}/inception/progress.md` を読んでください。
- プロンプト: `docs/aidlc/prompts/`
- テンプレート: `docs/aidlc/templates/`
- サイクル成果物: `docs/cycles/{{CYCLE}}/`

---

## Lite版での変更点

### スキップするステップ

- **ステップ5: PRFAQ作成** → スキップ（Lite版では不要）

### 簡略化するステップ

- **ステップ1: Intent明確化** → 簡潔に1ファイルで記述（詳細な対話は不要、要点のみ）
- **ステップ3: ユーザーストーリー作成** → 箇条書きレベルでOK（詳細な受け入れ基準は省略可）
- **ステップ4: Unit定義** → 1ファイルにまとめる（個別ファイル不要）
- **ステップ6: progress.md作成** → 最小限の管理（Unit一覧と状態のみ）

### 維持するルール

以下のルールはLite版でも**必ず維持**してください：

- 人間の承認プロセス（重要な決定時）
- Gitコミット
- 履歴記録（history.md）
- コンテキストリセット対応

---

## Lite版の完了基準

- Intent作成済み（簡潔版）
- 簡易ユーザーストーリー作成済み（箇条書き）
- Unit定義（1ファイル）作成済み
- construction/progress.md作成済み

---

## 次のステップ【コンテキストリセット必須】

Inception Phase (Lite) が完了しました。以下のメッセージをユーザーに提示してください：

```markdown
---
## Inception Phase (Lite) 完了

コンテキストをリセットしてConstruction Phaseを開始してください。

**理由**: 長い会話履歴はAIの応答品質を低下させます。新しいセッションで開始することで最適なパフォーマンスを維持できます。

**Construction Phaseを開始するプロンプト**:
```
以下のファイルを読み込んで、サイクル vX.X.X の Construction Phase (Lite) を開始してください：
docs/aidlc/prompts/lite/construction.md
```
---
```

**重要**: ユーザーから「続けて」「リセットしないで」「このまま次へ」等の明示的な連続実行指示がない限り、上記メッセージを**必ず提示**してください。デフォルトはリセットです。
