# Unit 003 計画: permissions audit 9 件の解消（C）

## 概要

`/tools:suggest-permissions --review all` で v2.5.5 リリース前から継続検出されている 9 件（1 CRITICAL / 1 HIGH / 7 MED）について、`ask` 追加と `acknowledgedFindings` 登録で「対処済み」状態にする。リポジトリ管理下の設定（プロジェクト `.claude/settings.json` + 監査記録 doc）を主成果物とし、`~/.claude/settings.json` 側の適用は手順書化 + 環境適用ステップを分離する。

## 関連 Issue

- #671（permissions audit: HIGH/CRITICAL/MED 指摘の解消）

## スコープ境界

| 範囲 | 含む / 含まない |
|------|----------------|
| プロジェクト `.claude/settings.json` の `suggestPermissions.acknowledgedFindings` セクション新設 | 含む |
| `docs/permissions-audit-v2.5.6.md` 監査記録 doc 作成 | 含む |
| `~/.claude/settings.json` への `permissions.ask` 追加手順書（CRITICAL/HIGH/MED の ask 候補と適用手順 + before/after ログ保存指示） | 含む |
| `~/.claude/settings.json` への実適用（環境適用 + 確認記録、AskUserQuestion で「適用 / 手順のみ受領 / 中止」を選択） | 含む（適用結果の `/tools:suggest-permissions --review all` 再実行ログ取得を必須） |
| 履歴記録（`construction_unit03.md`） | 含む |
| 新規 permissions の自動検出機能拡張 | 含まない |
| `~/.claude/settings.json` 以外の user-global ファイル（hooks / env 等）への変更 | 含まない |
| 他リポジトリの permissions audit | 含まない |

## 9 件の対処方針（Phase 1 で確定する M_plan の初期案）

> **位置付け**: 本セクションは Issue #671 本文に基づく初期案であり、**Phase 1 論理設計でベースライン M_baseline を実測取得した上で M_plan として再確定する**。完了条件 A-1〜A-3 / B-1〜B-3 の入力となるのは確定後の M_plan であり、本セクションの件数や対処割当は固定値ではない。


### CRITICAL 1 件 + HIGH 1 件 → 必ず ask 追加で対処

| pattern | severity | 対処方法 | 適用先 |
|---------|----------|----------|--------|
| `Bash(bash -n *)` | CRITICAL | ask 追加（または個別の細粒度 allow への昇格） | `~/.claude/settings.json` |
| `Bash(rm /tmp/aidlc-*)` | HIGH | ask 追加 または `Bash(rm /tmp/aidlc-*:*)` 等の細粒度 allow への昇格 | `~/.claude/settings.json` |

### MED 7 件 → ask 追加または acknowledgedFindings 登録

| pattern | severity | 対処方法 | 適用先 |
|---------|----------|----------|--------|
| `Bash(git push --force *)` | MED | ask 追加（user-global） | `~/.claude/settings.json` |
| `Bash(git push --force-with-lease *)` | MED | ask 追加（user-global） | `~/.claude/settings.json` |
| `Bash(git tag -d *)` | MED | ask 追加（user-global） | `~/.claude/settings.json` |
| `Bash(gh issue list *)` | MED | acknowledgedFindings 登録 | プロジェクト `.claude/settings.json` |
| `Bash(gh issue view *)` | MED | acknowledgedFindings 登録 | プロジェクト `.claude/settings.json` |
| `Bash(gh pr view *)` | MED | acknowledgedFindings 登録 | プロジェクト `.claude/settings.json` |
| `Bash(git push *)` | MED | acknowledgedFindings 登録（force ガード追加後の残余） | プロジェクト `.claude/settings.json` |
| `Bash(git tag *)` | MED | acknowledgedFindings 登録（-d ガード追加後の残余） | プロジェクト `.claude/settings.json` |

> 注: 上記 MED 8 行は Intent C の「MED 7 件すべて」と数が合わない。Issue #671 本文の MED は 7 件（`gh issue list` / `gh issue view` / `gh pr view` / `git push *` / `git tag *` / `git push --force-with-lease` 系の検出パターン整理）であり、上記対処表は重複検出（`git push *` と `git push --force *` の二重カウント等）を含む。**論理設計フェーズで実際の `--review all` 出力を取得し、9 件の正確な内訳を確定する**。

### responsibility 分離

- **「ask 追加」は user-global** (`~/.claude/settings.json`): 環境横断で危険操作を ask 化したい場合
- **「acknowledgedFindings 登録」はプロジェクト** (`.claude/settings.json`): 当該リポジトリで意図的に許容している pattern を note 付きで記録

`.claude/settings.json` の既存 `permissions.ask` には既に以下が登録済み（force/-d 系の前段ガード）:
- `Bash(git push*--force *)` / `Bash(git push*--force-with-lease *)` / `Bash(git tag*-d *)` / `Bash(git branch*-D *)` / `Bash(git branch*--force *)` / `Bash(git checkout -- *)` / `Bash(git checkout . *)` / `Bash(gh pr merge *)`

これらは **glob 形式が `git push*--force *`** であり、user-global 側に追加する `Bash(git push --force *)`（半角スペース区切り）とは別パターン。プロジェクト側を維持しつつ user-global 側で同等のガードを追加する設計とする（重複は許容、より厳格な側が先にマッチする）。

## 完了条件チェックリスト

完了判定は **2 系統** に分離する:

- **A 系（Unit 完了判定）**: AI が機械的に判定可能な成果物の存在・整合性確認。Unit を「完了」状態に遷移させる前提条件。
- **B 系（Intent 成功基準 C 達成判定）**: 環境適用後の再実行ログによる実測判定。`docs/permissions-audit-v2.5.6.md` §6 の before/after ログを SoT として用いる。

### Phase 1 出力（B 系判定の前提）

Phase 1 論理設計で以下を確定する:

- **検出ベースライン M_baseline**: `--review all` 出力の HIGH/CRITICAL/MED 全エントリを (pattern, severity, scope) の集合として記録。本サイクル時点の 9 件 ± を確定する
- **対処マトリクス M_plan**: M_baseline の各エントリに「ask 追加 (user-global)」「acknowledgedFindings 登録 (project)」「ask 昇格 (細粒度 allow)」のいずれかを 1 つ以上割り当て（`docs/permissions-audit-v2.5.6.md` §2 表形式）

### A 系（Unit 完了判定）

- [ ] **A-1**: `docs/permissions-audit-v2.5.6.md` §1 にベースライン M_baseline、§2 に対処マトリクス M_plan が記載されている
- [ ] **A-2**: `.claude/settings.json` の `suggestPermissions.acknowledgedFindings` セクションに、M_plan で「acknowledgedFindings 登録」割当てされた全エントリが追加されている（pattern / severity / note / acknowledgedAt 必須）。**割当て件数は M_plan 準拠**（固定 7 件等の前提を持たない）
- [ ] **A-3**: `~/.claude/settings.json` への ask 追加手順書（M_plan で「ask 追加」割当てされた全エントリ）が `docs/permissions-audit-v2.5.6.md` §3 に記述されている
- [ ] **A-4**: AskUserQuestion で「適用 / 手順のみ受領 / 中止」を提示し、選択結果を §5 に記録
- [ ] **A-5**: 「中止」選択時を除き、Unit 定義ファイル（`story-artifacts/units/003-permissions-audit-resolution.md`）の「実装状態」を「完了」に更新（中止選択時は「取り下げ」）
- [ ] **A-6**: 履歴ファイル（`history/construction_unit03.md`）に Phase 1 / Phase 2 / 完了処理の進捗を記録

### B 系（Intent 成功基準 C 達成判定）

- [ ] **B-1**: 「適用」選択時、適用後の `/tools:suggest-permissions --review all` 再実行ログを取得し、`docs/permissions-audit-v2.5.6.md` §6 に before/after を表形式で記載
- [ ] **B-2**: 再実行ログの実測判定:
  - HIGH/CRITICAL は **0 件**（必須）— 検出 1 件でも残れば B-2 未達
  - MED は M_plan の各エントリに対応する処理（ask 追加 or acknowledgedFindings 登録）が確認できる（再実行時に MED として残ること自体は acknowledgedFindings 仕様により許容）
  - LOW は対象外
- [ ] **B-3**: B-1 / B-2 達成時のみ Intent 成功基準 C を「達成」と記録
- [ ] **B-4**: 評価順序検証 — 同一 pattern が `permissions.allow` と `acknowledgedFindings` 双方にマッチする場合や、user-global ask とプロジェクト allow が競合する場合の評価順序を before/after ログで実測確認し、`docs/permissions-audit-v2.5.6.md` §2 末尾に「評価順序の実測結果」として記録。**CRITICAL/HIGH の対処は ask 追加を強制優先**（acknowledgedFindings 単独では不可）し、評価順序が想定外（例: ask が後勝ちで実質無効化）と判明した場合は ask 追加分を細粒度 allow への昇格に切り替える代替案を §2 に明記

### B 系未達時の扱い

- 「手順のみ受領」または「中止」選択時 → Intent C は **未達**（保留/繰越）と明記し、`docs/permissions-audit-v2.5.6.md` §5 に理由を記録、follow-up Issue（v2.5.7 等）を起票する
- 「適用」選択後に B-2 が未達（HIGH/CRITICAL 残存等）→ Intent C 未達。残課題を follow-up Issue 起票
- 「適用」選択後に B-4 が未達（評価順序実測の確認失敗、または ask 後勝ちで実質無効化判明）→ Intent C 未達。代替案（細粒度 allow への昇格）を §2 に記録 + follow-up Issue 起票
- A 系のみ達成し B 系未達 = Unit は完了扱いだが Intent C は未達（Operations Phase で繰越判定）

### 状態遷移ルール（AskUserQuestion 2 段階の関係）

ベースライン取得時の AskUserQuestion（第三経路 / 全 Skill 不在時）と環境適用ステップの AskUserQuestion は以下の関係で動作する:

| 第三経路の選択 | 後続フロー |
|---------------|----------|
| 「手動でベースライン記録」 | M_baseline 確定 → Phase 1 / Phase 2 続行 → 環境適用 AskUserQuestion を通常通り実施 |
| 「Unit 003 中止」 | Unit を「取り下げ」に更新（A-5 取り下げ分岐）、follow-up Issue 起票（Intent C 未達）、**環境適用 AskUserQuestion はスキップ**、Construction Phase 内の後続ステップ（コード生成 / レビュー / 完了処理）を打ち切る |

第三経路に到達せず通常経路（第一/第二経路）でベースライン取得できた場合は、環境適用 AskUserQuestion がそのまま入口となる（重複プロンプトなし）。

## 責務分離原則

| レイヤ | 役割 | ファイル |
|--------|------|---------|
| プロジェクト設定 SoT | acknowledgedFindings 登録（重複検出ノイズの note 付き抑制） | `.claude/settings.json` |
| user-global 設定（手順のみ） | CRITICAL/HIGH/MED の ask 追加候補と適用手順 | `docs/permissions-audit-v2.5.6.md`（手順 SoT） |
| 監査記録 SoT | 9 件の対処方針 + 適用結果（before/after ログ）+ ユーザー選択履歴 | `docs/permissions-audit-v2.5.6.md` |
| 履歴 | Unit 進捗（Phase 1 / Phase 2 / 完了処理） | `.aidlc/cycles/v2.5.6/history/construction_unit03.md` |

## 変更対象ファイル

| ファイル | 操作 | 概要 |
|---------|------|------|
| `.claude/settings.json` | 改修（既存 JSON へ `suggestPermissions.acknowledgedFindings` 追加） | MED 系の重複検出を note 付きで抑制 |
| `docs/permissions-audit-v2.5.6.md` | 新規作成 | 対処内容表（9 件分） + ask 追加手順書 + before/after 出力ログ + ユーザー選択結果記録 |
| `.aidlc/cycles/v2.5.6/history/construction_unit03.md` | 新規作成 | Unit 003 の進捗履歴 |

> 編集箇所の正確な diff（`.claude/settings.json` のキー位置 / acknowledgedFindings の各エントリ内容 / docs の章構成）は **論理設計** で確定する。

## 実装計画

### Phase 1（設計）

`depth_level=standard` のため Phase 1 はスキップしない。設計成果物として以下を作成する:

- ドメインモデル（`design-artifacts/domain-models/unit_003_permissions_audit_resolution_domain_model.md`）
  - 用語整理: pattern / severity (CRITICAL/HIGH/MED/LOW) / acknowledgedFindings / ask / allow / scope (user-global / project)
  - 状態遷移: 検出 → 対処方針決定（ask vs acknowledged）→ 設定ファイル変更 → 再実行検証 → 「対処済み」確定
- 論理設計（`design-artifacts/logical-designs/unit_003_permissions_audit_resolution_logical_design.md`）
  - **ベースライン取得手順**:
    1. **第一経路**: 主インターフェース `/tools:suggest-permissions --review all`（Skill 経由 / Skill ツールで起動）で実行し、HIGH/CRITICAL/MED の全エントリを (pattern, severity, scope) として抽出 → M_baseline 確定
    2. **第二経路（Skill 起動失敗時）**: `command -v` 等で Skill 利用可能性を確認し、不可時のみ探索フォールバック。探索は以下の複数候補ルートを順に試行:
       - `~/.claude/plugins/cache/ikeisuke-skills/tools/*/skills/suggest-permissions/scripts/suggest-permissions.py`
       - `~/.claude/skills/tools/suggest-permissions/scripts/suggest-permissions.py`
       - `~/.claude/plugins/skills/suggest-permissions/scripts/suggest-permissions.py`
    3. **第三経路（全不在時）**: ユーザーに「Skill / スクリプト実体不明」を提示し、AskUserQuestion で「手動でベースライン記録 / Unit 003 中止」を選択。手動記録選択時は Issue #671 本文の 9 件をそのまま M_baseline として採用（精度低下を §1 に明記）
  - **対処マトリクス確定**: M_baseline の各エントリに対し「ask 追加 / acknowledgedFindings 登録 / ask 昇格」のいずれかを 1 つ以上割り当て、M_plan として確定（完了条件 A-2 / A-3 の入力となる）
  - **`.claude/settings.json` 変更内容**: `suggestPermissions.acknowledgedFindings` JSON ブロックの完全形（pattern / severity / note / acknowledgedAt のキー設計）
  - **`docs/permissions-audit-v2.5.6.md` 章構成**: §1. 検出ベースライン / §2. 対処方針表 / §3. ask 追加手順（user-global） / §4. acknowledgedFindings 適用結果 / §5. ユーザー選択結果 / §6. before/after 監査ログ
  - **AskUserQuestion 設計**: 「適用 / 手順のみ受領 / 中止」の 3 択、各選択肢の挙動定義
- 設計AIレビュー（`reviewing-construction-design` スキル / codex）

### Phase 2（実装）

1. **コード生成**:
   - `.claude/settings.json` 改修（`suggestPermissions.acknowledgedFindings` 追加）
   - `docs/permissions-audit-v2.5.6.md` 新規作成（§1〜§3 を先行記述）
2. **コード AI レビュー**（`reviewing-construction-code` スキル / codex、`review_mode=required`）
3. **テスト**: 設定ファイル変更後の検証手順
   - `.claude/settings.json` の JSON 構文チェック（`jq . .claude/settings.json`）
   - markdownlint 実行（`docs/permissions-audit-v2.5.6.md`）
4. **ビルド・テスト実行**:
   - JSON syntax OK
   - markdownlint OK
   - `/tools:suggest-permissions --review all` 再実行（プロジェクト側変更後の中間ベースライン）→ 期待結果は MED 件数の減少（acknowledged 仕様で完全消失はしない、note 付き残余は許容）
5. **環境適用ステップ**（AskUserQuestion / 完了条件 A-4 + B 系の入口）:
   - 「適用」選択時: `~/.claude/settings.json` に M_plan の ask 割当てエントリを追加（**ユーザーに直接編集を依頼する形**、AI は編集しない）→ 適用後の再実行ログを `docs/permissions-audit-v2.5.6.md` §6 に追記 → B-1 / B-2 検証 → 達成時 B-3 記録
   - 「手順のみ受領」選択時: §6 に「ユーザー側で適用後に検証」と記録、Unit は A 系達成で完了。Intent C は未達として §5 に記録 + follow-up Issue 起票
   - 「中止」選択時: §5 に中止理由を記録、Unit を「取り下げ」状態に変更（Intent C 未達として follow-up Issue 起票、バックログ繰越）
6. **統合 AI レビュー**（`reviewing-construction-integration` スキル / codex、`review_mode=required`）

### 完了処理

- 完了条件チェック（A-1 〜 A-6 / B-1 〜 B-4）
- Unit 定義ファイル状態更新（→ 完了 または 取り下げ）
- 履歴記録
- markdownlint
- squash + コミット
- コンテキストリセット提示

## リスク・代替案

| リスク | 対応 |
|--------|------|
| `~/.claude/settings.json` への適用失敗（権限不足・ファイル破損） | AI は直接編集せず手順書を提供。ユーザーが手動適用 + before/after ログ取得 |
| `--review all` 出力の 9 件内訳が Issue #671 と異なる | Phase 1 ベースライン取得時に確定。差異がある場合は §1 で明記し、対処方針表を実測値に合わせて更新 |
| acknowledgedFindings の `acknowledgedAt` 日付が古いと再監査時に再検出される懸念 | acknowledgedFindings 仕様上「note 付きで残す」のが既定のため、当面は注記のみ |
| 「中止」選択時の Intent C 未達 | バックログ Issue 起票（v2.5.7 以降での再対応） |

## 見積もり

小〜中。0.5 日想定。
- ベースライン取得: 5 分
- 設計（domain + logical）: 30 分
- `.claude/settings.json` + docs: 30 分
- AI レビュー（設計 / コード / 統合）: 30 分（各 round 数次第）
- 環境適用 + 検証: 15 分
