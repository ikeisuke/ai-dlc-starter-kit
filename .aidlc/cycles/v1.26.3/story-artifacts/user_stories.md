# ユーザーストーリー

## Epic: ツール基盤の品質改善

### ストーリー 1: defaults.toml デフォルト値の補完
**優先順位**: Must-have

As a AI-DLCスターターキット利用者
I want to defaults.toml に不足しているデフォルト値が定義されている
So that aidlc.toml で未設定のキーでも read-config.sh が正常にデフォルト値を返し、フェーズ開始時のエラーが発生しない

**受け入れ基準**:

正常系:
- [ ] `read-config.sh rules.cycle.mode` が exit code 0 で `"default"` を返す（aidlc.toml で未設定の場合）
- [ ] `read-config.sh rules.upgrade_check.enabled` が exit code 0 で `"false"` を返す（aidlc.toml で未設定の場合）

境界条件:
- [ ] aidlc.toml でキーがコメントアウトされている場合、defaults.toml のデフォルト値が使用される
- [ ] aidlc.toml でキーが明示的に設定されている場合（例: `mode = "named"`）、その値がデフォルト値より優先される

**技術的考慮事項**:
- 正本は `prompts/package/config/defaults.toml`。`docs/aidlc/config/` は rsync で同期

---

### ストーリー 2: mktemp 許可ルールの統合
**優先順位**: Should-have

As a AI-DLCスターターキット開発者
I want to `.claude/settings.json` の mktemp 許可ルールがワイルドカードで統合されている
So that 新しい mktemp ユースケースを追加する際に個別ルールを追加する必要がなく、保守が容易になる

**受け入れ基準**:

正常系（許可されるべきコマンド）:
- [ ] `mktemp /tmp/aidlc-commit-msg.XXXXXX` が許可される
- [ ] `mktemp /tmp/aidlc-squash-msg.XXXXXX` が許可される
- [ ] `mktemp /tmp/aidlc-history-content.XXXXXX` が許可される
- [ ] `mktemp /tmp/aidlc-pr-body.XXXXXX` が許可される
- [ ] `mktemp /tmp/aidlc-review-input.XXXXXX` が許可される

異常系（許可されるべきでないコマンド）:
- [ ] `mktemp /tmp/other-file.XXXXXX` は許可されない（プレフィックス不一致）
- [ ] `rm /tmp/aidlc-commit-msg.XXXXXX` は許可されない（コマンド不一致）

統合:
- [ ] `.claude/settings.json` の個別ルール5件がワイルドカード1件に統合されている
- [ ] `setup-ai-tools.sh` のテンプレート生成部分が統合後のルールを出力する

**技術的考慮事項**:
- ワイルドカードの構文は `.claude/settings.json` のパターンマッチ仕様に依存する
- `setup-ai-tools.sh` の `_generate_template` 関数も同時更新が必要

---

### ストーリー 3: post-merge-cleanup.sh リモート解決ロジックのDRY改善
**優先順位**: Should-have

As a AI-DLCスターターキット開発者
I want to `post-merge-cleanup.sh` のリモート解決ロジックが重複なく一元管理されている
So that リモート解決ロジックの変更時に1箇所の修正で済み、複数箇所の動作が確実に同期される

**受け入れ基準**:

リモート解決の期待動作:
- [ ] `origin` のみの構成 → `origin` が解決される
- [ ] `origin` と `upstream` がある構成 → 適切なリモートが解決される（従来の優先順位を維持）
- [ ] リモートが存在しない構成 → エラーハンドリングが従来と同じ挙動を示す

コード品質:
- [ ] リモート解決ロジックがスクリプト内で1箇所に集約されている（重複が解消されている）
- [ ] 既存テストが全て通過する

**技術的考慮事項**:
- 関数抽出時に変数スコープに注意（local 宣言の確認）
- 両箇所の微妙な差異がある場合は統合前に差異を明確化する
