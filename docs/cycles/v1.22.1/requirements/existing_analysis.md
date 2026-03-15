# 既存コードベース分析

## ディレクトリ構造・ファイル構成

本サイクルのIntent対象領域に焦点を当てた分析。

```
prompts/package/
├── skills/session-title/          # session-titleスキル（削除対象）
│   ├── SKILL.md                   # スキル定義（44行）
│   └── bin/aidlc-session-title.sh # 実装スクリプト（92行）
├── lib/validate.sh                # 共有バリデーションライブラリ（92行、rsync対象外）
├── prompts/
│   ├── inception.md               # Inception Phaseプロンプト（アップグレードチェック: Step 5）
│   ├── operations.md              # Operations Phaseプロンプト
│   ├── operations-release.md      # Operations Phaseリリース手順（PRマージフロー: Step 6.6-6.7）
│   └── common/rules.md            # 共通ルール（$()禁止ルール定義）
└── guides/skill-usage-guide.md    # スキル利用ガイド

docs/aidlc/
├── skills/aidlc-setup/bin/aidlc-setup.sh  # セットアップスクリプト（rsync同期処理）
├── bin/
│   ├── read-config.sh             # 設定読み込み（lib/validate.sh依存）
│   └── write-history.sh           # 履歴記録（lib/validate.sh依存）
└── lib/validate.sh                # バリデーションライブラリ（コピー先、rsync対象外）

docs/cycles/rules.md               # プロジェクト固有ルール（PRレビューゲート定義）
```

## アーキテクチャ・パターン

### session-titleスキル統合構造
- **ソース**: `prompts/package/skills/session-title/`（ai-dlc-starter-kit内）
- **参照箇所**:
  - `inception.md` L176: Step 1.5で呼び出し（phase="Inception"）
  - `construction.md` L208: Step 2.6で呼び出し（phase="Construction"）
  - `construction.md` L311: Step 4.5で再実行（Unit選択後）
  - `operations.md` L148: Step 2.6で呼び出し（phase="Operations"）
  - `common/ai-tools.md` L29, L63: スキルカタログエントリ
  - `guides/skill-usage-guide.md` L40, L82-83, L100, L128: スキルディレクトリ・分類・呼び出し例
- **根拠**: 全フェーズで利用されるが、オプション機能であり欠落しても動作に影響なし

### lib/ディレクトリ同期ギャップ
- `aidlc-setup.sh` L327-334の`SYNC_DIRS`配列に`lib`が含まれていない
- `SYNC_DIRS`: prompts, templates, guides, bin, skills, kiro（6ディレクトリのみ）
- `read-config.sh` L42と`write-history.sh` L36が`source "${SCRIPT_DIR}/../lib/validate.sh"`で依存
- **根拠**: `aidlc-setup.sh`のrsync対象定義を直接確認

### $()コマンド置換の状況
- プロンプトファイル内のBashコードブロック: **違反0件**（全46ファイル検査済み）
- `common/rules.md` L249-261に禁止ルールが明記済み
- 全箇所がmktempパターンに準拠
- **根拠**: 全プロンプトファイルのBashブロックを網羅的に検査

### PRマージフロー構造
- `operations-release.md`: Step 6.6（PR Ready化）→ 6.6.5（コミット漏れ確認）→ 6.6.6（リモート同期）→ 6.6.7（main差分チェック）→ 6.7（マージ）
- `rules.md` L154-202: 6.6.7と6.7の間に必須ゲート（PRレビューコメント確認）をプロジェクト固有ルールとして定義
- `rules.md` L142-152: Codex PRレビュー再実行ルール（`@codex review`トリガー）
- **根拠**: `operations-release.md`と`rules.md`の該当セクションを確認

## 技術スタック

| 項目 | 値 | 根拠ファイル |
|------|-----|-------------|
| 言語 | Bash（スクリプト）、Markdown（プロンプト） | bin/*.sh, prompts/**/*.md |
| フレームワーク | AI-DLC（独自開発ライフサイクル手法） | docs/aidlc/ |
| 主要ツール | Claude Code, Codex CLI, GitHub CLI | docs/aidlc.toml, rules.md |

## 依存関係

### 内部モジュール間（パッケージ単位）
- `bin/read-config.sh` → `lib/validate.sh`（emit_error, validate_cycle関数）
- `bin/write-history.sh` → `lib/validate.sh`（emit_error, validate_cycle関数）
- `aidlc-setup.sh` → `prompts/package/`（rsync同期元）
- 各フェーズプロンプト → `common/rules.md`, `common/review-flow.md`（共通ルール参照）
- 各フェーズプロンプト → `skills/session-title/`（オプション呼び出し）

### 循環依存
- なし

## 特記事項

- **$()違反が0件**: #329（承認プロンプト頻発）の原因がプロンプトファイル内の$()ではないことが判明。他の原因（heredoc構文、複雑なパイプライン等）の調査が必要
- **session-title不具合修正は外部リポジトリ**: #328（関係ないタブを書き換える問題）はclaude-skills側のaidlc-session-title.shの問題。本サイクルでは削除・参照変更のみ
- **PRレビューゲートは2ファイルに分散**: パッケージ側（operations-release.md）とプロジェクト固有（rules.md）の両方に影響。統合・整理が必要
