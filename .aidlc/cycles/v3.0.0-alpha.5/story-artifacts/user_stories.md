# ユーザーストーリー

> 対象: v3.0.0-alpha.5 / Phase 4 = develop normal/risky 分岐（Relates to #736）
> 「ユーザー」= `/aidlc-v3 develop` を実行する開発者（メタ開発では本プロジェクト自身）
> 成果物要否の正本: `docs/v3/data-model.md` §8（= `workflow.md` §6.3 ミラー）

## Epic: develop フローの size × depth_level 分岐

### ストーリー 1: size 分岐で normal/risky が停止せず進む
**優先順位**: Must-have

As a `/aidlc-v3 develop` を実行する開発者
I want to work item の size が `normal` / `risky` のときに「未サポート停止」されず、size と depth_level に応じた経路で develop が進む
So that tiny 以外の実タスクを v3 で完走できる

**受け入れ基準**:
- [ ] `size: normal` の work item 選定時、現状の「normal / risky フローは未サポート」案内で終了せず develop が継続する
- [ ] `size: risky` の work item 選定時も同様に継続する
- [ ] `depth_level` を `.aidlc/config.toml` から解決し、未設定時は `standard` を既定とする
- [ ] `normal` + `depth_level: minimal` は Step 2（設計）/ Step 5（レビュー）をスキップし「実装 + テスト」のみで完了できる
- [ ] `risky` + `depth_level: minimal` は「risky は minimal 不可」としてエラー停止する（mutation なし＝副作用なし）
- [ ] `tiny` + `{minimal, standard}` の既存フローは一切変化しない（非回帰）。`tiny` + `comprehensive` のみ §8 に従い「短い理由記録」が追加される（それ以外の tiny 挙動は不変）

**技術的考慮事項**:
- 判定の正本は `data-model.md` §8 マトリクス。size は work item frontmatter、depth_level は config.toml。
- 「ドッグフーディング特殊処理の禁止」に従い自リポジトリ判定を埋め込まない。

---

### ストーリー 2: normal/risky で設計成果物が生成され承認できる
**優先順位**: Must-have

As a develop を実行する開発者
I want to normal/risky の work item で size×depth_level に応じた設計成果物（design / risk analysis / test plan / rollback note）が `designs/*.md` に生成され、Design 承認ゲートを通れる
So that 高リスク変更を実装前に明示的に重く扱える

**受け入れ基準**:
- [ ] `skills/aidlc-v3/templates/` に design テンプレートが新設され、develop Step 2 がそれを基に `designs/<id>-<slug>.md` を生成する
- [ ] `normal` + `standard` は簡易 design が生成される
- [ ] `normal` + `comprehensive` は design + リスク分析が生成される
- [ ] `risky` + `standard` は design + rollback note が生成される（`## Rollback Note` セクションが非空）
- [ ] `risky` + `comprehensive` は design + リスク分析 + test plan + rollback note が生成される
- [ ] Step 2 完了時に Design 承認ゲートが発火する（`automation_mode` に従う）
- [ ] `normal` + `minimal` では本 Step が実行されず `designs/*.md` を生成しない

**技術的考慮事項**:
- rollback note は別ファイルにせず `designs/*.md` 内の必須セクション `## Rollback Note` とする（v3 の成果物数を増やさない方針）。
- §3.2（risky 一般 = design+risk analysis+test plan）と §8（risky+standard は含まない）の文言差は §8 を正本として実装し、§3.2 の注記補正を本サイクル内で行う。

---

### ストーリー 3: review routing で normal/risky のレビューが既存スキルへ流れる
**優先順位**: Must-have

As a develop を実行する開発者
I want to normal/risky の work item で size×depth_level に応じたレビューが既存 reviewing-construction-* スキルへルーティングされ、`reviews/*.md` に perspective 別に記録される
So that v2 同等のレビュー品質を v3 develop でも、過不足ない厚みで担保できる

**develop 内レビューの実行マトリクス（`data-model.md` §8 + `workflow.md` §6.2 を正本とする）**:

| size × depth_level | develop 内で実行するレビュー |
|---|---|
| normal + minimal | なし |
| normal + standard | code |
| normal + comprehensive | code |
| risky + standard | code（security focus） |
| risky + comprehensive | 複数（code（security focus）+ design） |

**受け入れ基準**:
- [ ] develop は plan / design / code の 3 perspective を既存スキルへルーティングできる（ルーティング能力を実装）。**実行**は上表に従う（§8 の "review" / "複数 review" カウントに整合）
- [ ] `normal`（standard / comprehensive）は code review（`reviewing-construction-code`）を実行する
- [ ] `risky + standard` は code review（security focus）を実行する
- [ ] `risky + comprehensive` のみ「複数 review」= code（security focus）+ design review（`reviewing-construction-design`）を実行する
- [ ] `normal + minimal` はレビューを実行しない（`risky + minimal` は存在しない）
- [ ] レビュー結果は `.aidlc/cycles/<cycle>/reviews/<id>-<slug>.md` に、perspective 別セクション（`## Code Review` / `## Design Review` 等）として記録される。複数 review 時も単一ファイル内にセクション追記し上書きしない
- [ ] code review の呼び出しは `reviewing-construction-code`、design review は `reviewing-construction-design`（review-routing.md §7 の呼び出し形式）
- [ ] 反復上限 5R、`OUT_OF_SCOPE` / `TECHNICAL_BLOCKER` 確定指摘は自動 Issue 起票される（Defer 戦略）
- [ ] `deploy` / `premerge` / `integration` perspective は develop では実行しない（release で実行）

**技術的考慮事項**:
- 本サイクルは既存 reviewing-construction-* への暫定ルーティング（`aidlc-review` 9→1 統合は別サイクル）。
- **SoT 内不整合（設計で解消）**: `workflow.md` §6.1 は plan / design / code を「normal/risky」全般で列挙するが、§6.2（size×review）と §8 は develop の review を code 中心（risky+comprehensive のみ複数）とする。本サイクルは **§6.2/§8 を正本**とし上表で実装、§6.1 の plan review 列挙の文言整合は該当 Unit の設計で補正する（plan review の develop 内実行有無を含めて確定）。
- 呼び出し形式は review-routing.md §7 準拠（`skill="reviewing-construction-[stage]", args="[対象] 優先ツール: [tool]"`）。

---

### ストーリー 4: 全 size×depth_level 組合せが回帰テストで保証される
**優先順位**: Must-have

As a v3 を保守する開発者
I want to normal/risky フローと size×depth_level の全組合せが自動テストで検証され、tiny 非回帰も確認される
So that Phase 5 以降の変更で develop 分岐が壊れていないことを継続的に保証できる

**受け入れ基準**:
- [ ] `skills/aidlc-v3/scripts/tests/test-develop-flow.sh` に normal/risky の経路テストが追加される
- [ ] `data-model.md` §8 マトリクスの全有効組合せ（tiny×3 / normal×3 / risky×{standard,comprehensive}）が検証される
- [ ] `risky` + `minimal` がエラー停止（副作用なし）することがテストされる
- [ ] 既存テスト（define / develop tiny / state / next / activation / frontmatter / cycle-resolution）が全て緑のまま
- [ ] design / review 成果物の生成有無が size×depth_level に従うことが検証される

**技術的考慮事項**:
- 既存テストハーネス（bash unit test）に追加する。外部 CLI レビュー呼び出しはテストではモック/スタブ化を検討（実 CLI 依存を避ける）。
