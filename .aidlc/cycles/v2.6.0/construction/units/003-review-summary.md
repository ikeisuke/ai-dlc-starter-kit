# レビューサマリ: Unit 003 marketplace.json への version SoT 一本化

## 基本情報

- **サイクル**: v2.6.0
- **フェーズ**: Construction
- **対象**: Unit 003 marketplace.json への version SoT 一本化

<!-- 以下、AIレビュー完了時に Set が追記される -->

---

## Set 1: 2026-05-09 20:30:00

- **レビュー種別**: 設計レビュー（reviewing-construction-design）
- **使用ツール**: codex
- **反復回数**: 6
- **結論**: 指摘0件で `last_round_clean` 完了（Round 1: 高1/中3/低1 → 全件修正 / Round 2: 中2/低1 → 全件修正 / Round 3: 低1 → 修正 / Round 4: 低1 → 修正 / Round 5: 低1 → 修正 / Round 6: 0件で完了）

### 指摘一覧（Round 1: 5件）

| # | 重要度 | 内容 | 対応 | バックログ |
|---|--------|------|------|-----------|
| R1-1 | 高 | `.aidlc/cycles/v2.6.0/design-artifacts/domain-models/unit_003_marketplace_json_version_sot_domain_model.md`, `.aidlc/cycles/v2.6.0/design-artifacts/logical-designs/unit_003_marketplace_json_version_sot_logical_design.md` - aidlc-migrate fallback で aidlc lib を直接呼ぶ設計はコンテキスト境界をまたぐ逆依存 | 修正済み（domain-model: Unit 境界内記述を「migrate コンテキスト内で完結 / aidlc lib 非依存」に修正、logical-design: Migrate Layer 切替方式を「jq インラインまたは migrate 専用 lib」に変更し、aidlc lib への source を禁止と明記） | - |
| R1-2 | 中 | 同上 - 4 経路集約方針と env-info.sh / Inception 一部が dasel/jq 直接抽出記述で不一致 | 修正済み（logical-design: 選定理由・抽象化の境界・env-info.sh 記述を統一、aidlc 内 4 経路はすべて `read_marketplace_version` 経由に確定） | - |
| R1-3 | 中 | 同上 - read_marketplace_version の grep+sed 最終フォールバック有無が文書内矛盾 | 修正済み（domain-model: MarketplaceManifestRepository 注記、logical-design: 抽出ロジック / NFR / 技術選定 を統一、grep+sed 廃止 / dasel・jq 2 段のみに確定） | - |
| R1-4 | 中 | `.aidlc/cycles/v2.6.0/design-artifacts/logical-designs/unit_003_marketplace_json_version_sot_logical_design.md` - update-version.sh 出力キー変更を「CLI互換維持」と矛盾記述、後方互換性定義不足 | 修正済み（logical-design: bin/update-version.sh セクションに「後方互換性宣言」を追加、影響範囲調査結果と外部公開していない事実、CLI 互換維持、互換キー併記しない理由を明記） | - |
| R1-5 | 低 | 同上 - check-marketplace-version.sh が `gh pr` 依存している記述、不要依存 | 修正済み（logical-design: 依存を git diff + lib/version.sh のみに変更、ユースケース 5 から gh を除去） | - |

### 指摘一覧（Round 2: 3件）

| # | 重要度 | 内容 | 対応 | バックログ |
|---|--------|------|------|-----------|
| R2-1 | 中 | `.aidlc/cycles/v2.6.0/design-artifacts/domain-models/unit_003_marketplace_json_version_sot_domain_model.md` - GATE-3 [Answer] が grep+sed 3 段の旧記述で文書全体方針と矛盾 | 修正済み（domain-model: GATE-3 [Answer] を「dasel/jq の 2 段のみ、両ツール不在時 exit 2 + error:dasel-and-jq-unavailable」に更新） | - |
| R2-2 | 中 | `.aidlc/cycles/v2.6.0/design-artifacts/logical-designs/unit_003_marketplace_json_version_sot_logical_design.md` - ユースケース2 で env-info.sh が dasel/jq/grep+sed 直接抽出する記述残存 | 修正済み（logical-design: ユースケース2 を「env-info.sh -> lib/version.sh::read_marketplace_version 呼び出し」フローに書き換え） | - |
| R2-3 | 低 | 同上 - 技術選定欄に grep/sed（最終フォールバック）が残存 | 修正済み（logical-design: 技術選定の依存ツール記述を更新、grep/sed の JSON 抽出フォールバック用途を削除） | - |

### 指摘一覧（Round 3: 1件）

| # | 重要度 | 内容 | 対応 | バックログ |
|---|--------|------|------|-----------|
| R3-1 | 低 | `.aidlc/cycles/v2.6.0/design-artifacts/logical-designs/unit_003_marketplace_json_version_sot_logical_design.md` - check-marketplace-version 判定基準に「version.txt 編集（過渡期）」残存、PATHS_REGEX と二重化 | 修正済み（logical-design: 末尾 Q/A から `version.txt` 編集条件を削除、Round 3 反映の補足を追記） | - |

### 指摘一覧（Round 4: 1件）

| # | 重要度 | 内容 | 対応 | バックログ |
|---|--------|------|------|-----------|
| R4-1 | 低 | `.aidlc/cycles/v2.6.0/design-artifacts/logical-designs/unit_003_marketplace_json_version_sot_logical_design.md` - read_marketplace_version の exit 2 定義が「I/O error」と「実行環境エラー（I/O + ツール不在）」で混在 | 修正済み（logical-design: 終了コード仕様を表で再定義、exit 2 を「実行環境エラー（I/O 失敗 + dasel/jq 双方不在を含む）」に統一、サブケース判別は stdout エラーメッセージで実施と明記） | - |

### 指摘一覧（Round 5: 1件）

| # | 重要度 | 内容 | 対応 | バックログ |
|---|--------|------|------|-----------|
| R5-1 | 低 | `.aidlc/cycles/v2.6.0/design-artifacts/logical-designs/unit_003_marketplace_json_version_sot_logical_design.md` - コンポーネント詳細 1 行記述（exit 0=ok, 1=key/value missing, 2=I/O error）が後段仕様と二重定義 | 修正済み（logical-design: コンポーネント詳細の 1 行を後段仕様と整合する記述に置換、exit 1=コンテンツエラー / exit 2=実行環境エラーで統一） | - |

### Round 4 新領域判定（Round 4 / Round 5 で同一系統 / 早期 defer ガイド）

```json
{
  "K_old": ["cycle-artifacts"],
  "K_new": ["cycle-artifacts"],
  "K_diff": [],
  "rounds_executed": 6,
  "remarks": "全 round の指摘は cycle-artifacts（design-artifacts/）配下に閉じており新領域指摘なし。Round 3〜5 は同系統（exit code / フォールバック仕様の文書整合）の漸進的修正で、Round 6 で完全に clean に到達。"
}
```

### 設計レビュー早期 defer ガード判定

- Round 3 で件数 1 件（閾値 5 件未満）→ アラート発動なし
- Round 4 で件数 1 件（閾値 3 件未満）→ 千日手予兆警告発動なし
- 新規仮説追加検出: Round 1 の指摘は基底設計の改訂を要求したが、Round 2 以降は既存仮説内の記述整合のみで設計仮説の根本見直しは発生せず（H_new - H_old = []）
- 漸進パターン: 同一ディレクトリ内の漸進拡大なし

---

## Set 2: 2026-05-09 21:30:00

- **レビュー種別**: コードレビュー（reviewing-construction-code）
- **使用ツール**: codex
- **反復回数**: 4
- **結論**: Round 4 で `last_round_clean` 完了（Round 1: 高1/中3/低1 / Round 2: 高1/中2 / Round 3: 高1 / Round 4: 0 件）。OUT_OF_SCOPE 1 件は Issue #680 として defer 化済

### 指摘一覧（Round 1: 5件）

| # | 重要度 | 内容 | 対応 | バックログ |
|---|--------|------|------|-----------|
| R1-1 | 高 | `skills/aidlc-migrate/scripts/migrate-apply-config.sh:62-90` - manifest 由来の path / dest を無検証で cp / rm / mkdir -p / mv しており、細工された manifest によりリポジトリ外ファイルの上書き・削除が可能（パストラバーサル / 任意パス書込） | OUT_OF_SCOPE（理由: Unit 003 の境界外、Intent v2.6.0 「含まれるもの」に migrate のセキュリティ強化は含まれない、v2.0 以前から存在する既存問題、本 Unit は新たに脆弱性を導入していない、修正規模 4〜8 時間で独立 Unit 相当、ユーザー判断で OUT_OF_SCOPE 確定） | #680 |
| R1-2 | 中 | `skills/aidlc-setup/scripts/read-version.sh:41-43` - dasel/jq 両方不在時に exit 1 で確定方針 (exit 2) と不整合 | 修正済み（read-version.sh: ツール不在時 / ファイル不在時を exit 2 に変更、エラーコード契約を read_marketplace_version と整合） | - |
| R1-3 | 中 | `skills/aidlc-setup/scripts/read-version.sh:45` - tr -d '[:space:]' で値中の空白を全削除しフォーマット異常を補正してしまう | 修正済み（read-version.sh: 前後トリムのみに変更、値中の空白は保持） | - |
| R1-4 | 中 | `skills/aidlc/scripts/lib/version.sh:16` - SemVer 正規表現が prerelease を広く許容しすぎ、SemVer 2.0.0 厳密判定になっていない | 修正済み（version.sh `_SEMVER_PATTERN` を SemVer 2.0.0 準拠に書き換え。数値先行 0 禁止 / prerelease identifier dot 構造 / build metadata 対応。動作確認: `01.0.0` `1.0.0-01` `1.2.3-.` `1.2.3-alpha..1` が NG、`1.0.0-0.3.7` `1.0.0+build.123` `1.2.3-alpha+build` が OK） | - |
| R1-5 | 低 | `bin/update-version.sh:84-88` - 対象 JSON パスがカレントディレクトリ基準固定で、リポジトリ外起動時に誤動作 | 修正済み（update-version.sh: `git rev-parse --show-toplevel` でリポジトリルート絶対パスを解決、git 環境外はカレントディレクトリ相対へフォールバック） | - |

### 指摘一覧（Round 2: 3件 / Round 1 #1, #4 の継続 + 新規 #3）

| # | 重要度 | 内容 | 対応 | バックログ |
|---|--------|------|------|-----------|
| R2-1 | 高 | R1-1 と同一（パストラバーサル） | OUT_OF_SCOPE 継続 | #680 |
| R2-2 | 中 | R1-4 と同一（SemVer 厳密化）→ 修正反映確認 | 修正済み（Round 2 で対応） | - |
| R2-3 | 中 | `skills/aidlc-setup/scripts/read-version.sh:50-55` - metadata.version が非空なら成功終了、SemVer 妥当性検証なし | 修正済み（read-version.sh: SemVer 2.0.0 バリデーションを追加、validation 失敗時は exit 1） | - |

### 指摘一覧（Round 3: 1件 / R1-1 継続）

| # | 重要度 | 内容 | 対応 | バックログ |
|---|--------|------|------|-----------|
| R3-1 | 高 | R1-1 と同一（パストラバーサル） | OUT_OF_SCOPE 確定（千日手検出 3 連続発生 → ユーザー判断フローで確定）→ Issue #680 起票（必須ラベル `backlog` `type:defer-from-review` `type:security` `priority:high` 付与確認済） | #680 |

### 指摘一覧（Round 4: 0件）

| # | 重要度 | 内容 | 対応 | バックログ |
|---|--------|------|------|-----------|
| - | - | 指摘なし（last_round_clean 完了） | - | - |

### Round 4 新領域判定

```json
{
  "K_old": ["scripts/lib", "scripts", "bin"],
  "K_new": ["scripts/lib", "scripts", "bin"],
  "K_diff": [],
  "rounds_executed": 4,
  "remarks": "全 round の指摘は scripts/lib（version.sh）/ scripts（read-version.sh）/ bin（update-version.sh）/ migrate（migrate-apply-config.sh - パストラバーサル defer）に閉じており新領域指摘なし。R1-1 が R2-1 / R3-1 で 3 連続発生し千日手検出に該当 → ユーザー判断フローで OUT_OF_SCOPE 確定 → Issue #680 起票で defer 化"
}
```

### スコープ保護確認（OUT_OF_SCOPE 化判定）

- **対象指摘**: R1-1 / R2-1 / R3-1（migrate-apply-config.sh パストラバーサル）
- **Intent v2.6.0「含まれるもの」該当性**: 非該当（migrate のセキュリティ強化は含まれない、version SoT 一本化のみ）
- **判定結果**: `automation_mode` に関わらずユーザー確認は本来不要だが、Issue 起票自体が auto mode で制限されたためユーザーに確認 → ユーザー承認で OUT_OF_SCOPE 確定 + Issue 起票許可
- **記録**: review-summary 末尾に `スコープ保護確認: 非該当（Intent 含まれるもの非該当）+ ユーザー承認による defer 化（Issue #680）`

---

## Set 3: 2026-05-09 22:00:00

- **レビュー種別**: 統合とレビュー（reviewing-construction-integration）
- **使用ツール**: codex review --base main
- **反復回数**: 1
- **結論**: 指摘0件で `1R clean 特例` により完了

### 指摘一覧

指摘0件

### 確認内容

- SoT 移行（marketplace.json への一本化）の整合性
- 関連スクリプト変更（version.sh / env-info.sh / update-version.sh / check-marketplace-version.sh / read-version.sh / migrate-*.sh）の一貫性
- テストスイートの実行結果（test_update_version_no_toml_write.sh / test_check_marketplace_version.sh / test_read_marketplace_version.sh / test_migrate_version_update.sh / test_read_starter_kit_version.sh / test_migrate_detect_hashes.sh の合計 75 件 PASS）
- `version.txt` 系 3 ファイル削除に伴う参照漏れ確認

### 軽微な追加修正（指摘とは別の発見）

`config.toml.template:4` のプレースホルダー文言 `[version.txt の内容]` を `[marketplace.json metadata.version の内容]` に統一（codex の grep ログから検出）。レビュー本体での指摘ではなく、レビュー実行時の周辺情報として捕捉し同 PR 内で修正。
