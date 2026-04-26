# ユーザーストーリー

## Epic: setup/migrate アップグレードフロー後の整備（#607 / #605）

### ストーリー 1: アップグレード一時ブランチの自動削除案内

**優先順位**: Must-have

As a メタ開発者 / AI-DLC 利用者
I want to `/aidlc-setup` または `/aidlc-migrate` でアップグレードした後、`chore/aidlc-v*-upgrade` 一時ブランチをワンステップで削除できるよう案内されたい
So that 次サイクル開始時の `git branch` 出力ノイズや手動削除負荷をなくし、安心して次フェーズに進める

**受け入れ基準**:

- [ ] `/aidlc-setup` の最終ステップ（`steps/03-migrate.md` §9 以降または新規節）に「マージ確認 → ローカル / リモート一時ブランチ削除案内」が明示記載されている
- [ ] `/aidlc-migrate` の最終ステップ（`steps/03-verify.md` 末尾相当）に同等の削除案内が記載されている
- [ ] 案内には「PR をマージしましたか？」確認と「削除する / スキップ」の 2 択を含むユーザー対話手順が含まれる（`automation_mode` 非依存のユーザー選択扱い、具体的な提示方法は Construction Phase で確定）
- [ ] 削除実行時のコマンドは `git branch -d chore/aidlc-v<version>-upgrade` および `git push origin --delete chore/aidlc-v<version>-upgrade`（後者は失敗時 warning 表示で続行）
- [ ] 削除完了後、`git branch --list 'chore/aidlc-v*-upgrade'` が空になる。リモート削除が成功した場合は `git ls-remote --heads origin 'chore/aidlc-v*-upgrade'` も空になる
- [ ] リモート push 権限不足ケース: ローカル削除は成功し、リモートは `git ls-remote --heads origin 'chore/aidlc-v*-upgrade'` に残置する。warning 出力後、exit 0 で継続する
- [ ] スキップ選択時はローカル/リモートいずれも変更されず、警告のみ出して継続
- [ ] PR が未マージのまま削除案内が誤発火しないよう、ユーザー確認の前に「マージ確認」が前置される

**技術的考慮事項**:

- ユーザー対話 UI は `AskUserQuestion` 利用が有力候補だが、Construction Phase の設計レビューで確定（Intent §「不明点と質問」Q3 の方針準拠）
- リモート削除に push 権限がない場合のフォールバック: 失敗時は warning 出力のみで非中断（exit 0）。push 権限有無の判定は `git push origin --delete` の終了コードで実施（事前に `git ls-remote` で疎通確認するかは Construction で確定）
- `bin/post-merge-sync.sh` は `cycle/` + `upgrade/` 対応で `chore/aidlc-v*-upgrade` 非対応のため流用しない（Intent 制約準拠）
- 既存の setup/migrate フローを破壊しないため、削除案内は最終ステップで独立配置する
- **Unit 統合候補**: ストーリー2（HEAD 同期）の「マージ確認 UI」と本ストーリーの「マージ確認」は同一 setup フロー内で重複する。Construction Phase の Unit 設計レビュー（Intent §「Unit 構成（予定）」A 案 vs B 案）で A 案を採用した場合、マージ確認は 1 回に統合され、削除案内 → HEAD 同期案内の順で連続提示する想定。B 案採用時は別フローで独立配置

---

### ストーリー 2: アップグレード後の HEAD 自動同期

**優先順位**: Must-have

As a メタ開発者
I want to `/aidlc-setup` でアップグレードした後、PR マージ済みなら同意ベースで HEAD を `origin/main` 最新に自動同期してほしい
So that 次の Inception Phase 開始時にブランチベースが古い・枝分かれするリスクを排除し、手動で `git fetch` → `git checkout --detach origin/main` → `git branch -d` を打たずに済ませたい

**受け入れ基準**:

- [ ] `/aidlc-setup` のコミット後ステップに「PR マージ済みなら HEAD 同期しますか？」確認手順が追加されている（具体的な対話 UI 実装は Construction Phase で確定）
- [ ] 同意時は `git fetch origin --prune` を実行する
- [ ] 現在のブランチ状態（worktree / 通常ブランチ / detached HEAD）に応じて 3 ケース分岐し、同期完了後に以下が成立する:
  - 通常ブランチ: `git rev-parse HEAD == git rev-parse origin/main`
  - detached HEAD: `git rev-parse HEAD == git rev-parse origin/main`
  - worktree: 当該 worktree のチェックアウト位置が `origin/main` と一致（`git -C <worktree-path> rev-parse HEAD == git rev-parse origin/main`、親リポジトリ HEAD ではなく worktree のチェックアウト位置を観測）
- [ ] 未コミット差分がある場合は同期を中断し「未コミット差分があります。stash / commit / 中止のいずれかを選んでください」と案内する
- [ ] スキップ選択時は HEAD 状態を変更しない
- [ ] アップグレード以外の用途（通常 setup）でも誤発火しないよう、PR マージ確認をガードに置く

**技術的考慮事項**:

- 具体的な git コマンド系列（`git pull --ff-only` / `git checkout --detach origin/main` / `git reset --hard origin/main` 等）は Construction Phase の設計レビューで決定（Intent §「#605 の解決方針」outcome 固定方針）
- worktree の場合は detach 化でなく worktree のチェックアウト位置調整を選択（既存 worktree 運用との整合）
- マージ済み自動検出（`gh pr view --json state`）は本サイクルではスコープ外
- 強制継続オプション（未コミット差分ありでも同期を強行）の是非は Construction Phase の設計レビューで判断
- **マージ確認 UI 統合**: ストーリー1の「マージ確認」と本ストーリーの「PR マージ済み確認」は同一 setup フロー内で重複しうるため、Construction Phase の Unit 設計レビューで A 案（統合）採用時は 1 回のマージ確認 + 連続案内（削除 → 同期）に統合する想定

---

## Epic: Operations 手順書 / progress.md テンプレート明文化（#591 / #585）

### ストーリー 3: Operations 手順書の固定スロット明文化

**優先順位**: Must-have

As a Operations Phase 実施者（AI / 人間）
I want to `operations-release.md §7.2-§7.6` および `02-deploy.md §7` で固定スロット配置位置・行区切り規約・状態ラベル・コミット対象が明文化されていてほしい
So that subagent 間 / 人間間で出力差分が小さくなり、empirical-prompt-tuning で検出された 8 件の不明瞭点を解消できる

**受け入れ基準**:

- [ ] `skills/aidlc/steps/operations/operations-release.md §7.2-§7.6` に [P1] 最小完成例 inline（固定スロット 3 行を `## 固定スロット（Operations 復帰判定用）` セクションへ追記する具体例コードブロック、ストーリー4で同梱されるテンプレートと同じセクション名）が記載されている
- [ ] [P3] 状態ラベル 5 値（`未着手` / `進行中` / `完了` / `スキップ` / `PR準備完了`）が `02-deploy.md §7` 冒頭または注記に列挙されている
- [ ] [P4] §7.7 コミット対象ファイル列挙が `skills/aidlc/steps/operations/operations-release.md §7.7`（同セクション内の追記）に追加されている（`operations/progress.md` / `history/operations.md` / `README.md` / `CHANGELOG.md`（`rules.release.changelog=true` の場合のみ）/ `version.txt` / `.aidlc/config.toml`（`bin/update-version.sh` で更新した場合のみ）/ markdownlint 修正ファイル等）。`02-deploy.md §7.7` には誘導注記「詳細は **[必読] operations-release.md §7.7**」を残す
- [ ] 固定スロットの行区切り規約（改行区切り、Markdown リスト形式 `- key=value` ではなく独立行）が明示されている
- [ ] §7.2 CHANGELOG が `rules.release.changelog` 設定により条件分岐する旨が確認手順とともに記載されている
- [ ] 既存サイクル（v2.4.1 以前）の Operations Phase progress.md フォーマットに対する後方互換性が維持されている（強制移行なし、v2.4.1 以前の progress.md 形式（固定スロット欠如）を読み込んだ場合は既存形式継続でエラー扱いしない旨が手順書に明記）

**技術的考慮事項**:

- 手順書修正は文章のみで実装ロジックには影響しないため、回帰リスクは限定的
- empirical-prompt-tuning の 8 件指摘のうち本サイクルで解消するのは [P1] / [P2] / [P3] / [P4] の 4 件。残る 4 件（CHANGELOG 設定値確認手順 / 既存 progress.md 判定 / CHANGELOG 該当なし判定 / 設定依存判定）は文章補強で同時カバーする想定

---

### ストーリー 4: progress.md テンプレートへの固定スロット同梱

**優先順位**: Must-have

As a Operations Phase 開始者（AI）
I want to `operations_progress_template.md` を初期化した時点で固定スロット 3 種（`release_gate_ready` / `completion_gate_ready` / `pr_number`）が同梱されていてほしい
So that 各サイクルの初回テンプレート展開で裁量補完（独自セクション名・配置位置の不統一）を発生させず、同期判定 / 復帰判定の構造化シグナルがすぐに利用可能になる

> **Unit 統合に関する補足**: 本ストーリーは受け入れ基準上ストーリー3と独立しているが、Intent §「#591 / #585 の解決方針」に従い Construction Phase では同一 Unit（#591+#585 統合 Unit）で実装される。INVEST の Independent はストーリー単位で成立し、Unit 統合は実装効率上の選択（重複作業を避けるため）である。

**受け入れ基準**:

- [ ] `skills/aidlc/templates/operations_progress_template.md` に `## 固定スロット（Operations 復帰判定用）` セクションが新設されている
- [ ] 固定スロット 3 種（`release_gate_ready=` / `completion_gate_ready=` / `pr_number=`）が初期値空の `key=value` 形式で同梱されている
- [ ] `<!-- fixed-slot-grammar: v1 -->` コメントが固定スロットセクション直前または冒頭に付与されている
- [ ] 既存サイクルが古いテンプレートで初期化済みの場合、本サイクルでの強制移行は行わない（テンプレートはサイクル初期化時のみ展開され、既存サイクルの `operations/progress.md` がテンプレート更新後に上書きされない旨が確認できる）

**技術的考慮事項**:

- grammar は `phase-recovery-spec.md §5.3.5`（`key=value` 形式）に準拠
- ストーリー 3（手順書明文化）の [P2] と完全に重複するスコープのため、Unit 統合で重複作業を回避

---

## 受け入れ基準のチェック観点（自己検査）

| ストーリー | 具体性 | 検証可能性 | 完全性 | 独立性 |
|-----------|-------|-----------|-------|-------|
| 1（一時ブランチ削除） | ◎ git コマンド明示 | ◎ git branch / ls-remote で検証可 | ◎ 同意/スキップ/権限なし全分岐 | ◎ ストーリー2と独立、共通フローで実装可 |
| 2（HEAD 同期） | ◎ rev-parse 一致を観測条件化 | ◎ git rev-parse で検証可 | ◎ 3ケース + 未コミット差分 | ◎ ストーリー1の後続ステップ |
| 3（手順書明文化） | ◎ [P1]-[P4] 各項目に対応する具体的な記載要件 | ◎ ファイル grep / 目視で検証可 | ◎ 8件指摘のうち4件 + 補強4件 | ◎ ストーリー1/2と独立 |
| 4（template 固定スロット） | ◎ key=value 3種を初期値空で明示 | ◎ ファイル diff で検証可 | ◎ grammar コメント含む | △ ストーリー3 [P2] と重複、Unit 統合で解決 |
