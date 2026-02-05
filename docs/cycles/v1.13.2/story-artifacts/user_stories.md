# ユーザーストーリー

## Epic: AI-DLCスターターキット v1.13.2 パッチリリース

### ストーリー 1: init-label処理の修正 (#169)
**優先順位**: Must-have

As a AI-DLCスターターキット利用者
I want to アップグレード時にも自動的にラベルが初期化される
So that 手動でラベルを作成する必要がなくなる

**受け入れ基準**:
- [ ] アップグレード実行時に `init-labels.sh` が呼び出される
- [ ] 既存ラベルは上書きされずスキップされる（冪等性維持）
- [ ] スクリプトがrsync同期対象として適切に扱われる

**技術的考慮事項**:
- 変更対象: `prompts/setup-prompt.md`
- `docs/aidlc.toml` の `[backlog].mode` が `issue` または `issue-only` の場合のみ実行

---

### ストーリー 2: backlogディレクトリ作成の条件分岐 (#162)
**優先順位**: Must-have

As a AI-DLCスターターキット利用者（issue-onlyモード）
I want to サイクル初期化時に不要なbacklogディレクトリが作成されない
So that リポジトリに不要なディレクトリが残らない

**受け入れ基準**:
- [ ] `backlog.mode` が `issue` の場合、backlogディレクトリを作成しない
- [ ] `backlog.mode` が `issue-only` の場合、backlogディレクトリを作成しない
- [ ] `backlog.mode` が `git` または `git-only` の場合のみ、backlogディレクトリを作成する
- [ ] 出力に `skipped-issue-mode` が表示される

**技術的考慮事項**:
- 変更対象: `prompts/package/bin/init-cycle-dir.sh`
- 現在は `issue-only` のみスキップ、`issue` も追加する必要あり

---

### ストーリー 3: operations.md行数削減 (#172)
**優先順位**: Should-have

As a AI-DLCスターターキット開発者
I want to operations.mdが1,000行以下に削減される
So that ファイルの可読性と保守性が向上する

**受け入れ基準**:
- [ ] operations.mdの行数が1,000行以下になる
- [ ] 機能は削減せず、外部ファイルに分割する
- [ ] 既存のワークフローに影響を与えない

**技術的考慮事項**:
- 変更対象: `prompts/package/prompts/operations.md`
- 分割候補: セルフアップデート処理（スキル化）、共通フロー
- ストーリー5（セルフアップデート簡略化）と連携して削減

---

### ストーリー 4: コンパクション時のプロンプト読み込み (#170)
**優先順位**: Should-have

As a AI-DLC利用者
I want to コンテキストがコンパクション（自動要約）された後も、フェーズのルールと手順が維持される
So that 長時間の作業でもAIの応答品質が低下しない

**受け入れ基準**:
- [ ] Inception Phase中のコンパクション時: `docs/aidlc/prompts/inception.md` を読み込む指示が追加される
- [ ] Construction Phase中のコンパクション時: `docs/aidlc/prompts/construction.md` を読み込む指示が追加される
- [ ] Operations Phase中のコンパクション時: `docs/aidlc/prompts/operations.md` を読み込む指示が追加される
- [ ] progress.mdに「再開時に読み込むべきファイル」が記載される

**技術的考慮事項**:
- 変更対象: 各フェーズプロンプト（inception.md, construction.md, operations.md）
- 「コンテキストリセット対応」セクションの拡張または新規セクション追加

---

### ストーリー 5: セルフアップデート処理の簡略化
**優先順位**: Should-have

As a AI-DLCスターターキット開発者（メタ開発）
I want to Operations Phaseのセルフアップデート処理がスキル呼び出しで完結する
So that operations.mdの記述が簡潔になり、手順の一貫性が保たれる

**受け入れ基準**:
- [ ] operations.md内のセルフアップデート手順が `/aidlc-upgrade` スキル呼び出しに置き換わる
- [ ] 既存のaidlc-upgradeスキルが正しく動作する
- [ ] 手動での詳細手順は削除またはスキル内に移動される

**技術的考慮事項**:
- 変更対象: `prompts/package/prompts/operations.md`
- 依存: `docs/aidlc/skills/aidlc-upgrade/SKILL.md` が存在し動作すること
- ストーリー3（operations.md行数削減）と連携

---

### ストーリー 6: setup-branch.shのプレリリースバージョン対応
**優先順位**: Must-have

As a AI-DLCスターターキット利用者
I want to プレリリースバージョン（v2.0.0-alpha.9など）でもブランチを作成できる
So that アルファ版やベータ版のサイクルでも正常にワークフローを開始できる

**受け入れ基準**:
- [ ] `setup-branch.sh v2.0.0-alpha.9 branch` が正常に動作する
- [ ] `setup-branch.sh v1.13.2-beta.1 worktree` が正常に動作する
- [ ] セマンティックバージョニングのプレリリース形式（-alpha.N, -beta.N, -rc.N）がサポートされる
- [ ] 既存のvX.Y.Z形式は引き続き動作する

**技術的考慮事項**:
- 変更対象: `prompts/package/bin/setup-branch.sh`
- バージョン検証ロジックの修正が必要
- `init-cycle-dir.sh` のバージョン検証も確認が必要（スラッシュ禁止のみ）

---

## 受け入れ基準のチェック観点

| チェック項目 | US1 | US2 | US3 | US4 | US5 | US6 |
|-------------|-----|-----|-----|-----|-----|-----|
| 具体性 | OK | OK | OK | OK | OK | OK |
| 検証可能性 | OK | OK | OK | OK | OK | OK |
| 完全性 | OK | OK | OK | OK | OK | OK |
| 独立性 | OK | OK | 一部依存 | OK | 一部依存 | OK |
