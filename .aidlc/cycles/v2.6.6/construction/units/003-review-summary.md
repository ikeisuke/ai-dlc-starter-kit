# レビューサマリ: Unit 003 一次情報三層検証 helper

## 基本情報

- **サイクル**: v2.6.6
- **フェーズ**: Construction
- **対象**: Unit 003 (003-fact-extract-helper / 一次情報三層検証 helper / 3 source MVP + jsonl 引数 opt-in)

---

## Set 1: 2026-05-19 09:00:00

- **レビュー種別**: 設計レビュー（construction-design / focus: architecture）
- **使用ツール**: codex
- **反復回数**: 3
- **結論**: 指摘0件（last_round_clean）

### 指摘一覧

| # | 重要度 | 内容 | 対応 | バックログ |
|---|--------|------|------|-----------|
| 1 | 中 | `.aidlc/cycles/v2.6.6/design-artifacts/logical-designs/unit_003_fact_extract_helper_logical_design.md` - §1.1.5 5 行厳守 vs DR タイトル・主因 3 分類抽出の不整合（5 行と追加抽出のどちらかが破綻するリスク） | 修正済み（logical_design L142 付近: 「§1.1.5 互換モード公開契約」を追加 / `dr_titles` / `dr_root_cause_class` は内部集計のみで stdout 非表示 / 将来別 API で公開検討） | - |
| 2 | 中 | `.aidlc/cycles/v2.6.6/design-artifacts/logical-designs/unit_003_fact_extract_helper_logical_design.md` - L1↔L2 中間形式が `item` 文字列の固定リテラル依存で層分離が弱い | 修正済み（logical_design L120 付近: 中間形式を `{kind}\|{item_id}\|{value}\|{source_path}` に変更 / `item_id ↔ §1.1.5 表示ラベル マッピング`表を L2 専有 SoT として追加 / 表示ラベル変換は L2 限定） | - |
| 3 | 中 | `.aidlc/cycles/v2.6.6/design-artifacts/logical-designs/unit_003_fact_extract_helper_logical_design.md` - jsonl 機密フィルタ正規表現エンジン未指定（BRE/ERE 混在で検出漏れリスク） | 修正済み（logical_design L235 付近: 採用エンジン ERE に固定 / 4 パターンを ERE 構文で再定義 / BRE 風 `\|` 禁止を明記 / 必須テストケース MASK-01〜MASK-10 を設計章に追加） | - |
| 4 | 中 | `.aidlc/cycles/v2.6.6/design-artifacts/logical-designs/unit_003_fact_extract_helper_logical_design.md` - `secret_kv` パターン表記が `(secret\|password\|token)...` のままで ERE 方針と自己矛盾 | 修正済み（logical_design L245: `(secret\|password\|token)...` → `(secret|password|token)...` に統一） | - |

### Round 履歴

- **Round 1**: 4 件中 3 件指摘（高 0 / 中 3 / 低 0）— 上記 #1〜#3 を反映
- **Round 2**: 1 件指摘（高 0 / 中 1 / 低 0）— 上記 #4 を反映
- **Round 3**: 指摘 0 件（clean）

完了条件: `rounds.size=3 ≥ 2 && last_round_clean` → completed。`unresolved_count=0` + フォールバック非該当 → セミオートゲート `auto_approved`。

セッション ID: `019e3d7a-48fb-7701-baab-df6041a816b8`

---

## Set 2: 2026-05-19 09:30:00

- **レビュー種別**: コードレビュー（construction-code / focus: code, security）
- **使用ツール**: codex
- **反復回数**: 3
- **結論**: 指摘0件（last_round_clean）

### 指摘一覧

| # | 重要度 | 内容 | 対応 | バックログ |
|---|--------|------|------|-----------|
| 1 | 高 | `skills/aidlc/scripts/lib/retrospective-fact-extract.sh` - 機密マスク正規表現値文字種が `[A-Za-z0-9_.\-]` 限定で Base64 `+/=` 含むトークンが取りこぼされる | 修正済み（4 パターンすべて `[A-Za-z0-9._~+/=-]` に拡張 / MASK-11 / MASK-12 追加） | - |
| 2 | 中 | `skills/aidlc/scripts/lib/retrospective-fact-extract.sh` - jsonl_path 検証が `-f` のみで任意絶対パス + path traversal を許容（security 観点） | 修正済み（拡張子 `.jsonl` 必須化 + 制御文字拒否 + `..` セグメント拒否 / JSONL-4 / JSONL-5 / JSONL-6 追加） | - |
| 3 | 低 | `skills/aidlc/scripts/lib/retrospective-fact-extract.sh` - source_path 内の `|` 改行未エスケープで markdown 表が壊れうる | 修正済み（extractor 側でエスケープ + renderer 側で復元 / 同形のエスケープ規約適用） | - |

### Round 履歴

- **Round 1**: 3 件指摘（高 1 / 中 1 / 低 1）— 上記 #1〜#3 を反映 / MASK-11 / MASK-12 / JSONL-4 テスト追加
- **Round 2**: 1 件指摘（中 1）— path traversal `..` 未拒否を上記 #2 補足対応で反映 / JSONL-5 / JSONL-6 テスト追加
- **Round 3**: 指摘 0 件（clean）

完了条件: `rounds.size=3 ≥ 2 && last_round_clean` → completed。`unresolved_count=0` + フォールバック非該当 → セミオートゲート `auto_approved`。

セッション ID: `019e3d84-f68c-7981-a429-9403da0f9601`

---

## Set 3: 2026-05-19 09:50:00

- **レビュー種別**: 統合レビュー（construction-integration / focus: code）
- **使用ツール**: codex
- **反復回数**: 1
- **結論**: 指摘0件（1R clean 特例）

### 指摘一覧

指摘0件。

完了条件: `rounds.size=1 && rounds[0].is_clean()` → completed（1R clean 特例）。`unresolved_count=0` + フォールバック非該当 → セミオートゲート `auto_approved`。

