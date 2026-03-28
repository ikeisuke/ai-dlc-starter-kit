# ユーザーストーリー

## Epic: v2リリース品質確保

### ストーリー 1: config.toml移行マイグレーション (#456)
**優先順位**: Must-have

As a AI-DLC利用者
I want to `/aidlc migrate` 実行時にconfig.tomlの内容がv2形式に自動変換される
So that v1からの移行時に手動で設定を書き換える必要がなくなる

**受け入れ基準**:
- [ ] `/aidlc migrate` で `docs/aidlc.toml` → `.aidlc/config.toml` 移動時に内容マイグレーションが実行される
- [ ] 廃止された設定キー（例: `paths.aidlc_dir`）が削除される
- [ ] v2で追加された設定キーがデフォルト値で補完される
- [ ] v1形式のキーがv2形式に変換される（例: キー名変更への対応）
- [ ] 既にv2形式のconfig.tomlに対して実行しても破壊的変更が起きない（冪等性）
- [ ] マイグレーション結果のサマリが標準出力に表示される

**技術的考慮事項**:
既存の `migrate-config.sh` を移動後のファイルに対して実行する方式が候補

---

### ストーリー 2: コマンド短縮形対応 (#455)
**優先順位**: Should-have

As a AI-DLC利用者
I want to `/aidlc i` のような短縮形でフェーズを開始できる
So that 頻繁に使うコマンドの入力が効率化される

**受け入れ基準**:
- [ ] `/aidlc i` が `/aidlc inception` と同等に動作する
- [ ] `/aidlc c` が `/aidlc construction` と同等に動作する
- [ ] `/aidlc o` が `/aidlc operations` と同等に動作する
- [ ] `/aidlc e` が `/aidlc express` と同等に動作する
- [ ] `setup` / `migrate` / `feedback` には短縮形がない（誤操作防止）
- [ ] 無効な短縮形に対して適切なエラーメッセージが表示される
- [ ] 短縮形の後にadditional_contextを指定できる（例: `/aidlc c 前回の続き`）

**技術的考慮事項**:
SKILL.mdのARGUMENTSパーシング、AGENTS.md・CLAUDE.mdのテーブル更新が必要

---

### ストーリー 3: ファイル配置移行 (#454)
**優先順位**: Must-have

As a AI-DLC利用者
I want to プロジェクト全体に適用されるルールファイルが `.aidlc/` 直下に配置される
So that サイクル固有でないファイルが論理的に正しい場所に配置され、見つけやすくなる

**受け入れ基準**:
- [ ] `.aidlc/cycles/rules.md` が `.aidlc/rules.md` に移行される
- [ ] `.aidlc/cycles/operation.md` が存在する場合、`.aidlc/operation.md` に移行される
- [ ] 全参照箇所（プロンプト、スクリプト）のパスが更新される
- [ ] マイグレーションスクリプトが旧パスから新パスへの移行を自動化する
- [ ] 旧パスにファイルが残っている場合でも動作する（後方互換性）

**技術的考慮事項**:
参照箇所の洗い出しが必要。preflight.md、SKILL.md等の多数のファイルに影響

---

### ストーリー 4: migrate-config.sh バグ修正 (#453)
**優先順位**: Must-have

As a AI-DLC利用者
I want to migrate-config.shが部分失敗時に正確なメッセージを表示する
So that マイグレーション結果を正しく判断できる

**受け入れ基準**:
- [ ] `rules.reviewing.tools` の追加に失敗した場合、成功メッセージが出力されない
- [ ] コメントと実装の乖離が解消される（コメントに「exit 2」とあるが実装は常にexit 0）
- [ ] `_has_warnings` 変数が適切に処理されるか、不要であれば削除される
- [ ] 部分失敗時に失敗した項目が警告として出力される

**技術的考慮事項**:
exit-code-convention.mdとの整合性を確認する必要がある

---

### ストーリー 5: バージョン検証ロジック共通化 (#452)
**優先順位**: Should-have

As a AI-DLCスターターキット開発者
I want to バージョン検証ロジックが共通関数として統一される
So that バージョン形式の不整合がなくなり、保守コストが下がる

**受け入れ基準**:
- [ ] バージョン検証の共通関数が作成される
- [ ] `aidlc-setup.sh`、`check-version.sh`、`update-version.sh` が共通関数を使用する
- [ ] prerelease形式（例: `1.2.3-alpha.1`）が全スクリプトで統一的に扱われる
- [ ] `starter_kit_version` の読取・更新ロジックの重複が解消される
- [ ] 既存のテストが引き続きパスする

**技術的考慮事項**:
共通関数の配置場所（`skills/aidlc/scripts/lib/` 等）の検討が必要

---

### ストーリー 6: フェーズプロンプトでのルール再参照強化 (#438)
**優先順位**: Must-have

As a AI-DLCのAIエージェント
I want to フェーズプロンプトの重要ステップでルールが明示的に再参照される
So that ステップ順序やルールの見落としが減り、実行精度が向上する

**受け入れ基準**:
- [ ] construction.mdのPR作成前にcommit-flow.mdの順序制約が再参照される
- [ ] Phase 1→Phase 2遷移時に設計承認完了の確認が強化される
- [ ] レビュー前にreview-flow.mdの手順が再参照される
- [ ] operations.mdの重要ステップでもルール再参照が追加される
- [ ] 再参照の追加がWrong Approach（ルール無視）の減少に寄与する構造になっている

**技術的考慮事項**:
プロンプトの肥大化を防ぎつつ効果的な再参照を実現する必要がある
