# Unit 003 論理設計: permissions audit 9 件の解消

## 1. 対処マトリクス M_plan（確定版）

ドメインモデル §「検出ベースライン M_baseline」の 9 件に対する対処方針:

| # | pattern | severity | scope | 対処方針 | 適用先ファイル |
|---|---------|----------|-------|---------|---------------|
| 1 | `Bash(bash -n *)` | CRITICAL | global/allow | **ask 追加（細粒度）** + acknowledged 補足 | `~/.claude/settings.json` の `permissions.ask` に追加 + project の `acknowledgedFindings` にも記録 |
| 2 | `Bash(rm /tmp/aidlc-*)` | HIGH | global/allow | **細粒度 allow 昇格（決定木固定）** + acknowledged 補足 | `~/.claude/settings.json` の allow を `Bash(rm /tmp/aidlc-:*)` に書き換え（細粒度化） + project の `acknowledgedFindings` にも記録。**ask 追加は不採用**（Issue #671 受け入れ基準「`Bash(rm /tmp/aidlc-*)` の tmp スコープ削除は引き続き自動承認される」に準拠） |
| 3 | `Bash(gh issue list *)` | MED | global/allow | acknowledgedFindings 登録 | `.claude/settings.json` |
| 4 | `Bash(gh issue view *)` | MED | global/allow | acknowledgedFindings 登録 | `.claude/settings.json` |
| 5 | `Bash(gh pr view *)` | MED | global/allow | acknowledgedFindings 登録 | `.claude/settings.json` |
| 6 | `Bash(git push *)` | MED | global/allow | **ask 追加（user-global 側 force ガード）** + acknowledgedFindings 登録 | `~/.claude/settings.json` の `permissions.ask` に `Bash(git push --force *)` / `Bash(git push --force-with-lease *)` を追加（**user-global に同義の既存 ask が存在する場合は重複登録となる。`~/.claude/settings.json` 確認手順を §3.0 で実施し、既存有無を踏まえて B-4 検証で実測**） + `.claude/settings.json` に acknowledged 登録 |
| 7 | `Bash(git tag *)` | MED | global/allow | **ask 追加（user-global 側 -d ガード）** + acknowledgedFindings 登録 | `~/.claude/settings.json` の `permissions.ask` に `Bash(git tag -d *)` を追加（**user-global 既存 ask 確認 §3.0 を踏襲、重複時は B-4 で実測**） + `.claude/settings.json` に acknowledged 登録 |
| 8 | `Bash(git push *)` | MED | project/allow | acknowledgedFindings 登録 | `.claude/settings.json`（project の既存 ask `Bash(git push*--force *)` で前段ガード済みのため acknowledged 補足のみ） |
| 9 | `Bash(git tag *)` | MED | project/allow | acknowledgedFindings 登録 | `.claude/settings.json`（同上、project の既存 ask `Bash(git tag*-d *)` で前段ガード済み） |

### 1.1 CRITICAL/HIGH の対処方針詳細

- **#1 `Bash(bash -n *)` (CRITICAL)**: 「シンタックスチェック専用」の意図的許可だが、文字列マッチでは `bash` 全般がスコープに見える。**ask 追加** で実行時確認を挟みつつ、project `acknowledgedFindings` に「シンタックスチェック専用」note で記録 → 監査時の文書化を担保。代替案: 細粒度 allow（例: `Bash(bash -n bin/*.sh)`）への昇格も可能だが、対象スクリプト範囲が事前確定しないため ask が安全
- **#2 `Bash(rm /tmp/aidlc-*)` (HIGH)**: `/tmp/aidlc-` プレフィックス限定の意図的スコープ。**決定木固定: 細粒度 allow 昇格**として `Bash(rm /tmp/aidlc-:*)` への書き換えのみを採用する（`*` のワイルドカードを `:` プレフィックス分離で範囲確定）。Issue #671 受け入れ基準「`Bash(rm /tmp/aidlc-*)` の tmp スコープ削除は引き続き自動承認される」に準拠し、**ask 追加は最初から不採用**。`acknowledgedFindings` に「/tmp/aidlc- プレフィックス限定」note を併記
- **B-4 検証対象スコープ**: B-4 の評価順序実測検証では **#1（CRITICAL）の ask 追加** および **#6/#7（user-global git 系 MED）の ask 追加** を対象とする。**#2 は B-4 評価順序検証の対象外**（ask 追加を行わないため、評価順序問題の影響を受けない）。想定外時の代替案も #2 については適用しない（既に細粒度 allow 昇格固定）

### 1.2 MED の対処方針詳細

- **#3-#5 (gh 系 MED)**: いずれも `view` / `list` の read-only サブコマンドで、`create` / `close` 等の書込み系はワイルドカード上のオーバーマッチ。実害ないため acknowledgedFindings 単独で対処
- **#6-#7 (global/git 系 MED)**: `--force` / `-d` をユーザー全環境で ask 化することで、当該リポジトリ以外でも force push / タグ削除に確認を挟む。**Issue #671 受け入れ基準「force push 実行時にユーザー承認ダイアログが出る」の達成手段**
- **#8-#9 (project/git 系 MED)**: 既存 project ask（`Bash(git push*--force *)` 等）で前段ガード済みのため acknowledgedFindings 補足のみ

## 2. `.claude/settings.json` 変更内容

### 2.1 追加する `suggestPermissions.acknowledgedFindings` 配列

既存の JSON 構造に `permissions` と並列で `suggestPermissions` キーを新設し、以下を追加:

```json
{
  "suggestPermissions": {
    "acknowledgedFindings": [
      {
        "pattern": "Bash(bash -n *)",
        "severity": "CRITICAL",
        "note": "シンタックスチェック専用（-n フラグは parse のみで実行しない）。user-global の permissions.ask 追加と併用",
        "acknowledgedAt": "2026-05-09"
      },
      {
        "pattern": "Bash(rm /tmp/aidlc-*)",
        "severity": "HIGH",
        "note": "/tmp/aidlc- プレフィックス限定の意図的スコープ。user-global では細粒度 allow [Bash(rm /tmp/aidlc-:*)] へ昇格予定。ask 追加は不採用（Issue #671 受け入れ基準準拠）",
        "acknowledgedAt": "2026-05-09"
      },
      {
        "pattern": "Bash(gh issue list *)",
        "severity": "MED",
        "note": "list は read-only。create/close は別途 ask 化済み（既存 user-global ask 経由）",
        "acknowledgedAt": "2026-05-09"
      },
      {
        "pattern": "Bash(gh issue view *)",
        "severity": "MED",
        "note": "view は read-only。create/close は別途 ask 化済み",
        "acknowledgedAt": "2026-05-09"
      },
      {
        "pattern": "Bash(gh pr view *)",
        "severity": "MED",
        "note": "view は read-only。create/close は別途 ask 化済み",
        "acknowledgedAt": "2026-05-09"
      },
      {
        "pattern": "Bash(git push *)",
        "severity": "MED",
        "note": "--force / --force-with-lease ガードは project の ask（Bash(git push*--force *)）+ user-global 追加 ask（Bash(git push --force *)）で対処。本エントリは残余抑制",
        "acknowledgedAt": "2026-05-09"
      },
      {
        "pattern": "Bash(git tag *)",
        "severity": "MED",
        "note": "-d ガードは project の ask（Bash(git tag*-d *)）+ user-global 追加 ask（Bash(git tag -d *)）で対処。本エントリは残余抑制",
        "acknowledgedAt": "2026-05-09"
      }
    ]
  }
}
```

> **件数注**: M_baseline 9 件のうち、global #6/#7 と project #8/#9 は同一 pattern（`Bash(git push *)` / `Bash(git tag *)`）。`acknowledgedFindings` は pattern キーで一意化されるため 7 エントリで全 9 件を被覆する。

### 2.2 配置位置

既存 `.claude/settings.json` の `permissions` キーと並列に `suggestPermissions` キーを追加する。`hooks` / `permissions` セクションには変更を加えない。

## 3. ask 追加手順（user-global / `~/.claude/settings.json`）

ユーザーが手動で `~/.claude/settings.json` に以下を追加する手順を `docs/permissions-audit-v2.5.6.md` §3 に記述する:

### 3.0 user-global 既存 ask 確認（追加前ステップ）

ユーザーが追加前に `~/.claude/settings.json` の `permissions.ask` 配列を開き、以下のパターンが既に登録されているかを確認する:

- `Bash(bash -n *)` または同義
- `Bash(git push --force *)` / `Bash(git push*--force *)` 等の同義パターン
- `Bash(git push --force-with-lease *)` / `Bash(git push*--force-with-lease *)` 等の同義パターン
- `Bash(git tag -d *)` / `Bash(git tag*-d *)` 等の同義パターン
- `Bash(rm /tmp/aidlc-*)` の細粒度 allow への昇格対象 = `Bash(rm /tmp/aidlc-:*)`（既に細粒度化済みかどうか）

確認結果を `docs/permissions-audit-v2.5.6.md` §3 冒頭に「user-global 既存 ask 棚卸」として記録（pattern / 既存有無 / 追加要否を表形式）。既存と同義のパターンが存在する場合:

- **追加スキップ**: 同義の既存パターンが機能しているなら、新規追加は重複登録となるため省略可。判断は B-4 の実測検証で行う
- **強化追加**: 既存より厳格なパターン（例: `*` 位置の違いで挙動差がある場合）なら追加して B-4 で評価順序を実測

### 3.1 追加対象（user-global `permissions.ask` 配列、§3.0 で「未存在」と確認されたもののみ）

```json
{
  "permissions": {
    "ask": [
      "Bash(bash -n *)",
      "Bash(git push --force *)",
      "Bash(git push --force-with-lease *)",
      "Bash(git tag -d *)"
    ]
  }
}
```

### 3.2 細粒度 allow 昇格（HIGH #2）

`~/.claude/settings.json` の `permissions.allow` 配列で:

- 削除: `"Bash(rm /tmp/aidlc-*)"`
- 追加: `"Bash(rm /tmp/aidlc-:*)"`

### 3.3 適用手順（手動 / before/after ログ）

1. 適用前に baseline ログを取得:

   ```bash
   python3 ~/.claude/plugins/cache/ikeisuke-skills/tools/*/skills/suggest-permissions/scripts/suggest-permissions.py --review all > /tmp/aidlc-perm-before.log 2>&1
   ```

2. ユーザーが手元のエディタで `~/.claude/settings.json` を編集（§3.1 の ask 追加 + §3.2 の細粒度 allow 昇格）

3. 適用後ログを取得:

   ```bash
   python3 ~/.claude/plugins/cache/ikeisuke-skills/tools/*/skills/suggest-permissions/scripts/suggest-permissions.py --review all > /tmp/aidlc-perm-after.log 2>&1
   ```

4. before/after ログを `docs/permissions-audit-v2.5.6.md` §6 に表形式で貼付

## 4. `docs/permissions-audit-v2.5.6.md` 章構成

| § | タイトル | 内容 |
|---|---------|------|
| §1 | 検出ベースライン M_baseline | 9 件の Finding を表形式で記録（実測 / 2026-05-09） |
| §2 | 対処方針表 M_plan | 9 件の対処方針 + 評価順序の実測結果（B-4） |
| §3 | ask 追加手順（user-global） | §3.1 追加対象 / §3.2 細粒度 allow 昇格 / §3.3 適用手順 |
| §4 | acknowledgedFindings 適用結果 | プロジェクト `.claude/settings.json` 変更後の `--review all` 中間ログ（プロジェクト側のみ変更時の状態） |
| §5 | ユーザー選択結果 | AskUserQuestion 「適用 / 手順のみ受領 / 中止」の選択履歴 + 中止/手順のみ時の follow-up Issue 番号 |
| §6 | before/after 監査ログ | user-global 適用前後の `--review all` 出力比較表（HIGH/CRITICAL/MED 件数 + pattern 別） |

## 5. AskUserQuestion 設計

### 5.1 環境適用 AskUserQuestion（A-4 / B-1 入口）

質問: 「user-global `~/.claude/settings.json` への ask 追加 + 細粒度 allow 昇格を適用しますか？」

| 選択肢 | 後続フロー |
|--------|----------|
| **適用** | ユーザーがエディタで手動編集 → before/after ログ取得 → §6 記載 → B-1/B-2/B-4 検証 |
| **手順のみ受領** | §5 に「手順のみ受領」記録 → §6 はユーザー側で適用後に追記する旨記載 → A 系のみ Unit 完了 → Intent C 未達 follow-up Issue 起票 |
| **中止** | §5 に中止理由記録 → Unit 「取り下げ」 → Intent C 未達 follow-up Issue 起票 → 後続ステップ打ち切り |

### 5.2 ベースライン取得失敗時 AskUserQuestion（第三経路）

質問: 「`/tools:suggest-permissions` Skill とフォールバックスクリプトのいずれも見つかりません。どうしますか？」

| 選択肢 | 後続フロー |
|--------|----------|
| **手動でベースライン記録** | Issue #671 本文の 9 件をそのまま M_baseline として §1 に記録し、`M_baseline_source=issue_snapshot` フラグを §1 末尾と §5 に明記 → B 系判定を「**暫定判定**」に自動降格（B-3 で「Intent C 暫定達成」と記録、follow-up で実測再検証 Issue を起票）→ Phase 1/2 続行 |
| **Unit 003 中止** | Unit 「取り下げ」 → follow-up Issue 起票 → 環境適用 AskUserQuestion はスキップ → 後続ステップ打ち切り |

### 5.3 状態遷移ルール

計画ファイル「状態遷移ルール（AskUserQuestion 2 段階の関係）」セクションに準拠。

## 6. 完了条件のマッピング

| 完了条件 | 達成手段 |
|---------|---------|
| A-1 | §1 + §2 を本論理設計および `docs/permissions-audit-v2.5.6.md` §1/§2 に記載 |
| A-2 | `.claude/settings.json` に §2.1 の 7 エントリを追加 |
| A-3 | §3 を `docs/permissions-audit-v2.5.6.md` §3 に転記 |
| A-4 | §5.1 の AskUserQuestion を実施し選択結果を §5 に記録 |
| A-5 | A-4 結果に応じて Unit 定義状態を「完了」または「取り下げ」に更新 |
| A-6 | `history/construction_unit03.md` に Phase 1/2/完了処理を時系列記録 |
| B-1 | §3.3 適用後ログを §6 に表形式で貼付 |
| B-2 | §6 表で「**M_baseline の各 finding（pattern+scope）に対し、M_plan の action（ask 追加 / acknowledgedFindings 登録 / 細粒度 allow 昇格）が 1 つ以上紐付いていること**」を 9 件全件に対して `coverage(finding_id)=true` で評価。HIGH/CRITICAL は紐付け action に ask 追加または細粒度 allow 昇格を含むこと（acknowledged 単独不可）。MED は ask または acknowledged のいずれかでよい。再実行ログで HIGH/CRITICAL=0 件を確認 |
| B-3 | B-1/B-2 達成時 §5 に「Intent C 達成」を記録。第三経路採用時（M_baseline_source=issue_snapshot）は「Intent C 暫定達成」と記録し、follow-up で実測再検証 Issue を起票 |
| B-4 | §2 末尾に評価順序の実測結果を記録（**対象: #1 CRITICAL の ask 追加 + #6/#7 MED の ask 追加。#2 HIGH は細粒度 allow 昇格固定のため B-4 対象外**）。各 ask 追加対象が ask 先勝ちで機能することを **対象 ID 単位で pass/fail 記録** する。判定キーは「B-4 対象（#1 + #6 + #7）の各 finding に対し、対応コマンド実行時に ask ダイアログ表示が観測されたかどうか」。実測ケース: **(I-a) #6 の git push --force ... 実行**（多層重複時のヒット pattern を §6 に記録、ダイアログ表示有無を pass/fail 化）、**(I-b) #6 の git push --force-with-lease ... 実行**（同上）、**(I-c) #7 の git tag -d ... 実行**（同上）、**(II) #1 の bash -n some_script.sh 実行**（`.claude/settings.json` 側に同パターン既存 ask なし、user-global 既存有無は §3.0 で棚卸済み、追加 ask `Bash(bash -n *)` ないし既存 user-global ask のヒットを pass/fail 化）。**B-4 達成条件**: B-4 対象 #1 / #6 / #7 のいずれも ask ダイアログ表示が確認できること（all pass）。1 つでも fail（ダイアログ未表示で実行通過）の場合は B-4 未達。想定外時は #2 で適用済みの細粒度 allow 昇格パターンを **fail した対象（CRITICAL #1 / MED #6/#7）にも応用検討**（追加多層防御）|

## 7. リスクと代替

| リスク | 検出条件 | 代替手段 |
|--------|---------|---------|
| ユーザーが `~/.claude/settings.json` 編集を拒否 | A-4 で「中止」選択 | Unit 取り下げ + follow-up Issue 起票で次サイクル繰越 |
| 編集後 `--review all` が exit ≠ 0 | §3.3 ステップ 3 で stderr 確認 | エラーログを §6 に記録、ユーザーに JSON 構文修正を依頼（jq でバリデーション） |
| ask 追加が後勝ちで無効化（B-4 想定外） | §6 で B-4 対象（#1 / #6 / #7）のいずれかに fail 記録（ダイアログ未表示で実行通過）が出る | #2 と同様に細粒度 allow 昇格パターンを fail した対象（CRITICAL #1 / MED #6/#7）にも応用検討（実装可能性は対象 pattern 次第。`Bash(bash -n *)` の細粒度化は対象スクリプトを限定する allow 形に書き換え） + ask 追加は維持（多層防御） |
| Issue #671 と実測 9 件の差分発見 | §1 ベースライン取得時 | §1 末尾に差分メモ + M_plan を実測値に合わせて再構成 |
| **同義パターン多層重複時の優先順位不定** | **project 既存 ask**（例: `Bash(git push*--force *)`、`.claude/settings.json:103-110`）+ **user-global 既存 ask**（例: `Bash(git push*--force *)` 相当、§3.0 で棚卸） + **user-global 追加 ask**（例: `Bash(git push --force *)`）の 3 層が同一実行で両方マッチする場合の評価順序が実装依存で不定 | §3.0 棚卸で user-global 既存 ask を把握 → 重複登録の必要性を判断 → B-4 ケース (I) で実測検証（git push --force ... 実行時にどの pattern がヒットするかを §6 に記録）。問題があれば、より厳格な側に統一（重複登録は許容、機能している pattern が確認できれば B-4 達成）|
| 第三経路採用時の B 系暫定降格 | M_baseline_source=issue_snapshot 時 | B-3 を「暫定達成」記録に降格、follow-up で `--review all` 実測ベースの再検証 Issue 起票 |
