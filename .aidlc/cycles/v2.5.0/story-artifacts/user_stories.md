# ユーザーストーリー

## Epic 1: 4 階層設定の整理（#592）

### ストーリー 1: 個人好みキーを skill defaults へ集約

**優先順位**: Must-have

As a AI-DLC スターターキット利用者
I want to 「個人好み」設定 7 キー（reviewing.mode / reviewing.tools / automation.mode / git.squash_enabled / git.ai_author / git.ai_author_auto_detect / linting.enabled）が新規セットアップ時に project 共有の `.aidlc/config.toml` へ書き込まれない
So that 自分の好みが他のチームメンバーが clone するリポジトリに混入せず、user-global で個別管理できる

**対象キー集合（正規定義、本サイクル内全ファイルで参照）**:

```text
rules.reviewing.mode
rules.reviewing.tools
rules.automation.mode
rules.git.squash_enabled
rules.git.ai_author
rules.git.ai_author_auto_detect
rules.linting.enabled
```

**受け入れ基準**:

- [ ] `skills/aidlc-setup/templates/config.toml.template` から上記 7 キー全てが削除されている
- [ ] `skills/aidlc/config/defaults.toml` に削除した 7 キー全てが既定値付きで記載されている
- [ ] `read-config.sh` で各キーを読むと `defaults.toml` の値が返る（4 階層マージ仕様の動作確認）
- [ ] 既存プロジェクトの `.aidlc/config.toml` に同キーが残っている場合でも、4 階層マージで project 共有の値が優先される（後方互換）
- [ ] 新規 `aidlc-setup` 実行で生成される `.aidlc/config.toml` に上記 7 キーが含まれない

**技術的考慮事項**: `defaults.toml` の既定値と既存 `config.toml.template` の値が一致するように移植する（既定動作の変更を避ける）

---

### ストーリー 2: aidlc-setup ウィザードで user-global 推奨案内

**優先順位**: Should-have

As a AI-DLC スターターキット新規利用者
I want to `aidlc-setup` 実行中に「個人好みの設定は `~/.aidlc/config.toml`（user-global）に書くことを推奨」する案内を表示する
So that user-global に好みを集約する設計意図に気づき、project 共有を汚染しない運用を初期から取れる

**受け入れ基準**:

- [ ] `aidlc-setup` の対話フローのうち、生成サマリ表示直前または直後に「個人好みは `~/.aidlc/config.toml` 推奨」の案内テキストが 1 回表示される
- [ ] 案内テキストには対象 7 キー（ストーリー 1 の正規定義に従う）のうち代表 2〜3 件（`reviewing.mode` / `automation.mode` / `linting.enabled`）の例示が含まれる
- [ ] 案内テキストは `--non-interactive` モードでもログとして記録される（`stderr` 表示でもよい）
- [ ] 既存の `aidlc-setup` テスト（`test-` プレフィックスのスナップショット）が新案内追加を反映して通過する

**技術的考慮事項**: 既存ウィザードの UI 一貫性を保つため、確認プロンプトではなく「説明テキスト」として表示する

---

### ストーリー 3: aidlc-migrate で個人好みキーの移動提案

**優先順位**: Must-have

As a 既存 AI-DLC プロジェクトの利用者
I want to `aidlc-migrate` 実行時に、`.aidlc/config.toml` の「個人好み」キーを `~/.aidlc/config.toml` へ移動するか提案を受ける（強制移動はしない）
So that 既存プロジェクトを v2.5.0 仕様へ徐々に移行でき、判断はユーザー自身が握れる

**受け入れ基準**:

- [ ] `aidlc-migrate` 実行時、project `.aidlc/config.toml` に「個人好み」7 キー（ストーリー 1 の正規定義に従う）のいずれかが存在する場合、各キーごとに `AskUserQuestion` で「user-global へ移動 / そのまま残す / 全件移動（yes-to-all）/ 全件残す（no-to-all）」の 4 択を提示する
- [ ] **対話遷移規則**: 最初のキーで「全件移動（yes-to-all）」または「全件残す（no-to-all）」が選択された時点で、残りのキーは無質問で同一適用される（追加対話なし）。「user-global へ移動」または「そのまま残す」の場合は次のキーで再度 4 択を提示する
- [ ] 「user-global へ移動」選択時: 該当キーを `~/.aidlc/config.toml` に追記し、`.aidlc/config.toml` から削除する（dry-run でも差分を確認可能）
- [ ] 「そのまま残す」選択時: ファイルを変更せず黙って続行する（警告のみ表示）
- [ ] dry-run モードで実際の書き込みは行わず、変更予定の差分（追加先・削除先・キー名・値）が表示される
- [ ] 「次回も提案する / 抑制する」のオプションは v2.5.0 では未実装（Q4 として Construction 設計時に詳細化）

**技術的考慮事項**: TOML パース・編集は既存 `dasel` または `read-config.sh` の経路を活用する

---

## Epic 2: 振り返りステップ（#590）

### ストーリー 4: retrospective テンプレートと Operations 自動生成

**優先順位**: Must-have

As a AI-DLC 利用者
I want to Operations Phase 完了時に `operations/retrospective.md` が自動生成されるテンプレートとフローを使う
So that 「なぜ間違えたか」のプロセス学習を毎サイクル残せる

**受け入れ基準**:

- [ ] `templates/retrospective_template.md` が新規作成され、テンプレートには以下のセクションが含まれる: 1) 概要、2) 各問題項目（タイトル / 何が起きたか / なぜ起きたか / 損失と影響 / skill 起因判定 3 問）、3) 次サイクルへの引き継ぎ事項
- [ ] `steps/operations/04-completion.md` または相当する Operations 完了ステップに「retrospective 作成」サブステップが追加される
- [ ] サブステップは `feedback_mode ∈ {silent, mirror}` の場合に自動実行され、`.aidlc/cycles/{{CYCLE}}/operations/retrospective.md` を生成する。`feedback_mode = "disabled"` の場合はテンプレート生成自体をスキップ（Intent「feedback_mode 値の正式定義」の語彙と整合）
- [ ] 生成された retrospective.md は最低でも 1 件の問題項目（または「問題なし」明示）を含む（空ファイル禁止）
- [ ] テンプレート差分の markdownlint がパスする

**技術的考慮事項**: 既存サイクルの Operations 完了で遡及生成しないよう、v2.5.0 リリース後に開始する Operations Phase からのみトリガーする条件分岐を入れる

---

### ストーリー 5: skill 起因判定（3 問自問）

**優先順位**: Must-have

As a AI-DLC 利用者
I want to retrospective.md の各問題項目で「skill 起因か否か」を 3 問自問の形式で判定する
So that upstream Issue 候補を客観的かつ厳しめに絞り込み、氾濫を防ぐ

**受け入れ基準**:

- [ ] retrospective テンプレートの問題項目に「skill 起因判定」セクションがあり、**YAML フロントマター形式で機械可読**に以下のキーを保持する:
  ```yaml
  skill_caused_judgment:
    q1_answer: yes | no   # skill 内の具体的な箇所を引用できるか?
    q1_quote: "..."        # q1_answer=yes 時に必須、最小10文字
    q2_answer: yes | no   # 別の skill ファイルとの矛盾を示せるか?
    q2_quote: "..."        # q2_answer=yes 時に必須、最小10文字
    q3_answer: yes | no   # 「どう読んでも複数解釈できる」と示せるか?
    q3_quote: "..."        # q3_answer=yes 時に必須、最小10文字
  ```
- [ ] 3 問のうち 1 つ以上が `q*_answer: yes` の場合に `skill_caused = true` フラグが立つ
- [ ] 全て `no` の場合は `skill_caused = false` で retrospective ローカル記録のみ（upstream 候補にしない）
- [ ] **不正値ガード**: `q*_answer: yes` のキーに対応する `q*_quote` が空文字または最小 10 文字未満、または禁止語（`該当` / `あり` / `該当箇所` / `あります` 単独）の場合、警告を出して `skill_caused` を `false` に強制ダウングレードする

**技術的考慮事項**: YAML フロントマターは Markdown 互換のため markdownlint パスを保ちつつ、Unit 005/006 のロジックがパース可能。最終判定は Operations の retrospective サブステップでスキーマ検証 → 集計の順で実行する

---

### ストーリー 6: feedback_mode=mirror の /aidlc-feedback 連動

**優先順位**: Must-have

As a AI-DLC 利用者（upstream へ改善提案したい開発者）
I want to `feedback_mode=mirror` 設定下で、`skill_caused=true` の項目について「下書きを生成 → AskUserQuestion で承認 → /aidlc-feedback 経由で upstream Issue 起票」が動く
So that 安全に upstream 貢献でき、誤起票のリスクを下げられる

**受け入れ基準**:

- [ ] `defaults.toml` に `[rules.retrospective] feedback_mode = "silent"` が記載されている（user-global で `"mirror"` / `"on"` に上書き可能）
- [ ] `feedback_mode = "mirror"` 設定時、retrospective サブステップが各 `skill_caused=true` 項目について Markdown スニペット形式で Issue 下書きを生成する（タイトル / 本文 / 検出元: サイクル・Unit / 引用箇所 を含む）
- [ ] 各下書きについて `AskUserQuestion` で「送信する / 送信しない / 後で判断（保留）」の 3 択を提示する
- [ ] 「送信する」選択時: `/aidlc-feedback` スキル（または `gh issue create`）を呼び出し、Issue URL が stdout で確認できる。Issue URL は retrospective.md に追記される
- [ ] 「送信しない / 保留」選択時: retrospective.md に「skill 起因候補」として記録するのみで Issue 起票しない
- [ ] `feedback_mode = "silent"`（デフォルト）の場合、本フローは丸ごとスキップされる

**技術的考慮事項**: `/aidlc-feedback` の既存送信先設定を流用する。リポジトリ指定の固有設定は追加しない

---

### ストーリー 7: 氾濫緩和（重複検出 + サイクル毎上限）

**優先順位**: Should-have

As a メタ開発者（upstream リポジトリのメンテナ）
I want to 同一サイクル内で重複する skill 起因候補は統合提案のみ表示し、サイクル毎の起票上限を超えるとローカル記録のみに切り替わる
So that upstream Issue が氾濫せず、retrospective.md が肥大化しない

**受け入れ基準**:

- [ ] `defaults.toml` に `[rules.retrospective] feedback_max_per_cycle = 3` が記載されている（user-global で上書き可能）
- [ ] 同一サイクルの retrospective 内で「skill 引用箇所」または「タイトル類似度」が一致する複数項目を検出した場合、最初の 1 件のみ Issue 下書きを生成し、残りは「重複候補（最初の項目に統合）」と retrospective.md に記録する
- [ ] 同一サイクル内で `feedback_max_per_cycle` を超える `skill_caused=true` 項目が発生した場合、上限超過分はローカル記録のみとし、`AskUserQuestion` 表示も抑制する（ログにのみ「上限超過のためスキップ」と残す）
- [ ] 重複検出の対象は **同一サイクル内 retrospective に限定**（過去サイクル横断の AI 類似判定は v2.6.x 以降）
- [ ] 重複検出と上限ガードのロジックがユニットテストで個別検証される

**技術的考慮事項**: タイトル類似度は単純な文字列正規化 + Jaccard 係数または編集距離のしきい値で判定する（AI 推論は使わない）。実装複雑度を抑える
