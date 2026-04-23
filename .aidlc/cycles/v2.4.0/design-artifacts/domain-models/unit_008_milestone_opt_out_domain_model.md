# ドメインモデル: Unit 008 Milestone 運用 opt-out 設定の追加

## 概要

Unit 005 / 006 / 007 で「本採用」として実装した GitHub Milestone 運用を、`[rules.github].milestone_enabled`（boolean、既定 `false`）による **opt-in 方式**に切り替える。Unit A-C の実装本体は維持したまま、各 Milestone 関連処理の冒頭にガード分岐を追加し、未設定プロジェクト・既存利用者では Milestone 機能が一切動作しない状態（後方互換確保）を実現する。本 Unit はガード追加 + 設定キー新設 + 既定 false 表明 + メタ開発リポでの明示有効化を中心に定義する。

**重要**: このドメインモデル設計では**コードは書かず**、責務の定義のみを行う。実装は Phase 2 で行う。

## ドメイン責務

### Unit 008: Milestone 運用 opt-out 設定の追加

- **責務**: `[rules.github].milestone_enabled` 設定キーを新設し、Unit 005 / 006 / 007 で実装済みの Milestone 関連ステップに **opt-in ガード**を追加することで、利用者が明示的に有効化しない限り Milestone 機能が動作しない状態（後方互換確保）を実現する
- **入力**:
  - Unit 005 完了状態の Inception Phase ステップ（`02-preparation.md` ステップ 16 / `05-completion.md` ステップ 1 / `index.md`）
  - Unit 006 完了状態の Operations Phase ステップ（`01-setup.md` ステップ 11 / `04-completion.md` ステップ 5.5 / `index.md` §2.8）
  - Unit 007 完了状態の公開ドキュメント（`issue-management.md` / `backlog-management.md` / `backlog-registration.md` / `glossary.md`）+ `CHANGELOG.md` `[2.4.0]` 節
  - 既存の `defaults.toml`（`skills/aidlc/config/` 正本 + `skills/aidlc-setup/config/` コピー）
  - `read-config.sh`（4 階層マージ + canonical/legacy エイリアス対応の既存実装）
  - メタ開発リポジトリの `.aidlc/config.toml`
- **出力**:
  - `[rules.github]\nmilestone_enabled = false` を追加した defaults.toml × 2（同期）
  - opt-in ガードを冒頭に追加した Inception 2 ステップ + Operations 2 ステップ
  - `milestone_enabled=true` のみ動作する旨の補足を追加した Inception index / Operations index §2.8
  - `[rules.github]` セクションを追加した `docs/configuration.md`
  - 「既定 off + 明示設定で有効化」を追記した 4 guides
  - `### Added` に opt-out 設定追加を追記した `CHANGELOG.md` `[2.4.0]` 節
  - `[rules.github]\nmilestone_enabled = true` を明示設定したメタ開発リポ `.aidlc/config.toml`

## ファイル所有関係

| ファイル | Unit 008 所有範囲 | 他 Unit との関係 |
|---------|----------------|---------------|
| `skills/aidlc/config/defaults.toml`（正本） | `[rules.github]\nmilestone_enabled = false` 追加（**排他所有**） | 既存セクション・キーには触らない |
| `skills/aidlc-setup/config/defaults.toml`（同期コピー） | 正本と同じ追記（**排他所有**） | 同上、`bin/check-defaults-sync.sh` で同期検証 |
| `skills/aidlc/steps/inception/02-preparation.md` | ステップ 16 の Milestone 紐付けブロック冒頭にガード追加（**排他所有のガード差分**） | Unit 005 が実装した本体ロジックは触らない |
| `skills/aidlc/steps/inception/05-completion.md` | ステップ 1 の Milestone 作成ブロック冒頭にガード追加（**排他所有のガード差分**） | Unit 005 が実装した 1-1 / 1-2 / 5 ケース判定 / awk 抽出は触らない |
| `skills/aidlc/steps/inception/index.md` | Milestone（v2.4.0以降）参照箇所の補足追加（**排他所有のメタ差分**） | Unit 005 / 007 範囲外部分は触らない |
| `skills/aidlc/steps/operations/01-setup.md` | ステップ 11 冒頭にガード追加（**排他所有のガード差分**） | Unit 006 が実装した 11-1 / 11-2 / 11-3 / LINK_FAILED 集約判定は触らない |
| `skills/aidlc/steps/operations/04-completion.md` | ステップ 5.5 冒頭にガード追加（**排他所有のガード差分**） | Unit 006 が実装した 5 ケース判定 / `gh_status != available` 時 exit 1 契約は **`milestone_enabled=false` 時のみ無効化** |
| `skills/aidlc/steps/operations/index.md` §2.8 | gh_status 分岐表 + 補助契約の `enabled` 条件追加（**排他所有のメタ差分**） | Unit 006 / 007 範囲外部分は触らない |
| `docs/configuration.md` | 新規セクション `[rules.github]` + カスタマイズ例追加（**排他所有**） | 他セクションは触らない |
| `skills/aidlc/guides/*.md` × 4 | 「既定 off + 明示設定で有効化」前提の 1 行追記（**排他所有のメタ差分**） | Unit 007 が実装した本体記述は触らない |
| `CHANGELOG.md` `[2.4.0]` 節 `### Added` | Unit 008 の opt-out 設定追加項目を末尾追加（**排他所有**） | `### Changed` / `### Deprecated` / `### Removed` および他項目は触らない |
| `.aidlc/config.toml`（メタ開発リポ） | `[rules.github]\nmilestone_enabled = true` 明示設定追加（**排他所有**） | 他キーは触らない |
| `cycle-label.sh` / `label-cycle-issues.sh` の deprecation 注記 | **対象外**（Unit 005 / 007 所有、本 Unit のスコープ外） | Unit 005 / 007 完了済み |
| Unit 005 / 006 が実装した本体 bash ロジック（5 ケース判定 / 冪等補完原則 / awk 抽出 / 手動復旧 3 パターン / Keep a Changelog 順序） | **触らない** | 本 Unit は **ガード差分のみ**を上乗せする |

## 責任分離（Unit 005 / 006 / 007 / 008）

| 責務 | 担当 Unit | 出力先 |
|------|---------|-------|
| Inception Phase Markdown ステップに Milestone 作成・関連 Issue 紐付けを実装 | Unit 005 | `skills/aidlc/steps/inception/**` + `cycle-label.sh` / `label-cycle-issues.sh` の DEPRECATED 注記 |
| Operations Phase Markdown ステップに Milestone close + 紐付け確認 + fallback 作成を実装 | Unit 006 | `skills/aidlc/steps/operations/**` + `index.md` §2.8 補助契約 |
| 公開ドキュメントの Milestone 周知書き換え + CHANGELOG `#597` 節整備（Added / Changed / Deprecated / Removed の Keep a Changelog 順序） | Unit 007 | guides 4 ファイル + CHANGELOG |
| **Milestone 運用の opt-in 化（既定 off）+ ガード追加 + メタ開発リポでの明示有効化** | **Unit 008** | defaults.toml × 2 + 4 ステップファイル冒頭ガード + 2 index 補足 + docs/configuration.md + 4 guides 1 行追記 + CHANGELOG `### Added` 追記 + メタ開発 `.aidlc/config.toml` |

責任分離の根拠:

- **本体ロジックとガード分岐の分離**: Unit 005 / 006 が実装した 5 ケース判定 / 冪等補完原則などの本体ロジックは「Milestone を使う場合の正しい動作」を表す。これをガード分岐で包むのが Unit 008 の責務であり、本体ロジックには触らない
- **設定キー新設の責務独立性**: `[rules.github]` は新規セクション。既存 `[rules.git]` / `[rules.cycle]` などの編集権限とは独立しており、Unit 008 が排他所有する
- **メタ開発リポ設定追加の責務範囲**: 本 Unit のコミットに `.aidlc/config.toml` の `milestone_enabled=true` 追加を含めることで、本 Unit 完了直後の Operations Phase 04-completion ステップ 5.5 で v2.4.0 Milestone を close する流れを維持できる（自己整合性確保）

## 後方互換性原則【最重要】

本 Unit の最重要 NFR は **後方互換性の堅牢確保**である:

1. **既定 false 表明**: `defaults.toml` に明示的に `milestone_enabled = false` を書くことで、`read-config.sh` 終了コード 1（キー不在）で偶発的に有効化される事故を防ぐ
2. **環境異常時のフォールバック**: `read-config.sh` 終了コード 2（dasel 未インストール / project config 不在）でもガード側で `false` 扱いとし、defaults.toml 配布前のリポジトリ（v2.3.6 以前のチェックアウト + v2.4.0 ステップ実行）でも安全に動作させる
3. **既存利用者ゼロ影響**: v2.3.6 以前から v2.4.0 にアップグレードする利用者は config 編集なしで Milestone 機能が動作せず、Operations Phase が止まったり警告メッセージが出たりしない
4. **`exit 1` 契約の opt-out 対応**: Unit 006 で実装した `gh_status != available` 時 exit 1 契約および `LINK_FAILED` 集約判定 exit 1 契約は、`milestone_enabled=false` 時には**発動しない**（opt-out 利用者は Milestone close を要求されないため）

**根拠**: Unit 005 / 006 / 007 で本採用した Milestone 運用は、既定で全利用者に強制適用すると以下の問題が起きる:

- Operations Phase で `gh_status != available` 時 exit 1 → CI 環境や gh 未認証環境でサイクル完了不可
- Inception Phase で関連 Issue が GitHub 側に存在しない場合の挙動が不透明
- 既存利用者への破壊的変更となるため、v2.4.0 アップグレード時に互換性確認が必要

opt-in 方式（既定 false）に切り替えることで、これらすべてを「明示有効化した利用者のみの責任範囲」に閉じ込められる。

## ガード分岐契約

本 Unit が追加するガード分岐は **既存の `gh_status` 分岐パターン**（自然文での明示的スキップ指示 + 参考 bash スニペット）を踏襲する。`gh_status` 判定は「`gh_status` を参照する。`gh_status` が `available` 以外の場合: スキップ。`available` の場合、以下の手順を実行」という自然文で AI / 人間が解釈する仕組みになっており、Unit 008 の Milestone opt-in ガードもこれと**完全に同じ自然文パターン**で記述する。

**設計上の禁止事項**: ガード分岐を独立した bash コードブロックとして `if [ "$MILESTONE_ENABLED" != "true" ]; then ...; fi` の形で書き、後続 bash ブロックを別ブロックとして並べる構造は **禁止**。理由: `if` ブロック内で `exit 0` しない限り後続 bash は普通に AI / シェルから読まれて実行されてしまうため、ステップ全体スキップが達成されない（codex review round 1 P1 指摘）。

**統一ガード記述（4 箇所共通テンプレート）**:

各ステップは以下の自然文記述を採用する:

```
**Milestone 機能 opt-in ガード（v2.4.0 以降、Unit 008 / #597 Unit G）**:

`MILESTONE_ENABLED` を判定する:

(bash コードブロック)
MILESTONE_ENABLED=$(scripts/read-config.sh rules.github.milestone_enabled 2>/dev/null || echo "false")
(bash コードブロック終端)

- `MILESTONE_ENABLED` が `true` 以外（既定）の場合:
    メッセージ `milestone:disabled:skip:step=<step-id>:reason=opt-out` を出力し、
    **本ステップの Milestone 関連処理をすべてスキップ** して次のステップへ進む。
    後続の `gh_status` 判定および Milestone 関連 bash 群は **一切実行しない**
- `MILESTONE_ENABLED` が `true` の場合: 以下の `gh_status` 判定および Milestone 関連処理を実行する
```

| ステップ | ガード位置 | `milestone_enabled=false` 時の動作 | `milestone_enabled=true` 時の動作 |
|---------|----------|------------------------|----------------------|
| Inception 02-preparation ステップ 16 | Milestone 紐付けブロック冒頭（`gh_status` 判定の前） | `milestone:disabled:skip:step=02-preparation-step16:reason=opt-out` 出力 + 本ステップ範囲をスキップ | 既存処理（`gh_status` 判定 + 先行紐付け） |
| Inception 05-completion ステップ 1 | 「### 1. Milestone 作成・Issue 紐付け」見出し直後 | `milestone:disabled:skip:step=05-completion-step1:reason=opt-out` 出力 + 本ステップ範囲をスキップ | 既存処理（1-1 確認・作成 + 1-2 一括紐付け） |
| Operations 01-setup ステップ 11 | 「### 11. Milestone 紐付け確認・fallback 判定」見出し直後 | `milestone:disabled:skip:step=01-setup-step11:reason=opt-out` 出力 + 本ステップ範囲をスキップ（**LINK_FAILED 集約判定 exit 1 も不発動**） | 既存処理（11-1 / 11-2 / 11-3 + 末尾集約判定） |
| Operations 04-completion ステップ 5.5 | 「### 5.5 Milestone close」見出し直後 | `milestone:disabled:skip:step=04-completion-step5.5:reason=opt-out` 出力 + 本ステップ範囲をスキップ（**`gh_status != available` 時 exit 1 も不発動**） | 既存処理（`gh_status != available` 時 exit 1 + 5 ケース判定） |

`enabled` の比較は **`!= "true"` （厳密一致）** を使用する。`true`/`True`/`TRUE` の表記揺れは defaults.toml + project config + read-config.sh で正規化されるため、ガード側は文字列 `"true"` のみを許容することで誤動作を防ぐ。

## read-config.sh 終了コードの扱い契約

`read-config.sh` の実装（`skills/aidlc/scripts/read-config.sh`）に基づき、以下のように扱う。**`PROJECT_CONFIG_FILE` 不在は致命的で exit 2 を返す**（read-config.sh L106-L110）一方、`DEFAULTS_CONFIG_FILE` 不在は警告のみ表示して継続する（L112-L115）ことに注意:

| 終了コード | read-config.sh 出力 | 状況 | ガード判定 |
|----------|-------------------|------|----------|
| 0 | `true` | 明示有効化 | Milestone 処理を実行 |
| 0 | `false` | 明示無効化 | スキップ |
| 0 | その他（`yes` 等） | 不正値 | スキップ（`!= "true"` 厳密一致判定） |
| 1 | （何も出力しない） | キー不在（defaults.toml にも project にも無い） | スキップ（`echo "false"` フォールバック → 既定 false） |
| 2 | （stderr に診断メッセージ） | dasel 未インストール、または `PROJECT_CONFIG_FILE` 不在、または読取失敗 | スキップ（`2>/dev/null || echo "false"` フォールバック → 既定 false、後方互換最優先） |

**設計判断の根拠**: 終了コード 2 をエラー扱いせずスキップに倒すのは、ステップファイル単独テスト時（メタ開発リポ以外でのテスト等）にも Milestone 機能を強制起動しないため。defaults.toml 不在は read-config.sh が exit 0 で正常返却するため（project config に値があれば）、defaults.toml フォールバック経路は exit 1 ではなく「project config キー不在 + defaults.toml キー不在」のときに発動することを正確に反映する。後方互換性【最重要】を優先する。

## CHANGELOG セクション追加契約

`[2.4.0]` 節 `### Added` の末尾に opt-out 設定追加項目を 1 件追加する。Keep a Changelog 順序（Added → Changed → Deprecated → Removed）は Unit 007 で確立済みのため、本 Unit は順序を維持しつつ `### Added` 内に項目追加するのみ。`### Changed` / `### Deprecated` / `### Removed` には手を加えない。

**根拠**: opt-out 設定は新機能（`[rules.github]` 設定キーの新設）であり、既存運用方針の変更（`### Changed`）でも非推奨化（`### Deprecated`）でもない。Unit 005 / 006 と同じ `### Added` 配置とすることで、Milestone 関連項目が `### Added` にまとまり、利用者の認知負荷を下げる。

## メタ開発リポ自己整合性契約

本 Unit のコミットに `.aidlc/config.toml` の `[rules.github]\nmilestone_enabled = true` 設定追加を**必ず含める**。これにより:

1. 本 Unit 完了直後の Operations Phase 04-completion ステップ 5.5 で v2.4.0 Milestone を close する流れを維持できる
2. v2.3.6 試験運用 + v2.4.0 本採用継続の継続性が確保される
3. メタ開発リポでの「Milestone 運用」「opt-in ガード機能」の二重テストが成立する（Milestone 機能が動作しつつ、opt-in ガード自体も動作する）

**根拠**: メタ開発リポは ai-dlc-starter-kit の機能をドッグフード的に利用する立場のため、Milestone 機能を引き続き使う必要がある。一方で配布側のデフォルトは「未設定では動かない」とすべきであるため、メタ開発リポで明示的に `milestone_enabled=true` を書くことで両立させる。

## 過剰修正回避原則

Unit 定義の責務記述は予防的に網羅された候補リストである。Plan 段階の実態調査で以下を確認した結果、過剰修正は発生しない:

- Inception 05-completion のエクスプレスモードセクション 2 は本ステップ 1 に委譲しているため、ガードは自動波及する（追加編集不要）
- 4 guides の Milestone 関連箇所は Unit 007 で既に整備済みのため、1 行追記（「既定 off + 明示設定で有効化」）のみで足りる
- `cycle-label.sh` / `label-cycle-issues.sh` の deprecation 注記は Unit 005 / 007 所有のため触らない
- v2.5.0 以降の opt-out 設定の運用評価・既定 true への変更検討は本サイクル対象外

**根拠**: Unit 008 は「ガードと設定キーの追加」に責務を限定し、本体ロジック / ドキュメント本体 / 過去 Unit 所有範囲には侵入しない。これにより Unit 完了の独立性と最小編集原則を確保する。

## ユビキタス言語

- **opt-in 方式**: 利用者が明示的に有効化しない限り機能が動作しない方式。既定 false。本 Unit が Unit 005 / 006 / 007 の本採用方針を opt-in 化する
- **opt-in ガード**: 各 Milestone 関連ステップの冒頭に配置する `MILESTONE_ENABLED != "true"` 判定。`milestone_enabled=true` のときのみ本体処理を実行する分岐
- **後方互換性堅牢確保**: defaults.toml 不在 / dasel 不在 / 設定読み取り失敗のいずれの異常状態でも `false` 扱いとし、既存利用者の v2.4.0 アップグレードでゼロ影響を保証する原則
- **本体ロジック非干渉**: Unit 005 / 006 が実装した 5 ケース判定 / 冪等補完原則 / awk 抽出 / LINK_FAILED 集約判定 / `gh_status != available` 時 exit 1 契約には一切手を入れず、ガード分岐で外側を包む方針
- **メタ開発リポ自己整合性**: 配布側のデフォルトは false としつつ、メタ開発リポ自身は明示的に `milestone_enabled=true` で Milestone 運用を継続する両立構造

## 不明点と質問

なし（Plan 段階で defaults.toml 同期 / read-config.sh 終了コードの扱い / ガード分岐の統一契約 / メタ開発リポ自己整合性 / 過剰修正回避を確定済み）。
