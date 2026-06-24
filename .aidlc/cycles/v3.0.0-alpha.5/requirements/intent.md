# Intent（開発意図）

> Relates to #736（[Epic] v3 リニューアル Phase 4–7 完遂ロードマップ）

## プロジェクト名

AI-DLC Starter Kit v3 — Phase 4: develop normal / risky 分岐（サイクル v3.0.0-alpha.5）

## 開発の目的

v3 の develop フロー（`skills/aidlc-v3/steps/develop.md`）は現在 `size: tiny` のみ対応し、`normal` / `risky` は「Phase 4 で対応予定」として副作用なく停止している。本サイクルでこの停止を解消し、work item の `size` に応じて **設計・レビュー・テストプラン・depth_level の厚みを変える分岐**を実装する。

これにより v3 は tiny の軽量タスクだけでなく、実運用相当の `normal`（通常の機能追加・小中規模リファクタ）や `risky`（state model 変更・複数サブシステムまたがり等）の work item を完走できるようになり、Epic #736 のマイルストーン「v3 単独フルサイクル」へ前進する。

**なぜ今**: Phase 1–3（RFC / skeleton / define+develop tiny）と番外（parser 安全境界）が完了し、develop フローの骨格が揃った。normal/risky 分岐は release（Phase 5）以降の前提となるため、ここで実装する。

## ターゲットユーザー

- AI-DLC v3（`/aidlc-v3`）で開発を進める開発者
- メタ開発文脈では AI-DLC Starter Kit 自身を開発する本プロジェクト（ドッグフーディング）

## ビジネス価値

- **適応的な儀式の厚み**: 全作業に同じ重さを強制せず、高リスク変更（risky）は design + risk analysis + 複数 review で明示的に重く、通常変更（normal）は簡易 design + code review で扱える。tiny の軽量さは非回帰で維持
- **v3 自立性の前進**: normal/risky を完走できることで、v3 が実タスクで使えるレベルに近づく（Phase 6 完了 = v3 単独フルサイクルへの布石）

## 成功基準

renewal-plan Phase 4 完了条件および `docs/v3/workflow.md` §3.2 / §6.2 / §6.3 と整合する:

- tiny は従来どおり軽く完了する（**非回帰**: design / review をスキップ）
- size × depth_level の組み合わせが §6.3 マトリクス通りに動作する（下表が成功基準の正本マッピング。「review」は develop 内の plan/design/code perspective を指す）:

  | size \ depth_level | minimal | standard | comprehensive |
  |---|---|---|---|
  | **tiny** | 実装のみ | 実装のみ | 実装 + 短い理由記録 |
  | **normal** | 実装 + テスト（design/review なし） | 実装 + 簡易 design + テスト + review | 実装 + design + リスク分析 + テスト + review |
  | **risky** | **不可**（minimal は選べない） | design + テスト + review + rollback note | design + リスク分析 + テストプラン + 複数 review + rollback note |

- review routing が `data-model.md` §8 + `workflow.md` §6.2 に従い develop 内レビューを既存スキルへルーティングする: `normal+standard`/`normal+comprehensive`/`risky+standard` は code（`reviewing-construction-code`、risky は security focus）、`risky+comprehensive` は複数 review = code + design（`reviewing-construction-design`）、`normal+minimal` は実行なし。plan/design/code の 3 perspective のルーティング能力は実装するが、plan review の develop 内実行は本サイクルの実行マトリクスに含めない（§6.1 文言整合は Unit 003 設計で確定）
- risky（standard / comprehensive）の work item 完了時、対応する `designs/*.md` に非空の `## Rollback Note` セクションが存在する
- 既存の v3 テスト（define / develop / state / next / activation）が全て緑のまま、normal/risky 用の検証が追加される

## スコープ

### 含まれるもの

> **成果物の厚みは §6.3 マトリクス（成功基準の表）を正本とする**。以下の各 item は size×depth_level で条件付きに動作する。`normal+minimal` は Step 2/5 をスキップ、`risky+minimal` はエラー停止（minimal 選択不可）。

1. **develop.md の size 分岐実装**: Step 1 の size 判定後、size×depth_level に応じて Step 2（計画+設計）・Step 5（レビュー）の実行可否を決める分岐（現状の「未サポート停止」を置換）。`normal+minimal` は Step 2/5 をスキップ（実装+テストのみ）、`risky+minimal` はエラー停止
2. **Step 2（計画+設計）**: §6.3 に従い depth_level 条件付きで生成。`normal+standard`=簡易 design / `normal+comprehensive`=design+リスク分析 / `risky+standard`=design / `risky+comprehensive`=design+リスク分析+test plan。`designs/*.md` 生成、Design 承認ゲート（normal+minimal は本 Step なし）
3. **design template の追加**: `skills/aidlc-v3/templates/` に design 成果物テンプレートを新設
4. **Step 5（レビュー）**: `normal+standard`/`normal+comprehensive`/`risky+standard`/`risky+comprehensive` で実行（normal+minimal はスキップ）。perspective=code（risky は security focus）、上限 5R、Defer 戦略（OUT_OF_SCOPE・TECHNICAL_BLOCKER → 自動 Issue）、`reviews/*.md` 生成
5. **review routing（develop 内のみ）**: plan / design / code の 3 perspective を既存スキルへ**暫定ルーティングする能力**を実装する。ただし **develop 内での実行は `data-model.md` §8 + `workflow.md` §6.2 を正本とする**（user_stories.md ストーリー3 のレビュー実行マトリクスが詳細）:
   - `normal+standard` / `normal+comprehensive` / `risky+standard`: `code`（risky は security focus）→ `reviewing-construction-code`
   - `risky+comprehensive`: **複数 review** = `code`（security focus）+ `design`（`reviewing-construction-design`）
   - `normal+minimal`: 実行なし（`risky+minimal` は存在しない）
   - **「複数 review」の定義**: `risky+comprehensive` で実行する code + design を指す（§6.2/§8 準拠）。`deploy` / `premerge` / `integration` は release（Phase 5）で実行し develop では実行しない
   - **plan review の develop 内実行**: §6.1（plan を normal/risky 全般で列挙）と §6.2/§8（code 中心）の SoT 不整合のため、本サイクルは §6.2/§8 を正本とし plan review を develop の実行マトリクスに含めない（ルーティング能力は実装）。§6.1 文言整合は Unit 003 設計で確定する
6. **depth_level 分岐**: §6.3 の size × depth_level マトリクスを実装する（成功基準の表が正本）
7. **test plan handling**: §6.3 に従い `risky+comprehensive` でのみ test plan を生成する（`risky+standard` は design+テスト+review+rollback note でありテストプランは含まない）
8. **rollback note handling**: risky（standard / comprehensive）で rollback note を生成する。配置は `designs/*.md` 内の必須セクション（`## Rollback Note`）とし、別ファイルは作らない（成果物数を増やさない v3 方針に整合）
9. **回帰テスト**: normal/risky フローの検証テスト追加、tiny 非回帰の確認

### 含まれないもの（明示的除外）

- **`aidlc-review`（9→1 perspective 統合スキル）の新規作成**: RFC DG-4 の統合は独立した大型リファクタ。本サイクルは既存 reviewing-construction-* への暫定ルーティングに留め、統合は別サイクルへ（Epic #736 に追加予定）
- **#733 T1（共有 parser ライブラリ集約）**: **alpha.4 で完了済み**（Epic #736 番外項目 / alpha.4 Unit 001=T1 集約+T2' conformance、Unit 002=T4 CI guard。consumer 3 本を `scripts/lib/frontmatter.sh` へ移行・禁止規約文書化・CI 機械検出を実装済み）。本サイクルでは扱わない（残作業なし）
- **release / reflect / doctor フローの実装**: それぞれ Phase 5 / Phase 6
- **integration / deploy / premerge review の実行**: これらは release（Phase 5）で実行され、develop では実行しない（§3.3 / §6.1）

## 期限とマイルストーン

- 1 サイクル（v3.0.0-alpha.5）で完了
- Epic #736 ロードマップ上の Phase 4。完了後の次サイクルは Phase 5（release / alpha.6）でその先頭 Unit に T1 を含む

## 制約事項

- **SoT 二重定義回避**: フロー仕様の正本は `docs/v3/workflow.md`、データモデルは `docs/v3/data-model.md`。develop.md はこれらを参照し仕様を再定義しない
- **パース安全境界**: frontmatter / status の読取・遷移は既存の `scripts/work-item-status.sh` 等の安全境界スクリプトを経由する（RFC P4 / #733 P1 の再発防止）
- **ドッグフーディング特殊処理の禁止**: 「starter kit 判定」等の自リポジトリ特殊分岐を develop フロー本体に埋め込まない（リポジトリ規約準拠）
- **tiny 非回帰**: `tiny + {minimal, standard}` は既存の tiny フロー動作を変えない。`tiny + comprehensive` のみ §8 に従い「短い理由記録」を追加し、design / review は引き続きスキップする（それ以外の tiny 挙動は不変）

## 不明点と質問（Inception Phase中に記録）

[Question] review routing の連携先は既存 reviewing-construction-* か、新規 aidlc-review か？
[Answer] 既存 reviewing-construction-* へ暫定ルーティング。aidlc-review(9→1 統合)は別サイクルへ分離（2026-06-25 ユーザー確認）

[Question] #733 T1（共有 parser 集約）を本サイクルに含めるか？
[Answer] 含めない。**T1 は alpha.4 で完了済み**（Epic #736 番外 / Unit 001 T1+T2'、Unit 002 T4）であることが Unit 重複チェックで判明したため、本サイクル・将来サイクルともに残作業なし。当初「Phase 5 先頭 Unit へ」とした判断は #733 本文のみを参照した誤りで、訂正済み（2026-06-25 訂正）

[Question] aidlc-review スキル作成はどの Phase か（renewal-plan に未割り当て）？
[Answer] 本サイクルでは作らず、別サイクルとして Epic #736 に追加する（2026-06-25 ユーザー確認）

[Question] 成功基準が size×depth_level（§6.3）の差分を反映していない（codex レビュー #1）
[Answer] 成功基準に size×depth_level マトリクスを追加。normal+minimal=design/review なし、risky+minimal 不可を明記（2026-06-25 反映）

[Question] develop 内 review の実行 perspective とタイミングが曖昧（codex レビュー #2）
[Answer] §6.2/§8 を正本とし、develop 内実行は normal/risky の code（risky は security focus）と risky+comprehensive の design に限定。plan review はルーティング能力のみ実装し develop 実行マトリクス外（§6.1 文言整合は Unit 003 設計で確定）。「複数 review」= risky+comprehensive の code + design。deploy/premerge/integration（release）は除外（2026-06-25 反映 / Unit レビューで §6.2/§8 統一）

[Question] rollback note の配置・形式・検証条件が未定義（codex レビュー #3）
[Answer] designs/*.md 内の必須セクション `## Rollback Note` とし別ファイルは作らない。成功基準に非空セクション存在の測定条件を追加（2026-06-25 反映）

[Question] SoT 内不整合: `docs/v3/workflow.md` §3.2（risky 一般 = design + risk analysis + test plan）と §6.3 マトリクス（`risky+standard` は risk analysis / test plan を含まず、`risky+comprehensive` のみ含む）が矛盾する（codex Round2 で派生検出）
[Answer] 本サイクルは **§6.3 マトリクスを正本** として実装する（より詳細な size×depth_level 規定のため）。§3.2 の risky 行は depth_level 非依存のサマリ表現と解釈。workflow.md 本体の文言整合は Construction 設計時に該当 Unit で §3.2 に depth_level 注記を補う形で解消する（SoT 二重定義回避の制約に従う）
