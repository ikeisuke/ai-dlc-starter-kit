# Review 003: v2 → v3 migration 実装（new-cycle-only + archive-only）

- trace: work item 003-migrate-v2-to-v3-core
- matrix_review_mode: code_security（security 重点）
- 処理パス: 外部 CLI（codex / codex-cli 0.142.5 / routing_review_mode=required / automation_mode=semi_auto）

<!-- aidlc-review:code:start status=complete -->

## Code Review

- 実行日: 2026-07-07
- 対象: work item 003 の実装変更ファイル群（skills/aidlc-migrate/scripts/migrate-v3-{preflight,config,archive-index}.sh / steps/v3-migrate.md / SKILL.md ルーティング / skills/aidlc-v3/steps/define.md 4-3 resume 経路 / tests/migration/migrate-v3-*.bats / helpers / fixtures）
- 反復: 3 ラウンド（1R: 指摘 3 件 → 修正 → 2R: 指摘 1 件 → 修正 → 3R: 指摘 0 件）で完了判定

### 指摘と対応（focus=security は種類の要約のみ / 機密マスク方針準拠）

| R | focus | 重要度 | 種類 | 対応 |
|---|-------|--------|------|------|
| 1 | security | 中 | パス・トラバーサル（migrate-v3-config.sh の --source/--target が境界未検証） | 修正済み: lib/path-guard.sh による repo 相対パス限定検証（絶対パス / `..` / symlink 脱出を exit 1 で拒否）+ 拒否系 bats 追加 |
| 1 | security | 中 | パス・トラバーサル（migrate-v3-archive-index.sh の --output が境界未検証） | 修正済み: 同上の path-guard 検証 + 拒否系 bats 追加 |
| 1 | security | 低 | 出力インジェクション（cycle ディレクトリ名の Markdown table 無害化不足） | 修正済み: 許容文字集合検証（state-init.sh の cycle id ガードと同型）で不一致は警告付き skip + bats 追加 |
| 2 | code | 低 | 誤動作（target/output がディレクトリの場合に mv がディレクトリ内移動として成功） | 修正済み: 事前のディレクトリ検出で exit 1 + 拒否系 bats 追加 |

### 完了状態

- unresolved_count: 0（全件修正済み / defer なし）
- 検証: tests/migration/ 全 78 テスト pass / shellcheck green（既存 migrate-*.sh と同一基準） / parse-guard・bash-substitution・skill-references・markdownlint いずれも違反なし
- N/A 判定: ネットワーク・HTTP・認証・ログ監視の観点はローカル CLI スクリプトのため N/A

<!-- aidlc-review:code:end -->
