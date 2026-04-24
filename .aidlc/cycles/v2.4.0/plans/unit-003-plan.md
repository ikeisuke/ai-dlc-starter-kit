# Unit 003 計画: update-version.sh 仕様変更のドキュメント・周知

## 対象 Unit

- **Unit ファイル**: `.aidlc/cycles/v2.4.0/story-artifacts/units/003-update-version-docs-comms.md`
- **担当ストーリー**: ストーリー 6b（update-version.sh 仕様変更のドキュメント・周知、#596 周知側）
- **関連 Issue**: #596（部分対応：本 Unit はドキュメント・周知のみ。スクリプト挙動変更は Unit 002 で完了済み）
- **依存 Unit**: Unit 002（完了済み）
- **見積もり**: 0.5〜1 時間
- **実装優先度**: Medium

## 課題と修正方針

### 課題

Unit 002 で `bin/update-version.sh` の hidden breaking change（`.aidlc/config.toml.starter_kit_version` 上書き廃止 + `aidlc_toml_*` 出力削除）を実装したが、利用者がアップグレード時にこの挙動変化を把握できる文書化が未整備。各ドキュメントが Unit 002 の確定挙動を反映する必要がある。

### 修正方針

以下 4 ファイルの **`#596` 関連セクションのみ** を更新する。Milestone 関連（`#597`）の更新は Unit 007 へ委譲（責務分離）:

1. **CHANGELOG.md**: v2.4.0 セクション骨組みを作成し `#596` 節（hidden breaking change 2 項目）を記載
2. **bin/update-version.sh**: スクリプト先頭ヘッダコメント L3 / L12-L17 を新仕様に追従（本 Unit が排他所有）
3. **`.aidlc/rules.md`**: 「バージョンファイル更新」セクション（L80-95）に `starter_kit_version` の正規の書き換え経路の追記
4. **docs/configuration.md**: `starter_kit_version` 説明（L49）を新設計（更新対象外、`aidlc-setup` / `aidlc-migrate` 経由でのみ書き換わる）に追従

### Unit 定義との path 整合判断（rules.md 実体確認）

Unit 定義（`003-update-version-docs-comms.md` L19）と user_stories.md（L151）では `skills/aidlc/rules.md` を対象として記述しているが、本リポジトリ実体を `find -name "rules.md"` で確認したところ:

- `skills/aidlc/rules.md`: **存在しない**（`skills/aidlc/` 配下は `config/` `guides/` `scripts/` `SKILL.md` `steps/` `templates/` `version.txt` のみ）
- `.aidlc/rules.md`: **存在し、メタ開発用カスタムルールファイルとして機能**（L80-95 に「バージョンファイル更新」セクションあり、`bin/update-version.sh --version {{CYCLE}}` の呼び出し例を含む）

したがって、Unit 定義 / user_stories.md が想定していた `skills/aidlc/rules.md` は本リポジトリ環境では `.aidlc/rules.md` に対応する。本計画では実体に合わせて `.aidlc/rules.md` を対象とする。なお `guides/version-management.md`（user_stories.md 受け入れ基準で代替候補として挙げられたファイル）は、`.aidlc/rules.md` に追記する形で十分明文化できるため新規作成しない。

### CHANGELOG `#596` 節の記載案

v2.4.0 セクション骨組みを `## [2.4.0] - 2026-04-XX` で作成し、以下を含める:

```markdown
### Changed

- `bin/update-version.sh` の更新対象から `.aidlc/config.toml.starter_kit_version` を除外（hidden breaking change）。`starter_kit_version` は `aidlc-setup` / `aidlc-migrate` / 将来のアップグレード経路でのみ書き換わる「最後に実行した setup のバージョン」を表す値となり、リリース時の上書きが廃止される。これによりメタ開発リポジトリでバージョン三角検証（local / skill / remote）が正しく機能する（#596 / Unit 002 / Unit 003）
- `bin/update-version.sh` の出力フォーマットから `aidlc_toml_current` / `aidlc_toml_new` / `aidlc_toml:${VERSION}` 行を削除（hidden breaking change）。これらの行に依存する自動化や手順書を持つ利用者は v2.4.0 アップグレード時に追従修正が必要（#596 / Unit 002 / Unit 003）
```

**v2.4.0 セクション骨組み**: Unit 003 では `## [2.4.0] - 2026-04-XX` ヘッダ + `### Changed` 見出し + `#596` 節 2 項目のみを追加する。`#597` / `#588` / `#595` 節および他の見出し（`### Added` / `### Fixed` 等）の追加は Unit 007 / 001 / 004 が担当（編集競合予防）。

### bin/update-version.sh ヘッダコメント修正案

```text
# update-version.sh - version.txt とスキル version.txt のバージョン番号を一括更新
#
# 使用方法:
#   ./update-version.sh --version <version> [--dry-run]
#
# パラメータ:
#   --version <version>: バージョン番号（必須。vプレフィックス付き可: v1.16.2 → 1.16.2）
#   --dry-run: 実際の書き込みを行わず、変更内容を表示
#
# 更新対象:
#   - version.txt（プロジェクトルート）
#   - skills/aidlc/version.txt（存在時のみ）
#   - skills/aidlc-setup/version.txt（存在時のみ）
#
# 注: .aidlc/config.toml.starter_kit_version は v2.4.0 以降は更新対象外。
#     存在チェックと妥当性検証（read_starter_kit_version）のみ実施。
#     書き換えは aidlc-setup / aidlc-migrate 経由でのみ行われる。
```

### .aidlc/rules.md「バージョンファイル更新」セクション追記案

既存記述（L80-98）の末尾に注記追加:

```markdown
**`starter_kit_version` の扱い**: `bin/update-version.sh` は v2.4.0 以降、`.aidlc/config.toml.starter_kit_version` を **更新対象から除外** する。`starter_kit_version` は「最後に実行した `aidlc-setup` / `aidlc-migrate` のバージョン」を表し、リリース時の上書きは行われない。書き換え経路は `aidlc-setup` / `aidlc-migrate` / 将来のアップグレード経路の正規フローに限定される。
```

### docs/configuration.md L49 修正案

修正前:
```markdown
| `starter_kit_version` | string | インストール済みスターターキットのバージョン |
```

修正後:
```markdown
| `starter_kit_version` | string | 最後に実行した `aidlc-setup` / `aidlc-migrate` のバージョン（v2.4.0 以降、`bin/update-version.sh` による上書き対象外） |
```

## 完了条件チェックリスト

### Unit 定義「責務」由来

- [ ] CHANGELOG の v2.4.0 セクション骨組み（`## [2.4.0] - 2026-04-XX` + `### Changed`）が作成され、`#596` 節 2 項目（starter_kit_version 除外 / aidlc_toml_* 出力削除）が hidden breaking change として明記されている
- [ ] `bin/update-version.sh` の先頭ヘッダコメント（L3 / L12-L17）が新仕様に追従され、`.aidlc/config.toml` 関連の旧記述が削除されている
- [ ] `.aidlc/rules.md`「バージョンファイル更新」セクションに `starter_kit_version` の正規書き換え経路の追記が含まれている（実体確認済み: `skills/aidlc/rules.md` は本リポジトリに存在せず `.aidlc/rules.md` を対象とする）
- [ ] `docs/configuration.md` L49 の `starter_kit_version` 説明が新設計に追従している
- [ ] README.md は本 Unit で編集していない（Unit 007 担当）

### Unit 定義 / user_stories.md との path 整合判断

- [ ] Unit 定義 L19 / user_stories.md L151 の `skills/aidlc/rules.md` 想定は実体不在のため `.aidlc/rules.md` で代替したことを明記している
- [ ] user_stories.md L151 で代替候補として挙げられた `guides/version-management.md` の新規作成は不要（`.aidlc/rules.md` への追記で明文化要件を満たす）と判断している
- [ ] 4 ファイル固定（CHANGELOG / bin/update-version.sh / .aidlc/rules.md / docs/configuration.md）の判断根拠は「実体確認による合理化」と「既存ドキュメント構造への追記で受け入れ基準を満たせること」

### Unit 定義「境界」由来

- [ ] スクリプト本体の挙動変更を含まない（Unit 002 で完了済み）
- [ ] Milestone 関連ドキュメント（CHANGELOG `#597` 節 / README Milestone 説明 / `rules.md` の Milestone セクション / `configuration.md` のサイクル運用 / `guides/issue-management.md` 等）への変更を含まない
- [ ] `aidlc-setup` / `aidlc-migrate` の書き込み経路の実装変更を含まない
- [ ] 翻訳ドキュメント（`docs/translations/`）への変更を含まない

### CHANGELOG セクション分離（編集競合予防）

- [ ] v2.4.0 セクション骨組みは Unit 003 で作成（`#596` 節のみ埋める）
- [ ] `#597` / `#588` / `#595` 節の挿入位置は Unit 007 / 001 / 004 が後続で追記する余地を残す（`### Changed` / `### Added` / `### Fixed` の見出し配置を考慮）

### 設計フェーズ計画

`depth_level=standard` のため Phase 1（設計）を実施。ドキュメント更新のため極めて最小粒度:

- ドメインモデル: `.aidlc/cycles/v2.4.0/design-artifacts/domain-models/unit_003_update_version_docs_comms_domain_model.md`
  - 内容: 「ドキュメント周知の責務分離（#596 節 vs #597 節 vs 他）」のみ。エンティティ等は採用しない
- 論理設計: `.aidlc/cycles/v2.4.0/design-artifacts/logical-designs/unit_003_update_version_docs_comms_logical_design.md`
  - 内容: 修正対象 4 ファイルの修正前後のテキスト差分表のみ

## 実装フェーズ計画

1. CHANGELOG.md に v2.4.0 セクション骨組み + `#596` 節 2 項目を追加（既存 v2.3.6 セクションの直前に挿入）
2. `bin/update-version.sh` L3, L12-L17 のヘッダコメントを新仕様に修正
3. `.aidlc/rules.md` L80-95 周辺の「バージョンファイル更新」セクションに `starter_kit_version` 注記を追加
4. `docs/configuration.md` L49 の `starter_kit_version` 説明を新設計に追従
5. markdownlint 実行（CHANGELOG / docs/configuration.md / .aidlc/rules.md は `bin/check-defaults-sync.sh` 等の対象外、純粋に lint 確認のみ）
6. 自動テスト不要（ドキュメント更新のため）。代わりに目視レビューと codex AI レビューで品質担保

## 完了処理計画

1. Unit 定義ファイル `003-update-version-docs-comms.md` の「実装状態」を「完了」に更新
2. `.aidlc/cycles/v2.4.0/history/construction_unit03.md` への履歴追記
3. `construction/progress.md` の Unit 003 行 + 現在の Unit / 完了済み Unit 3 セクション一貫更新
4. **Operations Phase 引き継ぎタスクファイル作成**: `.aidlc/cycles/v2.4.0/operations/tasks/changelog-date-replacement.md` を作成し、`CHANGELOG.md` の v2.4.0 セクションに含まれる `2026-04-XX` プレースホルダを Operations Phase で確定日付に置換すべき旨を記録（Operations Phase 01-setup.md §10 で必ず確認される）
5. squash 統合（中間コミット 0 件のため `squash:skipped:no-commits` の見込み）
6. PR #599 へのコミット push
7. Issue #596 ステータス更新方針: **本 Unit 完了でサイクル PR マージ時に `Closes #596` で auto-close 準備が整う**（#596 は Unit 002 + Unit 003 の 2 Unit 完了を必要とする）

## リスク・注意事項

### 編集競合予防

- CHANGELOG の v2.4.0 セクションは Unit 003 が **骨組みと `#596` 節のみ** を作成。後続 Unit 007 / Unit 001 完了処理 / Unit 004 完了処理で `#597` / `#588` / `#595` 節を追記する際、`### Changed` / `### Added` / `### Fixed` の見出しを追加する形で物理的に競合を避ける
- `bin/update-version.sh` の先頭ヘッダコメントは Unit 003 が排他所有（Unit 002 計画でも明記済み）

### ドキュメント整合性

- `bin/update-version.sh` の使用方法説明は README ではなくスクリプト先頭コメントに集約する方針（Unit 定義 L21 で明記済み）
- `aidlc-setup` / `aidlc-migrate` の書き込み経路は既存挙動を維持するため、それらの内部ドキュメントは変更しない（影響範囲を最小化）

### CHANGELOG リリース日

- v2.4.0 のリリース日は Operations Phase で確定するため、Unit 003 では `## [2.4.0] - 2026-04-XX` の `XX` プレースホルダで記載する
- **置換責任者と置換タイミング**: Operations Phase の CHANGELOG 更新ステップ（`skills/aidlc/steps/operations/operations-release.md §7.2-7.6` および `skills/aidlc/steps/operations/02-deploy.md` 7.2 で規定、`rules.release.changelog = true` 時に実行）で AI エージェントが確定日付に置換する
- **引き継ぎメカニズム**: Unit 003 完了処理で `.aidlc/cycles/v2.4.0/operations/tasks/changelog-date-replacement.md` を作成し、Operations Phase 開始時に `skills/aidlc/steps/operations/01-setup.md §10`「Construction 引き継ぎタスク確認」で AI エージェントが必ず確認・実行する運用フローに乗せる。これにより `XX` プレースホルダ残存事故を防ぐ
- **完了処理時の追加確認**: 本 Unit 完了時に `git diff CHANGELOG.md` で v2.4.0 セクションに `XX` プレースホルダが正しく含まれていることを目視確認する
