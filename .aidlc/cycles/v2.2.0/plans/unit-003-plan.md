# Unit 003 計画: Reviewingスキル共通基盤抽出

## 概要

9つのReviewingスキルのSKILL.mdから共通ボイラープレート（実行コマンド・セッション継続・外部ツール関係・セルフレビューモード）を共通基盤ファイルに抽出し、各SKILL.mdをレビュー観点等の固有セクションのみに簡素化する。

## 現状分析

### サイズ（SKILL.md合計: 52,891 bytes）

| スキル | サイズ |
|--------|--------|
| reviewing-construction-code | 8,000B（focusメタデータ+N/A判定あり） |
| reviewing-inception-units | 6,112B |
| reviewing-construction-design | 6,083B |
| reviewing-operations-premerge | 5,730B（focusメタデータあり） |
| reviewing-construction-integration | 5,717B |
| reviewing-operations-deploy | 5,464B |
| reviewing-construction-plan | 5,423B |
| reviewing-inception-stories | 5,209B |
| reviewing-inception-intent | 5,153B |

### 共通セクション（全9スキルで同一）

1. **実行コマンド**: Codex/Claude Code/Geminiの3ツール実行コマンド
2. **セッション継続**: 反復レビュー用セッション継続コマンド + session-management.md参照
3. **外部ツールとの関係**: 通常モード/セルフレビューモードの2モード説明 + 責務分離
4. **セルフレビューモード**: 手順 + 実行方式 + サブエージェント指示テンプレート + 制約

共通部分: 約4,000B/スキル × 9 = 約36,000B

### 固有セクション

- frontmatter（name, description, argument-hint等）
- スキル説明・focusメタデータ（一部スキルのみ）
- **レビュー観点**（各スキル固有）
- N/A判定ガイダンス（reviewing-construction-codeのみ）

### 付随する重複: references/session-management.md

9スキルに同一ファイルが存在（MD5一致）。本Unitではスコープ外（Unit定義の境界: ランタイム効果なし）。共通基盤とsession-management.mdは別責務として維持する。

## 責務境界の定義

### 共通基盤の責務（reviewing-common-base.md）

外部ツール実行基盤に関する共通仕様を一元管理する:

- 実行コマンド（Codex / Claude Code / Gemini の3ツール）
- セッション継続コマンド
- 外部ツールとの関係（通常モード/セルフレビューモードの説明・責務分離）
- セルフレビューモード（手順・実行方式・サブエージェント指示テンプレート・制約）

### 各SKILL.mdの責務

スキル固有の振る舞いと識別情報を管理する:

- frontmatter（name, description, argument-hint, compatibility, allowed-tools）
- スキル説明・focusメタデータ
- **レビュー観点**（各スキル固有の品質基準）
- N/A判定ガイダンス（該当スキルのみ）
- 共通基盤への参照指示

### 境界ルール

- レビュー観点・focusメタデータ・N/A判定は常にSKILL.md側に配置
- 外部ツール実行方式・セルフレビュー手順は常に共通基盤側に配置
- 新規ツール追加（例: 新しいCLIレビューツール）は共通基盤への変更
- 新規レビュー観点追加はSKILL.mdへの変更

## 設計上の決定事項（Phase 1で確定）

### Q1: 配置と更新方式

**方針**: source of truth + 配布生成の分離

- **正本（source of truth）**: `skills/reviewing-common/reviewing-common-base.md`（専用ディレクトリに1ファイル）
- **配布先**: 各スキルの `references/reviewing-common-base.md`（生成物として複製）
- **更新手順**: 正本を編集 → `bin/sync-reviewing-common.sh` で9スキルに配布 → 差分確認 → コミット
- **プラグインデプロイ**: 各スキル配下に複製済みのためクロススキル参照不要。プラグインキャッシュ個別展開でも動作

### Q2: 参照方式

SKILL.md内にRead指示: 「共通基盤の実行コマンド・セルフレビューモード等は `references/reviewing-common-base.md` を参照」

### Q3: session-management.mdの扱い

**スコープ外**。共通基盤とsession-management.mdは別責務として分離を維持する:
- 共通基盤: 実行コマンド・モード切替・セルフレビュー（スキル起動時に常に参照）
- session-management.md: 反復レビューのセッション管理詳細（必要時のみ参照）

## 障害伝播防止

### 共通基盤読み込み失敗時のフォールバック

各SKILL.mdには共通基盤への参照指示のみを記載するが、以下の最小動作保証を設ける:

- SKILL.md単体でスキルの識別（frontmatter）とレビュー観点は完結する
- 共通基盤が欠落した場合、レビュー観点に基づくセルフレビューは実行可能（外部CLIコマンドやセッション継続の詳細が参照不可になるだけ）
- review-flow.md側のエラーフォールバック（CLI不在時→セルフレビュー→ユーザーレビュー）が既に存在するため、共通基盤欠落は「CLI実行情報不在」として既存フォールバックで吸収される

### 9スキル一括検証

Phase 2完了時に実施:
1. 初回ロードサイズ計測（`wc -c` で全SKILL.md合計）
2. Reviewing 9種の起動確認（各スキル呼び出しが正常動作するか）
3. 代表フロー疎通確認（Construction Code + Inception Intent + Operations Premerge）

## 作業内容

### Phase 1: 設計

1. 既存9スキルの共通セクションの差分確認（完全一致 or 微差）
2. 共通基盤ファイルの内容定義（責務境界に基づく）
3. SKILL.md簡素化後の構造定義
4. sync-reviewing-common.sh のインターフェース設計

### Phase 2: 実装

1. 正本 `skills/reviewing-common/reviewing-common-base.md` を作成
2. `bin/sync-reviewing-common.sh` を作成（正本→9スキルへの配布）
3. 9スキルのSKILL.mdから共通セクションを削除し、共通基盤参照に置換
4. 初回ロードサイズ計測 + 9スキル一括検証

## 完了条件チェックリスト

### 機能完了

- [ ] 正本（`skills/reviewing-common/reviewing-common-base.md`）が作成されている
- [ ] 配布スクリプト（`bin/sync-reviewing-common.sh`）が作成されている
- [ ] 9つのReviewingスキルのSKILL.mdが固有セクション（frontmatter・レビュー観点等）のみに簡素化されている
- [ ] 共通基盤への参照指示が各SKILL.mdに記載されている
- [ ] 各SKILL.mdのfrontmatter（name, description, argument-hint, compatibility, allowed-tools）が維持されている

### 設計品質

- [ ] 責務境界が明文化されている（共通基盤 vs 各SKILL.md）
- [ ] 共通基盤欠落時のフォールバック動作が確認されている
- [ ] 固有ルール追加時の変更箇所が各SKILL.mdに局所化されている
- [ ] 共通基盤変更時の影響が配布スクリプト実行で全スキルに一括反映される

### 検証

- [ ] 初回ロードサイズ計測で圧縮効果が確認されている（補助指標: SKILL.md合計 ~53KB → ~20KB以下）
- [ ] Reviewing 9種の起動確認（スキル呼び出しが正常動作）
- [ ] 代表フロー疎通確認（Construction Code + Inception Intent + Operations Premerge）

## 影響範囲

- 変更対象: 9スキルのSKILL.md + 正本新規作成 + 配布スクリプト新規作成
- レビュー観点の内容自体は変更しない
- スキルの外部インターフェース（呼び出し名・引数）は変更しない
- session-management.md は変更しない（スコープ外）
