# ユーザーストーリー

## Epic: AI-DLCスターターキット v1.13.2 パッチリリース

### ストーリー 1: init-label処理の修正 (#169)
**優先順位**: Must-have

As a AI-DLCスターターキット利用者（Issue駆動モード）
I want to セットアップ・アップグレード時に自動的にラベルが初期化される
So that 手動でラベルを作成する必要がなくなる

**受け入れ基準**:
- [ ] `prompts/setup-prompt.md` の初回セットアップフロー（8.2.6節）で `docs/aidlc/bin/init-labels.sh` が呼び出される
- [ ] `prompts/setup-prompt.md` のアップグレードフロー（8.2.6節）で `docs/aidlc/bin/init-labels.sh` が呼び出される
- [ ] 既存ラベルは上書きされずスキップされる（出力に `label:xxx:exists` が表示される）
- [ ] `prompts/package/bin/init-labels.sh` が存在し、rsync同期で `docs/aidlc/bin/init-labels.sh` にコピーされる

**技術的考慮事項**:
- 変更対象: `prompts/setup-prompt.md`
- `docs/aidlc.toml` の `[backlog].mode` が `issue` または `issue-only` の場合のみ実行

---

### ストーリー 2: backlogディレクトリ作成の条件分岐 (#162)
**優先順位**: Must-have

As a AI-DLCスターターキット利用者（Issue駆動モード）
I want to サイクル初期化時に不要なbacklogディレクトリが作成されない
So that リポジトリに不要なディレクトリが残らない

**受け入れ基準**:
- [ ] `backlog.mode=issue` で `init-cycle-dir.sh` を実行すると、`docs/cycles/backlog/` が作成されない
- [ ] `backlog.mode=issue-only` で `init-cycle-dir.sh` を実行すると、`docs/cycles/backlog/` が作成されない
- [ ] `backlog.mode=git` で `init-cycle-dir.sh` を実行すると、`docs/cycles/backlog/` が作成される
- [ ] Issue駆動モード時の出力に `dir:docs/cycles/backlog:skipped-issue-mode` が表示される

**技術的考慮事項**:
- 変更対象: `prompts/package/bin/init-cycle-dir.sh`
- 現在は `issue-only` のみスキップ、`issue` も追加する

---

### ストーリー 3: operations.md行数削減 (#172)
**優先順位**: Should-have

As a AI-DLCスターターキット開発者
I want to operations.mdが1,000行以下に削減される
So that ファイルの可読性と保守性が向上する

**受け入れ基準**:
- [ ] `wc -l prompts/package/prompts/operations.md` の結果が1,000以下
- [ ] AIレビューフローは既存の `prompts/package/prompts/common/review-flow.md` を参照する形に変更される
- [ ] operations.mdに「`docs/aidlc/prompts/common/review-flow.md` を読み込んでください」の指示が記載される

**技術的考慮事項**:
- 変更対象: `prompts/package/prompts/operations.md`
- 活用対象: 既存の `prompts/package/prompts/common/review-flow.md`（AIレビューフロー）
- 注意: セルフアップデート処理は `rules.md` にあり、operations.md には含まれない

---

### ストーリー 4: コンパクション時のプロンプト読み込み (#170)
**優先順位**: Should-have

As a AI-DLC利用者
I want to コンテキストがコンパクション（自動要約）された後も、フェーズのルールと手順が維持される
So that 長時間の作業でもAIの応答品質が低下しない

**受け入れ基準**:
- [ ] `prompts/package/prompts/inception.md` の「コンテキストリセット対応」セクションに「コンパクション時は本ファイルを再読み込み」の指示が追加される
- [ ] `prompts/package/prompts/construction.md` の「コンテキストリセット対応」セクションに同様の指示が追加される
- [ ] `prompts/package/prompts/operations.md` の「コンテキストリセット対応」セクションに同様の指示が追加される
- [ ] `prompts/package/templates/progress_inception_template.md` に「再開時に読み込むファイル」セクションが追加される
- [ ] `prompts/package/templates/progress_construction_template.md` に「再開時に読み込むファイル」セクションが追加される

**技術的考慮事項**:
- 変更対象: `prompts/package/prompts/inception.md`, `construction.md`, `operations.md`
- 変更対象: `prompts/package/templates/progress_*_template.md`
- 「コンテキストリセット対応」セクションの拡張

---

### ストーリー 5: セルフアップデート処理の簡略化
**優先順位**: Should-have

As a AI-DLCスターターキット開発者（メタ開発）
I want to Operations Phaseのセルフアップデート処理がスキル呼び出しで完結する
So that rules.mdの記述が簡潔になり、手順の一貫性が保たれる

**受け入れ基準**:
- [ ] `docs/cycles/rules.md` のカスタムワークフロー（Operations Phase完了時の必須作業）が「`/aidlc-upgrade` を実行」に簡略化される
- [ ] `/aidlc-upgrade` スキル実行により、「`prompts/setup-prompt.md` を読み込んでください」というメッセージが表示される
- [ ] `docs/aidlc/skills/aidlc-upgrade/SKILL.md` が存在する（前提条件確認）

**技術的考慮事項**:
- 変更対象: `docs/cycles/rules.md`（プロジェクト固有のカスタムワークフロー）
- 前提: `aidlc-upgrade` スキルが既に存在
- 注意: `prompts/package/prompts/operations.md` は汎用手順のため変更不要

---

### ストーリー 6: setup-branch.shのプレリリースバージョン対応
**優先順位**: Must-have

As a AI-DLCスターターキット利用者
I want to プレリリースバージョン（v2.0.0-alpha.9など）でもブランチを作成できる
So that アルファ版やベータ版のサイクルでも正常にワークフローを開始できる

**受け入れ基準**:
- [ ] `setup-branch.sh v2.0.0-alpha.9 branch` 実行時に `status:success` が出力される
- [ ] `setup-branch.sh v1.13.2-beta.1 worktree` 実行時に `status:success` が出力される
- [ ] `setup-branch.sh v1.0.0-rc.1 branch` 実行時に `status:success` が出力される
- [ ] 既存の `setup-branch.sh v1.13.2 branch` は引き続き動作する（`status:success` 出力）

**技術的考慮事項**:
- 変更対象: `prompts/package/bin/setup-branch.sh`
- バージョン検証正規表現の修正: `^v[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.]+)?$` 等

---

### ストーリー 7: setup-context.md機能の廃止
**優先順位**: Should-have

As a AI-DLCスターターキット開発者
I want to setup-context.md機能が廃止される
So that SetupとInception統合後の不要な機能が整理され、プロンプトがシンプルになる

**受け入れ基準**:
- [ ] `prompts/package/prompts/inception.md` から `setup-context.md` 作成・読み込みに関する記述が削除される
- [ ] `prompts/package/templates/setup_context_template.md` が削除される
- [ ] サイクル初期化時に `docs/cycles/{cycle}/requirements/setup-context.md` が作成されない

**技術的考慮事項**:
- 変更対象: `prompts/package/prompts/inception.md`
- 削除対象: `prompts/package/templates/setup_context_template.md`
- 背景: SetupとInceptionが統合されたため、引き継ぎ用ファイルは不要

---

## 受け入れ基準のチェック観点

| チェック項目 | US1 | US2 | US3 | US4 | US5 | US6 | US7 |
|-------------|-----|-----|-----|-----|-----|-----|-----|
| 具体性 | OK | OK | OK | OK | OK | OK | OK |
| 検証可能性 | OK | OK | OK | OK | OK | OK | OK |
| 完全性 | OK | OK | OK | OK | OK | OK | OK |
| 独立性 | OK | OK | OK | OK | OK | OK | OK |

**補足**:
- US5は `docs/cycles/rules.md`（プロジェクト固有）の変更であり、US3（operations.md行数削減）とは独立
- US7は `prompts/package/prompts/inception.md` と `prompts/package/templates/setup_context_template.md` の変更
- 各ストーリーは単独で完了可能
