# ユーザーストーリー

## Epic 1: バグ修正

### ストーリー 1: squash-unit.sh --dry-run修正（#466）
**優先順位**: Must-have

As a AI-DLC利用者
I want to squash-unit.sh の --dry-run 実行時に --message 必須チェックがスキップされる
So that dry-run でスカッシュ結果を事前確認できる

**受け入れ基準**:
- [ ] `squash-unit.sh --dry-run` を --message なしで実行してもエラーにならない
- [ ] `squash-unit.sh` を --message なしで実行するとエラーになる（既存動作維持）
- [ ] --dry-run 時はスカッシュ対象コミット一覧を表示し、実際のスカッシュは行わない

---

### ストーリー 2: migrate-config.sh --dry-run修正（#463）
**優先順位**: Must-have

As a AI-DLC利用者
I want to migrate-config.sh の --dry-run 実行時に cleanup trap の unbound variable エラーが発生しない
So that dry-run でマイグレーション結果を安全に事前確認できる

**受け入れ基準**:
- [ ] `migrate-config.sh --dry-run` を実行してもunbound variableエラーが発生しない
- [ ] cleanup trapが --dry-run 時も正常に動作する
- [ ] 通常実行時の動作に影響がない

---

### ストーリー 3: bootstrap.sh依存脱却（#465）
**優先順位**: Must-have

As a AI-DLC利用者
I want to aidlc-setup/aidlc-migrate スクリプトが bootstrap.sh に依存しない
So that スクリプト間の結合度が下がり、個別のメンテナンスが容易になる

**受け入れ基準**:
- [ ] aidlc-setup関連スクリプトが bootstrap.sh を source/呼び出ししていない
- [ ] aidlc-migrate関連スクリプトが bootstrap.sh を source/呼び出ししていない
- [ ] 各スクリプトが必要な関数を自身で定義するか、lib/ から個別にインポートしている
- [ ] 既存のセットアップ・マイグレーション機能が正常に動作する

---

### ストーリー 4: /aidlc help アクション追加（#464）
**優先順位**: Must-have

As a AI-DLC利用者
I want to `/aidlc help` または `/aidlc h` でヘルプ情報を表示できる
So that 利用可能なアクションと使い方をすぐに確認できる

**受け入れ基準**:
- [ ] `/aidlc help` で利用可能なアクション一覧が表示される
- [ ] `/aidlc h` が `help` の短縮形として動作する
- [ ] 各アクションの簡潔な説明と短縮形が表示される

---

## Epic 2: アクション総点検

### ストーリー 5: Inception Phase総点検
**優先順位**: Must-have

As a AI-DLCスターターキット開発者
I want to Inception Phaseのステップファイルとスクリプトの記述が実動作と一致している
So that AIエージェントがInception Phaseを正確に実行できる

**乖離の重大度判定基準**:
- 重大: フローが中断する、誤った結果を生成する、存在しないスクリプト/引数を参照している
- 軽微: 表記揺れ、コメントの不整合、動作に影響しない記述の齟齬

**受け入れ基準**:
- [ ] steps/inception/ の全ファイル（01-06）を実動作と突き合わせ、乖離リスト（.aidlc/cycles/v2.0.8/construction/units/003-audit-findings.md）を作成
- [ ] 関連スクリプト（check-open-issues.sh, suggest-version.sh, init-cycle-dir.sh, setup-branch.sh等）の動作を確認
- [ ] 重大な乖離（フロー中断・誤結果）が全て修正されている
- [ ] 軽微な乖離がGitHub Issueとしてバックログに登録されている（backlogラベル付き）

---

### ストーリー 6: Construction Phase総点検
**優先順位**: Must-have

As a AI-DLCスターターキット開発者
I want to Construction Phaseのステップファイルとスクリプトの記述が実動作と一致している
So that AIエージェントがConstruction Phaseを正確に実行できる

**乖離の重大度判定基準**: ストーリー5と同一基準を適用

**受け入れ基準**:
- [ ] steps/construction/ の全ファイル（01-04）を実動作と突き合わせ、乖離リスト（.aidlc/cycles/v2.0.8/construction/units/004-audit-findings.md）を作成
- [ ] 関連スクリプト（squash-unit.sh, write-history.sh等）の動作を確認
- [ ] 重大な乖離が全て修正されている
- [ ] 軽微な乖離がGitHub Issueとしてバックログに登録されている（backlogラベル付き）

---

### ストーリー 7: Operations Phase総点検
**優先順位**: Must-have

As a AI-DLCスターターキット開発者
I want to Operations Phaseのステップファイルとスクリプトの記述が実動作と一致している
So that AIエージェントがOperations Phaseを正確に実行できる

**乖離の重大度判定基準**: ストーリー5と同一基準を適用

**受け入れ基準**:
- [ ] steps/operations/ の全ファイル（01-04 + operations-release.md）を実動作と突き合わせ、乖離リスト（.aidlc/cycles/v2.0.8/construction/units/005-audit-findings.md）を作成
- [ ] 関連スクリプト（pr-ops.sh, issue-ops.sh, post-merge-cleanup.sh等）の動作を確認
- [ ] 重大な乖離が全て修正されている
- [ ] 軽微な乖離がGitHub Issueとしてバックログに登録されている（backlogラベル付き）

---

### ストーリー 8: Setup総点検
**優先順位**: Must-have

As a AI-DLCスターターキット開発者
I want to aidlc-setupスキルの記述が実動作と一致している
So that AIエージェントがセットアップを正確に実行できる

**乖離の重大度判定基準**: ストーリー5と同一基準を適用

**受け入れ基準**:
- [ ] aidlc-setup/SKILL.md とステップファイルを実動作と突き合わせ、乖離リスト（.aidlc/cycles/v2.0.8/construction/units/006-audit-findings.md）を作成
- [ ] 関連スクリプトの動作を確認
- [ ] 重大な乖離が全て修正されている
- [ ] 軽微な乖離がGitHub Issueとしてバックログに登録されている（backlogラベル付き）

---

## Epic 3: ガイドライン整備

### ストーリー 9: スキルスクリプト設計ガイドライン作成
**優先順位**: Should-have

As a AI-DLCスターターキット開発者
I want to bootstrap.sh脱却で得た知見をスキルスクリプトの設計ガイドラインとして文書化する
So that 今後のスキル開発・メンテナンスで同じ問題（共通スクリプトへの過度な依存）を防げる

**受け入れ基準**:
- [ ] guides/ 配下にスキルスクリプト設計ガイドラインが作成されている
- [ ] bootstrap.sh依存の問題点と脱却パターンが記載されている
- [ ] スクリプト間の依存管理の推奨方針（lib/からの個別インポート等）が記載されている
- [ ] 新規スクリプト作成時のチェックリストが含まれている
