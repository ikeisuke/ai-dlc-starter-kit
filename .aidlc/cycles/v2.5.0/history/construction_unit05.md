# Construction Phase 履歴: Unit 05

## 2026-04-29T13:30:00+09:00

- **フェーズ**: Construction Phase
- **Unit**: 05-mirror-feedback-integration（mirror モードの /aidlc-feedback 連動）
- **ステップ**: 計画AIレビュー完了
- **実行内容**: 計画レビュー（reviewing-construction-plan / codex / 3 ラウンド）で指摘 5→2→0 件に収束。

- ラウンド 1（5 件 / 高 2・中 2・低 1）: 送信経路（`/aidlc-feedback` vs `gh issue create` 直）の選定根拠が未明文化（高 / DR-006 不在）、recoverable/fatal 失敗契約の未分離（高）、retrospective.md 書き換えのトランザクション保証不足（中）、upstream_repo の単一ソース化未確定（中）、bats フィクスチャ命名不統一（低）
- ラウンド 2（2 件 / 中 2）: AskUserQuestion レイヤと Step 5 の責務境界曖昧、テスト観点 D/S/R/IM のラベル整合性不足
- ラウンド 3: 指摘ゼロ

主な反映:
- `inception/decisions.md` に DR-006 を追加。送信経路は `gh issue create` 直接呼び出しを採用、recoverable/fatal 2 系統失敗契約を明文化（recoverable: gh CLI 失敗 → exit 0 + `mirror\tsend-failed`、fatal: 構造的不正 → exit 2 + `error\t...`）
- 計画書に upstream_repo の単一ソース化（`defaults.toml` `[rules.feedback]` への集約）と `^[A-Za-z0-9._-]+/[A-Za-z0-9._-]+$` 正規表現バリデーションを追加
- retrospective.md 書き換えに mktemp + mv -- ベースのアトミック更新（_safe_transform）を採用、書き込み失敗時の rollback 経路を明記
- Step 5 (mirror フロー) 責務を「AskUserQuestion ↔ retrospective-mirror.sh 呼び出しのみ」に絞り、判定ロジックは全てスクリプトへ集約
- 観点ラベルを D（detect）/ S（send）/ R（record）/ IM（step-integration）の 4 種に統一

Codex Session: 019dd72c-fd80-7f12-a5ac-a8e0e1c0d4b0

---
## 2026-04-29T14:15:00+09:00

- **フェーズ**: Construction Phase
- **Unit**: 05-mirror-feedback-integration（mirror モードの /aidlc-feedback 連動）
- **ステップ**: 設計AIレビュー完了
- **実行内容**: 設計レビュー（reviewing-construction-design / codex / 2 ラウンド）で指摘 4→0 件に収束。

- ラウンド 1（4 件 / 中 3・低 1）: MirrorFlowAggregate と Unit 004 RetrospectiveAggregate の境界記述不足（中）、mirror_state YAML キー（state / issue_url / recorded_at）の永続化スキーマ未定義（中）、SnapshotReference の意図が IssueDraft 内のラベル参照と曖昧（中）、状態遷移図（Empty → Sent / Skipped / Pending）の表現省略（低）
- ラウンド 2: 指摘ゼロ

主な反映:
- ドメインモデルに MirrorFlowAggregate（Unit 005 独立 / Unit 004 のロジックは参照のみ）を明記、Unit 004 RetrospectiveAggregate との境界を「読み取りは共有 / 書き込みは Unit 005 独立」と定義
- 論理設計 §3 に mirror_state ブロック仕様（YAML 内の 3 キー / state_enum / issue_url_pattern / recorded_at_pattern）を追加し `retrospective-schema.yml` への移植先を明示
- SnapshotReference を「retrospective.md L\d+ 行参照 + 引用テキスト先頭 60 文字」に明確化、IssueDraft の検出元節への埋め込み規約を追記
- 状態遷移図 ASCII を追加し Empty → Sent / Skipped / Pending の遷移と record 上書き許容（任意の状態 → 任意の状態）を明示

Codex Session: 019dd734-8c12-4e89-9532-a8e0e1c0d4b1

---
## 2026-04-29T15:30:00+09:00

- **フェーズ**: Construction Phase
- **Unit**: 05-mirror-feedback-integration（mirror モードの /aidlc-feedback 連動）
- **ステップ**: コードAIレビュー完了
- **実行内容**: コードレビュー（reviewing-construction-code / codex / 4 ラウンド）で指摘 6→3→1→0 件に収束。

- ラウンド 1（6 件 / 高 1・中 4・低 1）:
  - (高/code) `_rewrite_mirror_state` の awk 関数が partial mirror_state（一部キーのみ既存）の場合に重複ブロックを生成
  - (中/code) `gh-not-installed` 検出経路が schema.send_failure_reasons に未登録、契約と実装の二重管理
  - (中/code) IFS 既定値（タブを空白として折りたたむ）により candidate 行の 4 フィールド読み込みが破綻
  - (中/security) draft path 検証なし、`/tmp/...` 配下以外の任意パス受付
  - (中/code) BSD sed の `[ \t]` リテラル `t` 解釈バグで `gh-rate-limit` が `gh-rate-limi` に切詰
  - (低/code) macOS BSD mktemp テンプレートの suffix 処理（X が末尾にないと展開されない）
- ラウンド 2（3 件 / 中 2・低 1）: dasel 単引用符付き出力（`'...'`）の strip 漏れ、mixed-state フィクスチャでの非末尾問題更新で `_rewrite_mirror_state` が exit 1、tmpfile クリーンアップが trap EXIT 連動なし
- ラウンド 3（1 件 / 低 1）: shellcheck SC2086 ワーニング（変数展開のクォート不足 1 箇所）
- ラウンド 4: 指摘ゼロ

主な反映:
- `_rewrite_mirror_state` を `block_existed` 判定 + `flush_missing_keys()` ヘルパーで「既存キーを保持 / 不足キーのみ追加 / 重複ブロック生成回避」に再設計
- `retrospective-schema.yml` の `send_failure_reasons` に `gh-not-installed` を追加、5 値固定列挙化
- candidate 行 TSV 出力を `mirror\tcandidate\t<idx>\t<state-or-dash>\t<draft_path>` に変更し、空 state は `-` プレースホルダ。read 後に `state="-"` → `state=""` 復元
- draft path 検証を `/tmp` 配下 + `retrospective-mirror-draft.<idx>.<random>.md` ファイル名固定に限定（path traversal 対策）
- BSD sed 互換のため `[ \t]` を全て POSIX `[[:space:]]` に置換
- mktemp `XXXXXX` テンプレートを末尾固定 + `.md` リネーム方式に変更
- dasel 出力 strip 用 `_strip_quotes` ヘルパー追加（`"` / `'` 両対応）
- `_rewrite_mirror_state` の `has_state/has_url/has_at` フラグを `updated_target` 単一フラグに集約、問題境界での `check_target_completion()` 呼び出しで非末尾問題更新を健全化
- `_register_cleanup` / `_cleanup_tmpfiles` で trap EXIT による tmpfile 自動削除
- shellcheck で警告ゼロ確認（SC1091 / SC2016 info のみ）

セキュリティ観点:
- パストラバーサル / シンボリックリンク悪用: 排除（`/tmp` + ファイル名固定）
- gh CLI 認証情報漏洩: stderr 抑止 + 構造化エラー分類のみ stdout 出力
- 通信暗号化: gh CLI 内部の HTTPS 利用、本実装で扱わず N/A
- ログ・監視: ローカル CLI / 監視基盤なしのため N/A

Codex Session: 019dd741-2cf2-4a89-bee0-2b83a196c581

---
## 2026-04-29T16:25:00+09:00

- **フェーズ**: Construction Phase
- **Unit**: 05-mirror-feedback-integration（mirror モードの /aidlc-feedback 連動）
- **ステップ**: 統合AIレビュー完了
- **実行内容**: 統合レビュー（reviewing-construction-integration / codex / 2 ラウンド）で指摘 2→0 件に収束。

- ラウンド 1（2 件 / 中 2）:
  - (中/完了条件) 計画書 unit-005-plan.md のチェックリストが `[ ]` のままで実装エビデンス（テスト件数・shellcheck 結果）未記録
  - (中/architecture, inception) ドメインモデル / 論理設計の SendFailureReason 列挙が 4 値のままで実装の 5 値（gh-not-installed 追加後）と非同期。`retrospective-schema.yml` も 5 値登録済みのため設計ドキュメントのみ追従漏れ
- ラウンド 2: 指摘ゼロ

主な反映:
- unit-005-plan.md チェックリスト全項目を `[x]` 化、エビデンス追記（detect 7 / send 6 / record 6 / step-integration 5 = 24 PASS、shellcheck 警告ゼロ、既存 retrospective テスト 43/43 PASS、migration-tests.yml PATHS_REGEX 拡張済み）
- ドメインモデル `SendFailureReason` に `GhNotInstalled` を追加し 5 値化、不変条件に「`retrospective-schema.yml` の `send_failure_reasons` と完全同期する単一ソース契約」を明記、`to_payload()` 例示を 5 値対応に拡張
- 論理設計 §終了コード規約表の recoverable failure 行を「5 種固定: gh-not-installed / gh-not-authenticated / gh-rate-limit / gh-network-error / gh-unknown-error」に修正、エラーカテゴリ表に「gh 未インストール」行を追加（`command -v gh` 失敗 → recoverable failure / `mirror\tsend-failed\t<idx>\tgh-not-installed` + exit 0）

事前ローカル検証:
- bats tests/retrospective-mirror/ で 24/24 PASS（detect 7 / send 6 / record 6 / step-integration 5）
- bats tests/retrospective/ で 43/43 PASS（回帰なし）
- bats tests/migration/ tests/config-defaults/ tests/aidlc-setup/ tests/aidlc-migrate-prefs/ tests/retrospective/ tests/retrospective-mirror/ で 186/186 PASS（migration 36 + config-defaults 34 + aidlc-setup 17 + aidlc-migrate-prefs 32 + retrospective 43 + retrospective-mirror 24）
- shellcheck で `retrospective-mirror.sh` 0 actionable 警告
- markdownlint で対象 .md ファイル 0 errors

Codex Session: 019dd820-3026-7061-bee0-2b83a196c584

---
