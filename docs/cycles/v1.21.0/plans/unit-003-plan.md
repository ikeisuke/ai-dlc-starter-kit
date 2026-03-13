# Unit 003 計画: スキル名前空間分離

## 概要

AI-DLC固有スキル（`aidlc:`）と汎用ツールスキル（`tools:`）を名前空間プレフィックスで論理的に分類する。カタログレベルの概念であり、ディレクトリ構造やスキルファイルの実体は変更しない。

## 全スキル一覧と名前空間マッピング

### スキル正規表

| ディレクトリ名 | 名前空間 | カタログ表示名 | 呼び出し名 | 状態 |
|--------------|----------|-------------|-----------|------|
| aidlc-setup | aidlc | `aidlc:aidlc-setup` | `aidlc-setup` | active |
| reviewing-architecture | aidlc | `aidlc:reviewing-architecture` | `reviewing-architecture` | active |
| reviewing-code | aidlc | `aidlc:reviewing-code` | `reviewing-code` | active |
| reviewing-inception | aidlc | `aidlc:reviewing-inception` | `reviewing-inception` | active |
| reviewing-security | aidlc | `aidlc:reviewing-security` | `reviewing-security` | active |
| squash-unit | aidlc | `aidlc:squash-unit` | `squash-unit` | active |
| session-title | tools | `tools:session-title` | `session-title` | active |
| versioning-with-jj | aidlc | `aidlc:versioning-with-jj` | `versioning-with-jj` | deprecated（Unit 004で削除予定） |

### 名前空間定義

| 名前空間 | プレフィックス | 説明 |
|----------|-------------|------|
| aidlc | `aidlc:` | AI-DLC固有のワークフロー・レビュースキル |
| tools | `tools:` | 汎用ツールスキル |

### 後方互換仕様

- 内部 `/skill` コマンドの実行は常にディレクトリ名ベース（例: `/reviewing-code`）
- プレフィックス付き名前（例: `aidlc:reviewing-code`）はカタログ上の論理的な表示名であり、実行時の解決には使用されない
- プレフィックス付き呼び出しのエイリアス解決レイヤーは実装しない

### 名前衝突時の解決規則

衝突解決の責務を実行コンテキストごとに分離する:

| コンテキスト | 解決方法 | 責務主体 |
|------------|---------|---------|
| 内部 `/skill` 呼び出し | ディレクトリ名で一意解決 | AIツール（Claude Code等） |
| マーケットプレイス `/plugin install` | `plugins[].name` + スキルスラッグで解決 | Claude Code プラットフォーム |
| 同一名前空間内の重複 | 禁止（カタログ登録時に検証） | ドキュメント管理者 |
| 異なる名前空間間の同一ディレクトリ名 | 禁止（ディレクトリ名がグローバル一意） | ドキュメント管理者 |

### 情報の正（Source of Truth）

| 情報 | 正 | 派生先 | 一致保証 |
|------|---|--------|---------|
| マーケットプレイス向けスキルカタログ | `.claude-plugin/marketplace.json` | なし（独立） | - |
| 埋め込み方式向けスキル参照 | `prompts/package/prompts/common/ai-tools.md` | `docs/aidlc/prompts/common/ai-tools.md`（rsync） | sync-package.sh |
| スキル利用手順 | `prompts/package/guides/skill-usage-guide.md` | `docs/aidlc/guides/skill-usage-guide.md`（rsync） | sync-package.sh |

**一致チェック手順**: 実装完了後に marketplace.json の plugins[].skills と ai-tools.md のスキル一覧が同一セットであることを手動確認する。

## 変更対象ファイル

### 変更

- `prompts/package/prompts/common/ai-tools.md` — スキルカタログに名前空間マッピングテーブルを追加
- `.claude-plugin/marketplace.json` — 名前空間情報の反映（plugins[].name が既に名前空間に対応済み。確認・微調整のみ）
- `prompts/package/guides/skill-usage-guide.md` — 名前空間の説明と後方互換仕様を追記

### 変更なし

- ディレクトリ構造（`prompts/package/skills/` 配下）
- スキルファイル（各 `SKILL.md`）
- `setup-ai-tools.sh`（シンボリックリンク作成ロジック）
- `sync-package.sh`（rsyncロジック自体は変更不要）

## 実装計画

### Phase 1: 設計

1. **ドメインモデル設計**: 名前空間の概念モデル、衝突解決ルールの構造化
2. **論理設計**: カタログ構造への名前空間マッピングの統合方法

### Phase 2: 実装

3. **ai-tools.md の更新**: スキルカタログに名前空間マッピングテーブルを追加
4. **marketplace.json の確認・更新**: plugins[].name が名前空間に対応していることを確認し、必要に応じて調整
5. **skill-usage-guide.md の更新**: 名前空間の説明、後方互換仕様、名前衝突解決規則を追記
6. **同期・互換確認**: `sync-package.sh` 実行 → `docs/aidlc/` 差分検証 → `setup-ai-tools.sh` 互換確認 → marketplace.json と ai-tools.md のスキル一覧一致確認

## 完了条件チェックリスト

- [ ] ai-tools.md のスキルカタログに名前空間マッピング（カタログID、表示名、呼び出し名）が定義されている
- [ ] marketplace.json に名前空間マッピングが反映されている
- [ ] 後方互換仕様が文書化されている（プレフィックスなし名前での呼び出しが既存動作として明記）
- [ ] 名前衝突時の解決規則が仕様として文書化されている（コンテキスト別に責務主体を明記）
- [ ] `sync-package.sh` 実行後、`docs/aidlc/` 側に変更が正しく反映されている
- [ ] marketplace.json の plugins[].skills と ai-tools.md のスキル一覧が同一セットであることを確認済み
