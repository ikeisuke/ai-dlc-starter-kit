# ユーザーストーリー

## Epic: ドキュメント整合性改善

### ストーリー 1: ステップ番号の統一
**優先順位**: Should-have

As a AI-DLC利用者
I want to setup.mdのステップ番号が連番になっている
So that 手順を追いやすくなる

**受け入れ基準**:
- [ ] setup.mdのステップ番号が1から連番になっている
- [ ] inception.mdの「完了時の作業」も同様に整理されている

**関連Issue**: #55

---

### ストーリー 2: リリース内容の完全な記録
**優先順位**: Should-have

As a プロジェクト管理者
I want to post_release_operations.mdにリリース内容が完全に記載されている
So that リリース内容を正確に把握できる

**受け入れ基準**:
- [ ] v1.7.2のpost_release_operations.mdにIssueテンプレート追加が記載されている

**関連Issue**: #54

---

### ストーリー 3: CIとチェックリストの整合性
**優先順位**: Should-have

As a 開発者
I want to deployment_checklist.mdのlint対象がCIと一致している
So that 手動チェックとCIで同じ結果が得られる

**受け入れ基準**:
- [ ] チェックリストのMarkdownlint対象範囲がCIと一致している

**関連Issue**: #53

---

### ストーリー 4: YAML抜粋の正確性
**優先順位**: Could-have

As a 開発者
I want to cicd_setup.mdのYAML抜粋が実ファイルと一致している
So that ドキュメントを信頼できる

**受け入れ基準**:
- [ ] cicd_setup.mdに「抜粋」であることが明示されている

**関連Issue**: #52

---

### ストーリー 5: 設定ファイルの整理
**優先順位**: Should-have

As a 開発者
I want to aidlc.tomlに冗長な情報がない
So that 設定ファイルがシンプルで保守しやすい

**受け入れ基準**:
- [ ] aidlc.tomlの冗長なコメント行が削除されている

**関連Issue**: #51

---

### ストーリー 6: ドラフトPR表記の簡素化
**優先順位**: Should-have

As a 開発者
I want to ドラフトPRに冗長な[Draft]表記がない
So that Ready化時の更新作業が不要になる

**受け入れ基準**:
- [ ] inception.mdのドラフトPR作成で[Draft]プレフィックスを使用しない
- [ ] operations.mdのReady化でタイトル変更処理を削除

**関連Issue**: #50

---

## Epic: DX改善

### ストーリー 7: daselによるTOML読み込み改善
**優先順位**: Should-have

As a 開発者
I want to setup-prompt.mdでdaselが適切に活用されている
So that TOML設定の読み込みが効率的になる

**受け入れ基準**:
- [ ] setup-prompt.mdのTOML読み込み箇所でdaselコマンドを使用している
- [ ] `if command -v dasel` でdasel存在チェックを行っている
- [ ] dasel未インストール時は既存のgrep/sed処理にフォールバックする

**関連Issue**: #33

---

### ストーリー 8: Markdownlint対象範囲の最適化
**優先順位**: Should-have

As a 開発者
I want to Markdownlintが現在のサイクルのファイルのみを対象にする
So that 過去サイクルのエラーに煩わされない

**受け入れ基準**:
- [ ] Construction Phaseプロンプトでlint対象が `docs/cycles/{{CYCLE}}/` または `git diff --name-only` で取得した変更ファイルに限定されている
- [ ] `docs/cycles/v1.x.x/` 等の過去サイクルディレクトリはlint対象から除外される
- [ ] プロンプト内にファイル選択ルールが明記されている

**関連Issue**: #46

---

### ストーリー 9: jjサポートの改善
**優先順位**: Should-have

As a jjユーザー
I want to jjサポートの課題が改善されている
So that jjをスムーズに使用できる

**受け入れ基準**:
- [ ] `docs/aidlc/guides/jj-support.md` に「作業開始時」「作業終了時」のチェックリストセクションが追加されている
- [ ] 各セクションにjjコマンド例（`jj new`, `jj bookmark set` 等）が記載されている
- [ ] jj推奨設定（`auto-local-bookmark = true`）がドキュメントに記載されている

**関連Issue**: #49
