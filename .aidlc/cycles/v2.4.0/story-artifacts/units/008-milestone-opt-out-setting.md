# Unit: Milestone 運用 opt-out 設定の追加

## 概要

#597 Unit G 相当（追加スコープ）。Unit A-C で「本採用」として実装した GitHub Milestone 運用を、**設定キー `[rules.milestone].enabled`（既定 `false`）による opt-in 方式**に切り替える。Unit A-C の実装本体は維持したまま、各 Milestone 関連処理の冒頭にガード条件を追加する。既定 false により、未設定プロジェクト・既存利用者は Milestone 機能が動作しない（後方互換確保）。

## 含まれるユーザーストーリー

- 追加ストーリー（v2.4.0 Operations Phase 中の振り返りで浮上）: 利用者として、GitHub Milestone 運用を opt-in で選択したい

## 責務（ファイル所有を Unit 005 / 006 / 007 と明確に分離）

本 Unit は **`enabled` 設定キーの追加 + 既存 Milestone ステップへのガード追加** のみを扱う。Unit 005 / 006 / 007 で確立した手順本体（5 ケース判定 / 冪等補完原則 / 手動復旧 3 パターン分岐 / Keep a Changelog 順序）は触らず、ガード分岐のみを追加する。

- `skills/aidlc/config/defaults.toml`: 新規セクション `[rules.milestone]` + `enabled = false` 追加（**排他所有**）
- `skills/aidlc-setup/config/defaults.toml`: 同期コピー（**排他所有**）
- `skills/aidlc/steps/inception/02-preparation.md`: ステップ 16 の Milestone 紐付けブロック冒頭にガード追加（既存処理は変更せず、`if enabled=false then skip` のラッパーのみ）
- `skills/aidlc/steps/inception/05-completion.md`: ステップ 1 の Milestone 作成ブロック冒頭に同様のガード追加
- `skills/aidlc/steps/inception/index.md`: Milestone（v2.4.0以降）参照箇所に「`enabled=true` のみ動作」の補足追加
- `skills/aidlc/steps/operations/01-setup.md`: ステップ 11 冒頭に同ガード追加
- `skills/aidlc/steps/operations/04-completion.md`: ステップ 5.5 冒頭に同ガード追加（**`enabled=false` 時の exit 1 契約は無効化**、つまり `gh_status != available` 時の exit 1 は `enabled=true` のみ適用）
- `skills/aidlc/steps/operations/index.md`: §2.8 補助契約に `enabled` 条件追加
- `docs/configuration.md`: 新規セクション `[rules.milestone]` の設定説明追加
- `skills/aidlc/guides/issue-management.md` / `backlog-management.md` / `backlog-registration.md` / `glossary.md`: 「既定 off + 明示設定で有効化」の前提を追記
- `CHANGELOG.md` `[2.4.0]` 節 `### Added`: Unit G の opt-out 設定追加を追記
- `.aidlc/config.toml`: メタ開発リポジトリ自体に `[rules.milestone].enabled = true` を明示設定（v2.3.6 試験運用 + v2.4.0 本採用継続のため）

## 境界

- Inception/Operations の Milestone 手順本体（5 ケース判定、冪等補完原則、手動復旧 3 パターン分岐、Keep a Changelog 順序）は Unit 005 / 006 / 007 の所有のため触らない
- `cycle-label.sh` / `label-cycle-issues.sh` の deprecation 注記は Unit 005 / 007 の所有
- 旧 cycle:vX.X.X ラベル運用への完全リバート機能は本 Unit 対象外（opt-out 時は単に Milestone 機能が動かないだけで、サイクル管理は CHANGELOG / `.aidlc/cycles/v*/` ディレクトリで行う）
- 翻訳ドキュメントへの波及は本 Unit 対象外
- v2.5.0 以降の opt-out 設定の運用評価・既定 true への変更検討は本サイクル対象外

## 依存関係

### 依存する Unit

- Unit 005: Inception Phase Milestone ステップ実装（完了済み、ガード対象）
- Unit 006: Operations Phase Milestone ステップ実装（完了済み、ガード対象）
- Unit 007: 公開ドキュメント Milestone 周知（完了済み、既定 off 前提を追記）

### 外部依存

- なし（社内ドキュメント + 設定ファイルのみ）

## 非機能要件（NFR）

- **後方互換性【最重要】**: 既存利用者（v2.3.6 以前）は config.toml に `[rules.milestone]` を追加せずに v2.4.0 にアップグレードしても、Milestone 機能が一切動作しない。Operations Phase が止まったり警告メッセージが出たりしてはならない
- **設定の透明性**: `defaults.toml` で `enabled = false` を明示し、利用者が「既定 off」を理解できる
- **メタ開発の継続性**: ai-dlc-starter-kit 本体の `.aidlc/config.toml` には `enabled = true` を明示設定し、Operations Phase 04-completion ステップ 5.5 で v2.4.0 Milestone を close する流れを維持
- **セキュリティ**: 機密情報の混入なし
- **可用性**: ガード条件は `read-config.sh rules.milestone.enabled` の終了コード 1（キー不在）→ 既定 false として扱う（フォールバック堅牢）

## 技術的考慮事項

- ガード条件は各ステップで **bash 単純分岐**（`if [ "$MILESTONE_ENABLED" = "true" ]; then ...; fi`）として実装。複雑な条件式は避ける
- `read-config.sh rules.milestone.enabled` の出力を取得し、`true` 以外（空文字列・`false`・キー不在）はすべて false 扱い
- `defaults.toml` 同期チェック（`bin/check-defaults-sync.sh`）が新規キー追加で正しく動作することを確認
- メタ開発リポジトリの `.aidlc/config.toml` への `[rules.milestone].enabled = true` 設定追加は、本 Unit のコミットに含める

## 関連Issue

- #597（追加対応：Unit G。Unit A は Unit 006、Unit B は Unit 005、Unit C は Unit 007）

## 実装優先度

High（v2.4.0 リリース前必須、Unit 005 / 006 / 007 の本採用化を opt-in 化する破壊的変更回避のため）

## 見積もり

3〜4 時間（11 ファイル編集 + codex AI レビュー反復 + メタ開発リポジトリ設定追加）

---

## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 完了
- **開始日**: 2026-04-24
- **完了日**: 2026-04-24
- **担当**: AI（Claude / codex 協調）
- **エクスプレス適格性**: -
- **適格性理由**: -
