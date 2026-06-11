# 実装記録: Unit 003 aidlc-v3 skill 骨組み

## 実装日時

2026-06-11（Construction Phase / Unit 003）

## 作成ファイル

### ソースコード（skill 骨組み）

- `skills/aidlc-v3/SKILL.md` - ルーティング。6 コマンド（define/develop/release/reflect/status/doctor）+ express 連続実行ラッパ（適格条件: 単一 work item tiny/normal）+ 旧名エイリアス（inception/construction/operations/retrospective）+ 引数なし実行のフェーズ導出ルーティング + コアルール参照ポイント + パス解決規約 + コマンド表記の区別（/aidlc end-state と /aidlc-v3 skeleton）
- `skills/aidlc-v3/steps/define.md` - define フロー Step 1-4（環境チェック / Intent 定義★ / Work Item 分割★ / 初期化）を読める手順として記述。Step 4 に state.json 必須フィールド・`define_completed` 書き込みタイミング・state-write/validate 参照・early_pr 条件を明示
- `skills/aidlc-v3/steps/status.md` - status 出力仕様。フェーズ導出は data-model §5 参照、complete 判定は release.merge_approved と PR merged 実態の両方参照、出力例（Blocked 含む）

### 設計ドキュメント

- `.aidlc/cycles/v3.0.0-alpha.2/design-artifacts/domain-models/unit_003_v3_skill_skeleton_domain_model.md`
- `.aidlc/cycles/v3.0.0-alpha.2/design-artifacts/logical-designs/unit_003_v3_skill_skeleton_logical_design.md`

## ビルド結果

成功（Markdown skeleton のためビルドは構造検証で代替）

```text
markdownlint-cli2: SKILL.md + steps 2 ファイル 0 errors
CI 構造チェック: skills/aidlc/ プロジェクトルート相対参照なし
```

## テスト結果（構造検証 / 再現可能手順）

成功。以下の再現可能な手順で構造を検証（計画 §4 完了条件に対応）:

```text
1. コマンド名: develop 採用、build/implement はエイリアスに含まない（不採用明記のみ）
2. 旧名エイリアス4種: inception/construction/operations/retrospective → 存在
3. 参照パス: status.md→scripts/state-read.sh, define.md→scripts/state-write.sh
   /state-validate.sh, define.md→templates/intent.md/work-item.md/journal.md
   → 参照先6ファイルすべて実在（Unit 001/002 実体）
4. complete判定: release.merge_approved と PR merged 実態の両方参照 → 確認
5. status出力: Blocked 行を含む（workflow.md §3.5 一致）
6. フェーズ導出SoT: data-model.md §5 を参照（SKILL.md/status.md で規則再定義なし）
7. 予約コマンド: 未作成 steps/(develop|release|reflect|doctor).md への実参照なし
8. v2非影響: skills/aidlc/ 配下の変更なし
```

## コードレビュー結果

- [x] セキュリティ: OK（機密情報・ローカル絶対パス混入なし）
- [x] コーディング規約: OK（`skills/aidlc/` 参照なし、スキルベースディレクトリ相対パス）
- [x] 整合性: OK（コマンド名 develop・フェーズ導出 SoT 参照・エイリアス方針・define Step・status 出力が workflow.md/data-model/rfc と一致）
- [x] テストカバレッジ: OK（構造検証 8 項目を再現可能手順で確認）
- [x] ドキュメント: OK（skeleton の位置づけ・コマンド表記の区別を明示）

## 技術的な決定事項

- **コマンド名 develop**: RFC DG-1 準拠。build/implement は不採用かつエイリアスにもしない
- **フェーズ導出の SoT 参照**: 導出規則は data-model §5 を正本とし、SKILL.md/status.md は結果参照のみ（first-match 等は非規範サマリと明記）。SoT 二重定義を回避
- **予約コマンド**: develop/release/reflect/doctor は本 Unit で実体を作らず、SKILL.md で「予約（後続 Phase で実装）」として記述。未作成 steps/*.md への実参照を作らない
- **コマンド表記の区別**: 最終表面 `/aidlc`（workflow.md end-state）と現 skeleton 起動表面 `/aidlc-v3`（v2 共存・marketplace 登録 defer 由来）を SKILL.md に明文化（コードレビュー指摘 #1 反映）
- **参照パスのスキルベース相対**: scripts/・templates/ は SKILL.md 基点のスキルベースディレクトリ相対と明示（step 相対の誤解釈を防止）

## 課題・改善点

- フロー実行実装（define/status の実行）・marketplace.json 登録（`/aidlc-v3` 起動有効化）・develop/release/reflect/doctor 手順・v3 rules 実体は Phase 3 以降へ defer（intent スコープに整合）

## 状態

**完了**

## 備考

- v2 非影響を全コミットで確認（`skills/aidlc/` 配下の変更なし）。成果物は `skills/aidlc-v3/` および `.aidlc/cycles/` 配下に限定
