# Fixture: Operations §1 振り返り対話ガード（mirror モード / auto mode）

## 目的

Unit 001（#647）で導入した「振り返り対話強制ガード」が予防すべき具体パターンを正常 / アンチの両側で例示し、ガード文言の予防効果を fixture として記録する。

本 fixture は cycle-artifacts（`.aidlc/cycles/v2.5.3/construction/fixtures/`）配下に配置され、サイクル完結性を維持する（`skills/aidlc/**` 配下には置かない）。

## 想定環境

- `feedback_mode = "mirror"`
- `automation_mode = "semi_auto"`
- AI エージェント: Claude Code（Opus 系 / auto mode 有効）
- jailrun #70 / PR #71 と同型シナリオ

## 関連ガード文言

| Layer | ファイル | 該当箇所 |
|-------|---------|---------|
| Layer 1: 規範（SoT） | `skills/aidlc/SKILL.md` | 「AskUserQuestion 使用ルール」テーブル「ユーザー選択（振り返り内容の決定）」行 + auto mode 適用外補足 |
| Layer 2: 手順 | `skills/aidlc/steps/operations/04-completion.md` | §1.0 直後「`silent` でも KPT 判断は対話必須」補足 / §1.0.5 対話必須ガード節 / §1.5 Step 4 直前 AskUserQuestion + `retrospective_dialog_token_record_response` 呼出記述 |
| Layer 3: 実行時ガード | `skills/aidlc/scripts/lib/retrospective-issue.sh` | `retrospective_dialog_token_record_response` 関数 / `retrospective_dialog_token_verify` 関数 / `retrospective_issue_create` 内の verify 呼出 |
| Layer 4: 検証例（本 fixture） | `.aidlc/cycles/v2.5.3/construction/fixtures/operations-mirror-autodialog.md` | 本ファイル |

## 正常パターン例（対話を経た振り返り起票）

### 進行例

| ステップ | アクター | アクション | ガード文言の予防ポイント |
|---------|---------|-----------|------------------------|
| 1 | AI agent | §1.0.5 対話必須ガード節を読み、auto mode でも対話必須であることを認識 | §1.0.5 冒頭の「auto mode に関わらず必ずユーザー対話を経て進める」明記 |
| 2 | AI agent → ユーザー | AskUserQuestion: 「Keep 1 件目: `v2.5.2 Inception Phase が 5R 内で完了` を Issue に含めますか？」 | §1.0.5 必須事項「KPT 各観点について 1 項目ずつ AskUserQuestion で確認」 |
| 3 | ユーザー → AI agent | 「含める」 | - |
| 4 | AI agent → ユーザー | AskUserQuestion: 「Problem 1 件目の主因切り分けは？（プロダクト固有 / AI-DLC Starter Kit 固有 / 両方に責任）」 | §1.0.5 必須事項「主因切り分けについて AskUserQuestion で確認」 |
| 5 | ユーザー → AI agent | 「両方に責任」 | - |
| 6 | AI agent → ユーザー | AskUserQuestion: 「格納先は？（マージ前 / マージ後 / 横断改善）」 | §1.0.5 必須事項「格納先選択について AskUserQuestion で確認」 |
| 7 | ユーザー → AI agent | 「マージ前」 | - |
| 8 | AI agent → ユーザー | AskUserQuestion: 「この内容で Issue を起票してよいですか？」 | §1.0.5 必須事項「§1.5 Step 4 起票実行直前に AskUserQuestion で確認」 |
| 9 | ユーザー → AI agent | 「approved」 | - |
| 10 | AI agent | `retrospective_dialog_token_record_response "v2.5.3" "approved"` を呼出 → exit 0 | §1.0.5 必須事項「対話確認トークンを発行する」 / Layer 3 発行関数 |
| 11 | AI agent | `retrospective_issue_create "$body" "mirror" "v2.5.3"` を呼出 | - |
| 12 | retrospective_issue_create | 内部で `retrospective_dialog_token_verify "v2.5.3"` を呼出 → exit 0（鮮度内 + approved）| Layer 3 検証関数（gh issue create 直前） |
| 13 | retrospective_issue_create | `gh issue create` 実行 → Issue URL 取得 | - |
| 14 | AI agent | 起票成功を表示してサマリに反映 | - |

### 観察される効果

- 全判断要素（KPT / 主因 / 格納先 / 起票実行）が AskUserQuestion を経由
- 対話確認トークンが鮮度内（300 秒以内）で発行され、検証成功
- jailrun #70 で発生した「auto mode が独断で KPT・主因・mirror 送信を生成し `gh issue create` に至る」経路は構造的に発生しない

## アンチパターン例（auto mode 独断起票 / jailrun #70 再現）

### 進行例

| ステップ | アクター | アクション | ガード文言が予防する経路 |
|---------|---------|-----------|----------------------|
| 1 | AI agent（auto mode） | §1.0.5 を読まずに「§1 全体を 1 ステップにまとめる」誘惑に従う | §1.0.5 冒頭ボックスが「対話必須」を明記しているため読み飛ばし困難（読み飛ばしても Layer 3 で阻止される） |
| 2 | AI agent | KPT・主因切り分け・格納先・mirror 送信判断のすべてを独断で生成 | §1.0.5 禁止事項「すべてを AI エージェントが独断で決定すること」に違反 |
| 3 | AI agent | `retrospective_dialog_token_record_response` を呼ばない（AskUserQuestion 省略） | §1.0.5 必須事項「対話確認トークンを発行する」を満たさない |
| 4 | AI agent | `retrospective_issue_create "$body" "mirror" "v2.5.3"` を直接呼出 | - |
| 5 | retrospective_issue_create | 内部で `retrospective_dialog_token_verify "v2.5.3"` を呼出 → トークンファイル不在 → exit 4 / `error\tdialog_required\ttoken_missing` を stderr 出力 | Layer 3 実行時ガード本体（gh issue create 直前で exit 4 ブロック） |
| 6 | retrospective_issue_create | `gh issue create` を実行せずに `result=failed`, `reason=dialog-required`, `verify_exit=4` を stdout 出力、return 4 | Layer 3 ブロック効果 |
| 7 | AI agent | exit 4 を受けて `gh issue create` 副作用は発生せず | - |
| 8 | AI agent | §1.0.5 / 04-completion.md の case 文 4 のメッセージを表示し、再対話を実施 | Layer 2 手順記述による復旧誘導 |

### 観察される効果

- 文書ガード（§1.0.5 必須事項）の見落としが発生しても、実行時ガードで `gh issue create` をブロック
- jailrun #70 と同型のシナリオが「`gh issue create` 直前で exit 4 / `token_missing`」として確定的に阻止される
- 二段防御により、AI エージェントの auto mode 動作下での再発リスクが構造的に排除される

## TTL 切れシナリオ（長時間放置後の保護）

### 進行例

| ステップ | アクター | アクション | ガード文言の予防ポイント |
|---------|---------|-----------|------------------------|
| 1 | AI agent → ユーザー | 起票実行可否 AskUserQuestion → ユーザー応答 `approved` | 正常パターンと同じ |
| 2 | AI agent | `retrospective_dialog_token_record_response "v2.5.3" "approved"` 呼出 | - |
| 3 | AI agent | 他作業で 600 秒（10 分、TTL=300 秒の 2 倍）以上経過 | - |
| 4 | AI agent | `retrospective_issue_create` 呼出 | - |
| 5 | retrospective_issue_create | `retrospective_dialog_token_verify` で TTL 切れ判定（`age > AIDLC_RETRO_TOKEN_TTL_SECONDS=300`）→ exit 4 / `error\tdialog_required\ttoken_stale` | Layer 3 TTL 検証 |
| 6 | retrospective_issue_create | `gh issue create` ブロック / return 4 | - |
| 7 | AI agent | 再対話 + 再 `record_response` 呼出を実施 | - |

### 観察される効果

- 対話から起票までの時間差が長すぎる場合、対話確認の有効性を否定して再対話を要求
- 「以前の対話確認」を流用した遅延起票を構造的に阻止

## I/O 異常シナリオ（ファイル破損 / 解釈失敗）

### 進行例

| ステップ | アクター | アクション | reason 値 |
|---------|---------|-----------|---------|
| 1 | AI agent | 通常の対話 → `record_response` で書出 | - |
| 2 | 第三者プロセス / OS | トークンファイルが破損（行数不足 / タイムスタンプ無効 / response 値不正等） | - |
| 3 | AI agent | `retrospective_issue_create` 呼出 | - |
| 4 | retrospective_issue_create | `retrospective_dialog_token_verify` でファイル読み取り or 形式不正検出 | `token_io_error` / `token_parse_error` |
| 5 | retrospective_issue_create | exit 4 / `gh issue create` ブロック | - |
| 6 | AI agent | 再対話 + 再書出を実施（再 `record_response` 呼出） | - |

### 観察される効果

- 業務拒否系（`token_missing` / `token_stale` / `token_denied`）と I/O 異常系（`token_io_error` / `token_parse_error`）を stderr の reason 値で分離
- 呼び出し元のリカバリ戦略（再対話 vs リトライ vs 中断）を reason 値ベースで分岐可能

## ユーザー拒否シナリオ（denied 応答）

### 進行例

| ステップ | アクター | アクション | reason 値 |
|---------|---------|-----------|---------|
| 1 | AI agent → ユーザー | 起票実行可否 AskUserQuestion → ユーザー応答 `denied`（起票したくない） | - |
| 2 | AI agent | `retrospective_dialog_token_record_response "v2.5.3" "denied"` 呼出 | - |
| 3 | AI agent | `retrospective_issue_create` 呼出（または呼出しない選択） | - |
| 4 | retrospective_issue_create | `retrospective_dialog_token_verify` で `denied` 検出 → exit 4 / `error\tdialog_required\ttoken_denied` | `token_denied` |
| 5 | retrospective_issue_create | exit 4 / `gh issue create` ブロック | - |

### 観察される効果

- ユーザーが明示的に起票を拒否した場合、対話確認トークン（`denied`）として記録され、`retrospective_issue_create` が呼ばれても確実にブロック
- 「ユーザー拒否」と「対話なし」を区別し、運用上の判断を残す

## サマリ

| パターン | reason 値 | exit code | gh issue create | 効果 |
|---------|---------|-----------|----------------|------|
| 正常（approved + 鮮度内） | - | 0 | 実行 | 正規の対話を経た起票 |
| auto mode 独断 | `token_missing` | 4 | ブロック | jailrun #70 同型阻止 |
| TTL 切れ | `token_stale` | 4 | ブロック | 遅延起票阻止 |
| ファイル破損 | `token_io_error` / `token_parse_error` | 4 | ブロック | I/O 異常時の安全ブロック |
| ユーザー拒否 | `token_denied` | 4 | ブロック | 明示的拒否の尊重 |

文書ガード（§1.0.5 + SKILL.md）と実行時ガード（`retrospective_dialog_token_verify`）の二段防御により、`feedback_mode=mirror` × auto mode の組み合わせで対話を経ない `gh issue create` を構造的に阻止する。

## 関連ファイル

- 計画ファイル: `.aidlc/cycles/v2.5.3/plans/unit-001-plan.md`
- ドメインモデル: `.aidlc/cycles/v2.5.3/design-artifacts/domain-models/unit_001_retro_dialog_guard_domain_model.md`
- 論理設計: `.aidlc/cycles/v2.5.3/design-artifacts/logical-designs/unit_001_retro_dialog_guard_logical_design.md`
- 関連 Issue: #647（[Feedback] Operations §1 振り返り対話強制ガード強化）
- 参考事例: jailrun #70 / PR #71（外部実証 / non-blocking）
