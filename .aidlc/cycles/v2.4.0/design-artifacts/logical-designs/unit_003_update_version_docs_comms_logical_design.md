# 論理設計: Unit 003 update-version.sh 仕様変更のドキュメント・周知

## 概要

修正対象 4 ファイルの修正前後のテキスト差分を表形式で定義する。本 Unit はドキュメント更新のみのため、コンポーネント構成・処理フロー等は採用しない。

**重要**: この論理設計では**コードは書かず**、テキスト差分とその位置のみを定義する。具体的なファイル編集は Phase 2 で行う。

## アーキテクチャパターン

ドキュメント更新（plain text Markdown / bash script コメント）。プログラムロジックの変更を含まない。

## 修正対象ファイル一覧

### 1. CHANGELOG.md

修正内容: v2.4.0 セクション骨組みを追加（既存 v2.3.6 セクションの直前、L9 周辺の `---` 区切りの直後）

挿入位置: `## [2.3.6] - 2026-04-20` の直前

挿入テキスト:

```markdown
## [2.4.0] - 2026-04-XX

### Changed

- `bin/update-version.sh` の更新対象から `.aidlc/config.toml.starter_kit_version` を除外（hidden breaking change）。`starter_kit_version` は `aidlc-setup` / `aidlc-migrate` / 将来のアップグレード経路でのみ書き換わる「最後に実行した setup のバージョン」を表す値となり、リリース時の上書きが廃止される。これによりメタ開発リポジトリでバージョン三角検証（local / skill / remote）が正しく機能する（#596 / Unit 002 / Unit 003）
- `bin/update-version.sh` の出力フォーマットから `aidlc_toml_current` / `aidlc_toml_new` / `aidlc_toml:${VERSION}` 行を削除（hidden breaking change）。これらの行に依存する自動化や手順書を持つ利用者は v2.4.0 アップグレード時に追従修正が必要（#596 / Unit 002 / Unit 003）

---

```

注: `### Changed` 見出し配置は、後続 Unit 001/004/007（および Unit 005/006/007 完了処理）が必要に応じて `### Added` / `### Fixed` 等の別見出しを追加できる構造とする。Unit 003 は `### Changed` 配下の `#596` 関連 2 項目のみを所有・編集する（他見出し配下は所有しない）。

### 2. bin/update-version.sh ヘッダコメント

修正対象: L1-L26 全体（特に L3 / L12-L17）

#### 修正前（L1-L26）

```text
#!/usr/bin/env bash
#
# update-version.sh - version.txtとaidlc.tomlのバージョン番号を一括更新
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
#   - .aidlc/config.toml の starter_kit_version
#   - skills/aidlc/version.txt
#   - skills/aidlc-setup/version.txt
#
# 出力形式:
#   - 成功: "version_update:success" + 詳細行
#   - dry-run: "version_update:dry-run" + 詳細行
#   - エラー: "error:<エラー種別>"
#
# 終了コード:
#   0: 正常終了（更新成功またはdry-run）
#   1: エラー
#
```

#### 修正後

```text
#!/usr/bin/env bash
#
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
#     書き換えは aidlc-setup / aidlc-migrate / 将来のアップグレード経路でのみ行われる。
#
# 出力形式:
#   - 成功: "version_update:success" + 詳細行
#   - dry-run: "version_update:dry-run" + 詳細行
#   - エラー: "error:<エラー種別>"
#
# 終了コード:
#   0: 正常終了（更新成功またはdry-run）
#   1: エラー
#
```

### 3. .aidlc/rules.md「バージョンファイル更新」セクション

修正対象: L80-95 周辺（既存「カスタムワークフロー > バージョンファイル更新」セクション末尾）

挿入位置: 既存「**理由**: AI-DLCスターターキット自体のリリース時にバージョン番号を更新するため。」の直後（L97 の直後）

挿入テキスト:

```markdown
**`starter_kit_version` の扱い**: `bin/update-version.sh` は v2.4.0 以降、`.aidlc/config.toml.starter_kit_version` を **更新対象から除外** する。`starter_kit_version` は「最後に実行した `aidlc-setup` / `aidlc-migrate` のバージョン」を表し、リリース時の上書きは行われない。書き換え経路は `aidlc-setup` / `aidlc-migrate` / 将来のアップグレード経路の正規フローに限定される。
```

### 4. docs/configuration.md L49 starter_kit_version 説明

修正対象: L49 の表の 1 行

#### 修正前

```markdown
| `starter_kit_version` | string | インストール済みスターターキットのバージョン |
```

#### 修正後

```markdown
| `starter_kit_version` | string | 最後に実行した `aidlc-setup` / `aidlc-migrate` のバージョン（v2.4.0 以降、`bin/update-version.sh` による上書き対象外） |
```

## Operations Phase 引き継ぎタスク

### `.aidlc/cycles/v2.4.0/operations/tasks/changelog-date-replacement.md`（新規）

`CHANGELOG.md` の v2.4.0 セクションに含まれる `2026-04-XX` プレースホルダを Operations Phase で確定日付に置換するためのタスクファイル。Operations Phase `01-setup.md §10` で AI エージェントが必ず確認する。

ファイル内容は `skills/aidlc/templates/operations_task_template.md`（既存テンプレート）の構造に準拠する:

```markdown
# CHANGELOG リリース日置換

Construction Phase で発生した手動作業を Operations Phase に引き継ぐためのタスク定義です。

---

## 基本情報

- **発生Unit**: Unit 003 - update-version-docs-comms
- **発生日**: 2026-04-23
- **発生サイクル**: v2.4.0
- **緊急度**: 高（CHANGELOG プレースホルダのまま出荷を防ぐ必須タスク）

## 発生理由

Construction Phase Unit 003 で `CHANGELOG.md` の v2.4.0 セクション骨組みを追加した際、リリース日が未確定だったため `## [2.4.0] - 2026-04-XX` の形式でプレースホルダを記載した。Operations Phase の CHANGELOG 更新ステップ（`operations-release.md §7.2-7.6` および `02-deploy.md` 7.2）で確定日付に置換する必要がある。

- 自動化できない理由: リリース日が Operations Phase 実施時点で初めて確定するため、Construction Phase では確定値を埋められない
- 一時的な対応か恒久的な対応か: 一時的（v2.4.0 サイクル限定の引き継ぎ）

## 作業手順

1. `CHANGELOG.md` を開き、`## [2.4.0] - 2026-04-XX` を検索
2. `XX` を Operations Phase 実施日（2 桁ゼロ埋め）に置換（例: `2026-04-25`）
3. `git diff CHANGELOG.md` で置換完了を確認

## 完了条件

- [ ] `grep -c "2026-04-XX" CHANGELOG.md` が 0 を返す
- [ ] v2.4.0 セクションヘッダが `## [2.4.0] - YYYY-MM-DD` の有効な日付形式
- [ ] CHANGELOG コミットに置換差分が含まれている

## 注意事項

- Operations Phase 7.2 の CHANGELOG 更新ステップで他の見出し追加と同タイミングで実施することで、追加コミットを発生させない
- v2.5.0 以降のサイクルでは本タスク不要（このタスクファイルは v2.4.0 サイクル限定）

---

## 実行状態

- **状態**: 未実行
- **実行日**: -
- **実行者**: -
- **備考**: -
```

## 修正前後の整合性確認方針

実装フェーズで以下の確認を行う:

Markdown 表のパイプ文字 `|` 衝突を避けるため、確認コマンドはコードブロックで提示する（実装フェーズでそのままコピー実行可能）:

```bash
# 1. CHANGELOG.md: v2.4.0 セクション骨組み + #596 節 2 項目
grep -c '## \[2.4.0\] - 2026-04-XX' CHANGELOG.md  # → 1
grep -c '\.aidlc/config\.toml\.starter_kit_version` を除外' CHANGELOG.md  # → 1
grep -c 'aidlc_toml_current` / `aidlc_toml_new` / `aidlc_toml' CHANGELOG.md  # → 1

# 2. bin/update-version.sh ヘッダコメント（L1-L30 限定で確認）
sed -n '1,30p' bin/update-version.sh | grep -c '\.aidlc/config\.toml の starter_kit_version'  # → 0（旧記述削除確認）
sed -n '1,30p' bin/update-version.sh | grep -c 'v2.4.0 以降は更新対象外'  # → 1（新記述追加確認）

# 3. bin/update-version.sh 全体（参考、Unit 002 結果回帰なし確認）
grep -cE 'aidlc_toml_(current|new)|aidlc_toml:' bin/update-version.sh  # → 0（Unit 002 で既に削除済み）

# 4. .aidlc/rules.md（実挿入文 **`starter_kit_version` の扱い**: にマッチ、バッククォート + 太字混在のため正規表現で柔軟に確認）
grep -cE 'starter_kit_version.*扱い' .aidlc/rules.md  # → 1

# 5. docs/configuration.md
grep -c 'v2.4.0 以降' docs/configuration.md  # → 1

# 6. 引き継ぎタスクファイル
test -f .aidlc/cycles/v2.4.0/operations/tasks/changelog-date-replacement.md && echo "exists"  # → exists
```

## 非機能要件（NFR）への対応

### パフォーマンス

該当なし（ドキュメント変更）

### セキュリティ

機密情報の混入なし（`starter_kit_version` の値自体は公開情報）

### 可用性

CHANGELOG の記述が公開リリース時点で確実に含まれていること（Operations Phase 7.2 と引き継ぎタスクで担保）

## 技術選定

- **マークダウン**: Keep a Changelog 形式（既存スタイル踏襲）
- **bash コメント**: 既存スタイル踏襲（`# ` プレフィックス、空行区切り）

## 実装上の注意事項

- CHANGELOG の見出し配置は後続 Unit との編集競合を避けるため `### Changed` のみ配置（`### Added` / `### Fixed` は後続 Unit が必要時に追加）
- bin/update-version.sh の使用方法説明は README に重複させない（スクリプト先頭コメントに集約）
- `.aidlc/rules.md` の追記は既存セクション末尾に配置（中間挿入を避け、編集差分を最小化）
- `docs/configuration.md` L49 のテーブル行は 1 行で完結させる（複数行に折り返すと markdownlint 違反の可能性）

## 不明点と質問

なし（計画段階で codex AI レビュー 4 反復を経て path 整合・引き継ぎメカニズム・将来経路明示等を確定済み）。
