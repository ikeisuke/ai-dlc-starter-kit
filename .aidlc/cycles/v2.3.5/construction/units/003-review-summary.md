# レビューサマリ: Unit 003 merge-pr `--skip-checks` オプション追加

## 基本情報

- **サイクル**: v2.3.5
- **フェーズ**: Construction
- **対象**: Unit 003 merge-pr `--skip-checks` オプション追加（関連 Issue: #575）

---

## Set 1: 計画レビュー（3 Round）

- **レビュー種別**: 計画（reviewing-construction-plan）
- **使用ツール**: codex
- **反復回数**: 3
- **結論**: Round 3 で指摘 0 件、semi-auto auto_approved

### 指摘一覧

| # | 重要度 | 内容 | 対応 | バックログ |
|---|--------|------|------|-----------|
| 1 | 高 | 現状の `checks_status="unknown"` は `no-checks-configured` と `checks-query-failed` を混在させており、`--skip-checks` の適用範囲が不安全 | 修正済み（計画書: 5 状態モデルに拡張、`no-checks-configured` のみバイパス許可） | - |
| 2 | 中 | ドキュメント責務（`03-release.md` vs `operations-release.md`）が計画で揺れている | 修正済み（計画書「ドキュメント責務の整理」セクション追加、`operations-release.md` 7.13 を正本と確定） | - |
| 3 | 中 | Behavior Contract（案 A / B の二択）が未確定 | 修正済み（計画書で `pass` 経路と同じ `--match-head-commit` 共用に確定） | - |
| 4 | 中 | 内部状態は分離したが外部契約はヒント文面に依存しており、機械可読性が不十分 | 修正済み（計画書: `pr:<N>:reason:<code>` 補助行と `pr:<N>:hint:<text>` 行を契約化、出力順序固定） | - |

---

## Set 2: 設計レビュー（5 Round）

- **レビュー種別**: 設計（reviewing-construction-design）
- **使用ツール**: codex
- **反復回数**: 5
- **結論**: Round 5 で指摘 0 件、semi-auto auto_approved

### 指摘一覧

| # | 重要度 | 内容 | 対応 | バックログ |
|---|--------|------|------|-----------|
| 1 | 高 | `resolve_check_status()` の Bash 実装パターン（stdout/stderr/exit code 取得方式）が未確定のまま実装フェーズに先送りされていた | 修正済み（論理設計: if/else 形式・mktemp + 2>file のパターンを疑似コードで明示、`$()` は `.sh` 内で許容と整理） | - |
| 2 | 中 | exit code 契約（`error:*` すべて exit 1）と `guides/exit-code-convention.md` の規約（外部コマンド失敗は exit 2）が矛盾していた | 修正済み（論理設計: 既存 `pr-ops.sh` 互換のため exit 1 を例外的に維持する旨を明示、将来のバックログ化を記載） | - |
| 3 | 中 | `head_sha` 解決タイミングがドメインモデル（遅延解決）と論理設計（先行解決）で不一致 | 修正済み（ドメインモデル・論理設計・シーケンス図で `check_status` 確定後の `action=merge-now`/`set-auto-merge` のみ解決に統一） | - |
| 4 | 高 | `|| true` の後に `$?` を取得すると常に 0 を拾う誤りが疑似コードに残っていた | 修正済み（論理設計: if/else 形式に置換、`|| true` を禁止パターンとして明示） | - |
| 5 | 中 | シーケンス図で `merge-now` と `set-auto-merge` を同じ分岐にまとめ、戻り値が `pr:N:merged:squash` のみになっていた | 修正済み（分岐を分離、`set-auto-merge` で `pr:N:auto-merge-set:squash` を返すよう修正） | - |
| 6 | 中 | 責務境界表で「マージ実行ドメイン」が `MergeDecision` 生成と実行を二重化していた | 修正済み（決定ドメインを独立レイヤーとして明示、`MergeExecutor` は `MergeDecision` のみ受領） | - |
| 7 | 中 | `trap ... EXIT` を関数内で使う設計はシェル全体に副作用を与えるため危険 | 修正済み（論理設計: `trap EXIT`/`RETURN` 禁止、明示的 `rm -f` に変更） | - |
| 8 | 中 | `PullRequest.buildMergeCommand(decision)` が残っておりコマンド生成責務が二重化 | 修正済み（ドメインモデル: 振る舞いを `resolveHeadSha()` のみに縮退、マージコマンド構築は `MergeExecutor` に一本化） | - |

---

## Set 3: コードレビュー（3 Round）

- **レビュー種別**: コード（reviewing-construction-code）
- **使用ツール**: codex
- **反復回数**: 3
- **結論**: Round 3 で指摘 0 件、semi-auto auto_approved

### 指摘一覧

| # | 重要度 | 内容 | 対応 | バックログ |
|---|--------|------|------|-----------|
| 1 | 高 | `resolve_check_status()` が `checks_ec == 0` を必須条件にしており、pending 時の `gh pr checks` 公式 exit code 8 に対応できず既存 `auto-merge-set` 経路が壊れる（regression） | 修正済み（`skills/aidlc/scripts/pr-ops.sh`: stdout が pass/fail/pending なら exit code に関わらず優先するよう変更、ドメインモデル・論理設計・guide も整合） | - |
| 2 | 低 | 論理設計 FAQ に旧仕様（`checks_ec == 0` かつ `checks_output == "pass"`）の記述が 1 箇所残存 | 修正済み（FAQ 文言を新仕様「`checks_output == "pass"` なら exit code に関わらず `pass`」に更新） | - |

---

## Set 4: 統合レビュー（1 Round）

- **レビュー種別**: 統合（reviewing-construction-integration）
- **使用ツール**: codex
- **反復回数**: 1
- **結論**: Round 1 で指摘 0 件、semi-auto auto_approved

### 指摘一覧

指摘なし（Unit 定義の責務・Intent・Issue #575 要件の完全充足、5 マトリクスセル × 2 フラグ有無 + pending regression を含む 21 件テスト全 PASS を確認）。
