# 論理設計: スキル名前空間分離

## 概要

ai-tools.md と skill-usage-guide.md に名前空間マッピングを追加し、marketplace.json との整合性を確保する。カタログレベルの変更のみで、ディレクトリ構造・スキルファイル・シェルスクリプトは変更しない。

## コンポーネント構成

### 1. ai-tools.md への名前空間マッピング追加

**変更箇所**: `prompts/package/prompts/common/ai-tools.md`

現行のスキルテーブル（レビュースキル・ワークフロースキル）を、正規表ベースの構造に変更する。

**変更後の構造**:

```markdown
## スキルカタログ

### 名前空間

| 名前空間 | 説明 |
|----------|------|
| `aidlc:` | AI-DLC固有のワークフロー・レビュースキル |
| `tools:` | 汎用ツールスキル |

### スキル正規表

| 名前空間 | 呼び出し名 | カタログ表示名 | 読むファイル | 状態 | MP掲載 |
|----------|-----------|-------------|-------------|------|--------|
| aidlc | `reviewing-code` | `aidlc:reviewing-code` | `docs/aidlc/skills/reviewing-code/SKILL.md` | active | Yes |
| aidlc | `reviewing-architecture` | `aidlc:reviewing-architecture` | `docs/aidlc/skills/reviewing-architecture/SKILL.md` | active | Yes |
| aidlc | `reviewing-security` | `aidlc:reviewing-security` | `docs/aidlc/skills/reviewing-security/SKILL.md` | active | Yes |
| aidlc | `reviewing-inception` | `aidlc:reviewing-inception` | `docs/aidlc/skills/reviewing-inception/SKILL.md` | active | Yes |
| aidlc | `aidlc-setup` | `aidlc:aidlc-setup` | `docs/aidlc/skills/aidlc-setup/SKILL.md` | active | Yes |
| aidlc | `squash-unit` | `aidlc:squash-unit` | `docs/aidlc/skills/squash-unit/SKILL.md` | active | Yes |
| aidlc | `versioning-with-jj` | `aidlc:versioning-with-jj` | `docs/aidlc/skills/versioning-with-jj/SKILL.md` | deprecated | No |
| tools | `session-title` | `tools:session-title` | `docs/aidlc/skills/session-title/SKILL.md` | active | Yes |

MP掲載 = marketplace.json に掲載。deprecated スキルはマーケットプレイスに非掲載。

### 用途別ガイド（派生表示）

上記正規表から用途別にフィルタした参照ガイド:

- **レビュースキル**: reviewing-* のスキル群。review-flow.md から参照される
- **ワークフロースキル**: aidlc-setup, squash-unit, versioning-with-jj（非推奨）
- **ツールスキル**: session-title
```

**設計根拠**: 1つの正規表を主テーブルとし、用途別セクションは派生表示とすることで、marketplace.json とのセット一致確認を容易にする。squash-unit と session-title が現行 ai-tools.md に未掲載のため、このタイミングで追加する。

### 2. marketplace.json の確認

**変更箇所**: `.claude-plugin/marketplace.json`

現行の marketplace.json は既に `plugins[].name` が名前空間に対応している（`aidlc`, `tools`）。確認事項:

- `aidlc` グループに squash-unit が含まれていること: 含まれている（確認済み）
- `tools` グループに session-title が含まれていること: 含まれている（確認済み）
- `versioning-with-jj` が除外されていること: deprecated のため、マーケットプレイスカタログには登録しない（現状通り）

**marketplace.json と ai-tools.md の非対称性**: ai-tools.md には `versioning-with-jj`（deprecated / MP非掲載）が含まれるが、marketplace.json には非掲載。これは意図的な設計であり、正規表の `状態` 列と `MP掲載` 列で明示される。deprecated スキルは埋め込み方式でのみ提供され、マーケットプレイス経由では配布しない。

**結論**: marketplace.json は変更不要。現状のまま名前空間と整合している。

### 3. skill-usage-guide.md への名前空間説明追加

**変更箇所**: `prompts/package/guides/skill-usage-guide.md`

以下のセクションを追加:

1. **名前空間について**: 名前空間の概念説明
2. **後方互換性**: プレフィックスなしでの呼び出しが引き続き動作する旨
3. **名前衝突解決規則**: コンテキスト別の解決方法

**追加位置**: 「利用可能なスキル」セクションの前（スキル一覧の前に概念を説明）

### 4. sync-package.sh との関係

`sync-package.sh` は `prompts/package/` → `docs/aidlc/` のrsyncを実行する。変更対象の ai-tools.md と skill-usage-guide.md は `prompts/package/` 配下にあるため、sync 実行で自動的に `docs/aidlc/` 側にも反映される。

**確認手順**: 実装後に `sync-package.sh --dry-run` で差分を確認し、`sync-package.sh` を実行して `docs/aidlc/` 側の一致を検証する。

## インターフェース定義

### カタログ表示名の形式

```text
{namespace}:{slug}

namespace := [a-z][a-z0-9-]*    （名前空間プレフィックス）
slug     := [a-z0-9][a-z0-9-]*  （ディレクトリ名、Unit 002のSkillSlug制約に準拠）
```

### 呼び出し名の解決

```text
ユーザー入力: /reviewing-code
→ AIツールがディレクトリ名ベースで解決（外部プラットフォーム責務）
→ .claude/skills/reviewing-code/ のSKILL.mdを読み込み

ユーザー入力: /plugin install reviewing-code
→ Claude Code がmarketplace.jsonから解決（外部プラットフォーム責務）
→ plugins[name="aidlc"].skills から一致するパスを取得
```

## 変更影響範囲

| コンポーネント | 変更 | 影響 |
|--------------|------|------|
| `prompts/package/prompts/common/ai-tools.md` | 正規表ベースの構造に変更 | カタログに名前空間マッピング・状態・MP掲載が追加される |
| `prompts/package/guides/skill-usage-guide.md` | セクション追加 | 名前空間・後方互換・衝突規則が文書化される |
| `.claude-plugin/marketplace.json` | 変更なし | 既に名前空間対応済み |
| `docs/aidlc/prompts/common/ai-tools.md` | sync-package.sh で自動反映 | prompts/package/ のコピー |
| `docs/aidlc/guides/skill-usage-guide.md` | sync-package.sh で自動反映 | prompts/package/ のコピー |
| `setup-ai-tools.sh` | 変更なし | シンボリックリンク作成ロジックに影響なし |
