# Unit: CLAUDE.md / AGENTS.md 刷新

## 概要
プラグインレベルのCLAUDE.md/AGENTS.mdを作成。旧 `docs/aidlc/prompts/CLAUDE.md` と `docs/aidlc/prompts/AGENTS.md` を統合し、`/aidlc` スキルへのフェーズルーティングを提供する。

## 含まれるユーザーストーリー
- ストーリー 9: プラグインレベルCLAUDE.md/AGENTS.md

## 責務
- ルートCLAUDE.md: フェーズ簡略指示 → `/aidlc` スキルへのマッピング
- ルートAGENTS.md: マルチツール対応エントリポイント
- AskUserQuestion使用ルール
- gitコミットメッセージルール（$()禁止）
- コンパクション後の復帰手順
- 非AIDLCプロジェクトガード

## 境界
- 旧CLAUDE.md/AGENTS.mdの機能を統合するのみ（新機能追加なし）

## 依存関係

### 依存する Unit
- Unit 005: aidlcスキル - Inception Phase（依存理由: フェーズルーティング先のスキルが存在する必要がある）
- Unit 006: aidlcスキル - Construction Phase（依存理由: 同上）
- Unit 007: aidlcスキル - Operations Phase（依存理由: 同上）
- Unit 008: aidlcスキル - Setup Phase（依存理由: 同上）

### 外部依存
- なし

## 非機能要件（NFR）
- **パフォーマンス**: 特になし
- **セキュリティ**: 特になし
- **スケーラビリティ**: 特になし
- **可用性**: 特になし

## 技術的考慮事項
- CLAUDE.mdはプラグインレベルで読み込まれるため、プロジェクトのCLAUDE.mdと競合しないよう注意

## 実装優先度
Medium

## 見積もり
小〜中

---
## 実装状態

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
- **エクスプレス適格性**: -
- **適格性理由**: -
