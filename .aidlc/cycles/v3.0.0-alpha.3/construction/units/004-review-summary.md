# レビューサマリ: Unit 004 state-validate.sh schema_version 互換性検証（#731）

## 基本情報

- **サイクル**: v3.0.0-alpha.3
- **フェーズ**: Construction
- **対象**: Unit 004 state-validate.sh schema_version 互換性検証（#731）

<!-- 以下、AIレビュー完了時に Set が追記される -->

---

## Set 0: 2026-06-14 計画レビュー

- **レビュー種別**: 計画承認前レビュー（reviewing-construction-plan / focus: 構造・パターン・依存関係 + Unit 固有）
- **使用ツール**: codex
- **反復回数**: 1
- **結論**: 指摘0件（Round 1 clean / 1R clean 特例で完了）。validator=検証 SoT / writer=更新ガード の責務分離、未知 schema_version を validator WARN+exit0・writer 更新拒否 exit1 とする設計が data-model.md §6・終了コード規約と整合と確認。

### 指摘一覧

指摘なし（0 件）。

---

## Set 1: 2026-06-14 設計レビュー

- **レビュー種別**: 設計レビュー（reviewing-construction-design / focus: architecture）
- **使用ツール**: codex
- **反復回数**: 3
- **結論**: 指摘対応判断完了（R1 2 件 + R2 1 件 全 3 件 修正済み / Round 3 で指摘0件 clean）

### 指摘一覧

| # | 重要度 | 内容 | 対応 | バックログ |
|---|--------|------|------|-----------|
| 1 | 中 | `logical-designs/unit_004_..._logical_design.md` - validator の値検証挿入位置の記述揺れ。前半が「既存 jq 式の後」と読め、既存 jq 式は release/updated_at まで検証するため未知 schema_version + release 欠落を warn 短絡できず D2・テスト設計と矛盾 | 修正済み（ステップ0 (a)/(b)・代替案検討表（値検証の実装位置 / 短絡のタイミング）・検証順序の設計詳細を「既存 jq 式を 2 段に分割: 前段=schema_version has+string / 間に bash 互換性判定・未知 WARN+exit0 短絡 / 後段=残り構造+ISO8601」と一貫記述に統一） | - |
| 2 | 中 | `domain-models/..._domain_model.md`, `logical-designs/..._logical_design.md` - `status:warn:unsupported-schema-version:<value>` に schema_version 生値を埋め込む契約が、改行・制御文字・コロンで status 行が複数行化・曖昧化し writer/doctor の parse 契約を破る | 修正済み（値を改行・制御文字除去した `<safe-value>` に変更し単一行保証。writer の検知契約を「stdout 先頭行がリテラル接頭辞 `status:warn:unsupported-schema-version:` で始まるか」のみに限定（値内容非依存）。生値は stderr 側でのみ参考表示。ドメインモデル ValidationOutcome に parse 契約（不変条件）を追記。validator/writer 双方に改行・制御文字を含む未知値の境界テストを追加） | - |
| 3 | 中 | `domain-models/..._domain_model.md` L35 - 代替案検討表に旧表現「既存の if-elif 検証チェーンの後段に値判定を足す」が残存し、論理設計の 2 段分割と矛盾（R2 検出） | 修正済み（ドメインモデル採用行を「既存 jq if-elif 式を 2 段に分割し、schema_version has+string 検証直後・残り構造検証の前に互換性判定を挿入」と論理設計に一致させた） | - |

---

## Set 2: 2026-06-14 コードレビュー

- **レビュー種別**: コードレビュー（reviewing-construction-code / focus: code, security）
- **使用ツール**: codex
- **反復回数**: 2
- **結論**: 指摘対応判断完了（R1 1 件 修正済み / Round 2 で指摘0件 clean）。codex がテストを実行し PASS=88 FAIL=0・shellcheck 通過を確認

### 指摘一覧

| # | 重要度 | focus | 内容 | 対応 | バックログ |
|---|--------|-------|------|------|-----------|
| 1 | 低 | security | `skills/aidlc-v3/scripts/state-write.sh` - pre-write validator の rc=0 分岐が warn 接頭辞のみ拒否で、それ以外（空 / 未知 status 行）を valid 扱いで更新継続。将来 validator 出力契約が壊れた場合に status 行 parse 契約の防御が弱まる | 修正済み（rc=0 分岐を 3 分岐化: `status:valid` のみ proceed / warn 接頭辞は拒否（exit 1 / ファイル不変）/ それ以外は出力契約違反として exit 2 の fail-safe。論理設計の writer 設計詳細も同期） | - |

- **N/A 判定**: セキュリティのうちネットワーク（CLI ツール / 通信なし）・OWASP HTTP 系・ログ機密混入は本スクリプト（ローカル state ファイル検証 / 機密非取扱）では N/A。本 Unit のセキュリティ主眼は status 行 parse 契約保護と非互換 state 更新ガードであり、指摘 #1 で hardening 済み。

---

## Set 3: 2026-06-14 統合レビュー

- **レビュー種別**: 統合レビュー（reviewing-construction-integration / focus: code / 設計-実装整合性・レビュー/テスト実施・完了条件）
- **使用ツール**: codex
- **反復回数**: 2
- **結論**: 指摘対応判断完了（R1 1 件 修正済み / Round 2 で指摘0件 = 残課題なし）。codex 実測で PASS=88 FAIL=0 / bash -n・shellcheck・markdownlint 通過 / v2 非影響を確認

### 指摘一覧

| # | 重要度 | 内容 | 対応 | バックログ |
|---|--------|------|------|-----------|
| 1 | 低 | `story-artifacts/units/004-state-validate-schema-compat.md`, `plans/unit-004-plan.md` - Unit 定義の実装状態が「未着手」のまま・計画チェックリスト未チェックで、実装記録の「完了」と乖離（成果物メタデータが古い） | 修正済み（Unit 定義を 状態:完了 / 開始日・完了日 2026-06-14 に更新、計画チェックリスト全 9 項目を [x] に同期） | - |
