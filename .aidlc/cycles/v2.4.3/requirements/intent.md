# Intent（開発意図）

## プロジェクト名

ai-dlc-starter-kit v2.4.3 (patch)

## 開発の目的

**主目的**: v2.4.2 までに発見されたオープン Issue 4 件を 1 patch サイクルで解消し、(A) `aidlc-setup` のアップグレード走行ブランチ命名と運用文言の明確化、(B) レビューツール解決ロジックのセルフ呼び出し正式統合（後方互換シム付き）、(C) `migrate-backlog.sh` の UTF-8 対応バグ修正、(D) `markdownlint` のローカル即時検出への一本化（PostToolUse hook 採用 + Operations §7.5 削除）を完成させる。CI（`pr-check.yml` の `markdownlint-cli2-action`）は必須 Check として継続、ローカル hook は即時フィードバック、Operations Phase は CI と hook に依存する形に簡素化する。

対象 Issue:

1. **#612 bug**: aidlc-setup スターターキット自身に対するアップグレード走行でブランチ名 `upgrade/vX.X.X` が紛らわしい
2. **#611 refactor**: レビューツール設定にセルフ呼び出し（self/claude）を含めて、フォールバック分岐をツール解決に統合する
3. **#610 bug/feedback**: `migrate-backlog.sh` の Perl invocation が UTF-8 を解釈せず `tr` が `Illegal byte sequence` を出す（fullwidth カッコ含むタイトルで slug が欠落）
4. **#609 refactor**: `markdownlint` を Claude Code hook（PostToolUse）に移行する

## ターゲットユーザー

- AI-DLC Starter Kit を **メタ開発（Inception/Construction/Operations）するメンテナ自身**
  - #612 の影響を直接受けるのはメタ開発者（dogfooding 中の version 不一致時）
  - #609 / #611 の hook / レビューツール体験向上もメタ開発時の即時フィードバック改善
- AI-DLC Starter Kit を **ダウンストリームプロジェクトに導入して使う利用者**
  - #612 案 B のブランチ命名変更（`upgrade/aidlc-vX.X.X`）が直接見える運用文言
  - #611 のレビューツール設定（`tools = ["codex", "self"]` の正式表現）を新たに使える
  - #610 のバグ修正で日本語タイトル含む backlog 移行が破綻しなくなる

## ビジネス価値

- **メタ開発体験の改善**: 日常的に踏むバグ・紛らわしい運用（#612 / #610）を解消し、レビューループ・lint ループの即時性を高める（#609 / #611）
- **ダウンストリーム品質**: スターターキット利用プロジェクトでの操作ミス（誤読されるブランチ名）と日本語データロス（slug 欠落）を未然に防ぐ
- **ドキュメント・実装の整合性回復**: 実装は既に `chore/aidlc-v<version>-upgrade` 命名で稼働しているが `.aidlc/rules.md` には旧表記 `upgrade/vX.X.X` が残存。本サイクルで実態と文言を整合させ、ローカル `starter_kit_version` 同期、Operations §7.5 削除も含めて「実態と手順書の乖離」を解消

## 成功基準

- **#612**: ダウンストリーム向け upgrade ブランチ命名は既に実装上 `chore/aidlc-v<version>-upgrade` で稼働しているため、`.aidlc/rules.md` の旧表記 `upgrade/vX.X.X` を実装と整合する形に更新し、`aidlc-setup` / `aidlc-migrate` スキル文言で「ダウンストリーム向け運用 vs スターターキット自身は `cycle/vX.X.X`」の役割対比が明示される。命名のリネーム（実装側の作業）は対象外で、文言・ドキュメント整合のみで完結する
- **#611**: `[rules.reviewing].tools` に `"self"`（および alias `"claude"`）が正式に許容される。`tools = ["codex"]` のような既存設定は **末尾 self を暗黙追加する後方互換シム**で従来通り動作する。`tools = []` は従来通り「セルフ直行シグナル」として扱い、シム適用後の解決結果と等価（`["self"]` 相当）であることを明文化する。新規明示 `tools = ["codex", "self"]` も正しく解釈される。`review-routing.md` の `fallback_to_self` 分岐がツール解決ロジックに畳み込まれる
- **#610**: `scripts/migrate-backlog.sh` の `generate_slug()` が `perl -CSD -Mutf8` で動作し、fullwidth カッコ含む日本語タイトルでも `tr: Illegal byte sequence` を出さず slug が末尾まで保持される
- **#609**: `.claude/settings.json` の PostToolUse に markdownlint hook（新規 hook スクリプト、命名は Construction で確定）が追加され、Edit/Write 直後の `*.md` 編集で違反検出。Operations §7.5 ステップは Operations Phase 手順書から削除され、`scripts/operations-release.sh lint` サブコマンド本体も削除する（hook と CI に集約）。`operations-release.md` 以外で §7.5 を参照している全箇所（grep ベースで特定）も同期して更新される。CI の `pr-check.yml` `markdown-lint` job は必須 Check として継続
- **共通**: 4 Issue がすべて close、関連テスト pass、CI green、関連 history / progress が記録される
- **CHANGELOG / README**: v2.4.3 リリースノートに 4 Issue の解消内容が反映され、`.aidlc/config.toml` の `starter_kit_version = "2.4.3"` が同コミットで更新される

## 期限とマイルストーン

- 単一 patch サイクル v2.4.3 内で完了
- Operations Phase で PR 作成 → main マージ → タグ `v2.4.3` 付与 → リリース完了
- GitHub Milestone `v2.4.3` は本サイクルでは未作成。直近サイクル（v2.4.2 等）の慣習に従い、`inception.05-completion` ステップ1で正式作成し 4 Issue を紐付ける（早期紐付けは `02-preparation` で試行済みだが Milestone 不在のため `defer-to-05-completion`）

## 制約事項

- **patch スコープ厳守**: 上記 4 Issue 以外の backlog（#592, #590, #586, #582, #581, #573 等）は本サイクル対象外
- **後方互換性**: #611 の `tools` 設定は **既存 `.aidlc/config.toml` を変更せずに動作する**こと（暗黙 self 追加シムで対応）
- **CI 互換性**: `pr-check.yml` の `markdown-lint` job 仕様は変えない（必須 Check として継続）。hook 追加は `.claude/settings.json` のみ
- **メタ開発・ダウンストリーム両立**: #612 のブランチ命名変更は両者の文脈を区別できる形で実装（`cycle/*` がスターターキット自身、`upgrade/aidlc-*` がダウンストリーム）
- **DEPRECATED スクリプト保守**: #610 の `migrate-backlog.sh` には DEPRECATED マークが付与されているが、現サイクルで日本語タイトル破壊を起こすため最小修正（UTF-8 解釈の有効化）を入れる。削除タイミング自体の見直しは本サイクルでは行わず、必要なら別 Issue 化する

## 含まれるもの

1. `.aidlc/rules.md` のブランチ運用フロー文言を実装（既存命名 `chore/aidlc-v<version>-upgrade`）に整合させ、`aidlc-setup` / `aidlc-migrate` SKILL.md ・関連ステップに「ダウンストリーム向け運用 vs スターターキット自身は `cycle/vX.X.X`」の役割対比を追加（#612 案 B）。命名自体のリネームは行わない（実装は既に新命名）
2. `[rules.reviewing].tools` に `"self"` を正式追加し、後方互換シム（暗黙末尾 self 追加）と既存 `fallback_to_self` 分岐の整理（#611）。`review-routing.md` / `review-flow.md` / `defaults.toml` 更新
3. `scripts/migrate-backlog.sh` の `generate_slug()` を Perl の UTF-8 モード（例: `perl -CSD -Mutf8`）に切り替え、fullwidth カッコ等を含む日本語タイトルでバイト境界破壊を起こさないようにする（#610）
4. `.claude/settings.json` への markdownlint PostToolUse hook 追加（新規 hook スクリプト、命名・配置は Construction で確定）と Operations §7.5 削除（`operations-release.md` / 関連手順書の §7.5 参照を grep で特定して同期更新、`scripts/operations-release.sh` lint サブコマンドも削除）（#609）
5. v2.4.3 リリース準備（CHANGELOG / README 更新、`.aidlc/config.toml` `starter_kit_version` 更新、history 記録）

## 含まれないもの

- v2.4.2 以前のサイクルで完了済みの修正の再適用や巻き戻し
- 新機能追加（minor 相当）: 振り返りステップ追加（#590）、cycle ディレクトリ別リポジトリ分離（#582）、Operations 復帰判定 new_format 完成（#581）、construction 並列実装（#441）など
- `"self"` / `"claude"` 以外の汎用ツール名正規化拡張（例: 任意の LLM CLI 名のエイリアス機構、複数 LLM 並列実行）。本サイクルでは `"self"` を主軸 + `"claude"` を alias の単純置換に限定し、汎用化は後続サイクルへ
- markdownlint の lint ルール変更（`.markdownlint.json` のルール調整は本サイクル対象外）
- `migrate-backlog.sh` 自体の DEPRECATED 解除や全面リライト

## 不明点と質問（Inception Phase中に記録）

[Question] #611 の `"self"` と `"claude"` のエイリアス扱いはどう正規化するか？
[Answer] 本サイクルでは `"self"` を主軸の正式名称、`"claude"` を alias として扱う最小実装。エイリアス正規化は ToolResolver 入口で `"claude" -> "self"` の単純置換で吸収する（#611 Issue 本文の「self（または claude）」記述に整合）。

[Question] #612 案 B のブランチ命名は、過去サイクルで作成された `upgrade/v*` ブランチや関連スクリプト（`bin/post-merge-sync.sh` 等）にどう影響するか？
[Answer] 実態確認の結果、ダウンストリーム向け命名は v2.4.2 サイクル（#607 対応）で既に `chore/aidlc-v<version>-upgrade` に統一済みで、`aidlc-setup` / `aidlc-migrate` 実装が新命名で稼働している。旧表記 `upgrade/vX.X.X` が残存するのは `.aidlc/rules.md` のブランチ運用フロー文言のみ。本サイクルでは「実装は既存のまま、rules.md の文言を実装に整合させ、両用途の役割対比を追加する」という最小修正で完結する。過去履歴上の `upgrade/v*` ブランチ名は変更しない。`bin/post-merge-sync.sh` の対応プレフィックスは Construction Phase で再確認するが、v2.4.2 で `chore/aidlc-v*-upgrade` が追加されている可能性が高く、追加作業は最小化する見込み。

[Question] #609 hook 追加で markdownlint 未インストール環境はどうハンドリングするか？
[Answer] hook スクリプト `bin/markdownlint-on-md-changes.sh` 内で `markdownlint-cli2` の存在確認を行い、未インストール時はスキップして exit 0（Claude Code 側でブロックされない）。CI 側は `markdownlint-cli2-action@v18` がセットアップを行うため未インストール問題は発生しない。
