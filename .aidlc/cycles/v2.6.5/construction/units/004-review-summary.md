# レビューサマリ: Unit 004 defaults.toml 二重 SoT 同期ガード (CI 早期検出)

## 基本情報

- **サイクル**: v2.6.5
- **フェーズ**: Construction
- **対象**: Unit 004 (関連 Issue: #714)

---

## Set 1: 2026-05-17 (設計レビュー)

- **レビュー種別**: reviewing-construction-design / architecture focus
- **使用ツール**: codex (session id: 019e360b-464b-71c2-a73d-02678f56ef2a)
- **反復回数**: 5
- **結論**: 指摘0件 (last_round_clean → completed)

### 指摘一覧

| # | 重要度 | 内容 | 対応 | バックログ |
|---|--------|------|------|-----------|
| 1 | 高 | logical_design.md - failure contract スキーマ文書間不一致 | 修正済み (`in-source`/`in-copy` 区別の正式契約に統一 / commit 4e95e572) | - |
| 2 | 高 | logical_design.md - dasel/jq 依存供給経路未定義 | 修正済み (workflow インストール + スクリプト存在チェックの二重防御明文化 / commit 4e95e572) | - |
| 3 | 中 | logical_design.md - Phase 1 / Phase 2 gate 役割が矛盾 | 修正済み (Phase 1 diagnostic 降格、Phase 2 のみ gate / commit 4e95e572) | - |
| 4 | 中 | domain_model.md - failure contract に parse-error / tool-missing 欠落 | 修正済み (exit 3/4 + 5 種類の failure contract に拡張 / commit 4e95e572) | - |
| 5 | 低 | domain_model.md - Phase 1 を残す根拠が弱い | 修正済み (後方互換維持 + コメント false positive 排除の根拠明示 / commit 4e95e572) | - |
| 6 | 中 | logical_design.md - 文書内で Phase 1 扱いがまだ矛盾 | 修正済み (処理フロー側の Phase 1 gate 表現を diagnostic に統一 / commit 53409668) | - |
| 7 | 中 | logical_design.md - workflow 変更要否が文書内矛盾 | 修正済み (コンポーネント構成側を「pr-check.yml に dasel/jq インストール追加」に統一 / commit 53409668) | - |
| 8 | 低 | domain_model.md Step 0 に旧 failure contract 記述残存 | 修正済み (正式契約参照に書き換え / commit 53409668) | - |
| 9 | 低 | logical_design.md - 概要冒頭の「CI ジョブ変更不要」残存 | 修正済み (workflow 変更要に統一 / commit ad3c952d) | - |
| 10 | 低 | logical_design.md - NFR 後方互換に「既存 CI ジョブ変更不要」残存 | 修正済み (「workflow に dasel/jq インストール追加が必要」に統一 / commit 55fe55fc) | - |

### round 別集計

- Round 1: 5 件 (高 2 / 中 2 / 低 1)
- Round 2: 3 件 (中 2 / 低 1)
- Round 3: 1 件 (低 1)
- Round 4: 1 件 (低 1)
- Round 5: 0 件 (clean → completed)

---

## Set 2: 2026-05-17 (コードレビュー)

- **レビュー種別**: reviewing-construction-code / code+security focus
- **使用ツール**: codex (session id: 019e3613-4e01-7321-b048-111e5473c3b1)
- **反復回数**: 2
- **結論**: 指摘0件 (last_round_clean → completed)

### 指摘一覧

| # | 重要度 | 内容 | 対応 | バックログ |
|---|--------|------|------|-----------|
| 1 | 高 | `.github/workflows/pr-check.yml` - dasel `releases/latest` 経路でサプライチェーン脆弱性 (SECURITY-10) | 修正済み (v3.10.1 pin + sha256 検証 `e35d899a...` + 更新手順コメント / commit 3a116d14) | - |
| 2 | 中 | `.github/workflows/pr-check.yml` - `/usr/local/bin/dasel` 直接書き込みで権限失敗リスク | 修正済み (`sudo install -m 0755` + `mktemp -d` 一時ディレクトリ + EXIT trap / commit 3a116d14) | - |
| 3 | 低 | `bin/check-defaults-sync.sh` - エラーメッセージ「apt-get install」が実際の curl 経路と不一致 | 修正済み (「sha256 検証つき curl ダウンロード」+ jq preinstalled 明示 / commit 3a116d14) | - |

### round 別集計

- Round 1: 3 件 (高 1 / 中 1 / 低 1)
- Round 2: 0 件 (clean → completed)

---

## Set 3: 2026-05-17 (統合レビュー)

- **レビュー種別**: reviewing-construction-integration / code focus
- **使用ツール**: codex (session id: 019e3616-0f53-7830-82bd-68b72a557924)
- **反復回数**: 2
- **結論**: 指摘0件 (last_round_clean → completed)

### 指摘一覧

| # | 重要度 | 内容 | 対応 | バックログ |
|---|--------|------|------|-----------|
| 1 | 中 | Unit 定義状態 `進行中` のままで計画書・履歴と SoT 不整合 | 修正済み (`完了` + `完了日 2026-05-17` に更新 / commit 6b1e97c4) | - |
| 2 | 低 | logical_design に `apt-get` 記述残存 (実装は curl/sha256/sudo install) | 修正済み (依存解決記述を実装と整合 / commit 6b1e97c4) | - |

### round 別集計

- Round 1: 2 件 (中 1 / 低 1)
- Round 2: 0 件 (clean → completed)
