# ユーザーストーリー

## Epic: AI-DLC設定体系の整理と安定性向上

### ストーリー 1: Git関連設定キーの統合
**優先順位**: Must-have

As a AI-DLC利用者
I want to Git関連の設定を `[rules.git]` セクションで一元管理できる
So that 設定ファイルの見通しが良くなり、設定変更時の迷いが減る

**受け入れ基準**:
- [ ] `rules.branch.mode`, `rules.worktree.enabled`, `rules.unit_branch.enabled`, `rules.squash.enabled`, `rules.commit.ai_author`, `rules.commit.ai_author_auto_detect` が `[rules.git]` 配下に統合されている
- [ ] `defaults.toml` に新キーのデフォルト値が定義されている
- [ ] `read-config.sh` で旧キー形式（`rules.branch.mode` 等）を指定した場合、新キー（`rules.git.branch_mode` 等）にフォールバックして値を返す
- [ ] プリフライトチェック（`preflight.md`）のバッチ取得が新キーを使用している
- [ ] ステップファイル内の全参照箇所が新キーに更新されている
- [ ] `aidlc-setup` の `detect-missing-keys.sh` が新キー構造に対応している

**技術的考慮事項**:
- フォールバックの方向: 新キー優先、不在時に旧キーを読み取り
- `read-config.sh` のフォールバック実装は既存パターン（`rules.history.level` → `rules.depth_level.history_level`）を参考にする

---

### ストーリー 2a: rules.mdの設定項目整理
**優先順位**: Should-have

As a AI-DLC利用者
I want to `.aidlc/rules.md` の内容が整理され、設定的な項目と自由記述が明確に分離されている
So that どの設定をconfig.tomlで管理し、どの内容をrules.mdに残すかが明確になる

**受け入れ基準**:
- [ ] `rules.md` 内の各セクションについて、config.tomlへの移行候補を一覧化した表が設計ドキュメントに作成されている
- [ ] 各項目に「移行する/しない」と判断理由が記載されている
- [ ] 移行対象項目がconfig.tomlの適切なセクションに定義されている
- [ ] rules.mdから移行済み項目が除去され、config.toml参照への導線が記載されている

**技術的考慮事項**:
- rules.mdは自由記述が中心のため、移行可能な項目は限定的と想定
- 移行判断の基準: 値がtrue/false/文字列で表現できるものはconfig.toml候補

---

### ストーリー 2b: operations.mdの構成整理
**優先順位**: Should-have

As a AI-DLC利用者
I want to `.aidlc/operations.md` の内容が共通手順とメタ開発固有手順に分離されている
So that 一般プロジェクトでも使いやすいテンプレートになる

**受け入れ基準**:
- [ ] `operations.md` の各セクションが「共通手順」と「メタ開発固有手順」に分類されている
- [ ] メタ開発固有セクションが明示的にマーク（見出しに「メタ開発」等）されている
- [ ] 一般プロジェクト向けテンプレート（`templates/operations_template.md`）の構成がoperations.mdの共通セクションと一致している（同名セクション・同内容）
- [ ] `steps/operations/01-setup.md` と `steps/operations/operations-release.md` から `.aidlc/operations.md` の参照が正しいパスで記載されている

**技術的考慮事項**:
- 現在の `operations.md` にはメタ開発固有の手順（defaults.toml同期確認、サイズチェック等）が含まれている
- 一般ユーザー向けテンプレートとの差分を明確にする

---

### ストーリー 3: dasel v3対応
**優先順位**: Must-have

As a dasel v3環境のAI-DLC利用者
I want to `/aidlc setup` のバージョン比較がdasel v3で正常動作する
So that セットアップ時にバージョン比較がスキップされず、正しいバージョン情報を確認できる

**受け入れ基準**:
- [ ] `aidlc-setup` の `01-detect.md` のバージョン取得コマンドがv2形式（`dasel -f file 'key'`）とv3形式（`dasel query -f file 'key'`）の両方で値を返す
- [ ] `02-generate-config.md` の `dasel put` コマンドがv2/v3両方で期待キーを書き込める形式に更新されている
- [ ] dasel未インストール環境では「daselが見つかりません」警告を表示し、バージョン比較ステップをスキップしてセットアップを続行する（最終終了コード0）
- [ ] v2環境で `01-detect.md` のバージョン取得と `02-generate-config.md` のキー書き込みが成功する（回帰確認）

**技術的考慮事項**:
- `read-config.sh` は `bootstrap.sh` 経由で既にv2/v3対応済み
- `detect-missing-keys.sh` も v2/v3ブラケット記法に対応済み
- 問題はプロンプトファイル内に直接記載されたv2形式のdaselコマンド例のみ
