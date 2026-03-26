# 実装記録: ルール責務分離とフェーズ簡略指示

**Unit**: 001-rules-separation
**完了日**: 2026-01-10

---

## 実装概要

AI-DLC共通ルールを `AGENTS.md` に集約し、`rules.md` をプロジェクト固有ルールのみに整理。
また、フェーズ簡略指示機能を追加し、シンプルな指示でフェーズを開始できるようにした。

---

## 変更ファイル一覧

| ファイル | 変更内容 |
|----------|----------|
| `prompts/package/prompts/AGENTS.md` | 共通ルール + フェーズ簡略指示追加 |
| `prompts/package/prompts/inception.md` | 完了時メッセージ簡略化 |
| `prompts/package/prompts/construction.md` | 完了時メッセージ簡略化 |
| `prompts/package/prompts/operations.md` | 完了時メッセージ簡略化 |
| `prompts/package/prompts/setup.md` | 完了時メッセージ簡略化 |
| `prompts/package/prompts/lite/*.md` | 完了時メッセージ簡略化 |
| `docs/cycles/rules.md` | スターターキット固有ルールのみに整理 |

---

## 追加された機能

### フェーズ簡略指示

| 指示 | 対応フェーズ |
|------|-------------|
| 「インセプション進めて」「start inception」 | Inception Phase |
| 「コンストラクション進めて」「start construction」 | Construction Phase |
| 「オペレーション進めて」「start operations」 | Operations Phase |
| 「セットアップ」「start setup」 | Setup |

**Lite版**:
| 指示 | 対応フェーズ |
|------|-------------|
| 「start lite inception」 | Inception Phase (Lite) |
| 「start lite construction」 | Construction Phase (Lite) |
| 「start lite operations」 | Operations Phase (Lite) |

---

## 関連バックログ

- `docs/cycles/backlog/chore-move-common-rules-to-agents-md.md` → 対応完了
- `docs/cycles/backlog/feature-setup-prompt-path-recording.md` → 新規作成（別途対応）

---

## テスト結果

- 整合性チェック: PASS
  - 全プロンプトの完了時メッセージが簡略指示形式に更新されていることを確認
  - AGENTS.mdのフェーズ簡略指示テーブルが正しく定義されていることを確認

---

## 状態

**完了**
