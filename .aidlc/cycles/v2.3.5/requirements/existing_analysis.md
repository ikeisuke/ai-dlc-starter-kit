# 既存コードベース分析

## ディレクトリ構造・ファイル構成

```
skills/aidlc/
├── SKILL.md                           # メインオーケストレータースキル
├── version.txt                        # スキルバージョン (2.3.4 → 2.3.5 へ更新)
├── config/
│   └── defaults.toml                  # デフォルト設定値
├── steps/
│   ├── common/                        # 全フェーズ共通
│   │   ├── preflight.md
│   │   ├── rules-core.md
│   │   ├── rules-automation.md
│   │   ├── phase-recovery-spec.md     # ← #579 更新対象（5.3 Operations判定仕様）
│   │   ├── review-flow.md
│   │   └── ...
│   ├── inception/
│   ├── construction/                  # ← #574 (3) 更新対象（squash完了後の案内）
│   └── operations/                    # ← #579, #574, #575 修正対象
│       ├── index.md                   # ← #579 更新対象（チェックポイント表）
│       ├── 01-setup.md                # ← #574 (2) 更新対象（diverged 分岐）
│       ├── 02-deploy.md
│       ├── 03-release.md              # ← #575 (c) 更新対象（前提条件記載）
│       └── 04-completion.md
├── scripts/
│   ├── operations-release.sh          # ← #574 (1)(2), #575 (a)(b) 修正対象
│   └── ...
├── templates/
│   └── operations_progress_template.md  # ← #579 更新対象（サブステップフラグ）
└── guides/                            # ← #575 (c) 追加対象（merge-pr 挙動サマリ）
```

## アーキテクチャ・パターン

- **スキルプラグイン構成**: `skills/aidlc/` 配下にスキルリソースを集約（v2.0.5以降）
- **フェーズインデックスパターン**: 各フェーズに `index.md` を持ち、分岐ロジック・チェックポイント・ステップ読み込み契約を一元管理
- **Materialized Binding**: `phase-recovery-spec.md` の規範仕様をフェーズインデックスに具象化
- **復帰判定の参照責務分離**: `RecoveryJudgmentService.judge()` が唯一の公開 API、`PhaseResolver` → フェーズ別 `StepResolver` の順で評価

## 技術スタック

| 項目 | 値 | 根拠ファイル |
|------|-----|-------------|
| 言語 | Bash, Markdown | scripts/*.sh, steps/**/*.md |
| 設定形式 | TOML | .aidlc/config.toml, config/defaults.toml |
| CLIツール | gh, dasel, codex | scripts/env-info.sh |
| パッケージャ | プラグインマーケットプレイス（Claude Code） | - |

## 依存関係

- SKILL.md → steps/common/*.md → steps/{phase}/*.md（ステップ読み込み契約経由）
- steps/common/preflight.md → scripts/read-config.sh, scripts/env-info.sh
- steps/operations/03-release.md → scripts/operations-release.sh（`verify-git` / `merge-pr`）
- steps/common/phase-recovery-spec.md §5.3 → steps/operations/index.md §3（Materialized Binding）
- templates/operations_progress_template.md → サイクル生成時に scripts/init-cycle-dir.sh から参照

## 特記事項

### #579: Operations 復帰判定の現状

- **チェックポイント**: `steps/operations/index.md` §3 に `release_done` / `completion_done` が定義されており、`history/operations.md` の「PR Ready化」「PRマージ」記録を参照している
- **履歴追記のタイミング**: `steps/operations/03-release.md` のステップ 7.4 が唯一の正規タイミング。7.8 / 7.13 は本来履歴追記を行わない設計
- **問題の発生経路**: AIエージェントが復帰判定の参照先（history.md）を認識しているため、「7.8 / 7.13 後に history に記録したほうがよい」と誤判断する → worktree に未コミット変更が残る
- **修正範囲**: `phase-recovery-spec.md` §5.3 / `steps/operations/index.md` §3 / `templates/operations_progress_template.md` / 復帰判定を呼び出す `compaction.md` / `session-continuity.md` の参照整合

### #574: リモート同期チェックの現状

- **実装**: `scripts/operations-release.sh verify-git` の `remote-sync` サブルーチンで実装
- **問題箇所**: `git rev-list HEAD..@{u} --count` の結果を behind としてカウント。squash 後の履歴書き換えでリモートに未マージの中間コミットが残るため、誤検知が発生
- **修正範囲**: `scripts/operations-release.sh`（検出ロジック）/ `steps/operations/01-setup.md`（diverged 分岐）/ `steps/construction/**`（squash 完了後の案内）

### #575: merge-pr サブコマンドの現状

- **実装**: `scripts/operations-release.sh merge-pr` サブコマンド
- **問題箇所**: `gh pr checks` 出力を検証する際、`no checks reported`（CIチェック未設定）が `checks-status-unknown` として扱われ、エラー終了する
- **修正範囲**: `scripts/operations-release.sh`（`--skip-checks` オプション追加、エラーメッセージ改善）/ `steps/operations/03-release.md`（前提条件記載）/ `skills/aidlc/guides/`（挙動サマリ新規追加）

### 既存サイクル互換性の担保方針

- v2.3.4 以前のサイクルは新形式の `operations/progress.md` を持たないため、復帰判定の実装では「新形式キー不在なら旧ロジック（history.md 参照）にフォールバック」する設計とする
- 旧サイクルの実ファイルへの遡及変更は行わない（読み取り時の互換性のみ担保）
