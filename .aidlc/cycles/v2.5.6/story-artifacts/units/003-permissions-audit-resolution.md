# Unit: permissions audit 9 件の解消（C）

## 概要

`/tools:suggest-permissions --review all` で v2.5.5 リリース前から継続検出されている 9 件（1 CRITICAL / 1 HIGH / 7 MED）を、ask 追加と acknowledgedFindings 登録で「対処済み」状態にする。リポジトリ管理下の設定テンプレート + 手順書を主成果物とし、ユーザーグローバル設定の適用は確認記録付きで分離する。

## 含まれるユーザーストーリー

- ストーリー 3: permissions audit 9 件の検出を解消したい（C）

## 責務

**重要: 9 件の対処方針（Intent 成功基準 C との整合）**:
- **CRITICAL 1 件 + HIGH 1 件 (合計 2 件)**: **必ず ask 追加で対処**（acknowledgedFindings での抑制は不可）
  - `Bash(bash -n *)` (CRITICAL): note 付き acknowledged では足りず、ask 追加（または個別の細粒度 allow）で再分類が必要
  - `Bash(rm /tmp/aidlc-*)` (HIGH): /tmp/aidlc- プレフィックス限定の細粒度 allow への昇格、または ask 追加
- **MED 7 件**: ask 追加または acknowledgedFindings 登録のいずれかで対処（ワイルドカードオーバーマッチ系は acknowledged 中心、危険な拡張サブコマンドは ask 中心）
  - `Bash(git push --force *)` / `Bash(git push --force-with-lease *)` / `Bash(git tag -d *)`: ask 追加（user-global）
  - `Bash(gh issue list *)` / `Bash(gh issue view *)` / `Bash(gh pr view *)` / `Bash(git push *)` / `Bash(git tag *)`: acknowledgedFindings 登録 (note 必須)

**[主成果物] リポジトリ管理下**:
- `.claude/settings.json` の `suggestPermissions.acknowledgedFindings` セクションを新設し、上記方針に基づく該当エントリを登録（pattern / severity / note / acknowledgedAt）
- `docs/permissions-audit-v2.5.6.md`（または PR description）に対処内容を表形式で記録（pattern / severity / 対処方法 / 設定ファイル / note 内容）
- 手順書: `~/.claude/settings.json` の `permissions.ask` 配列追加候補（HIGH/CRITICAL 用 + MED 用）の適用手順 + before/after 出力ログ保存指示

**[環境適用 + 確認記録]**:
- AskUserQuestion で「適用 / 手順のみ受領 / 中止」の選択を提示
- 適用後、`/tools:suggest-permissions --review all` 再実行ログを保存
- 適用結果検証:
  - **HIGH/CRITICAL は 0 件**（必須）— 検出 1 件でも残れば未達扱い
  - **MED は 7 件すべてに ask 追加または acknowledgedFindings 登録**が施されている（再実行時に MED として検出されること自体は acknowledged 仕様により許容）
  - **LOW は本サイクル対象外**

## 境界

- 新規発生する permissions の自動検出機能拡張は対象外
- `~/.claude/settings.json` 以外の user-global ファイル（hooks / env 等）への変更は対象外
- 他リポジトリの permissions audit は対象外

## 依存関係

### 依存する Unit
- なし

### 外部依存
- `/tools:suggest-permissions` スキル（実行可能であること）
- `.claude/settings.json` の suggestPermissions セクション仕様（既存スキル定義に準拠）

## 非機能要件（NFR）

- **セキュリティ**: acknowledged 登録は note を必ず付与し「なぜ意図的に許容されるか」を後追い可能にする
- **可用性**: ask 追加によりユーザー操作 1 段階増えるが、危険操作の事故防止と引き換えに許容
- **保守性**: pattern / severity / note を表形式で 1 箇所に集約し、後続サイクルで監査再実行時の参照を容易にする

## 技術的考慮事項

- `~/.claude/settings.json` への変更はユーザー（管理者）の確認必須（rules.md「設定ファイルのスコープ」: スコープ不明時は確認）
- acknowledged 登録は検出を抑制せず note 付きで残す仕様。再実行時に MED として残るが、表でカバー済みであることを示せれば「対処済み」とみなす
- ask 追加と acknowledged 登録の使い分け: 危険な拡張サブコマンド（`--force` / `-d` 等）は ask、ワイルドカードオーバーマッチの誤検出は acknowledged

## 関連Issue

- #671

## 実装優先度

High（Must、Intent C）

## 見積もり

小〜中。0.5 日（settings.json 編集 + 手順書作成 + before/after ログ保存）

---
## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 完了
- **開始日**: 2026-05-09
- **完了日**: 2026-05-09
- **担当**: AI-DLC（Construction Phase 自動実行）+ ユーザー（user-global 編集）
- **エクスプレス適格性**: -
- **適格性理由**: -

### Intent C 達成状況の引き継ぎ（Operations Phase 用）

- **検出ベース達成**: HIGH/CRITICAL/MED の `--review all` 検出 0 件（acknowledgedFindings + 細粒度 allow 昇格 + 既存 user-global ask の組み合わせ）
- **Intent §C 厳格ルール例外**: CRITICAL #1 `Bash(bash -n *)` のみ acknowledged 単独対処（parse-only 実害なし / ユーザースコープ保護確認済 / 恒久措置）
- **follow-up Issue**: 不要（`docs/permissions-audit-v2.5.6.md` §5.3 参照）
- **完了経路**: 通常完了経路（A-1 達成 + Intent C 達成判定はユーザー判断ベースで「達成」扱い）

詳細は `docs/permissions-audit-v2.5.6.md` §6.4 / `.aidlc/cycles/v2.5.6/construction/units/003-review-summary.md` Unit 003 全体サマリ参照。
