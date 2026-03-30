# ユーザーストーリー

## Epic: skills/正本化とv1残存インフラ排除

### ストーリー 1: スキル利用リソースの移設
**優先順位**: Must-have

As a AI-DLCスターターキット開発者
I want to スキルが参照するガイド・テストが `skills/aidlc/` 配下に揃っている状態にしたい
So that プラグインとして自己完結し、外部パスへの依存がなくなる

**受け入れ基準**:
- [ ] `docs/aidlc/guides/` の18ファイルが `skills/aidlc/guides/` に存在する（`ls skills/aidlc/guides/ | wc -l` が18）
- [ ] `docs/aidlc/tests/` の11ファイルが `skills/aidlc/scripts/tests/` に存在する
- [ ] `git log --follow` で移動元ファイルの履歴が追跡可能

**技術的考慮事項**:
- `git mv` を使用して履歴追跡を維持

---

### ストーリー 2: 非スキルリソースの再配置
**優先順位**: Must-have

As a AI-DLCスターターキット開発者
I want to スキルが使用しないリソース（Kiro設定等）が適切な場所に配置されていてほしい
So that スキルディレクトリが肥大化せず、各リソースの所在が明確になる

**受け入れ基準**:
- [ ] `docs/aidlc/kiro/agents/aidlc.json` が `kiro/agents/aidlc.json` に存在する
- [ ] `kiro/` ディレクトリが `.gitignore` に含まれていない（Gitで管理される）

**技術的考慮事項**:
- Kiro CLI設定はスキル非依存のため `skills/` 配下には置かない

---

### ストーリー 3: docs/aidlc/ の重複削除
**優先順位**: Must-have
**依存**: ストーリー 1, 2 完了後

As a AI-DLCスターターキット開発者
I want to `docs/aidlc/` の重複ファイルと空ディレクトリが完全に削除されていてほしい
So that 「どこが正本か」の混乱が完全に解消される

**受け入れ基準**:
- [ ] `ls docs/aidlc/ 2>/dev/null` が空（ディレクトリ自体が存在しない）
- [ ] `docs/aidlc/prompts/` が存在しない（`skills/aidlc/steps/` と重複のため削除）
- [ ] `docs/aidlc/templates/` が存在しない（`skills/aidlc/templates/` と重複のため削除）
- [ ] `docs/aidlc/lib/` が存在しない（`skills/aidlc/scripts/lib/` と重複のため削除）
- [ ] `docs/aidlc/AGENTS.md`, `docs/aidlc/CLAUDE.md` が存在しない
- [ ] `prompts/package/` が存在しない（`docs/aidlc/` のコピー元、同様に重複）

**技術的考慮事項**:
- 削除前にストーリー1, 2の移設が完了していること

---

### ストーリー 4: パス参照の一括更新
**優先順位**: Must-have
**依存**: ストーリー 1 完了後

As a AI-DLCスターターキット利用者
I want to パス設定に依存せずスキルが正常に動作してほしい
So that `aidlc_dir` の設定ミスや未設定でスキルが壊れることがない

**受け入れ基準**:
- [ ] `grep -r '{{aidlc_dir}}' skills/` の結果が0件
- [ ] `grep -r 'docs/aidlc' skills/ --include='*.md' --include='*.sh'` の結果が0件
- [ ] `skills/aidlc/steps/` 内のガイド参照が `guides/` 始まりの相対パスである（`grep -r 'guides/' skills/aidlc/steps/ | grep -v '{{aidlc_dir}}'` で確認）
- [ ] `.aidlc/config.toml` から `paths.aidlc_dir` キーが除去されている
- [ ] `skills/aidlc/config/defaults.toml` から `paths.aidlc_dir` のデフォルト値が除去されている
- [ ] 既存ユーザーの `config.toml` に `aidlc_dir` が残っていても `read-config.sh` が終了コード0を返す（未知キーはエラーにしない）

**技術的考慮事項**:
- `read-config.sh --keys` のバッチモードで `paths.aidlc_dir` を要求しなくなるため、プリフライトチェックの更新も必要

---

### ストーリー 5: v1セットアップインフラの廃止
**優先順位**: Must-have

As a AI-DLCスターターキット利用者
I want to v1時代のセットアップインフラ（rsync同期、旧パス参照）が除去されていてほしい
So that 不要なファイルに混乱せず、v2プラグインモデルだけを意識すればよい

**受け入れ基準**:
- [ ] `prompts/bin/sync-package.sh` が存在しない
- [ ] `grep -r 'docs/aidlc.toml\|docs/aidlc\|docs/cycles' prompts/setup/` の結果が0件
- [ ] `prompts/setup/` 配下のスクリプト・テンプレートがv2パス（`.aidlc/config.toml` 等）を使用している

**技術的考慮事項**:
- #450, #449, #448 を包含
- `prompts/setup/` で `/aidlc setup` が参照する機能は維持し、rsync前提の機能のみ廃止

---

### ストーリー 6: スクリプトのv2対応
**優先順位**: Must-have

As a AI-DLCスターターキット利用者
I want to `aidlc-setup.sh` と `update-version.sh` がv2プラグイン構造で正しく動作してほしい
So that `/aidlc setup` のパス解決エラーやバージョン更新の失敗が発生しない

**受け入れ基準**:
- [ ] `aidlc-setup.sh` の `resolve_starter_kit_root()` がシンボリックリンクを `readlink` で解決する
- [ ] 外部プロジェクトで `/aidlc setup` 実行時に `version.txt` が正しく検出される
- [ ] シンボリックリンクが壊れている場合、明確なエラーメッセージを出力して終了コード1で終了する
- [ ] macOS（BSD readlink）とLinux（GNU readlink）の両方で動作する
- [ ] `update-version.sh` が `docs/aidlc.toml` を参照していない（`grep 'docs/aidlc' bin/update-version.sh` が0件）
- [ ] `update-version.sh` が `version.txt` と `.aidlc/config.toml` を更新する

**技術的考慮事項**:
- #447, #444 を包含
- macOS: `readlink` はGNU互換でないため `readlink -f` の代わりにループ解決が必要な場合あり

---

### ストーリー 7: バックログ即時実装ルール追加
**優先順位**: Should-have

As a AI-DLC利用者
I want to 即時実装を指示した際にAIがバックログに回さないルールが明記されていてほしい
So that 意図しないバックログ送りを避けられる

**受け入れ基準**:
- [ ] `steps/common/agents-rules.md` の「バックログ管理」セクションに「ユーザーが即時実装を指示した場合はバックログに回さない。バックログ追加は明示的に指示された場合のみ」の文言が追加されている
- [ ] `grep '即時実装' steps/common/agents-rules.md` が1件以上ヒットする
- [ ] `rules.md` の「改善提案のバックログ登録ルール」と矛盾しない（即時実装指示 ≠ 改善提案のため、適用場面が異なることが明記されている）

**技術的考慮事項**:
- #439 を包含

---

### ストーリー 8: 旧エントリポイントの誘導設置
**優先順位**: Must-have

As a v1からのアップグレードユーザー
I want to 旧エントリポイントにアクセスした際に新しいプラグイン構造への案内を受けたい
So that v2への移行方法が明確にわかる

**受け入れ基準**:
- [ ] `prompts/setup-prompt.md` の先頭10行以内に「v2ではプラグインモデルを使用してください。`/aidlc setup` で開始できます。」を含む誘導文がある（`head -10 prompts/setup-prompt.md | grep -c 'aidlc setup'` が1以上）
- [ ] `AGENTS.md` の「従来の詳細な指示は `/aidlc` コマンドにリダイレクトされます」の記載が維持されている
- [ ] `docs/aidlc/` は完全削除されるため、旧 `docs/aidlc/prompts/` 経由のアクセスは不可能。案内不要（ストーリー3で対応済み）

**技術的考慮事項**:
- `setup-prompt.md` の簡略化（誘導文 + 最小限の内容）はこのストーリーで実施
- ストーリー5の `prompts/setup/` パス更新とは別責務
