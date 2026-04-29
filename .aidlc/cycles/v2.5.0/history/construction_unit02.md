# Construction Phase 履歴: Unit 02

## 2026-04-29T08:16:15+09:00

- **フェーズ**: Construction Phase
- **Unit**: 02-setup-wizard-prefs-guidance（aidlc-setup ウィザードの個人好み推奨案内）
- **ステップ**: AIレビュー完了
- **実行内容**: 計画承認前レビュー（reviewing-construction-plan / codex / 3 ラウンド）で指摘 4→2→0 件に収束。

- ラウンド 1（4 件 / 高 1・中 2・低 1）: --non-interactive AC vs 実動作整合（高）、観点A2式不整合（中）、観点C2 grep -E パイプエスケープ（中）、Unit 003 参照スタンス（低）
- ラウンド 2（2 件 / 中 1・低 1）: 「初回セットアップ限定」と「automation_mode 全モード対応」のスコープ衝突（中）、観点C2 OR記法に誤表記残存（低）
- ラウンド 3: 指摘ゼロ

主な反映: AC「--non-interactive でもログ記録」を automation_mode 全モード対応 + stderr リダイレクト指示に再定義し実動作保証へ転換。観点 C3 を新設。観点 A2 ヘルパ関数化、C2 を 2 段判定方式に統一。Unit 003 の参照を計画書ではなく実装ソース（03-migrate.md L9b）に固定。

Codex Session: 019dd65c-dece-7ae2-93bc-0cb72194f627（記録時の thread_id）

---
## 2026-04-29T08:25:08+09:00

- **フェーズ**: Construction Phase
- **Unit**: 02-setup-wizard-prefs-guidance（aidlc-setup ウィザードの個人好み推奨案内）
- **ステップ**: AIレビュー完了
- **実行内容**: 設計レビュー（reviewing-construction-design / codex / 3 ラウンド）で指摘 4→2→0 件に収束。

- ラウンド 1（4 件 / 中 2・低 2）: ドメインモデルへの required_tokens 混入（中）、C3/D2 仕様不一致（中）、ヘルパ環境変数と関数 API の同列扱い（低）、Unit 003 連携が見出し文言依存（低）
- ラウンド 2（2 件 / ともに低）: required_tokens 残存箇所 3 ヶ所（domain）、2 ヶ所（logical）の語彙統一漏れ
- ラウンド 3: 指摘ゼロ（rg で required_tokens 残存ゼロを実機確認）

主な反映:
- ドメイン層は semantic_requirements（抽象的な意味要件）に統一し、具体トークン（`rules.reviewing.mode` 等）は論理設計／テスト設計層へ移管
- C3 に「初回セットアップ」必須トークンを追加し D2 と整合（D2 を「初回セットアップ」固定検査に統一）
- ヘルパ契約を「定数/環境変数」表 + 「関数 API（引数 / 戻り値 / 失敗時 exit code）」表に分離
- GuidanceMessage に stable_id 属性を導入。markdown には HTML コメントアンカー `<!-- guidance:id=unit002-user-global -->` を埋め込み、Unit 003 は安定 ID で参照する契約に変更（見出し文言変更耐性）

Codex Session: 019dd65c-dece-7ae2-93bc-0cb72194f627（記録時の thread_id）

---
## 2026-04-29T08:38:55+09:00

- **フェーズ**: Construction Phase
- **Unit**: 02-setup-wizard-prefs-guidance（aidlc-setup ウィザードの個人好み推奨案内）
- **ステップ**: AIレビュー完了
- **実行内容**: コードレビュー（reviewing-construction-code / codex / 2 ラウンド）で指摘 2→0 件に収束。

- ラウンド 1（2 件 / 中 1・低 1）: S1 が直前位置を保証していない（中）、stable ID の一意性検証不足（低）
- ラウンド 2: 指摘ゼロ

主な反映:
- S1 を強化: コメント行番号と ## 9b. 行番号を grep -n で取得し `line_comment + 1 == line_9b` を検証（空行を許さない直前配置）
- S2 を新設: HTML コメントアンカー `<!-- guidance:id=unit002-user-global -->` の出現数を grep -c -F -- で 1 固定検証

セキュリティ観点: N/A（markdown / 静的テスト / CI 設定変更のみで新規リスク増分なし）

事前ローカル検証:
- bats tests/aidlc-setup/ で 17/17 PASS（観点 A 3 + B 3 + C 3 + D 4 + R 2 + S 2 = 17）
- bats tests/migration/ tests/config-defaults/ tests/aidlc-setup/ で 87/87 PASS（migration 36 + config-defaults 34 + aidlc-setup 17、回帰なし）
- bin/check-defaults-sync.sh sync:ok
- markdownlint-cli2 で対象 4 ファイル 0 errors

Codex Session: 019dd65c-dece-7ae2-93bc-0cb72194f627（記録時の thread_id）

---
## 2026-04-29T08:41:18+09:00

- **フェーズ**: Construction Phase
- **Unit**: 02-setup-wizard-prefs-guidance（aidlc-setup ウィザードの個人好み推奨案内）
- **ステップ**: AIレビュー完了
- **実行内容**: 統合レビュー（reviewing-construction-integration / codex / 2 ラウンド）で指摘 2→0 件に収束。

- ラウンド 1（2 件 / 中 1・低 1）: Unit 定義の実装状態未更新（中）、計画チェックリスト未チェック（低）
- ラウンド 2: 指摘ゼロ

主な反映:
- Unit 002 定義（story-artifacts/units/002-...md）の状態を「未着手」→「完了」、開始日/完了日を 2026-04-29、担当を Claude Code に更新
- unit-002-plan.md の完了条件 17 項目（既存 16 + 安定 ID 契約 S1/S2 追加項目 1）を全て [x] 化し、各項目に達成証跡（PASS 件数 / 検証ツール）を追記

セミオートゲート判定: review_mode=required, automation_mode=semi_auto, unresolved_count=0 → auto_approved（実装承認）

事前ローカル検証は変更なし: bats 87/87 PASS（migration 36 + config-defaults 34 + aidlc-setup 17、回帰なし）/ sync:ok / markdownlint 0 errors

Unit 002 関連コミット: c8e83b18（計画）/ 45b41f46（設計）/ b2c9eec4（実装）

Codex Session: 019dd65c-dece-7ae2-93bc-0cb72194f627（記録時の thread_id）

---
