# ユーザーストーリー

## Epic: AI-DLC スターターキット v2.6.5 改善（5 Issue 集約サイクル）

直近 2 サイクル（v2.6.3 / v2.6.4）の運用で表面化した課題を、スターターキットのフロー・テンプレ・CI ガード・委譲規約に構造的に組み込み、再発を予防する。

---

### ストーリー 1: Inception での Unit 重複起案を未然に検出する

**優先順位**: Must-have

As a AI-DLC スターターキット利用者の AI エージェント / 開発者
I want to Inception Phase での Unit 定義策定時に、直近 N サイクル（既定 3 サイクル想定）の完了 Unit スラグおよび関連 CLOSED Issue 番号と自動突合し、重複候補を AskUserQuestion で警告できる
So that v2.6.4 Unit 001 のような「他サイクル完了 Unit と完全一致のスラグ + 重複責務」状態を最初から防げる

**受け入れ基準**:

- [ ] `skills/aidlc/steps/inception/` 配下の Unit 定義策定ステップに「直近サイクル完了 Unit との重複チェック」手順が追加され、SoT として明文化されている
- [ ] チェック手順は (a) `.aidlc/cycles/v*.*/story-artifacts/units/*.md` のファイル名（スラグ）一覧の取得、(b) 各 Unit 定義ファイルの「関連Issue」セクションから Issue 番号を抽出、(c) 取得した Issue 番号の OPEN/CLOSED 状態を `gh issue view --json state` で確認、の 3 ステップを含む
- [ ] スラグ完全一致または「同一 CLOSED Issue 番号への紐付け」が検出された場合、AskUserQuestion で「重複候補として起案を取り下げる / そのまま起案を継続する（理由記録必須）」を選択できる
- [ ] 警告デフォルトは「ブロックせず警告 + AskUserQuestion」であり、ユーザーが継続を選んだ場合は理由を該当 Unit 定義ファイルの末尾コメントとして記録する
- [ ] 本サイクル自身の Inception でドッグフーディング検証され（予定 U1〜U5 スラグが v2.6.3 / v2.6.4 完了 Unit と一致なしと判定された記録が成果物に残る）、検証履歴が `.aidlc/cycles/v2.6.5/history/inception.md` に記録される

**技術的考慮事項**:

- 直近 N サイクル数は config 値（既定 3）として将来拡張可能な形にする
- `phase-recovery-spec.md` の materialized binding 構造を破壊しないこと
- false positive（偶然のスラグ一致）を考慮し、デフォルトは警告のみでブロックしない

---

### ストーリー 2: Construction Phase 1 で設計起草前に既存実装を Read する工程を必須化する

**優先順位**: Must-have

As a AI-DLC スターターキット利用者の AI エージェント
I want to Construction Phase 1（設計フェーズ）の設計起草前に、変更対象機能の既存実装コードを事前に Read してから設計を起草する工程がテンプレ・チェックリスト・レビュー観点に組み込まれている
So that 「既存実装の挙動を読まずに設計起草」を主因とする Round 1 設計レビュー反復（margin セマンティクス／責務分担／paint タイミング齟齬等）を構造的に予防できる

**受け入れ基準（必須）**:

- [ ] `skills/aidlc/templates/construction_plan_template.md` または該当 plan テンプレに「## 事前コード読込み」セクションが追加され、(a) Read 対象ファイル + 読込み目的、(b) 読込みから抽出した「設計時に意識すべき挙動」、(c) 既存実装に基づく代替案の検討、の 3 サブセクションを必須化している
- [ ] `skills/aidlc/steps/construction/` 配下の設計起草フローステップに「事前コード Read → 設計起草」の二段階分離が明示されている
- [ ] `skills/reviewing-construction-design/SKILL.md` の `architecture` focus 観点に「設計ドキュメントに『事前コード読込み』セクションが存在し、変更対象 utility / hook / 隣接コンポーネントの挙動が引用されているか」のチェック項目が追加されている
- [ ] 改修後の `reviewing-construction-design` で「事前コード Read セクション不在」を検出する**判定条件と失敗時アクション**が明示されている: 判定条件 = plan ドキュメント内に「## 事前コード読込み」見出しが存在しない、または存在しても (a) Read 対象ファイル一覧、(b) 設計時に意識すべき挙動、(c) 代替案検討 のサブセクションが空である場合。失敗時アクション = `reviewing-construction-design` の `architecture` focus で「指摘 #N - 事前コード Read セクション不在 / 内容不足」を 1 件以上出力し、当該 Round を **設計レビュー不合格** として扱う（修正されるまで次 Round へ反復）
- [ ] 本サイクル U2 自身の Construction Phase で改修内容のドッグフーディング（U2 自身の plan に事前コード Read セクションが書かれていること）が確認される

**技術的考慮事項**:

- 既存の `templates/construction_plan_template.md` を破壊的変更しないようセクション追加方式で行う
- `#633`（責務領域全体を広視野で検討するプロンプト指示）/ `#692`（副作用境界 / ドメイン層分離評価軸）は本サイクルでは対象外（intent §含まれないもの 参照）

---

### ストーリー 3: Operations §7.13 直前にマージ前完結契約最終確認を常時表示する

**優先順位**: Must-have

As a AI-DLC スターターキット利用者の AI エージェント / 開発者
I want to Operations Phase §7.13（PR マージ実行）の AskUserQuestion 直前に「マージ後はサイクル成果物が凍結されます。記録漏れがないか最終確認してください」を提示する AskUserQuestion が常時実行される
So that post-merge cleanup の流れで progress.md / history/operations.md / post_release_operations.md に追記しようとする手順違反 + branch protection reject + rollback の連鎖を未然に防げる

**受け入れ基準（必須）**:

- [ ] `skills/aidlc/steps/operations/02-deploy.md`（および `operations-release.md` の該当箇所）の §7.13（PR マージ実行）AskUserQuestion 直前に、マージ前完結契約最終確認のための AskUserQuestion ステップが挿入されている
- [ ] 提示メッセージは凍結対象ファイル一覧（progress.md / post_release_operations.md / history/operations.md / 必要に応じ retrospective.md）と、マージ後 write-history.sh が exit 3 で拒否することの説明を含む
- [ ] 選択肢は「記録漏れなし、マージに進む」「記録を追加する（§7.6 / §7.7 に戻る）」の 2 択
- [ ] `automation_mode` が `manual` / `semi_auto` / `full_auto` のいずれかに関わらず常時表示される（ユーザー選択種別として扱う）
- [ ] §7.13 への到達経路として以下の検証ケースが網羅的に定義され、**各ケースで本プロンプトが 1 回提示されることが履歴（`.aidlc/cycles/v2.6.5/history/operations.md` または review-summary）に記録される**:
  - (a) 通常経路（修正コミット完備 + 通常 PR + マージ準備完了）
  - (b) 修正コミット欠落（uncommitted 状態で §7.13 到達）
  - (c) 空 PR（差分が無いまま §7.13 到達）
  - (d) 緊急マージ（CI 不完全 / 通常チェック省略）
  - (e) automation_mode=semi_auto 経路
  - (a) は本サイクル自身の Operations Phase で実機検証必須。(b)〜(e) は実機 OR ドキュメント上の論理検証（該当経路が分岐ロジック上必ず本プロンプトを通過することの根拠提示）のいずれかで証跡を残す
- [ ] 本サイクル自身の Operations Phase でドッグフーディングされ、(a) 通常経路で本プロンプトが期待どおり表示されることが履歴に記録される
- [ ] 完了判定は本「受け入れ基準（必須）」のみで成立する

**技術的考慮事項**:

- 既存 §4 マージ前完結ルール（Unit 002 / #583）の post-merge ガード（write-history.sh exit 3）と双方向に対称となる pre-merge 提示として位置付ける
- semi_auto では多くの確認が auto_approved になるが、本確認は「ユーザー選択」種別として常時必要

---

### ストーリー 4: defaults.toml 二重 SoT の同期漏れを CI で早期検出する

**優先順位**: Must-have

As a AI-DLC スターターキット自身のメタ開発者
I want to `skills/aidlc/config/defaults.toml`（本体） と `skills/aidlc-setup/config/defaults.toml`（consumer 配布用） のキー差分を CI で自動検出するガードジョブが追加されている
So that v2.6.4 Unit 004 のような「片方への defaults キー追加が他方に同期されないまま PR マージ目前まで進む → CI 修復コミット必要」状態を Construction Phase 早期に検出できる

**受け入れ基準（必須）**:

- [ ] `.github/workflows/` に Defaults TOML Sync チェックジョブが追加され（既存があれば強化・整理し）、PR トリガーで実行される
- [ ] チェックジョブは `skills/aidlc/config/defaults.toml` を正本として `skills/aidlc-setup/config/defaults.toml` とキー集合を比較し、差分（追加・削除・型不一致）を検出した場合 CI を fail させる
- [ ] CI fail 出力に「不足キー一覧」「修復方法（正本に合わせて同期 / 削除）」が明示されている
- [ ] CI ジョブは starter kit 自己リポジトリ専用として `.github/workflows/` に配置され、consumer プロジェクトへの追加配布物にならない（CLAUDE.md「ドッグフーディング特殊処理を本体に埋めない」原則準拠）
- [ ] 本サイクル U4 自身で「意図的に同期を崩した状態 → CI red」「同期を戻した状態 → CI green」を再現し、failing → green の遷移が確認される

**受け入れ基準（任意 / 追加達成条件）**:

- [ ] Unit 完了処理段階での自動同期スクリプトが Construction Phase Unit 4 設計時にトレードオフ評価され、採用されれば `skills/aidlc/scripts/` に追加される

完了判定は「受け入れ基準（必須）」のみで成立する。任意項目は完了判定に含めない。

**技術的考慮事項**:

- defaults.toml の構造変更（共通テンプレ展開等）は本サイクルでは対象外（intent §含まれないもの 参照）
- 既存の `task-management.md` / `commit-flow.md` の Unit 完了処理セクション改修は任意要件側で実施

---

### ストーリー 5: /aidlc 委譲フローを Skill ツール経由で自動継続実行する

**優先順位**: Must-have

As a AI-DLC スターターキット利用者の AI エージェント / 開発者
I want to `/aidlc r` / `/aidlc setup` / `/aidlc migrate` / `/aidlc feedback` を入力したら、委譲案内テキストを介さず対象スキル（`/aidlc-retrospective` / `/aidlc-setup` / `/aidlc-migrate` / `/aidlc-feedback`）が AI エージェントの Skill ツール呼び出し経由で直接 invoke される
So that ユーザー操作のステップ数が削減され、`/aidlc r` 等で「一旦止まる → 案内テキスト読む → 再入力」の摩擦が解消される

**受け入れ基準（必須）**:

- [ ] `skills/aidlc/SKILL.md` の「独立フロー委譲」セクション（アンカー: `## 引数処理` 配下の「独立フロー委譲」見出し節 / 行番号には依存しない）が更新され、委譲対象 4 アクション（`retrospective` / `setup` / `migrate` / `feedback`）に対し AI エージェントが Skill ツール経由で自動継続実行する規約が明文化されている
- [ ] 新規約は (a) 委譲先スキル名と AskUserQuestion を介さない継続 invoke 手順、(b) `additional_context` の透過渡し、(c) 委譲案内テキストを「実行済み報告」に変える形式、を含む
- [ ] Claude Code 実機で `/aidlc r` を入力したら、案内テキストを介さず `/aidlc-retrospective` のフローが直接開始されることが Construction Phase で検証される
- [ ] 委譲廃止（#717 提案 2）は採用しない旨が SKILL.md の「独立フロー委譲」セクション内コメントまたは関連 Issue 参照として記載される

**受け入れ基準（任意 / 追加達成条件）**:

- [ ] Codex CLI 実機で同等挙動が動作することが Operations Phase 振り返り前段で検証され、結果が `.aidlc/cycles/v2.6.5/operations/post_release_operations.md` または振り返り Issue に記録される

完了判定は「受け入れ基準（必須）」のみで成立する。任意項目は完了判定に含めない。

**技術的考慮事項**:

- AI エージェント側の Skill 連鎖呼び出し挙動依存のため、Claude Code 以外（Codex CLI / Gemini CLI 等）での挙動検証は Operations Phase での追加達成条件として扱う
- 既存の独立スキル化（v2.6.0+）との整合性を保つ（独立スキル自体は維持）
