# Intent（開発意図）

## プロジェクト名

AI-DLC Starter Kit v1.9.2

## 開発の目的

v1.8.2でのマージ漏れ機能の完了と、既存機能のバグ修正・改善を行うパッチリリース。

- v1.8.2で延期されたai_tools/ai_author機能の実装完了
- write-history.shのプレリリースバージョン対応
- operations.mdのサイズ最適化
- KiroCLI Skills対応の調査と実装

## ターゲットユーザー

- AI-DLCスターターキットを使用する開発者
- 複数のAIツール（Claude Code, Cursor, Cline, Windsurf等）を使い分けるユーザー
- KiroCLIを使用するユーザー

## ビジネス価値

- **開発体験の向上**: 複数AIツール利用時のCo-Authored-By情報が正確になる
- **柔軟性の向上**: プレリリースバージョンでの開発サイクルが可能に
- **保守性の向上**: operations.mdのサイズ最適化でメンテナンスしやすく
- **エコシステム拡大**: KiroCLI対応によりユーザー層拡大

## 成功基準

| 基準 | 検証方法 |
|------|---------|
| write-history.shがv2.0.0-alpha.6形式を受け付ける | `write-history.sh --cycle v2.0.0-alpha.6 ...` が正常終了することを確認（macOS/zsh, Ubuntu/bash） |
| operations.mdが1000行以下になる | `wc -l prompts/package/prompts/operations.md` で1000以下を確認 |
| review-flow.mdにai_tools設定が追加される | 設定例と使用方法が記載されていることを確認 |
| AIツールの環境変数からai_authorが自動設定される | 各環境変数設定時のCo-Authored-By出力をテスト |
| KiroCLI用スキルファイルが作成される | `prompts/package/skills/kiro/SKILL.md` が存在し、KiroCLI v1.24.0で読み込めることを確認 |

## 期限とマイルストーン

パッチリリースのため、短期間での完了を目指す。

## 制約事項

- パッチリリースのため、破壊的変更は行わない
- 既存の設定（aidlc.toml）との後方互換性を維持
- メタ開発の意識: prompts/package/を編集し、docs/aidlc/は直接編集しない

## 非ゴール（スコープ外）

- 新規機能の追加（Issue対象外の機能）
- docs/aidlc/の構造変更
- aidlc.tomlのスキーマ変更（既存キーの追加オプションは可）
- 他のAIツール（Gemini CLI等）への対応拡大

## 影響範囲

| 変更対象 | 影響 |
|---------|------|
| prompts/package/bin/write-history.sh | プレリリースバージョン形式の受付（既存動作に影響なし） |
| prompts/package/prompts/operations.md | 説明文の簡略化（機能変更なし） |
| prompts/package/prompts/common/review-flow.md | ai_tools設定の追加（既存設定との後方互換性あり） |
| prompts/package/prompts/common/rules.md | ai_author自動検出ロジック追加（既存設定優先で後方互換性あり） |
| prompts/package/skills/kiro/ | 新規ディレクトリ追加（既存に影響なし） |

**周辺ファイルの確認結果**:
- `prompts/package/skills/` 配下にREADME.mdは存在しない
- 既存スキル: claude/, codex/, gemini/ の3ディレクトリ
- kiro/ 追加による名前衝突なし、索引更新不要

## 依存関係・前提条件

- **KiroCLI**: v1.24.0以降（Skills機能が追加されたバージョン）
- **環境変数**: CLAUDE_CODE, CURSOR_EDITOR, CLINE_VERSION, WINDSURF等のAIツール固有環境変数を参照
- **参考ドキュメント**:
  - AWS Blog - KiroCLI 1.24.0リリース記事: https://aws.amazon.com/jp/blogs/news/kiro-cli-1-24-0/
  - KiroCLI公式ドキュメント: https://kiro.dev/docs/cli/
  - **参照時点**: 2026-01-25（KiroCLI v1.24.0）
  - **注記**: 外部URLは変更される可能性あり。リリース時点のバージョンと取得日を記録

## KiroCLI Skills仕様準拠範囲

**注**: 詳細はUnit実装時のKiroCLI調査で確定する。以下は現時点での想定。

- **ディレクトリ構成**: `.kiro/skills/{skill-name}/` または `prompts/package/skills/kiro/`
- **必須ファイル**: SKILL.md（スキル定義）
- **準拠すべき項目**: KiroCLI公式ドキュメントのSkillsセクションに従う
- **調査で確定する事項**: フロントマター形式、必須セクション、resources指定方法

## 互換性リスクと対策

| リスク | 対策 |
|-------|------|
| ai_author自動検出が既存設定を上書きする | aidlc.tomlのai_author設定を最優先とし、未設定時のみ自動検出 |
| 検出失敗時に誤った値が設定される | 固定デフォルト値は使用せず、ユーザーに確認 |
| 自動検出を無効化したい場合 | aidlc.tomlで明示的にai_authorを設定 |
| CI環境での動作 | CI環境でもAIツール自己認識により正しく検出 |

## 既存ユーザーへの影響シナリオ

| シナリオ | 影響 | 対処 |
|---------|------|------|
| aidlc.tomlでai_authorを設定済み | 影響なし（既存設定優先） | - |
| ai_authorを設定していない | AIツールを自動検出してCo-Authored-Byを設定 | 固定したい場合はaidlc.tomlで明示設定 |
| 自動検出に失敗した場合 | ユーザーに確認（固定デフォルト値は使用しない） | 初回のみ確認、以降はaidlc.tomlに保存推奨 |

**CHANGELOGへの記載方針**: 上記の挙動変更を「Changed」セクションに明記し、固定方法を案内する

## 成果物定義

| 成果物 | 保存場所 | フォーマット |
|-------|---------|-------------|
| KiroCLI調査レポート | docs/cycles/v1.9.2/research/kirocli-skills.md | Markdown |
| KiroCLI用スキルファイル | prompts/package/skills/kiro/SKILL.md | Markdown（KiroCLI Skills形式） |
| ai_tools/ai_author実装 | prompts/package/prompts/common/rules.md, review-flow.md | Markdown |
| write-history.sh修正 | prompts/package/bin/write-history.sh | Bash |
| operations.md最適化 | prompts/package/prompts/operations.md | Markdown |

## 配布・更新方針

- **編集対象**: `prompts/package/` 配下のみ編集
- **docs/aidlc/生成**: Operations Phaseでrsyncにより同期（直接編集禁止）
- **リリースノート**: CHANGELOG.mdに変更内容を追記
- **バージョンタグ**: Operations Phase完了後にv1.9.2タグを付与

## 対象Issue

| # | タイトル | 対応方針 |
|---|---------|---------|
| 105 | write-history.sh プレリリース対応 | バージョン形式バリデーション拡張 |
| 108 | operations.mdサイズ最適化 | 説明の簡略化 |
| 111 | ai_tools設定による複数AIサービス対応 | review-flow.mdへ機能追加 |
| 110 | ai_author動的切替機能 | 環境変数からの自動検出 |
| 107 | KiroCLI Skills対応 | 調査+スキルファイル作成 |

## 不明点と質問（Inception Phase中に記録）

[Question] #108 operations.mdの最適化方法は？
[Answer] 説明の簡略化で対応（外部ファイル分離は行わない）

[Question] #110 ai_author動的切替の実装アプローチは？
[Answer] 環境変数からの自動検出で実装

[Question] #107 KiroCLI調査の成果物は？
[Answer] 調査レポート + KiroCLI用スキルファイル作成まで実施
