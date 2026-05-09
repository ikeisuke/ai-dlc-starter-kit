# Intent（開発意図）

## プロジェクト名

ai-dlc-starter-kit v2.6.0

## 開発の目的

AI-DLC スターターキットの **運用基盤を整備する minor サイクル** として、以下 3 系統と関連する小バグを統合的に解消する。

1. **バージョン管理 SoT 一本化（#617 + #618）**: Plugin Marketplace の表示乖離を防ぐため、バージョン参照を `.claude-plugin/marketplace.json` の `metadata.version` に一本化する。冗長な `version.txt` 系 3 ファイル（ルート / `skills/aidlc/version.txt` / `skills/aidlc-setup/version.txt`）を廃止し、`update-version.sh` を再構築。`aidlc-setup` のアップグレードフローでは「`starter_kit_version` のみ差分」を no-op スキップ判定できるようにする。
2. **バックログ動的管理化（#673）**: Issue #524 の手動チェックリスト運用を GitHub Projects (ProjectsV2) に移行し、Status / Priority / Cycle / Type 軸での動的フィルタとビュー切り替えを可能にする。Milestone（サイクルスコープ）と並行運用し、Issue Close → Done 自動遷移ワークフローを設定する。
3. **振り返りフロー独立化（#667）**: `/aidlc r`（短縮: `/aidlc retrospective`）で独立起動可能な `aidlc-retrospective` スキルを新設し、Operations Phase §1 から振り返りロジックを完全移転する。**v2.6.0 を破壊的変更タイミング**として位置付け、Operations 内の振り返り呼び出しは削除する。一方で運用継続性のため、**Operations 完了時のフェーズ移行案内に `/aidlc i` と同列で `/aidlc r` の案内を追加**する。
4. **小バグ統合（#615 / #614）**: `migrate-backlog.sh` の `cut -c1-50` が `LANG=C` 等で UTF-8 多バイト境界を分断する問題（slug 末尾文字化け）を修正し、`rules.md` L107/L122 の `MD040`（fenced-code-language）違反を解消する。

## ターゲットユーザー

- AI-DLC スターターキット利用者（プラグインユーザー）
- AI-DLC スターターキット開発者（本リポジトリのメンテナ・コントリビュータ）
- 振り返りを Operations と独立して実施したい運用チーム

## ビジネス価値

- **誤インストール・表示乖離の根絶**: Marketplace 表示と実体バージョンが常に同期。SoT 二重管理リスクを撤廃。
- **バックログ意思決定の高速化**: Inception 開始時に GitHub Projects を確認するだけで次サイクル候補が決まる状態を実現。Issue Close 時の手動編集コストを 0 化。
- **振り返り運用の柔軟化**: Operations 完走直後だけでなく後日まとめて振り返りを実施可能。Operations Phase の完了条件が明確化される。
- **品質基盤の安定**: マルチバイト環境での slug 生成の信頼性向上、ドキュメント lint 違反の解消で markdownlint CI を一段階前進。

## 含まれるもの

### #617 + #618: バージョン管理 SoT 一本化

- `.claude-plugin/marketplace.json` の `metadata.version` を **唯一の SoT（正本）** に確定
- ルート `version.txt`、`skills/aidlc/version.txt`、`skills/aidlc-setup/version.txt` の **3 ファイルを廃止**（参照側コードを `marketplace.json` 参照に書き換え後に削除）
- `bin/update-version.sh` を `marketplace.json` 更新主体に再構築（同期更新ターゲットを `marketplace.json` に統一）
- バージョン読み取り処理（`scripts/read-config.sh starter_kit_version` / `01-setup.md` ステップ5a / `aidlc skill version` 等）の参照先を `marketplace.json` の `metadata.version` に更新
- pre-release チェック / CI ガードの追加（`marketplace.json` 未更新でのリリース防止）
- `aidlc-setup` アップグレードフローで「`starter_kit_version` のみ差分」を検出した場合に **no-op スキップ**（メッセージ: 「変更不要のためスキップしました」）

**`config.toml.starter_kit_version` の役割境界**:

- **正本判定は常に `marketplace.json.metadata.version` で行う**（SoT）。`config.toml.starter_kit_version` は **参照専用のローカルキャッシュ値**として位置付ける
- 用途: `aidlc-setup` / `aidlc-migrate` がアップグレード差分を検出するための「前回適用バージョン」記録（旧名: `last_applied_version` 相当の意味付け）
- バージョン比較 / 表示 / リリース整合性チェックは **すべて `marketplace.json` から取得した値で実施**し、`config.toml.starter_kit_version` は `aidlc-setup` のアップグレード差分検出時のみ参照する
- v2.6.0 以降の `bin/update-version.sh` は `config.toml.starter_kit_version` を更新対象としない（v2.4.0 以降の既存方針を継続）。書き換えは `aidlc-setup` / `aidlc-migrate` のみが行う

### #673: GitHub Projects 移行

- gh CLI トークンスコープ拡張ガイドの整備（`gh auth refresh -s project,read:project`）。**実行はユーザー手動作業**
- ProjectsV2 の作成（命名・Visibility・フィールド定義・ビュー定義）
  - フィールド: `Status`（Backlog/Next/In Progress/Review/Done）、`Priority`（high/medium/low）、`Cycle`（vX.Y.Z/Later）、`Type`（label 流用）
  - ビュー: Roadmap / Backlog Board / Priority Table / Feedback View
- **自動化ワークフロー設定**: Project の built-in workflow `Auto-archive items` ではなく `Item closed` トリガを使用し、Issue が `closed`（GitHub の `issues.closed` イベント / UI Close / `gh issue close` / API いずれの経路でも発火）となった時点で当該 Project Item を `Status=Done` に自動遷移させる。対象範囲は本 Project に紐付く Repository project items のみ（外部リポジトリ Issue は対象外）
- 現状 Open Issue（#524 で管理されている全項目）の Project 一括投入。Priority/Cycle/Status の初期値セット
- Issue #524 を **Project URL + 運用ルール** にリダイレクト化（完了済セクション削除運用は廃止）
- AI-DLC 運用ガイダンス更新（Inception 開始時の Project 参照手順）。**`steps/inception/02-preparation.md` のバックログ確認導線に「Project 参照ステップ」を本サイクルで必ず追加する**（`gh issue list --label backlog` 経路と Project ビュー参照を併記し、`gh project item-list` 経由での絞り込み手順を明記）

### #667: 振り返りフロー独立化

- `aidlc-retrospective` スキル新設（`/aidlc-retrospective` として独立起動）
- `/aidlc` parser に `retrospective`（短縮: `r`）アクションを追加し、`setup` / `migrate` / `feedback` 同様に独立スキルへ委譲
- Operations Phase §1 振り返りロジックを `/aidlc-retrospective` 側に **全量移転**（Operations 側は呼び出しガイドのみ残さず完全削除）
- **Operations 完了時の案内メッセージ更新**: 既存の `/aidlc i` 案内と同列で `/aidlc r` を案内する（次サイクル開始の前または並列に振り返りが起動できることを明示）
- 設定 `[rules.retrospective].feedback_mode` 等の既存スキーマは互換維持（振り返り内容の決定ロジックは `aidlc-retrospective` 側で参照する）
- `predecessor_resolve_issue` 等の関連スクリプトは `aidlc-retrospective` から呼び出されるよう参照を整理

**互換性方針（破壊的変更）**:

- v2.6.0 以降、**Operations Phase 内から振り返りは一切起動されない**（既存の `04-completion.md §1` 経由の暗黙起動・自動遷移は完全廃止）
- **代替導線は `/aidlc r`（または `/aidlc retrospective`）のみ**。Operations 完了メッセージで案内
- README.md / CHANGELOG.md / `docs/` 配下の関連ドキュメントに **「v2.6.0 で破壊的変更」** として明記（`MIGRATION` セクション追加、または専用 NOTICE 追記）
- `aidlc-migrate` で v2.5.x → v2.6.0 アップグレード時に **「振り返り起動方法が変わりました（`/aidlc r` を使用してください）」** メッセージを表示
- 既存サイクルで Operations 内振り返りを実施中だったケースは存在しない想定（マージ前完結契約により振り返りは Operations 完了 = サイクル完了 = 即時実施されてきたため）。仮に途中状態が残っていた場合は `/aidlc r` で対象サイクルを明示指定して継続できることをドキュメント化

### #615: migrate-backlog.sh UTF-8 cut バグ修正

- **採用実装**: `LC_ALL=C.UTF-8 awk '{ s=$0; if (length(s) > 50) s=substr(s, 1, 50); print s }'` で文字数（コードポイント単位）50 文字に制限する。`cut -c1-50` を当該実装に置換する（line 79）
- **理由**: macOS/Linux 双方で `awk substr` は `LC_ALL=C.UTF-8` 配下で UTF-8 コードポイント単位で動作する一方、`cut -c` はバイト境界で切る BSD 実装が残るため
- **受け入れ条件**:
  - 入力 `これは日本語のIssueタイトルですABCDEFGHIJKLMNOPQRSTUVWXYZ`（51 文字以上の日本語混在文字列）に対し、出力末尾が **マルチバイト境界で分断されない**（`� ` や半端な多バイトシーケンスを含まない）
  - `LC_ALL=C` 環境下でも文字化けしない（`LC_ALL=C.UTF-8` を実装内で明示固定するため、呼び出し側ロケールの影響を受けない）
  - 既存の純 ASCII Issue タイトルでは従来動作（先頭 50 文字）と完全一致
- **テスト**: `skills/aidlc-setup/scripts/tests/` 配下に `test_migrate_backlog_slug.sh`（新規）を追加し、上記 3 ケース（日本語混在 / `LC_ALL=C` / ASCII のみ）を網羅。CI で実行可能な形式（exit code + 期待出力比較）

### #614: rules.md MD040 違反修正

- `rules.md` L107 / L122 の fenced code block に言語指定を追加（既存テキストから推定: `text` または該当言語）
- `markdownlint-cli2` で MD040 違反 0 件を確認

### スコープ横断

- `.aidlc/config.toml` の `starter_kit_version` を 2.6.0 にバンプ（リリース時）
- 各 Issue は Milestone `v2.6.0` に紐付け、Construction Phase でそれぞれ独立 Unit として実装

## 含まれないもの

- `[rules.backlog]` DEPRECATED セクション削除（#646）→ 別サイクル
- config.toml の `[rules.branch]` / `[rules.worktree]` / `[rules.backlog]` 整理（#640）→ 別サイクル
- CI workflow への `test_pr_ops_*.sh` 実行ジョブ追加（#669）→ 別サイクル
- 振り返り Issue と通常 backlog Issue の分離・可視化方式（#664）→ 別サイクル（#667 と協調するが本サイクルでは取り扱わない）
- 振り返り 3 層検証手順の skill 化（#652）→ 別サイクル
- GitHub Projects のラベル `priority:*` と Project `Priority` フィールドの双方向同期 workflow → 本サイクルではどちらかを SoT として運用ルール明記まで。実装は別サイクル

## 成功基準

- **#617**: `marketplace.json` の `metadata.version` のみがバージョン参照 SoT として機能する。`version.txt` 系 3 ファイルが削除され、参照側コードがすべて移行済みであること。`bin/update-version.sh` が `marketplace.json` を更新主体として動作する。pre-release / CI ガードで `marketplace.json` 未更新を検出可能
- **#618**: `aidlc-setup` のアップグレード実行時に `starter_kit_version` のみ差分の場合 no-op スキップが効き、ユーザーに無駄な変更を見せない
- **#673**: GitHub Projects 上で Status / Priority / Cycle / Type の各ビューが稼働し、`Item closed` ワークフローにより **GitHub の `issues.closed` イベント発火経路（UI Close / `gh issue close` / API 経由）すべて**で当該 Project Item が自動で `Status=Done` 列へ遷移する。**検証手順**: テスト用ダミー Issue を Project に追加 → `gh issue close <N>` で close → `gh project item-list <PROJECT> --owner <OWNER>` で `Status=Done` を確認、の 3 ステップを v2.6.0 PR の test plan に記載。Issue #524 が Project URL + 運用ルールにリダイレクト済み。`steps/inception/02-preparation.md` のバックログ確認導線に Project 参照ステップが組み込まれていること
- **#667**: `/aidlc r` で `aidlc-retrospective` スキルが起動し、振り返り Issue 作成までのフローが完結する。Operations Phase 内に振り返りロジックが残存しない（`grep -rn "retrospective" skills/aidlc/steps/operations/` で `aidlc-retrospective` 案内以外の実行ロジック検出ゼロ）。Operations 完了メッセージに `/aidlc r` 案内が含まれる。**README.md / CHANGELOG.md / `aidlc-migrate` 出力**で v2.6.0 破壊的変更が明示されている
- **#615**: 日本語タイトルを含む Issue でも `migrate-backlog.sh` の slug 末尾が文字化けしない
- **#614**: `markdownlint-cli2` で `rules.md` の MD040 違反が 0 件
- **横断**: v2.6.0 PR が markdownlint / 自動 CI チェックを通過し、Milestone v2.6.0 が close 状態でリリース完了

## 期限とマイルストーン

- 本サイクル（v2.6.0）リリースをもって完了
- Milestone は `inception.05-completion` ステップ1で正式作成（`v2.6.0`）

## 制約事項

- **手動作業必須**: GitHub Projects 作成のための gh CLI トークンスコープ拡張（`gh auth refresh -s project,read:project`）はユーザー手動作業
- **破壊的変更**: #667 により Operations 内の振り返り呼び出しは v2.6.0 で削除される（後方互換維持なし）。利用ガイド・README・CHANGELOG に明示
- **Project 操作の冪等性**: `gh project` / GraphQL 経由のスクリプト化時は冪等性を確保すること
- **SoT 移行の段階性**: `version.txt` 削除前に参照側コードの移行を完了させる（順序を誤ると CI が壊れる）
- **automation_mode**: 本リポジトリは `semi_auto`、`review_mode=required`。各 Unit でレビュースキップ不可

## 不明点と質問（Inception Phase中に記録）

[Question] GitHub Projects のフィールド `Cycle` の値は Milestone と完全 1:1 同期させるか、それとも Project 側のみで自動化するか
[Answer] （Construction Phase Unit 設計時に確定。初期方針は Milestone を SoT とし Project 側は手動 or Workflow で同期）

[Question] `version.txt` 系 3 ファイル削除に伴い、`predecessor_resolve_issue` 等で版数を参照しているスクリプトは `marketplace.json` から `dasel` または `jq` で抽出する形に変更するが、`dasel` バージョンによる差は影響するか
[Answer] （Construction Phase Unit 設計時に確定。プリフライトで `dasel_major_version` を参照済みのため互換は確保される想定）

[Question] `aidlc-retrospective` 移管時、Operations Phase §1 内の `decisions.md`/`history` 連携はどう扱うか（独立スキルから現サイクルの履歴ファイルへ書き込む際のパス解決）
[Answer] （Construction Phase Unit 設計時に確定。`/aidlc r` 起動時のサイクル特定ロジック設計と合わせて検討）
