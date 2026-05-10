# Unit 003 計画: aidlc-feedback の `--web` 強制起動解消（opt-in 化）

## 概要

`/aidlc feedback` のデフォルト経路を `gh issue create --web`（ブラウザ強制起動）から `gh issue create --body-file ...`（直接起票）へ変更する。`[rules.feedback].open_in_browser` 設定または明示的フラグでのみ `--web` を選ぶ opt-in 構造に再設計し、非 TTY / CI 環境では常に直接起票を採用する。優先順位は **TTY 状態 > 設定 > フラグ**（`user_stories.md` ストーリー 3 の真理値表 6 行を SoT）。

## SoT 整合（計画レビュー Round 1 反映）

本 Unit における経路判定の Source of Truth（SoT）は **`user_stories.md` ストーリー 3 の真理値表 6 行**（および優先順位「TTY 状態 > 設定 > フラグ」）に固定する。

- `intent.md §成功基準 #690` には旧表現「**設定 > フラグ > 対話**」が残存するが、これは Inception 初期版の表現であり、user_stories.md ストーリー 3（後続成果物）で精緻化されたものと解釈する
- 実装・テスト・ドキュメントの全層で `user_stories.md` 真理値表 6 行を一次参照とし、`intent.md` の旧表現は本 Unit では同表に従って解釈する
- Operations Phase で `intent.md` 表現の整合性追従が必要かは別途判断（本 Unit のスコープ外）

## 採用案（Issue #690 / ユーザーストーリー 3）

### スコープ確定方針

- 影響範囲は `aidlc-feedback` スキル単体に限定する。他スキル（`/aidlc retrospective` 等）の `gh issue create` 経路は本 Unit の対象外
- ブラウザ起動経路の opt-in 化は patch リリースの非破壊変更とみなし、`open_in_browser = true` で従来挙動を再現可能とする
- 設定読取は Unit 004 で確立した `read-config.sh` 経由統一規約に従う（`bash skills/aidlc/scripts/read-config.sh <key>`、リポジトリルート相対の絶対参照）

### 経路判定ロジックの構造

`feedback.md` の手順 2 を「直接起票（主経路）+ opt-in `--web`（条件付き）」に書き換える。経路判定は以下の論理に従う:

```text
inputs:
  is_tty       = [[ -t 0 ]] が true
  setting      = read-config.sh rules.feedback.open_in_browser  # exit 0 で値（true/false）, exit 1 = 未設定, exit 2 = エラー
  explicit_web = 環境変数 AIDLC_FEEDBACK_WEB が "1" / "true" / "yes" のいずれか（明示フラグの SoT）

decision:
  if NOT is_tty                              → "direct"（警告ログは呼び出し側で出力）
  elif setting == true                       → "web"
  elif setting in {false, "未設定", "エラー（fallback）"} ∧ explicit_web == true
                                             → "web"
  else                                        → "direct"
```

優先順位の文言定義（user_stories.md SoT）: **「TTY 状態 > 設定 > フラグ」**

**`explicit_web` の SoT 確定（計画レビュー Round 1 反映）**: 「明示フラグ」は **環境変数 `AIDLC_FEEDBACK_WEB`** を唯一の入力経路とする。値の真偽は `1` / `true` / `yes`（大小文字無視）を真、それ以外を偽として扱う。これにより `feedback.md`・`resolve-route.sh`・bats テストが同一契約を共有し、真理値表 6 行を機械検証可能にする（論点 3 解消）。

### 真理値表（user_stories.md ストーリー 3 / SoT 再掲）

> 列名を本 Unit の実装インターフェース（`AIDLC_FEEDBACK_WEB`）に揃えた版を以下に記す（計画レビュー Round 2 反映）。`user_stories.md` の原表は表現上「明示フラグ `--web`」のままだが、本 Unit における「明示フラグ」入力経路の SoT は環境変数 `AIDLC_FEEDBACK_WEB`（`1` / `true` / `yes` で真）であり、`--web` は CLI 引数ではなく gh issue create 側に最終的に付与されるオプションを指す。

| 設定 `open_in_browser` | 明示フラグ（`AIDLC_FEEDBACK_WEB`） | TTY 状態 | 採用経路 |
|----------------------|---------------------------------|---------|---------|
| `true` | -              | TTY    | `--web`（ブラウザ） |
| `true` | -              | 非 TTY | 直接起票（**TTY 優先**: 警告ログ出力） |
| `false` / 未設定 | あり        | TTY    | `--web`（ブラウザ） |
| `false` / 未設定 | あり        | 非 TTY | 直接起票（警告ログ出力） |
| `false` / 未設定 | なし        | TTY    | 直接起票（デフォルト） |
| `false` / 未設定 | なし        | 非 TTY | 直接起票（デフォルト） |

### 実装構造（計画段階の主案、設計レビューで確定）

経路判定ロジックを `feedback.md` の AI 手順内 if 文だけで表現すると bats による真理値表網羅検証が困難になる。**計画段階の主案**として、判定ロジックを bash 関数に抽出し、bats でユニットテスト可能とする:

- **新規スクリプト**: `skills/aidlc-feedback/scripts/lib/resolve-route.sh`
  - 関数 `resolve_feedback_route(setting, explicit_web, is_tty) → "web" | "direct"`（**純関数**、出力は採用経路名のみ。stderr 副作用なし）
  - exit code 規約: 0 = 採用経路を stdout に出力、1 = 入力不正
  - **計画レビュー Round 1 反映**: 警告ログ（非 TTY で `setting=true` 強制無効化、設定値型不一致時のフォールバック）は本関数の責務外。呼び出し側（`feedback.md` の実行フロー）が判定結果と入力状態を見て stderr 出力する
- **`feedback.md` 改訂**: 設定読取（`read-config.sh`）→ TTY 判定（`[[ -t 0 ]]`）→ `resolve_feedback_route` 呼び出し → 採用経路に応じた `gh issue create` 実行、というフローに書き換え。**警告ログの出力責務は本層**（純関数 `resolve_feedback_route` の入力状態をもとに、必要時に stderr へ 1 行出力）
- **`SKILL.md` 改訂**: 「優先順位真理値表」と opt-in 手順の概要を追記
- **`config/defaults.toml`**: `[rules.feedback].open_in_browser = false` を追加（デフォルト: 直接起票）
- **CHANGELOG 追記内容の草案作成（実ファイル更新は Operations Phase に集約）**: 本 Unit ではリリースノート文言の草案を計画ファイル末尾「CHANGELOG 草案」セクションに記録するに留め、`CHANGELOG.md` の実ファイル更新は Operations Phase 7.2（CHANGELOG 更新）で他 Unit と合算して反映する。これは `user_stories.md` 共通責務（CHANGELOG 追記は Operations Phase の責務）と整合させる目的（計画レビュー Round 1 反映）

代替案（設計レビューで検討）: 判定ロジックを `feedback.md` の AI 手順だけで表現し、bats テストは判定ロジックを抽出した小規模なテスト用シェル関数に絞る方針。トレードオフ: 主案は実装が増えるが真理値表 6 行のテストが直接的、代替案は実装は小さいが AI 手順の解釈ブレのリスクが残る。

## 完了条件チェックリスト

### Unit 003 受け入れ基準（user_stories.md ストーリー 3 より）

#### 正常系

- [x] `/aidlc feedback` のデフォルト経路が直接起票（ブラウザ非起動）に変更され、ブラウザが自動起動しない
- [x] `[rules.feedback].open_in_browser` 設定値、明示フラグ、TTY 状態の組合せに対する経路選択が真理値表 6 行に従って一意に決まる（bats で網羅検証）
- [x] 起票内容のユーザー承認フロー（feedback.md 手順 1 のヒアリング）が引き続き機能する（事前確認なしの直接起票はしない）
- [x] `skills/aidlc-feedback/steps/feedback.md` および `SKILL.md` に変更内容と opt-in 手順、優先順位真理値表が記載されている（`CHANGELOG.md` の実ファイル更新は Operations Phase 7.2 で実施し、本 Unit では計画ファイル末尾の「CHANGELOG 草案」セクションに文言案を残す）

#### 異常系

- [x] `open_in_browser` の設定値が型不一致（数値・配列等）または不正値の場合、警告ログを stderr に出力したうえで「未設定」相当（直接起票）にフォールバックする
- [x] `gh issue create` が失敗した場合、stderr にエラー内容（コマンドと exit code）を出力し非 0 終了する。既存の対話再試行フローがあれば維持
- [x] `.aidlc/config.toml` 自体が壊れている場合、`read-config.sh` の exit 2 で警告 + デフォルト挙動継続（直接起票）

#### テスト

- [x] 上記真理値表の全 6 行を bats で網羅検証する（`tests/feedback-route-resolution.bats`（仮）)

### Unit 定義「責務」セクション

- [x] `skills/aidlc-feedback/steps/feedback.md` の手順を「直接起票を主経路、`--web` を opt-in」に書き換える
- [x] `[rules.feedback].open_in_browser` 設定キーの追加と、優先順位 **TTY 状態 > 設定 > フラグ** の明文化
- [x] 非 TTY 判定（`[[ -t 0 ]]`）による CI 安全動作の組込み
- [x] 起票内容のユーザー承認フロー（feedback.md 手順 1 のヒアリング）の維持

### Construction Phase 共通

- [x] 計画レビュー（reviewing-construction-plan）: 指摘 0 件 or 全 resolve / defer
- [x] 設計レビュー（reviewing-construction-design）: 同上
- [x] コードレビュー（reviewing-construction-code）: 同上
- [x] 統合レビュー（reviewing-construction-integration）: 同上
- [x] markdownlint 実行（`bash skills/aidlc/scripts/run-markdownlint.sh v2.6.1`）でエラー 0 件
- [x] shellcheck 実行（新規 `resolve-route.sh` 対象）でエラー 0 件
- [x] 設計と実装の整合性チェック

### 観測可能な判定指標（機械判定可能）

- [x] **デフォルト経路チェック**: `feedback.md` 内に `gh issue create --web` の無条件呼び出しが残っていない（grep で 0 件、opt-in 経路の条件分岐内のみ許容）
- [x] **真理値表 bats テスト green**: `tests/feedback-route-resolution.bats`（仮）の全 6 ケースが pass
- [x] **既存 bats テスト green**: 既存の feedback 系 bats（`feedback-mode-*` / `feedback-cap-by-mode.bats`）が回帰なしで pass
- [x] **設定キー存在チェック**: `config/defaults.toml` に `[rules.feedback].open_in_browser = false` が追加されている
- [x] **ドキュメント整合**: `SKILL.md` に真理値表と opt-in 手順が記載されている（`CHANGELOG.md` 実ファイル更新は Operations Phase 7.2 担当）
- [x] **CHANGELOG 草案存在チェック**: `unit-003-plan.md` 末尾に「CHANGELOG 草案」セクションが存在し、Operations Phase 7.2 で参照可能な文言案が記載されている
- [x] **明示フラグ契約チェック**: `feedback.md` / `resolve-route.sh` / bats テストの 3 層で「明示フラグの SoT は環境変数 `AIDLC_FEEDBACK_WEB`（`1`/`true`/`yes` で真）」が同一契約として記述されている（grep / 目視）

## スコープ

### 含まれるもの

- `skills/aidlc-feedback/steps/feedback.md` の手順 2 改訂（直接起票主経路化 + opt-in `--web`）
- 新規 `skills/aidlc-feedback/scripts/lib/resolve-route.sh`（または同等位置の判定ヘルパー、設計レビューで確定）
- `skills/aidlc/config/defaults.toml` への `[rules.feedback].open_in_browser = false` 追加
- `skills/aidlc-feedback/SKILL.md` への変更内容・優先順位真理値表・opt-in 手順の追記
- `CHANGELOG.md` 追記文言の **草案作成**（本計画ファイル末尾「CHANGELOG 草案」セクションに記載。実ファイル更新は Operations Phase 7.2）
- 真理値表 6 行を網羅する bats テスト追加（`tests/feedback-route-resolution.bats`（仮））
- `read-config.sh` 経由統一規約への準拠（Unit 004 規約）

### 含まれないもの

- `.github/ISSUE_TEMPLATE/feedback.yml`（テンプレート構造）の変更
- 他スキル（`/aidlc retrospective` 等）の `gh issue create` 経路への波及修正
- `aidlc-feedback` スキルが扱うラベル付与・タイトル整形ロジックの変更
- `[rules.feedback].open_in_browser` の user-global / project-local 階層マージ機能の新規追加（`read-config.sh` の既存マージ機構をそのまま利用）
- フィードバック内容の自動分類・整形機能（既存ヒアリングフロー維持）
- bats テスト実行環境のセットアップ手順変更（既存環境を前提）

## 関連ファイル（修正対象）

| ファイル | 変更内容 |
|---------|---------|
| `skills/aidlc-feedback/steps/feedback.md` | 手順 2 を「直接起票主経路 + opt-in `--web`」に書き換え。`open_in_browser` 読取（`read-config.sh` 経由）+ TTY 判定 + 経路判定の明文化 |
| `skills/aidlc-feedback/SKILL.md` | 真理値表・優先順位・opt-in 手順の追記 |
| `skills/aidlc-feedback/scripts/lib/resolve-route.sh`（新規） | 経路判定純関数 `resolve_feedback_route(setting, explicit_web, is_tty)` のみ（stderr 副作用なし。ログ出力責務は呼び出し側 `feedback.md` 実行フロー） |
| `skills/aidlc/config/defaults.toml` | `[rules.feedback].open_in_browser = false` 追加 |
| `tests/feedback-route-resolution.bats`（新規・仮） | 真理値表 6 行を網羅するテスト |
| `.aidlc/cycles/v2.6.1/plans/unit-003-plan.md` | 末尾「CHANGELOG 草案」セクションへ文言案を追記（`CHANGELOG.md` 実ファイル更新は Operations Phase 7.2 担当） |

## 設計フェーズ（Phase 1）の対象

`depth_level=standard` のため Phase 1（設計）を実施する。設計の論点:

- **論点 1**: 判定ロジックの抽出先（`skills/aidlc-feedback/scripts/lib/resolve-route.sh` 新設 vs `feedback.md` 内 inline）
- **論点 2**: bats テストの命名・配置（`tests/feedback-route-resolution.bats` 直下 vs `tests/feedback/` サブディレクトリ）
- **論点 3（計画段階で確定済 / 計画レビュー Round 1 反映）**: `--web` 経路選択の「明示フラグ」の SoT は **環境変数 `AIDLC_FEEDBACK_WEB`**（`1` / `true` / `yes` で真）に固定。設計フェーズでは値の正規化規則（前後空白・大文字小文字）の細部のみ確定する
- **論点 4**: 警告ログの文言と粒度（非 TTY での `open_in_browser=true` 強制無効化、設定値型不一致時のフォールバック）。**警告ログの出力責務は呼び出し側（`feedback.md` の実行フロー）**であり、`resolve_feedback_route` 純関数の責務外であることを設計フェーズで再確認する（計画レビュー Round 1 反映）

設計フェーズで上記を確定し、`unit_003_aidlc_feedback_web_opt_in_domain_model.md` / `unit_003_aidlc_feedback_web_opt_in_logical_design.md` に記録する。

## 実装フェーズ（Phase 2）の対象

- 6 ファイルの編集（feedback.md / SKILL.md / resolve-route.sh / defaults.toml / unit-003-plan.md「CHANGELOG 草案」追記 / bats）
- shellcheck 実行（新規 `resolve-route.sh` 対象）
- markdownlint 実行（`bash skills/aidlc/scripts/run-markdownlint.sh v2.6.1`）
- 真理値表 6 行 bats テストの実行
- 既存 feedback 系 bats の回帰確認
- **明示フラグ契約の 3 層整合確認**: `feedback.md` / `resolve-route.sh` / bats テストで `AIDLC_FEEDBACK_WEB` の SoT が一致していることを目視 + grep で確認

## リスク

| リスク | 影響度 | 対応 |
|-------|-------|------|
| AI エージェントが手順書改訂後も従来の `--web` 必須記述を「学習済み」として再生成する | 中 | 真理値表とフロー図を `feedback.md` / `SKILL.md` に明示し、AI への明確なアンカーを残す。CHANGELOG にも変更点を記載 |
| 真理値表 6 行のうち、AI 判断由来の「明示フラグ」を bats で表現できない | 中 | 「明示フラグ」を環境変数 / 引数で表現し、`resolve_feedback_route` の純関数引数に落とすことで bats で扱える形にする（設計レビュー論点 3） |
| `open_in_browser=true` 設定済みのユーザーが non-TTY 経由で実行した際、警告ログが煩雑 | 低 | 警告は 1 回のみ（`stderr` に 1 行）。非 TTY フォールバックは仕様通り。CHANGELOG で挙動を案内 |
| 既存 feedback bats（`feedback-cap-by-mode` 等）が `open_in_browser` 追加で読取エラーを起こす | 低 | 新規キーは optional（未設定時は exit 1 でデフォルト false にフォールバック）。既存テストの fixture は変更なしで済む想定（設計レビューで確認） |
| `gh issue create --body-file <path>` 経路で本文の改行・特殊文字エスケープ問題 | 中 | 既存 `gh issue create --body-file` パターンは `tests/retrospective-issue-create.bats` 等で利用実績あり。Write ツール経由の一時ファイル作成 + 削除フローを feedback.md にも踏襲 |
| Issue #690 の "Submit ボタン押下" UX を期待していたユーザーへの非互換 | 中 | `open_in_browser = true` で完全に従来挙動を再現可能。CHANGELOG / SKILL.md で opt-in 手順を明示 |

## 見積もり

0.5 day（feedback.md / SKILL.md 改訂 + 設定キー追加 + resolve-route.sh 新規 + bats テスト 6 ケース + CHANGELOG 草案追記 + 既存 bats 回帰確認）

---

## CHANGELOG 草案（Operations Phase 7.2 で `CHANGELOG.md` 反映用）

> 本 Unit では `CHANGELOG.md` の実ファイル更新は行わない。以下の文言案を Operations Phase 7.2（CHANGELOG 更新）で他 Unit の追記項目と合算して反映する（計画レビュー Round 1 反映）。

### v2.6.1 セクションへの追記候補

#### Changed（patch / 非破壊扱い、デフォルト挙動変更）

- `aidlc-feedback`: `/aidlc feedback` の Issue 起票デフォルト経路をブラウザ自動起動（`gh issue create --web`）から直接起票（`gh issue create --body-file ...`）に変更しました（#690 / Unit 003）。
  - 従来挙動を維持したい場合は、`.aidlc/config.toml` の `[rules.feedback]` セクションに `open_in_browser = true` を設定するか、環境変数 `AIDLC_FEEDBACK_WEB=1` を付けて実行してください
  - 経路判定の優先順位: **TTY 状態 > 設定 > フラグ**（非 TTY / CI 環境では設定・フラグに関わらず常に直接起票）
  - 6 行の真理値表は `skills/aidlc-feedback/SKILL.md` 参照

#### Added

- `[rules.feedback].open_in_browser`（boolean、デフォルト `false`）: feedback Issue 起票時にブラウザを自動起動するか
- 環境変数 `AIDLC_FEEDBACK_WEB`（`1` / `true` / `yes` で真）: feedback コマンド単発でブラウザ経路を選択する明示フラグ
