# Unit 003 ドメインモデル: permissions audit 9 件の解消

## 用語整理

| 用語 | 定義 |
|------|------|
| **Pattern** | `Bash(...)` 等の許可ルール文字列。`permissions.allow` / `permissions.ask` / `permissions.deny` / `acknowledgedFindings[].pattern` のキーになる |
| **Severity** | `CRITICAL` / `HIGH` / `MED` / `LOW` / `INFO`。`/tools:suggest-permissions --review all` が assign |
| **Scope** | `global` (`~/.claude/settings.json`) または `project` (`.claude/settings.json`)。同じ pattern が両方に存在することがある |
| **Finding** | (pattern, severity, scope, message) の組。検出 1 件分 |
| **acknowledgedFindings** | `.claude/settings.json` の `suggestPermissions.acknowledgedFindings` 配列要素。`{pattern, severity, note, acknowledgedAt}` 構造で「検出は記録するが意図的許容」を表す |
| **ask 追加** | `permissions.ask` 配列に新規 pattern を追加し、該当パターンの実行時にユーザー確認ダイアログを出す |
| **ask 昇格 (細粒度 allow)** | 既存の広範囲 allow（例: `Bash(rm /tmp/aidlc-*)`）を細粒度 allow（例: `Bash(rm /tmp/aidlc-:*)`）に書き換え、危険サブコマンドを構造的に除外する |
| **M_baseline** | 監査実行時点の Finding 集合（HIGH/CRITICAL/MED の全件）。本サイクルでは 9 件 |
| **M_plan** | M_baseline の各 Finding に対する対処方針（ask 追加 / acknowledgedFindings 登録 / ask 昇格）の割当 |

## 検出ベースライン M_baseline（実測 / 2026-05-09）

`/tools:suggest-permissions --review all` の実行結果から抽出:

| # | pattern | severity | scope |
|---|---------|----------|-------|
| 1 | `Bash(bash -n *)` | CRITICAL | global/allow |
| 2 | `Bash(rm /tmp/aidlc-*)` | HIGH | global/allow |
| 3 | `Bash(gh issue list *)` | MED | global/allow |
| 4 | `Bash(gh issue view *)` | MED | global/allow |
| 5 | `Bash(gh pr view *)` | MED | global/allow |
| 6 | `Bash(git push *)` | MED | global/allow |
| 7 | `Bash(git tag *)` | MED | global/allow |
| 8 | `Bash(git push *)` | MED | project/allow |
| 9 | `Bash(git tag *)` | MED | project/allow |

INFO 1 件（`Bash(python3 /Users/keisuke/.c... [global]`）は本 Unit の対処対象外（LOW 同等扱い）。

## 状態遷移

各 Finding は以下の 3 状態を遷移する:

```text
[detected] ──(対処方針決定)──► [planned (ask|ack|escalate)]
              ──(設定ファイル変更)──► [applied]
              ──(--review all 再実行 + 検証)──► [resolved] | [unresolved]
```

| 状態 | 定義 | 判定根拠 |
|------|------|---------|
| detected | M_baseline に含まれる | `--review all` Finding |
| planned | M_plan で対処方針が確定 | `docs/permissions-audit-v2.5.6.md` §2 表 |
| applied | 設定ファイル変更が完了 | `.claude/settings.json` の commit / `~/.claude/settings.json` のユーザー手動編集 |
| resolved | 再実行で「対処済み」と判定 | HIGH/CRITICAL: 0 件 / MED: M_plan 割当通りの ask or ack で記録 |
| unresolved | 再実行で「未対処」が残存 | HIGH/CRITICAL 残存、または MED の M_plan 割当未反映 |

## 対処方針の選択原則

| Severity | 対処方針 | 理由 |
|----------|---------|------|
| CRITICAL | **必ず ask 追加** または **ask 昇格**（acknowledgedFindings 単独不可） | 任意コード実行可能パターンは note 抑制では足りない（Intent C / Unit 003 責務） |
| HIGH | **必ず ask 追加** または **ask 昇格**（acknowledgedFindings 単独不可） | 破壊的操作を note 抑制で残すのは衛生上不適切 |
| MED | **ask 追加** または **acknowledgedFindings 登録** のいずれか | ワイルドカードオーバーマッチ系は acknowledged 中心、危険拡張サブコマンド検出は ask 中心 |
| LOW / INFO | 対象外 | 本サイクルでは対処しない |

## 評価順序ドメイン（B-4 検証用）

`permissions.{allow, ask, deny}` と `acknowledgedFindings` の評価順序仕様:

- 同一 pattern が `allow` と `ask` 双方に存在する場合の優先度（実装次第）
- user-global と project の競合時の優先度（一般的に project 優先）
- `acknowledgedFindings` は **検出抑制ではなく注釈** であり、実行時の許可判定には影響しない（仕様上）

本仕様は `/tools:suggest-permissions` の挙動確認 + 実際の Bash 実行時のダイアログ挙動の双方で実測検証する（B-4）。
