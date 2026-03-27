# Unit: 旧ディレクトリ移行・削除

## 概要
`docs/aidlc/` 配下の旧ディレクトリ（templates, bin, config, skills, tests）を削除し、参照先をv2パスに更新する。エントリポイントMD（inception.md等）はリダイレクト用として残す。

## 含まれるユーザーストーリー
- ストーリー 2: 旧ディレクトリの移行・削除
- ストーリー 3: 旧パス参照の一掃（部分）

## 責務
- #415 B1: `docs/aidlc/templates/` 参照の更新（20+箇所）→ 削除
- #415 B3: `docs/aidlc/config/` 参照の更新 → 削除
- #415 B4: `docs/aidlc/skills/` の `skills/` トップレベルへの統合確認 → 削除
- #415 B7: `.claude/skills/` シンボリックリンクの確認・整理
- #414 D3: `docs/aidlc/prompts/CLAUDE.md` の正本参照先更新
- #414 D5: `.kiro/agents/aidlc-poc.json` の旧パス修正
- `docs/aidlc/bin/` の削除（スクリプトは `skills/aidlc/scripts/` に移行済み）
- エントリポイントMD（inception.md, construction.md, operations.md等）にリダイレクト案内を記載して残す

## 境界
- `docs/aidlc/guides/` は削除しない（ガイド文書として維持）
- `docs/aidlc/kiro/` は削除しない（Kiro設定として維持）
- `docs/aidlc/lib/` は削除しない（バリデーションスクリプト）
- `prompts/package/` の廃止は含まない（#415 B5 → v2.0.2以降）

## 依存関係

### 依存する Unit
- Unit 001（依存理由: `docs/cycles/` の移動が先に完了している必要がある。旧ディレクトリ削除の前提）

### 外部依存
- なし

## 非機能要件（NFR）
- **パフォーマンス**: N/A
- **セキュリティ**: N/A
- **スケーラビリティ**: N/A
- **可用性**: N/A

## 技術的考慮事項
- ステップファイル内のテンプレート参照（`docs/aidlc/templates/`）は20+箇所。一括置換で対応
- `setup-ai-tools.sh` のシンボリックリンク生成ロジック確認が必要
- エントリポイントMDのリダイレクト案内は後方互換性のため

## 実装優先度
High

## 見積もり
中規模（参照更新20+箇所 + ディレクトリ削除 + シンボリックリンク確認）

---
## 実装状態

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
- **エクスプレス適格性**: -
- **適格性理由**: -
