# ユーザーストーリー

## Epic: 振り返りエコシステム総仕上げ（v2.5.1）

v2.5.0 で導入した retrospective 自動生成 + mirror モード + 主因切り分け 3 分類を、Issue ベースの一本化フローへ昇華させる。

---

### ストーリー 1: retrospective ローカルファイル撤廃と Issue 起票統合

**優先順位**: Must-have

As a AI-DLC を運用する開発者
I want to 振り返り内容をローカル `retrospective.md` ファイルではなく最初から GitHub Issue として記録したい
So that cycle ブランチ削除後も参照可能な永続化先に統一でき、ファイル/Issue 二重管理を解消できる

**受け入れ基準（正常系: Issue 一本化）**:

- [ ] **新規生成禁止**: `04-completion.md §1.5` 実行後、`.aidlc/cycles/{{CYCLE}}/operations/retrospective.md` は **生成されない**（`test ! -f` で 0 を返す）
- [ ] retrospective Issue が `gh issue list --milestone <CYCLE> --label retrospective` で取得できる
- [ ] 起票された Issue 本文に KPT（Keep/Try/Problem）と主因分類セクションが含まれる
- [ ] Issue 本文に v2.5.0 互換 YAML ブロック（`mirror_state`, `skill_caused_judgment`）が `gh issue view --json body | jq` で抽出可能

**受け入れ基準（mirror_state ラベル化）**:

- [ ] `mirror_state` の値域は v2.5.0 と完全一致（`""` / `pending` / `created` / `skipped:max_exceeded` / `skipped:duplicate` / `error`）
- [ ] 状態がラベル `mirror-state:<value>` で保持される（区切り `:`、`""` は **ラベル不要 = ラベル無し** で表現、空状態専用ラベルは追加しない）
- [ ] ラベル表記は colon 区切り統一: `mirror-state:created`, `mirror-state:skipped-max_exceeded`, `mirror-state:skipped-duplicate`, `mirror-state:error`（YAML 値の `:` は `-` に変換）
- [ ] 読み取り側（feedback_max_per_cycle 判定 / duplicate detector）は新ラベル経路を優先し、YAML を fallback とする

**受け入れ基準（旧資産読み取り互換 / 異常系）**:

- [ ] 既存 `cycles/{{PREV_CYCLE}}/operations/retrospective.md` の YAML パーサ読み取りは維持（v2.5.0 互換 / **読み取りのみ許可、新規生成は禁止**）
- [ ] 旧ファイルが残存していても Issue 起票フローは正常動作する（旧ファイルは無視せず読み取り経路として併存）

**受け入れ基準（gh 不可時のスプール）**:

- [ ] `gh_status != available` 時は `cycles/{{CYCLE}}/history/retrospective-spool.md` にスプール
- [ ] `scripts/retrospective-resend.sh` で次回 `gh` 利用可能時に再送できる
- [ ] スプールファイルは `history/` 配下のため cycle ブランチ削除後も main に保持される

**技術的考慮事項**:
- v2.5.0 の `mirror_state` YAML 構造は読み取り側互換のため Issue 本文にも残す
- スプール時は Issue 本文と同じ Markdown 形式で保存

---

### ストーリー 2: feedback_mode 5 値拡張 + 初回 wizard + cap 適用範囲

**優先順位**: Must-have

As a 振り返り Issue の起票先を選びたいユーザー
I want to 初回振り返り時に「プロダクト Issue / upstream Issue / 両方 / disabled」から選べる wizard と、選択モードに応じた cap 適用範囲が機能する状態
So that 自プロジェクトの性質に応じた起票先を文脈付きで決められ、過剰起票を抑制できる

**受け入れ基準（5 値拡張 + wizard）**:

- [ ] `feedback_mode` が `interactive` / `local-issue-only` / `mirror-only` / `local-and-mirror` / `disabled` の 5 値を取り得る
- [ ] `config/defaults.toml` に enum 制約（5 値）が記載される
- [ ] `feedback_mode = "interactive"` または未設定時、Operations 04-completion §1.5 直前で AskUserQuestion により wizard が起動する
- [ ] wizard 選択結果を `.aidlc/config.toml` に保存する（既存 wizard 設定保存パターンに準拠）
- [ ] wizard は **初回のみ** 起動。設定保存後の同一サイクル/次サイクル以降はスキップ
- [ ] CI/非対話環境では wizard が起動できないため `disabled` にフォールバック（保守的に「起票しない」を選ぶ）
- [ ] BATS テスト `tests/feedback-mode-wizard.bats` で wizard 起動条件と設定保存パスを検証

**受け入れ基準（cap 適用範囲 / Intent 判断 5 と整合）**:

- [ ] `feedback_max_per_cycle = 3` は維持（変更なし）
- [ ] mode 別適用が以下のとおり verify される（BATS テスト `tests/feedback-cap-by-mode.bats`）:
  - `local-issue-only` → プロダクト Issue 起票数のみカウント
  - `mirror-only` → upstream Issue 起票数のみカウント
  - `local-and-mirror` → プロダクト + upstream の **合算** で cap 適用
  - `interactive` → wizard で選択された経路のみに適用（合算 or 単独）
  - `disabled` → cap 適用なし（スキップ）
- [ ] cap 上限超過時の動作は v2.5.0 互換（ローカル記録のみ → v2.5.1 では Issue 起票せず本文を `retrospective-spool.md` に記録）

**技術的考慮事項**:
- AskUserQuestion 起動条件は `feedback_mode = "interactive"` または key 不在の両方をカバー
- wizard 中に「設定保存しますか？」確認を含める

---

### ストーリー 3a: 主因分類 LLM 下書き生成 + 失敗フォールバック

**優先順位**: Must-have

As a 振り返りで主因切り分けを記述する開発者
I want to 主因分類（プロダクト固有 / AI-DLC 固有 / 両方）と `skill_caused_judgment` 3 質問の引用文が LLM で自動下書きされ、失敗時には手動入力に fallback できる
So that 認知負荷が下がり、LLM 障害時にも振り返りが継続できる

**受け入れ基準（下書き生成本体）**:

- [ ] retrospective Issue 起票時、各「問題項目」に対し主因分類（3 値のいずれか）が LLM で下書きされ、本文に prefilled される
- [ ] `skill_caused_judgment` の q1/q2/q3 + 引用文も LLM で下書きされる
- [ ] LLM 下書き結果は YAML ブロック（既存 v2.5.0 形式と同一）で Issue 本文に保持される
- [ ] primary 実装は Claude Code（メインエージェントまたは `retrospective-drafter` subagent）

**受け入れ基準（失敗フォールバック + CI 分岐）**:

- [ ] LLM 失敗 / タイムアウト時は手動入力フォールバック（人間が AskUserQuestion で 3 分類を選択）
- [ ] CI / 非対話環境では LLM 実行をスキップし、retrospective Issue 起票自体を skip（`feedback_mode=disabled` 動作と同等）
- [ ] BATS テスト `tests/retrospective-llm-draft.bats` で「LLM 成功 → prefilled」「LLM 失敗 → 手動入力 prompt」「CI → skip」を verify

**技術的考慮事項**:
- subagent 化でコンテキスト分離を確保（main agent の context を肥大化させない）
- 既存の write-history.sh / mirror フローへの統合経路を維持

---

### ストーリー 3b: 主因分類の human_reviewed 確認運用 + 差分記録

**優先順位**: Should-have

As a LLM 下書きを利用する開発者
I want to 下書き結果を人間が確認・修正したことが Issue で追跡可能で、修正があれば差分が学習データとして記録される
So that LLM 出力の品質を継続改善でき、誤判定の傾向を観察できる

**受け入れ基準**:

- [ ] LLM 出力は人間確認・修正フローを必ず経由する（Issue 本文に `human_reviewed: true` マーカーが付与される）
- [ ] `human_reviewed: true` 未付与の Issue が存在する場合、`scripts/retrospective-verify.sh` で警告 exit ≥ 1
- [ ] LLM 推論結果と人間確認後の最終結果が異なる場合、差分が Issue コメントとして記録される（コメント本文に `[llm-diff]` プレフィックス）
- [ ] BATS テスト `tests/retrospective-human-review.bats` で「LLM 結果 == 人間結果 → 差分コメントなし」「不一致 → 差分コメント記録」「marker 未付与 → verify 警告」を verify

**技術的考慮事項**:
- 既存の write-history / mirror 起票フローのコメント追加経路を再利用
- `[llm-diff]` プレフィックスは将来の自動分析（LLM 学習サンプル収集）を想定

---

### ストーリー 4: predecessor handoff の Issue 検索化

**優先順位**: Must-have

As a 新サイクル Inception を開始する開発者
I want to 前サイクルの振り返り内容をファイル参照ではなく Issue 検索で取得したい
So that cycle ブランチ削除後も参照経路が壊れず、`predecessor_retrospective.md` 手動配置の手間がなくなる

**受け入れ基準（正常系 / 検索成功）**:

- [ ] `01-setup.md §4a` で前サイクル closed Milestone + `retrospective` ラベル の AND 検索で前サイクル Issue を取得する
- [ ] ヒット 1 件 → 自動採用、コンテキスト変数 `predecessor_retrospective_issue_url` に格納
- [ ] ヒット ≥ 2 件 → AskUserQuestion で対話確認（候補一覧から選択）

**受け入れ基準（異常系 / フォールバック判定順）**:

判定順は以下を厳密に守る（`milestone_enabled=true` 環境）:
1. **Milestone 検索 0 件** → `cycles/{{PREV_CYCLE}}/history/retrospective-spool.md` を fallback で確認 → spool 存在なら Intent 前提として読み取り
2. **Milestone 検索 1 件** → 自動採用（前項と同じ）
3. **Milestone 検索 ≥ 2 件** → AskUserQuestion 対話確認

`milestone_enabled=false` 環境の判定順:
1. **label 検索 0 件** → spool fallback（同上）
2. **label 検索 1 件** → 自動採用
3. **label 検索 ≥ 2 件** → `closedAt` 降順で最新を提示し AskUserQuestion で確認

`gh_status != available` 環境の判定順:
1. **gh 不可** → spool fallback（同上、spool 存在で Intent 前提として読み取り）
2. **spool も無し** → predecessor 参照なしで継続（warn 表示）

**受け入れ基準（旧資産読み取り互換 / 廃止境界）**:

- [ ] **新規生成禁止**: `01-setup.md` から `predecessor_retrospective.md` 関連の手動配置案内が grep で 0 件
- [ ] **新規生成禁止**: `templates/predecessor_retrospective.md` テンプレが廃止（または存在しても警告）
- [ ] **旧資産読み取りのみ許可**: 既存 `cycles/{{PREV_CYCLE}}/operations/retrospective.md` ファイルが残存する場合の読み取り経路は維持（v2.5.0 互換、Issue 検索 0 件時の追加 fallback として動作）

**技術的考慮事項**:
- Issue 取得失敗時のフォールバック設計を明確に
- `gh issue list` の `--state all` で closed Milestone 内の Issue が取得できる

---

### ストーリー 5: feedback_mode マイグレーション（破壊的動作変更の防止）

**優先順位**: Must-have

As a v2.5.0 から v2.5.1 にアップグレードするユーザー
I want to 旧 `feedback_mode` 値（`silent` / `mirror` / `disabled`）が新値へ自動マイグレーションされ、動作変更を伴うマッピングは明示同意で行われる
So that 知らないうちに Issue 起票が始まる等の破壊的動作変更を避けられる

**受け入れ基準（マイグレーション本体）**:

- [ ] `aidlc-migrate` 実行時、写像表に従い `.aidlc/config.toml` を書き換え
- [ ] `silent` → `interactive` への変更は同意プロンプトを表示し、ユーザーが拒否した場合は `disabled` にフォールバック
- [ ] `mirror` → `mirror-only` は名前変更のみで動作互換、警告なし
- [ ] `disabled` → `disabled` は変更なし
- [ ] 未設定（key 不在） → `interactive` に設定（新規ユーザー向け）
- [ ] 非対話環境では `silent` → 新値の自動昇格を禁止 → `disabled` フォールバック
- [ ] `aidlc-migrate --rollback` で `.aidlc/config.toml.backup-<timestamp>` を復元できる

**受け入れ基準（ストーリー2 との責務境界）**:

最終決定値の確定責務（対話環境 / 非対話環境 行分割）:

| シナリオ | 環境 | 最終決定責務 | ストーリー 2 wizard 起動有無 | 結果 feedback_mode |
|---------|------|-------------|--------------------------|-------------------|
| migrate 済み（silent→interactive 同意済み） | 対話 | 04-completion §1.5 wizard | 起動 | wizard 選択値 |
| migrate 済み（silent→interactive 同意済み） | 非対話 | aidlc-migrate（既に interactive） | 起動できず → `disabled` fallback | `disabled`（保守的） |
| migrate 済み（silent→disabled 拒否経路） | 対話 / 非対話 | aidlc-migrate | 起動しない | `disabled` |
| migrate 済み（mirror→mirror-only） | 対話 / 非対話 | aidlc-migrate | 起動しない | `mirror-only` |
| migrate 未実施 + 旧 silent 残存 | 対話 | 04-completion §1.5 で警告 + メモリ内 `interactive` 扱い → wizard | 起動 | wizard 選択値（config 書き換えなし、no-op 互換） |
| migrate 未実施 + 旧 silent 残存 | 非対話 | 04-completion §1.5 で警告 + 自動 `disabled` fallback | 起動できず → `disabled` fallback | `disabled`（保守的、config 書き換えなし） |
| migrate 未実施 + 新規ユーザー（key 不在） | 対話 | 04-completion §1.5 wizard | 起動 | wizard 選択値 |
| migrate 未実施 + 新規ユーザー（key 不在） | 非対話 | 04-completion §1.5 で `disabled` fallback | 起動できず → `disabled` fallback | `disabled` |

**設計原則**: 非対話環境では **常に wizard を起動できないため `disabled` フォールバック**。これにより CI 等で意図しない Issue 起票が起きないことを保証する。

- [ ] BATS テスト `tests/feedback-mode-migration.bats` で以下を verify:
  - 「対話: silent→interactive ＋ wizard 拒否時 disabled へ fallback」
  - 「非対話: silent→disabled へ自動 fallback」
  - 「mirror→mirror-only は同意不要で無警告」
  - 「migrate 未実施: silent 残存環境で 04-completion §1.5 が wizard 起動 + 警告表示」

**技術的考慮事項**:
- 既存の `aidlc-migrate` rollback 機能を再利用
- マイグレーション失敗時の警告 + no-op 動作を維持

---

### ストーリー 6: #616 マージ前 write-history 追加コミット漏れガード

**優先順位**: Should-have

As a Operations Phase でマージ前レビューを反映する開発者
I want to 7.12 PR マージ前レビュー反映後の `/write-history` 追加コミット漏れが検出されてマージブロックされる
So that v2.4.3 で発生した未コミット履歴差分の破棄事故を未然に防げる

**受け入れ基準（Option 非依存 / 必ず成立すべき観測点）**:

これらは実装 Option（A: review-flow ガード / B: write-history --commit / C: verify-git 必須化 / D: write-history 1 回限定）の選定に **依存せず必ず成立**:

- [ ] 7.12 マージ前レビュー反映後に未コミット差分が残った状態でフェーズ完了処理を実行すると、必ず exit ≥ 1 を返すいずれかのガードが発火する（具体的なガード箇所は Construction で確定）
- [ ] BATS テスト `tests/operations-uncommitted-detection.bats` で「マージ前レビュー後 write-history 後の未コミット → exit ≥ 1」を verify
- [ ] 既存の Issue #579（マージ後 write-history 禁止 exit 3）との整合は維持

**受け入れ基準（Option 依存 / Construction で確定後に差し替える暫定基準）**:

- [ ] `scripts/operations-release.sh verify-git` の実装変更（暫定）または `write-history.sh --commit` 追加（暫定）または `review-flow.md` の手順明示（暫定）。Construction Phase で Option を 1 つに確定してから受け入れ基準を確定値に置換する

**技術的考慮事項**:
- `review-flow.md` L50「レビュー後コミット」の曖昧定義を明確化
- 実装 Option（A: review-flow ガード / B: write-history --commit / C: verify-git 必須化 / D: write-history 1 回限定）の選定は Construction で確定
