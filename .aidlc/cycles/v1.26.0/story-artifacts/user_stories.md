# ユーザーストーリー

## Epic: 設定の柔軟化と品質基盤の強化

### ストーリー 1: バックログモード別の成果物フォーマットバリデーション
**優先順位**: Must-have
**関連Issue**: #315

As a AIエージェント
I want to バックログモードに応じた成果物形式のバリデーションルールが明示されている
So that 誤ったフォーマットでバックログを保存するミスを防止できる

**受け入れ基準**:
- [ ] `git-only` モード時、バックログをローカルファイル（`docs/cycles/backlog/`）にのみ保存し、GitHub Issue作成は禁止される旨がルール化されている
- [ ] `issue-only` モード時、バックログをGitHub Issueにのみ作成し、ローカルファイル作成は禁止される旨がルール化されている
- [ ] `git` モード時、ローカルファイルが優先だがIssue作成も許可される旨がルール化されている
- [ ] `issue` モード時、GitHub Issueが優先だがローカルファイル作成も許可される旨がルール化されている
- [ ] AIがバックログ保存前にモードを確認し、禁止形式での保存を行わない旨が明記されている（検証タイミング: バックログ保存時）
- [ ] 禁止形式での保存を試みた場合の期待動作が定義されている（例: 「【バリデーションエラー】issue-onlyモードではローカルファイル作成は禁止されています」等の警告を出力し、正しい形式で保存し直す）
- [ ] バリデーションルールは `prompts/package/prompts/common/rules.md` のバックログセクションに追加されている

**技術的考慮事項**:
- 変更は rules.md のプロンプトテキストのみ（スクリプト変更不要）
- 既存のバックログ管理ガイド（`docs/aidlc/guides/backlog-management.md`）との整合性を維持
- バリデーションはAIエージェントがプロンプトルールに従って実行（実行時チェック機構ではなくプロンプトベースの制約）

---

### ストーリー 2: プリフライトチェック項目の設定化
**優先順位**: Must-have
**関連Issue**: #323

As a AI-DLCスターターキット利用者
I want to プリフライトチェック項目のon/offを `aidlc.toml` で制御できる
So that プロジェクト特性に応じて不要なチェックを省略し、セッション開始を高速化できる

**受け入れ基準**:
- [ ] `docs/aidlc.toml` に `[rules.preflight]` セクションが追加され、`enabled`（デフォルト: true）と `checks` リストが定義されている
- [ ] `rules.preflight.checks` にチェック項目（gh, review-tools等）をリストで指定でき、リストにない項目はスキップされる
- [ ] `rules.preflight.enabled = false` の場合、blockerチェック（git存在確認、aidlc.toml存在確認）は常時実行し、それ以外のチェック（gh, review-tools, 設定値取得）がスキップされる（警告メッセージを表示）
- [ ] `rules.preflight.checks` が未設定の場合、現行の全項目チェック（gh, review-tools, config-validation）が実行される（後方互換性）
- [ ] `rules.preflight.checks` が空配列 `[]` の場合、blockerチェックのみ実行される（オプションチェック全スキップ）
- [ ] `rules.preflight.checks` に未知の項目が含まれる場合、警告を表示してその項目を無視し、残りの項目を実行する
- [ ] `preflight.md` の手順5（レビューツール確認）が `checks` リストの設定に従って動作する

**技術的考慮事項**:
- `read-config.sh` の配列読取機能を活用
- blockerチェック（git, aidlc.toml存在確認）は設定に関わらず常時実行（無効化不可）
- オプションチェック項目の有効値: `gh`, `review-tools`, `config-validation`

---

### ストーリー 3: Self-Healingリトライ回数の設定化
**優先順位**: Must-have
**関連Issue**: #322

As a AI-DLCスターターキット利用者
I want to Self-Healingループの最大リトライ回数を `aidlc.toml` で設定できる
So that テストスイートの規模や実行時間に応じてリトライ回数を最適化できる

**受け入れ基準**:
- [ ] `docs/aidlc.toml` に `[rules.construction]` セクションの `max_retry`（デフォルト: 3）が追加されている
- [ ] `construction.md` のSelf-Healingループが `max_retry` 設定値を参照して試行回数を制御する
- [ ] `max_retry` 未設定時は3回（現行動作と同一）で動作する
- [ ] `max_retry` に0を設定した場合、Self-Healingループをスキップして即座にユーザー判断フォールバック（construction.md「Self-Healing失敗時のフォールバック」セクション）に進む
- [ ] `max_retry` に負の値や非数値を設定した場合、警告を表示してデフォルト値3にフォールバックする
- [ ] プリフライトチェック時に `rules.construction.max_retry` がコンテキスト変数として取得される

**技術的考慮事項**:
- construction.md 内の "最大3回" ハードコード箇所を全て設定値参照に変更
- バリデーション: 0以上の整数のみ許可
