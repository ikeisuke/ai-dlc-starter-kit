# Construction Phase 履歴: Unit 08

## 2026-04-24T15:00:00+09:00

- **フェーズ**: Construction Phase
- **Unit**: 08-milestone-opt-out-setting（Milestone 運用 opt-out 設定の追加）
- **ステップ**: Unit 完了
- **実行内容**: Unit 008 milestone-opt-out-setting 完了。`[rules.milestone].enabled` 設定キーを新設し（boolean、既定 `false`）、Unit 005 / 006 / 007 で本採用した GitHub Milestone 運用を opt-in 方式に切り替え。Unit 005-007 の本体ロジックは触らず、各 Milestone 関連ステップの冒頭にガード分岐のみを追加。

## 修正範囲

- skills/aidlc/config/defaults.toml（正本）+ skills/aidlc-setup/config/defaults.toml（同期コピー）に `[rules.milestone]\nenabled = false` 追加。`bin/check-defaults-sync.sh` で `sync:ok` 確認
- Inception 2 ステップへのガード追加:
  - skills/aidlc/steps/inception/02-preparation.md ステップ 16「Milestone 紐付け」サブセクション直前
  - skills/aidlc/steps/inception/05-completion.md ステップ 1（「### 1. Milestone 作成・Issue 紐付け」見出し直後）
- Operations 2 ステップへのガード追加:
  - skills/aidlc/steps/operations/01-setup.md ステップ 11（「### 11. Milestone 紐付け確認・fallback 判定」見出し直後）
  - skills/aidlc/steps/operations/04-completion.md ステップ 5.5（「### 5.5 Milestone close」見出し直後）
- インデックスファイル補足:
  - skills/aidlc/steps/inception/index.md L33 / L113 / L208 の Milestone 参照に「`[rules.milestone].enabled=true` のみ動作 / 既定 off」を追記
  - skills/aidlc/steps/operations/index.md §2.8 表の `available` 通常行 + `available 以外` 例外行 + 補助契約見出し + 補助契約本文に `enabled` 条件追加
- 公開ドキュメント更新:
  - docs/configuration.md に `### [rules.milestone] — Milestone 運用（v2.4.0 で追加）` 新規セクション + カスタマイズ例 2 種追加
  - 4 guides（issue-management / backlog-management / backlog-registration / glossary）に「既定 off + 明示設定で有効化」前提の 1 行追記
- CHANGELOG.md `[2.4.0]` 節 `### Added` の Operations Phase 追加項目の後に Unit 008 opt-out 設定追加項目を末尾追加（Keep a Changelog 順序維持）
- メタ開発リポ自身: .aidlc/config.toml に `[rules.milestone]\nenabled = true` を明示設定（v2.3.6 試験運用 + v2.4.0 本採用継続のため）

## 設計上の重要決定

- **ガード分岐パターン**: 既存 `gh_status` 分岐と同じ「自然文での明示的スキップ指示 + 単一 bash ブロック（`MILESTONE_ENABLED` 取得 1 行のみ）」を採用。独立 bash ブロックで `if ...; then ... fi` を書くと後続独立ブロックが普通に実行されてしまうため禁止
- **read-config.sh 終了コード扱い**: exit 0（値）/ exit 1（キー不在）/ exit 2（dasel 不在 / project config 不在 / 読取失敗）すべてで `2>/dev/null || echo "false"` フォールバックにより `false` 扱い。後方互換性最優先
- **`gh_status != available` 時 exit 1 契約 + LINK_FAILED 集約判定 exit 1 契約**: いずれも `enabled=true` のときのみ適用。`enabled=false` 時は両契約とも発動しない（自然文で明示）
- **メタ開発リポ自己整合性**: 本 Unit のコミットに `.aidlc/config.toml` の `enabled=true` 設定追加を含めることで、本サイクル後続の Operations Phase 04-completion ステップ 5.5 で v2.4.0 Milestone を close する流れを維持

## 過剰修正回避

- Unit 005 / 006 / 007 の本体ロジック（5 ケース判定 / 冪等補完原則 / awk 抽出 / 手動復旧 3 パターン分岐 / Keep a Changelog 順序）には**一切触らない**
- Inception 05-completion エクスプレスモードセクション 2 はステップ 1 に委譲しているため自動波及（追加編集不要）
- `cycle-label.sh` / `label-cycle-issues.sh` の deprecation 注記は Unit 005 / 007 所有のため対象外
- v2.5.0 以降の opt-out 設定の運用評価・既定 true への変更検討は本サイクル対象外

## codex AI レビュー

- **Plan**: 2 反復で auto_approved 適格達成
  - Round 1: P1×1（ガード分岐が独立 bash ブロック構造でステップ全体スキップが達成されない）/ P2×2（read-config.sh 終了コード説明ズレ + opt-out 動作検証手順欠落）/ P3×1（ファイル数 12 → 15 誤記）
  - Round 2: **No findings**
- **Implementation**: 2 反復で auto_approved 適格達成
  - Round 1: P2×1（operations/index.md L130 の `gh_status = available` 通常行が無条件で「Milestone 紐付け確認・close をすべて実行」と読める）/ P3×1（実装記録の「見出し直後」表現が 02-preparation ステップ 16 と整合しない）
  - Round 2: **No findings**

## サイクル完了状態

全 8 Unit 完了。Issue #597 は本サイクル PR マージ時に Unit 005 / 006 / 007 / 008 の Milestone 関連 4 Unit すべて完了で auto-close 条件成立（Closes キーワード経由）。次は Operations Phase 続行（ステップ 7 リリース準備から再開）。

---
