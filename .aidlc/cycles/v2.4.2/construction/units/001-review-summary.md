# レビューサマリ: Unit 001 - aidlc-setup マージ後フォローアップ

## 基本情報

- **サイクル**: v2.4.2
- **フェーズ**: Construction
- **対象**: Unit 001 - aidlc-setup マージ後フォローアップ
- **対象ファイル**:
  - `.aidlc/cycles/v2.4.2/design-artifacts/domain-models/unit_001_setup_merge_followup_domain_model.md`
  - `.aidlc/cycles/v2.4.2/design-artifacts/logical-designs/unit_001_setup_merge_followup_logical_design.md`

---

## Set 1: 2026-04-26（設計レビュー）

- **レビュー種別**: 設計レビュー（Phase 1）
- **使用ツール**: self-review(skill) / general-purpose subagent（Codex usage limit のためフォールバック、`review-routing.md §6` `cli_runtime_error → retry_1_then_user_choice` 経由でユーザー選択）
- **反復回数**: 4（反復1: 15件、反復2: 10件、反復3: 10件、反復4: 0件で承認可能判定）
- **結論**: 指摘対応判断完了（合計 35件 全件「修正する」で対応、4 反復後に構造的・安全性指摘ゼロを確認）

### 反復1 指摘（15件 / 高3 中8 低4）

| # | 重要度 | 内容 | 対応 | バックログ |
|---|--------|------|------|-----------|
| 1 | 高 | HeadStateClassifier の main 系判定で `merge-base --is-ancestor HEAD origin/main` を採用すると、マージ後 `chore/aidlc-v*-upgrade` が origin/main の祖先となり「main 系」と誤判定される | 修正済み（判定基準を `git symbolic-ref --short HEAD == main` に変更） | - |
| 2 | 高 | チェックアウト中ブランチを `git branch -d` / `-D` で削除できない git 制約により、`chore/aidlc-v*-upgrade` チェックアウト中に BranchDeleteFlow が必ず失敗する | 修正済み（実行順序を「マージ確認 → 差分ガード → HEAD 同期 → 一時ブランチ削除」に変更し、HEAD 同期で `chore/...` から離脱した後に削除する設計に確定） | - |
| 3 | 高 | UncommittedDiffGuard が `git status --porcelain` 出力非空を一律「差分あり」扱いとし、untracked のみでも HEAD 同期が中止される過剰反応 | 修正済み（tracked / untracked を `??` プレフィックスで分離判定。untracked のみは注意喚起のみで続行） | - |
| 4 | 中 | BranchDeleteConsent が「同意 / スキップ」の 2 択で、push 権限不在ユーザーがローカル削除のみを選べない | 修正済み（「ローカル+リモート / ローカルのみ / スキップ」の 3 択化、INV-9 追加） | - |
| 5 | 中 | DiffResolution の stash / commit 後に `git status --porcelain` 再検査が無く、ユーザーが解消を忘れたまま HEAD 同期に進むリスク | 修正済み（再検査ループ追加、最大 3 回。後の反復2 で INV-10 として上限不変条件を明示） | - |
| 6 | 中 | INV-4「ff 不可ケースは対象外」が例外規定として大きすぎ、同期失敗時の到達状態が不明瞭 | 修正済み（INV-4 を「同期成功時のみ HEAD == origin/main」に書き直し、S4_sync_aborted で警告通知 + 一時ブランチ削除一律スキップを必須化） | - |
| 7 | 中 | HeadStateClassifier の事前条件として fetch 必要性が暗黙的で、`origin/main` 不在で判定エラー → 例外停止リスク | 修正済み（処理フロー順序を明示。後の反復3 で HeadStateClassifier から fetch 要件を外し HeadSyncFlow 側に集約） | - |
| 8 | 中 | worktree-main 系での `git pull --ff-only` 挙動が論理設計に補足されていない | 修正済み（git の worktree 設計に基づく挙動補足を追加。各 worktree 独立 HEAD のため main repository 側に影響しない旨を明示） | - |
| 9 | 中 | `bin/post-merge-sync.sh` の言及で「`upgrade/` プレフィックス」と「`chore/aidlc-v*-upgrade` プレフィックス」を混同する誤解の余地 | 修正済み（言及を「本 Unit のスコープ外」に簡潔化） | - |
| 10 | 中 | §10 既存構造（サブセクション分割の有無）が論理設計の前提として確認されていない | 修正済み（`steps/03-migrate.md` §10 構造を確認し論理設計に明記） | - |
| 11 | 低 | AskUserQuestion 不採用フォールバック設計の Phase 2 残存有無が不明瞭 | 修正済み（採用確定後 Phase 2 で削除する旨を明示） | - |
| 12 | 低 | `git fetch --prune` の副作用注記文面が論理設計に提示されていない | 修正済み（具体注記文面を実装上の注意事項に追加） | - |
| 13 | 低 | `automation_mode=full_auto` 時の対話必須根拠が論理設計に欠ける | 修正済み（自動化モード適合性節を追加。後の反復3 でフォワード互換要件として位置付け直し） | - |
| 14 | 低 | 処理フローで章番号 §10.2.2 等を直接参照しており (a)/(b) 採用変更時に書き換え必要 | 修正済み（章番号非依存の記述に統一） | - |
| 15 | 低 | バージョン番号取得方法（`git branch --list` パース vs 既存変数）の選定基準が曖昧 | 修正済み（§9 までで判明した既存コンテキスト変数からの流用に確定） | - |

### 反復2 指摘（10件 / 高1 中5 低4）

| # | 重要度 | 内容 | 対応 | バックログ |
|---|--------|------|------|-----------|
| 1 | 高 | plan の実行順序（BranchDelete → DiffGuard → HeadSync）と設計の実行順序（DiffGuard → HeadSync → BranchDelete）が逆転 | 修正済み（plan の §実行順序セクションを設計と同期更新） | - |
| 2 | 中 | 再検査ループ最大 3 回のカウンタ管理が状態遷移に不変条件として未定義 | 修正済み（INV-10 として「カウンタは AI エージェント内部保持」と明示） | - |
| 3 | 中 | `#### マージ後フォローアップ` の §10 内配置位置（メッセージ前段 / 後段）が曖昧 | 修正済み（メッセージブロックの「前段」に挿入する旨を論理設計に明記） | - |
| 4 | 中 | aidlc-setup が `automation_mode` を参照しているか未確認 | 修正済み（SKILL.md / steps/03-migrate.md とも未参照を確認、INV-7 をフォワード互換要件として位置付け直し） | - |
| 5 | 中 | フィーチャ系で `git checkout --detach origin/main` により detached 化される副作用の通知不足 | 修正済み（SyncConsent description に副作用説明を追加） | - |
| 6 | 中 | ff 不可時の divergence 確認手順（`git log --oneline HEAD..origin/main` 等）が未提示 | 修正済み（警告メッセージ文面に divergence 確認コマンドを追加） | - |
| 7 | 低 | `<version>` プレースホルダの実体化タイミング（手順書 Markdown レベル / 実行時展開）が曖昧 | 修正済み（手順書 Markdown 上はプレースホルダで記述し、AI エージェントが実行時に展開する旨を明示） | - |
| 8 | 低 | post-merge-sync.sh との機能重複への注意喚起なし | 修正済み（外部エンティティ節に機能重複の可能性を追記。反復3 で前提を限定） | - |
| 9 | 低 | S5_branch_local の説明に「設計レビュー一次案」表記が残存 | 修正済み（「Phase 1 設計レビューで確定済み」に書き換え） | - |
| 10 | 低 | ドメインモデル単独で 5 サブ条件マトリクス判定順序が追跡困難 | 修正済み（ユビキタス言語節に判定順序を明記） | - |

### 反復3 指摘（10件 / 高0 中4 低6）

| # | 重要度 | 内容 | 対応 | バックログ |
|---|--------|------|------|-----------|
| 1 | 中 | 状態遷移テキストの S5_branch_local_fallback → S5_branch_remote 経路に「リモート同意あり」条件が欠落 | 修正済み（テキスト状態遷移を Mermaid 図と整合させ、リモート同意 / ローカルのみ分岐を明示） | - |
| 2 | 中 | INV-1（オプトイン保証）と AI 代理実行（stash/commit）の境界が曖昧 | 修正済み（INV-1 に「DiffResolution の stash/commit 選択は同意とみなす」境界を追記） | - |
| 3 | 中 | 再検査ループ 3 回上限の手順書表現方法が論理設計に未明記 | 修正済み（保守性節に「最大 3 回まで再検査します」の手順書注記方法を明記） | - |
| 4 | 中 | 5 サブ条件マトリクスの各サブ条件への到達現実性（典型 / 異常 / レア）が不明 | 修正済み（マトリクスに「到達現実性」列を追加） | - |
| 5 | 低 | post-merge-sync.sh 機能重複の前提（利用者環境 vs メタ開発リポジトリ）が広すぎる | 修正済み（メタ開発リポジトリのみ並行存在の前提に限定） | - |
| 6 | 低 | worktree フィーチャ系の checkout で untracked ファイル衝突リスクが「非破壊」ラベルに反映されていない | 修正済み（git checkout が衝突検知時失敗で安全側停止する旨を補足） | - |
| 7 | 低 | HeadStateClassifier の事前条件に fetch 要件が含まれているが、責務として origin/main 参照しない | 修正済み（HeadStateClassifier から fetch 要件を外し HeadSyncFlow 側に集約） | - |
| 8 | 低 | S5_branch_local の説明とフォールバック動作の責務境界が曖昧 | 修正済み（S5_branch_local は `-d` 実行のみを責務、フォールバックは S5_branch_local_fallback に集約） | - |
| 9 | 低 | 自動化モード適合性節の見出しが「現状要件」と誤読される | 修正済み（見出しを「フォワード互換要件」に変更） | - |
| 10 | 低 | ASCII ツリーの記号と ASCII 記号の意図が一部混乱 | 修正済み（メッセージブロックの「前段」配置を本文で明示） | - |

### 反復4 指摘（0件、最終確認）

| # | 重要度 | 内容 | 対応 | バックログ |
|---|--------|------|------|-----------|
| - | - | 構造的・安全性観点での指摘なし。設計は承認可能（高 = 0、中 = 0） | - | - |

### 構造化シグナル

- `review_detected`: true（反復1〜3で計 35件検出）
- `deferred_count`: 0
- `resolved_count`: 35
- `unresolved_count`: 0
- `auto_approved`: 該当（フォールバック条件非該当）

### フォールバック発生（参考）

外部 CLI（codex）が usage limit（次回リセット 2026-04-29 07:56）のため利用不可。`review-routing.md §6` の `cli_runtime_error → retry_1_then_user_choice` に従い、ユーザー選択でセルフレビュー（パス2、general-purpose subagent）にフォールバック。

---

## Set 2: 2026-04-26（コードレビュー）

- **レビュー種別**: コードレビュー（Phase 2 / focus: code, security）
- **使用ツール**: self-review(skill) / general-purpose subagent（codex usage limit 継続のためフォールバック）
- **反復回数**: 2（反復1: 8件、反復2: 0件で承認可能判定）
- **結論**: 指摘対応判断完了（合計 8件 全件「修正する」で対応）

### 指摘一覧（反復1: 8件 / 高1 中3 低4）

| # | 重要度 | 内容 | 対応 | バックログ |
|---|--------|------|------|-----------|
| 1 | 高 | plan / Unit 定義 §責務の順序記述が旧順序のまま追従漏れ（設計は新順序「マージ確認 → 差分 → HEAD 同期 → ブランチ削除」で確定済み） | 修正済み（plan §完了条件 + Unit 定義 §責務 を新順序に同期更新） | - |
| 2 | 中 | bash code block コメントに worktree 判定の解釈ルール（`--git-common-dir` != `--git-dir` → worktree）が欠落 | 修正済み（手順書 bash コメントに worktree 判定説明を追記） | - |
| 3 | 中 | 再検査ループ「3 回到達時は中止扱い」が実装詳細を露出（INV-10 と整合させる必要） | 修正済み（手順書記述を「解消が見込めない場合は中止扱いで離脱」 + 「カウンタは AI エージェント内部管理」に変更） | - |
| 4 | 低 | AskUserQuestion の `header` 値（5 種）が手順書から欠落 | 修正済み（5 箇所すべてに `header: "..."` 指定を追記） | - |
| 5 | 低 | BranchDeleteConsent の `description` 記述粒度（push 権限不在ユーザー向け説明）が手順書に未明示 | 修正済み（手順書 3 択テーブルに description 列を追加） | - |
| 6 | 中 | `git stash push -u` の untracked 巻き込みリスク（untracked 続行設計と整合せず） | 修正済み（`git stash push`（tracked のみ退避）に変更し `-u` 不採用理由を明示） | - |
| 7 | 低 | `git add -A && git commit` がエディタ起動を伴うため非対話実行不可 | 修正済み（`git commit -m "<message>"` 形式に修正、エディタ起動回避を明記） | - |
| 8 | 低 | "exit 0 相当" 表現が AI エージェント / ユーザーへの指示として曖昧 | 修正済み（「フローは中断せず継続する（後続ステップは「アップグレード完了メッセージ」へ進むのみ）」に書き換え） | - |

### 反復2 指摘（0件、承認可能）

| # | 重要度 | 内容 | 対応 | バックログ |
|---|--------|------|------|-----------|
| - | - | 構造的・安全性観点での指摘なし。コードは承認可能 | - | - |

### 構造化シグナル（Set 2）

- `review_detected`: true（反復1で 8件検出）
- `deferred_count`: 0
- `resolved_count`: 8
- `unresolved_count`: 0
- `auto_approved`: 該当（フォールバック条件非該当）

### Self-Healing 発生（参考）

ビルド・テスト実行（markdownlint）で 3 件のエラーを検出。Self-Healing attempt 1/3 で recoverable 分類のため自動修正:

- 失敗要因: テーブルセル内の `|` 文字が code span 内でも区切り解釈され、列数不一致 + spaces in code span 検出
- 修正内容: テーブルセル内の `git branch -d|-D` 表記を `git branch -d` / `-D` に分離してパイプ文字を排除

attempt 1 で markdownlint 0 error 達成、ビルド・テスト実行 PASS。

---

## Set 3: 2026-04-26（統合レビュー）

- **レビュー種別**: 統合レビュー（Phase 2 / focus: code）
- **使用ツール**: self-review(skill) / general-purpose subagent（codex usage limit 継続のためフォールバック）
- **反復回数**: 1（指摘0件で承認可能判定）
- **結論**: 指摘0件（統合は構造的・実施状況観点で承認可能）

### 検証観点

1. **設計乖離確認**: ドメインモデル / 論理設計と実装手順書の整合性確認 → ✓ 完全整合（INV-1〜INV-10 全 10 件、状態遷移 S0〜S6、5 サブ条件マトリクス、AskUserQuestion 5 種すべて手順書に反映済み）
2. **レビュー・テスト実施確認**:
   - 計画 AI レビュー: 反復2 で承認可能（unresolved_count=0）
   - 設計 AI レビュー: 反復4 で承認可能（unresolved_count=0）
   - コード AI レビュー: 反復2 で承認可能（unresolved_count=0）
   - 手順書 walkthrough: 001-test-walkthrough.md で完了条件 16 項目 / INV 10 件 / AskUserQuestion 5 種 / 5 サブ条件マトリクスをセル単位照合済み
   - markdownlint: Self-Healing attempt 1 で 0 error 達成
3. **完了条件チェック**: 機能要件 12 項目 + Issue 終了条件 4 項目 + Unit 定義 §責務 4 項目 すべて手順書に反映済み

### 構造化シグナル（Set 3）

- `review_detected`: false
- `deferred_count`: 0
- `resolved_count`: 0
- `unresolved_count`: 0
- `auto_approved`: 該当
