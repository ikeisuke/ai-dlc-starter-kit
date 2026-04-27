# 意思決定記録: Inception Phase v2.4.2

本サイクル Inception Phase 中に実施された主要な意思決定の記録。Construction Phase 着手時の前提情報および将来サイクルの参照用。

## DR-001: サイクルバージョンを v2.4.2 (patch) に確定

- **日時**: 2026-04-26
- **判断者**: ユーザー
- **コンテキスト**: 直近 v2.4.0 / v2.4.1 が patch スタイルで小規模 Issue 集約解消サイクル。オープン Issue にもsetup/migrate / Operations 関連の patch 級 bug + docs 改善が複数存在
- **選択肢**:
  - A: v2.4.2 (patch) — bugfix / 小規模 Issue 集約
  - B: v2.5.0 (minor) — #590 振り返りステップ追加など機能追加を含む
  - C: v3.0.0 (major) — 破壊的変更
- **決定**: A (v2.4.2 patch)
- **理由**: setup/migrate のマージ後フォローアップ（#607 / #605）は patch 相当の bug 寄りで、放置すると一時ブランチ累積や開発者手動修正の摩擦が継続するため早急に解消する価値が高い。minor 級の機能追加は別サイクルで分離

## DR-002: 取り組み Issue を #607 / #605 / #591 / #585 の 4 件に確定

- **日時**: 2026-04-26
- **判断者**: ユーザー
- **コンテキスト**: 20 件以上のオープン Issue のうち patch 親和性で絞り込み
- **決定**: #607（一時ブランチ未削除）+ #605（マージ後 HEAD 同期）+ #591（operations-release §7.6 明文化）+ #585（progress.md 固定スロット追加）の 4 件
- **理由**: テーマが「setup/migrate マージ後フォローアップ」と「Operations 手順書 / progress.md テンプレート明文化」で揃い、1 サイクル内のセット修正として親和性が高い。#591 のスコープに #585 が包含される関係も活用できる
- **スコープ外の Issue**: #590 / #582 / #581 / #573 / #586 / #592 など。規模・破壊性のため別 minor サイクルで対応

## DR-003: #607 の解決方針 — 対話ベースの最終ステップ追加

- **日時**: 2026-04-26
- **判断者**: ユーザー
- **コンテキスト**: Issue #607 本文で 3 つの「期待する挙動」（最終ステップで案内 / `post-merge-cleanup` スクリプト統合 / ドキュメント明記のみ）が提示
- **決定**: `/aidlc-setup` `/aidlc-migrate` の最終ステップで「マージ確認 → ローカル / リモート一時ブランチ削除」を案内する手順を追加（対話ベース、ユーザー同意で実行）
- **理由**: スクリプト統合は範囲が広がり patch には過剰。ドキュメント明記のみではスキル側で動作しない。対話ベース最終ステップ追加が patch に最適
- **影響**: Unit 001 / Unit 002 で実装

## DR-004: #605 の解決方針 — ユーザー確認ベースの fetch + detach/branch 切替

- **日時**: 2026-04-26
- **判断者**: ユーザー
- **コンテキスト**: Issue #605 本文で 3 つの対応方針候補（ユーザー確認ベース / 自動同期 / 手順提示のみ）
- **決定**: `/aidlc-setup` のコミット後ステップで「PR を作成・マージしましたか？」を確認し、同意があれば `git fetch origin --prune` → 現在ブランチが worktree / 通常ブランチ / detached HEAD に応じた同期処理を実行
- **理由**: マージ済み自動検出（`gh pr view`）は誤検出リスクと実装複雑度が patch には過剰。手順提示のみではスキル側で動作しない
- **outcome 固定 / 手段 Construction で確定**: 同意時 3 ケースいずれでも「ローカル HEAD（または worktree のチェックアウト位置）が `origin/main` の最新コミットに一致する」状態に至る。具体的な git コマンド系列（`git pull --ff-only` / `git checkout --detach origin/main` / `git reset --hard origin/main` 等）は Construction Phase の設計レビューで決定
- **影響**: Unit 001 で実装

## DR-005: #591 と #585 を 1 Unit に統合し、#585 は #591 完了時に同時 close

- **日時**: 2026-04-26
- **判断者**: ユーザー
- **コンテキスト**: #591 の [P2]（template 更新）が #585 と同一スコープ
- **決定**: 1 Unit (Unit 003) に統合し #591 + #585 を一括実装。#585 は #591 完了時に同時 close
- **理由**: 重複作業を避け、テンプレート更新と手順書明文化のセクション名・行区切り規約等の整合を 1 回の実装で確保
- **影響**: Unit 003 で実装

## DR-006: 検証境界 — スクリプト dry-run / 手順書レビュー / 単体ロジック検証のみ

- **日時**: 2026-04-26
- **判断者**: ユーザー（コメント形式の応答）
- **コンテキスト**: setup/migrate スキルへの変更は実アップグレード走行で検証しにくい
- **決定**: 本サイクル内では `scripts/*.sh` の dry-run / `--help` テキスト整備、Markdown 手順書のレビュー、setup/migrate スキル内ロジックの単体検証のみ。実アップグレード走行検証は v2.4.2 リリース後に別リポジトリ（visitory 等）で運用検証として実施
- **理由**: メタ開発時の検証境界明確化。リリース前の自走検証を強要せず、リリース後の運用検証として位置付けることで patch サイクルの規模を抑制

## DR-007: CHANGELOG 記載粒度を Issue 別詳細列挙とする

- **日時**: 2026-04-26
- **判断者**: ユーザー
- **コンテキスト**: v2.4.1 の patch スタイルを継続するか集約するかの選択
- **決定**: Issue 別に詳細列挙（v2.4.1 と同等のスタイル）
- **理由**: 4 件の Issue が独立した bug / docs / template 修正で、まとめると変更点と Issue の紐帯が見えづらくなる

## DR-008: main 最新化方針 — git merge origin/main で取り込み

- **日時**: 2026-04-26
- **判断者**: ユーザー
- **コンテキスト**: cycle/v2.4.2 ブランチ作成直後に main_status=behind が報告された
- **決定**: `git merge origin/main --no-edit` で v2.4.1 のマージコミット（#606）を取り込む
- **理由**: ストレートな patch サイクルのため、先に取り込むことで逆行コミットや追加作業を防止

## DR-009: Unit 構成 — B 案ベース 3 Unit を Inception 段階で確定

- **日時**: 2026-04-26
- **判断者**: ユーザー
- **コンテキスト**: Intent §「Unit 構成（予定）」では Unit A 案（setup/migrate 統合）と B 案（分離）の選択を Construction Phase に委譲すると記載していたが、Inception 段階で Unit 定義ファイルを作成する必要が発生
- **決定**: B 案ベース 3 Unit（Unit 001=setup マージ後フォローアップ #607 setup側+#605 / Unit 002=migrate マージ後フォローアップ #607 migrate側 / Unit 003=Operations 手順書/template 明文化 #591+#585 統合）
- **理由**: setup/migrate のスキル境界が独立しており、Unit 単位で分離する方がテスト境界が明確で PR 差分も最小化できる。Construction Phase で必要に応じて A 案（統合）に戻す判断が可能（弱依存として Unit 001 → Unit 002 のソフト依存を明記）
- **影響**: Construction Phase の Unit 設計レビューで A/B 案の最終確定を再評価する

## DR-010: AI レビューのフォールバック — セルフレビュー（general-purpose subagent）採用

- **日時**: 2026-04-26
- **判断者**: ユーザー
- **コンテキスト**: codex usage limit に達し、外部CLI（codex）でのIntent / ストーリー / Unit定義レビューが実行不可（次回リセット 2026-04-29 07:56）
- **決定**: `review-routing.md §6` の `cli_runtime_error` フォールバックポリシー（required + cli_runtime_error → retry → user_choice）に従い、ユーザー選択でパス 2（セルフレビュー）にフォールバック。general-purpose subagent でレビュー実施
- **理由**: review_mode=required のためスキップ不可。codex の利用制限解除待ちは Inception を中断させるが、セルフレビューで反復 3 回まで実施することで品質を担保
- **影響**: Inception の 3 回のレビュー（Intent / ストーリー / Unit定義）すべてでセルフレビューを採用。各 progress 文書に「フォールバック発生」を記録。semi_auto ゲートも fallback(cli_runtime_error) 扱いとしてユーザー承認を取得

## DR-011: Intent ファイル参照誤りの訂正 — `scripts/post-merge-cleanup.sh` → `bin/post-merge-sync.sh`

- **日時**: 2026-04-26
- **判断者**: メタ開発者（Inception ステップ2 Reverse Engineering 中に発見）
- **コンテキスト**: Issue #607 本文で「既存 `scripts/post-merge-cleanup.sh`」と記載されていたが実態は `bin/post-merge-sync.sh`。Intent もこの表記をそのまま転記していた
- **決定**: Intent 内の全箇所のファイル参照を `bin/post-merge-sync.sh` に訂正。対応プレフィックスも実態（`cycle/` + `upgrade/`、`chore/aidlc-v*-upgrade` 非対応）に合わせて記述更新
- **理由**: 事実関係の誤りに対する訂正。Construction Phase 着手時にファイルが見つからず Unit 設計が空回りするリスクを排除。Intent の意図・スコープには変更なし
- **影響**: 軽微修正のため Intent 再レビューはスキップ（既存承認内のスコープと判断）。履歴に修正記録を追加

## DR-012: Unit 001 実行順序を「マージ確認 → 差分ガード → HEAD 同期 → 一時ブランチ削除」に変更（Construction Phase）

- **日時**: 2026-04-26
- **判断者**: メタ開発者（Construction Phase Unit 001 設計レビュー反復1 指摘 #2 で発見）
- **コンテキスト**: 当初 Unit 定義 §責務 / plan §実行順序では「マージ確認 → 一時ブランチ削除 → 差分ガード → HEAD 同期」の順序で記述されていたが、設計レビューで `chore/aidlc-v*-upgrade` がチェックアウト中の状態では git 制約により `git branch -d|-D` での削除が不可能であることが判明
- **選択肢**:
  - A: 既存順序を維持し、BranchDeleteFlow 内で「事前 detach → 削除 → 再 checkout」を行う（複雑、コンテキスト破壊）
  - B: 順序を変更し、HEAD 同期で `chore/...` から離脱した後に削除する（シンプル、設計上の不変条件で保証）
- **決定**: B（順序変更）。「マージ確認 → 差分ガード → HEAD 同期 → 一時ブランチ削除」に確定
- **理由**: B 案は INV-8（チェックアウト中ブランチ削除回避）として不変条件で保証可能。HEAD 同期で `chore/...` から離脱（detached or main 系移動）した後にローカル削除が安全に可能となる
- **影響**: Unit 定義 §責務 / plan §実行順序 / domain model / logical design / 手順書 すべてを新順序に同期更新済

## DR-013: Unit 001 main 系判定基準 — `git symbolic-ref --short HEAD == main`

- **日時**: 2026-04-26
- **判断者**: メタ開発者（Construction Phase Unit 001 設計レビュー反復1 指摘 #1 で発見）
- **コンテキスト**: 当初は `git merge-base --is-ancestor HEAD origin/main` を採用候補としていたが、マージ後 `chore/aidlc-v*-upgrade` が origin/main の祖先となり「main 系」と誤判定されることが判明
- **選択肢**:
  - A: `merge-base --is-ancestor` ベース（誤判定リスク）
  - B: `git symbolic-ref --short HEAD == main` ベース（明示的な main ブランチ判定）
- **決定**: B（symbolic-ref ベース）
- **理由**: `chore/aidlc-v*-upgrade` のマージ済みブランチが「main 系」と誤判定されるリスクを排除し、利用者が意図する「現在ブランチが main そのものであるか」を正しく判定する
- **影響**: 5 サブ条件マトリクスの判定ロジックに反映、`master` 等のデフォルトブランチ非対応は Intent §不明点と質問で v2.4.2 スコープ外として明示

## DR-014: Unit 001 ローカル削除コマンド選定 — `-d` 一次 + 失敗時 `-D` 再確認

- **日時**: 2026-04-26
- **判断者**: メタ開発者（Construction Phase Unit 001 設計レビュー反復1 指摘 #5 で発見）
- **コンテキスト**: ローカル削除コマンドの選定で安全性とユーザー体験のバランスを取る必要
- **選択肢**:
  - A: `-d` 一律（squash/rebase merge では失敗）
  - B: `-D` 一律（安全装置を外す）
  - C: `-d` 一次 + 失敗時 `-D` 再確認（フォールバック）
- **決定**: C（フォールバック方式）
- **理由**: 本リポジトリのデフォルト merge_method は `merge`（マージコミット保持）で `-d` が成功する。利用者環境によっては squash/rebase merge が使われる可能性があり、その場合のみ `-d` フォールバック後に `-D` 再確認で対応。`-D` 一律は安全装置を外すため初手としては避ける
- **影響**: Unit 001 手順書および BranchDeleteFlow 設計に反映

## DR-015: Unit 001 挿入位置 — §10「アップグレードの場合」サブサブセクション統合（(b) 案）

- **日時**: 2026-04-26
- **判断者**: メタ開発者（Construction Phase Unit 001 設計レビュー反復2 指摘 #10 で `steps/03-migrate.md` §10 の現状構造確認結果として確定）
- **コンテキスト**: 新規セクションの挿入位置を (a) §9-§10 間の独立節 / (b) §10「アップグレードの場合」サブサブセクション内 のいずれにするか
- **選択肢**:
  - A: §9.5 として独立節（リナンバ大規模化、アップグレード限定の冒頭明示要）
  - B: §10「アップグレードの場合」見出し配下にサブサブセクション `#### マージ後フォローアップ` を追加（リナンバ不要、アップグレード限定が構造的に保証）
- **決定**: B（サブサブセクション統合）
- **理由**: (1) 構造的にアップグレードケース限定が保証される、(2) §10 以降のリナンバ不要、(3) §10「アップグレードの場合」見出し配下のサブサブセクションとしてアップグレード完了メッセージの「前段」に配置することで、フォローアップ完了 → 完了メッセージという自然な流れを実現
- **影響**: Unit 001 手順書実装で (b) を採用、`steps/03-migrate.md` §10 の構造変更なし（サブサブセクション追加のみ）

## DR-016: Unit 002 対象ブランチを `aidlc-migrate/v2` に修正

- **日時**: 2026-04-27
- **判断者**: ユーザー（Construction Phase Unit 002 着手時に発見、AskUserQuestion で 3 択提示し選択）
- **コンテキスト**: Unit 002 定義は当初「`chore/aidlc-v<version>-upgrade` ローカル + リモートブランチの削除」と記載していたが、`aidlc-migrate` スキルが実際に生成するブランチ名は `aidlc-migrate/v2`（v1→v2 マイグレーション専用、固定名）であることが判明。Issue #607 本文も setup ケース（`chore/aidlc-vX.X.X-upgrade`）のみ言及しており、Unit 002 定義の対象ブランチ表記は誤転記
- **選択肢**:
  - A: Unit 002 スコープを `aidlc-migrate/v2` ブランチのマージ後削除案内に変更（推奨）
  - B: Unit 002 を取り下げ（スコープ外と判断）
  - C: Unit 002 定義をそのまま実装（不整合許容、推奨しない）
- **決定**: A（Unit 002 スコープを `aidlc-migrate/v2` 用に変更）
- **理由**: Unit 002 の本質的意図「マージ後の一時ブランチ削除案内」は migrate 側でも同様の利用者体験向上に寄与する。Issue #607 本文は setup スコープのみだが、対象ブランチを `aidlc-migrate/v2` に変更することで Unit の意図を維持しつつ実装可能
- **影響**:
  - Unit 002 定義（`story-artifacts/units/002-migrate-merge-followup.md`）の対象ブランチを `aidlc-migrate/v2` に修正
  - HEAD 切替（`git checkout --detach origin/main` の 1 ケースのみ）を Unit 002 のスコープ内とし、5 サブ条件マトリクス完全実装は Unit 001 のみとする
  - 未コミット差分ガードは migrate のフロー特性上スコープ外
  - Issue 関連付け: Unit 002 は #607 の「精神」に従う形で migrate 側のマージ後フォローアップを実装するが、#607 本文は setup スコープのみ言及のため、本 Unit の close 対象 Issue は別途整理（Operations Phase で明示）
