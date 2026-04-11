# ユーザーストーリー

## Epic: v2.3.3 バグ修正・セキュリティ改善パッチ

### ストーリー 1: パス解決ルールの完全化
**優先順位**: Must-have

As a AI-DLCスキル利用者
I want to スキル内リソース（config/, templates/, guides/, references/）がスキルベースディレクトリから正しく解決される
So that プリフライトチェック等で偽陰性の警告が発生しなくなる

**受け入れ基準**:
- [ ] SKILL.mdのパス解決ルールに `config/`, `templates/`, `guides/`, `references/` が明記されている
- [ ] `config/` プレフィックスのパス（例: `config/defaults.toml`）がスキルベースディレクトリから解決される
- [ ] `templates/` プレフィックスのパス（例: `templates/intent_template.md`）がスキルベースディレクトリから解決される
- [ ] `guides/` プレフィックスのパス（例: `guides/version-check.md`）がスキルベースディレクトリから解決される
- [ ] `references/` プレフィックスのパスがスキルベースディレクトリから解決される
- [ ] 既存の `steps/`, `scripts/` の解決挙動が変更されていない
- [ ] スキルベースディレクトリ外のパスが誤って解決対象にならない

**技術的考慮事項**:
SKILL.md本文500行以内の制約を維持すること

---

### ストーリー 2: write-config.shのレガシーエイリアス対応
**優先順位**: Must-have

As a AI-DLC設定管理者
I want to write-config.shが設定保存時にレガシーエイリアスキーを検出し、正規キーに正規化して書き込む
So that config.toml内に矛盾する重複設定が発生しなくなる

**受け入れ基準**:
- [ ] レガシーエイリアスキー（例: `rules.branch.mode`）が存在する場合、正規キー（`rules.git.branch_mode`）への重複追加が発生しない
- [ ] 正規キーが既に存在する場合はその値が更新される
- [ ] レガシーキーのみ存在する場合は正規キーとして書き込まれる
- [ ] 代表ケース（`rules.branch.mode` -> `rules.git.branch_mode`）でレガシー→正規変換が正しく動作する
- [ ] 05-completion.md経由で `rules.git.draft_pr` を保存した際に重複キーが生成されない

**技術的考慮事項**:
read-config.shの `resolve_with_aliases()` パターンを参考にする。lib/key-aliases.shを共通で利用する。

---

### ストーリー 3: 設定保存フローの構造改善
**優先順位**: Should-have

As a AI-DLCスキル利用者
I want to Inception完了時の設定保存が確実に実行される
So that draft_pr設定の選択結果が保存漏れなくconfig.tomlに反映される

**受け入れ基準**:
- [ ] `draft_pr=ask` でユーザーが任意の選択をした場合でも、設定保存フローが実行される
- [ ] 設定保存完了後にPR作成ステップへ進む（順序が構造的に保証されている）
- [ ] 設定未保存のままInception完了処理が終了しない

**技術的考慮事項**:
Issue #566の対策案A（設定保存フローを独立ステップに分離）を採用

---

### ストーリー 4: GitHub Actions permissions追加
**優先順位**: Must-have

As a リポジトリ管理者
I want to permissions未定義の2ワークフロー（pr-check.yml, migration-tests.yml）に最小権限のpermissionsが定義されている
So that セキュリティベストプラクティスに準拠し、不要な権限が付与されない

**受け入れ基準**:
- [ ] `pr-check.yml` のワークフローレベルに `permissions` ブロックが追加されている
- [ ] `migration-tests.yml` のワークフローレベルに `permissions` ブロックが追加されている
- [ ] 定義されたpermissionsが最小権限原則に従っている（`contents: read` 等）
- [ ] 既存のジョブ（markdown-lint, bash-substitution-check, defaults-sync-check, migration-tests）が権限不足で失敗しない
- [ ] 差分上に `permissions` ブロックが追加され、`actions/missing-workflow-permissions` パターンに該当する箇所がない

**技術的考慮事項**:
`skill-reference-check.yml`（`contents: read`）を参考モデルとする
