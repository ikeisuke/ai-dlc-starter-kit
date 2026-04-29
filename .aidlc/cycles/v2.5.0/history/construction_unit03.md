# Construction Phase 履歴: Unit 03

## 2026-04-29T08:54:01+09:00

- **フェーズ**: Construction Phase
- **Unit**: 03-migrate-prefs-relocation（aidlc-migrate での個人好みキー移動提案）
- **ステップ**: AIレビュー完了
- **実行内容**: 計画承認前レビュー（reviewing-construction-plan / codex / 3 ラウンド）で指摘 3→2→0 件に収束。

- ラウンド 1（3 件 / 高 2・中 1）: detect 出力仕様矛盾（JSON vs タブ区切り）（高）、detect 責務と上書き可否確認の接続欠如（高）、exit code 1 と set -e の衝突（中）
- ラウンド 2（2 件 / 高 1・低 1）: move 上書き手段未定義（高）、設計方針に JSON 旧語彙残存（低）
- ラウンド 3: 指摘ゼロ

主な反映:
- detect 出力をタブ区切り単一形式に統一し JSON は不採用。`<user_global_conflict>` 列を追加して step 側「上書き可否」追加確認の判定根拠を一本化
- exit code を `0=正常 / 2=エラー` に整理（detect 0 件も exit 0 + summary total 0）。`1` は使用しない（set -e 文脈での誤判定回避）
- move サブコマンドに `--overwrite` フラグを追加。step 側 3 択（上書き / スキップ / キャンセル）と script コマンドの対応を明記。観点 B6 で `--overwrite` 動作を fixture 検証

Codex Session: 019dd65c-dece-7ae2-93bc-0cb72194f627（記録時の thread_id）

---
## 2026-04-29T09:02:27+09:00

- **フェーズ**: Construction Phase
- **Unit**: 03-migrate-prefs-relocation（aidlc-migrate での個人好みキー移動提案）
- **ステップ**: AIレビュー完了
- **実行内容**: 設計レビュー（reviewing-construction-design / codex / 2 ラウンド）で指摘 3→0 件に収束。

- ラウンド 1（3 件 / 中 1・低 2）: --dry-run の位置づけ揺れ（中）、error: と exit 0 の意味論不一致（低）、Unit 001 SoT 追従契約の弱さ（低）
- ラウンド 2: 指摘ゼロ

主な反映:
- サブコマンド (detect|move|keep) と グローバルオプション (--dry-run) / 専用オプション (--overwrite) の責務を一本化し別表に分離
- プレフィックス命名規約を明記: error: は exit 2 限定、warn: は exit 0 で処理継続可能、dry-run: は dry-run プレフィックス。`error:user-global-key-exists` を `warn:user-global-key-exists` にリネーム
- 「Unit 001 正規 7 キー集合への固定参照点」セクションを新設し、SoT + 派生先 3 種を明記。観点 K1（集合対称差 = 0）を `tests/aidlc-migrate-prefs/key-set-sync.bats` に新設して CI で乖離検出。「Unit 001/002/003 のキー集合参照ハブ」表で全派生先と同期手段を一元化

Codex Session: 019dd65c-dece-7ae2-93bc-0cb72194f627

---
## 2026-04-29T09:26:01+09:00

- **フェーズ**: Construction Phase
- **Unit**: 03-migrate-prefs-relocation（aidlc-migrate での個人好みキー移動提案）
- **ステップ**: AIレビュー完了
- **実行内容**: コードレビュー（reviewing-construction-code / codex / 3 ラウンド）で指摘 3→2→0 件に収束。

- ラウンド 1（3 件 / 中 2・低 1）: 値エスケープ + ホワイトリスト検証の欠如（中）、move のトランザクション化欠如（中）、失敗注入テスト不足（低）
- ラウンド 2（2 件 / 中 1・低 1）: タブ文字 0x09 が unsafe chars 除外パターンから漏れている（中）、ロールバック実証テスト未実装（低）
- ラウンド 3: 指摘ゼロ

主な反映:
- KEY_VALUE_TYPES ホワイトリスト + `_validate_and_normalize_value`（boolean / enum / string / string_array の 4 型）+ `_value_has_unsafe_chars`（制御文字 0x00-0x1F + 0x7F + タブ）+ `_toml_escape_string`（\ と " の TOML エスケープ）を実装
- move 内に project / user-global の backup + `_rollback_move` を導入（_safe_transform / _append_key_to_file / _delete_key_in_file いずれか失敗時に両ファイルを backup から復元）
- 失敗注入テスト 5 件追加（B7: 不正 enum / B8: 不正 boolean / B9: 文字列 TOML エスケープ / B10: タブ文字 reject / B11: project read-only による delete 失敗時の user-global ロールバック）

セキュリティ観点: 通信・認証系は N/A。本変更範囲はローカル I/O の入力検証 + 整合性が中心であり、ホワイトリスト検証 + トランザクション化により value injection / partial update リスクを排除

事前ローカル検証:
- bats tests/aidlc-migrate-prefs/move.bats で 11/11 PASS（B1〜B11）
- bats tests/migration/ tests/config-defaults/ tests/aidlc-setup/ tests/aidlc-migrate-prefs/ で 119/119 PASS（migration 36 + config-defaults 34 + aidlc-setup 17 + aidlc-migrate-prefs 32、回帰なし）
- markdownlint-cli2 で対象 4 ファイル 0 errors

Codex Session: 019dd65c-dece-7ae2-93bc-0cb72194f627

---
## 2026-04-29T09:31:35+09:00

- **フェーズ**: Construction Phase
- **Unit**: 03-migrate-prefs-relocation（aidlc-migrate での個人好みキー移動提案）
- **ステップ**: AIレビュー完了
- **実行内容**: 統合レビュー（reviewing-construction-integration / codex / 2 ラウンド）で指摘 3→0 件に収束。

- ラウンド 1（3 件 / 高 1・中 2）: Unit 003 定義が「未着手」のままで完了条件不整合（高）、unit-003-plan.md チェックリストが [ ] のまま（中）、ドメインモデル OutputPrefix に warn 抜け（中）
- ラウンド 2: 指摘ゼロ

主な反映:
- story-artifacts/units/003-migrate-prefs-relocation.md の状態を「完了」に更新（開始日/完了日 2026-04-29、担当 Claude Code）
- plans/unit-003-plan.md の完了条件チェックリスト 25 項目を全て [x] 化
- domain-models/unit_003_migrate_prefs_relocation_domain_model.md の OutputPrefix に warn を追加 + OutputStream 値オブジェクト新設 + プレフィックス命名規約（warn=exit0継続通知 / error=exit2致命）を明記

設計乖離確認: ドメインモデル / 論理設計で定義した PreferenceKeyDetection / RelocationCommand / BulkActionState / OutputPrefix / OutputStream 全エンティティが script + steps + bats で実装されていることを確認。Unit 002 SetupGuidanceAggregate への参照（unit002-user-global）も保持

レビュー・テスト実施確認: 計画 / 設計 / コード / 統合の 4 種 AI レビュー全てラウンド指摘 0 件で完了。bats 119/119 PASS（migration 36 + config-defaults 34 + aidlc-setup 17 + aidlc-migrate-prefs 32）。markdownlint 0 errors

完了条件チェック: unit-003-plan.md の 25 項目全て [x] 化済み。NFR（非破壊性 / 冪等性 / dry-run 完全性）は keep.bats / idempotency.bats / dry-run.bats で実機検証済み

Codex Session: 019dd65c-dece-7ae2-93bc-0cb72194f627

---
