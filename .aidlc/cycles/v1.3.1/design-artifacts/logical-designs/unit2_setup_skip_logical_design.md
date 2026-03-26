# 論理設計: セットアップスキップ

## 概要

Inception Phase開始時のサイクル存在確認フローを拡張し、サイクルが存在しない場合に自動作成を提案する機能の論理設計。

**重要**: このUnitはプロンプトファイル（Markdown）の修正のみで、コード実装は不要。以下はinception.mdの改修内容の論理設計。

## 変更対象

- **ファイル**: `prompts/package/prompts/inception.md`
- **セクション**: 「最初に必ず実行すること（5ステップ）」の「1. サイクル存在確認」

## 現在のフロー

```
1. サイクル存在確認
   |
   +-- 存在する → 処理を継続
   |
   +-- 存在しない → エラー表示、セットアップを促す
```

## 新しいフロー

```
1. サイクル存在確認
   |
   +-- 存在する → 処理を継続
   |
   +-- 存在しない → 1-1. バージョン確認へ

1-1. バージョン確認
   |
   +-- バージョンが異なる → アップグレード推奨
   |     |
   |     +-- アップグレードする → setup-prompt.md を読み込み（終了）
   |     +-- 続行する → 1-2. サイクル作成へ
   |
   +-- バージョンが同じ、またはファイルがない → 1-2. サイクル作成へ

1-2. サイクル作成
   |
   +-- 作成する → サイクルディレクトリ作成 → ステップ2へ継続
   +-- 作成しない → エラー表示（従来通り）
```

## 詳細設計

### 1-1. バージョン確認

**目的**: AI-DLCスターターキットのアップグレードが必要かどうかを判断

**処理**:
```bash
# スターターキットの最新バージョン（GitHubから取得）
LATEST_VERSION=$(curl -s --max-time 5 https://raw.githubusercontent.com/ikeisuke/ai-dlc-starter-kit/main/version.txt 2>/dev/null || echo "")

# 現在使用中のバージョン（aidlc.toml の starter_kit_version）
CURRENT_VERSION=$(grep -oP 'starter_kit_version\s*=\s*"\K[^"]+' docs/aidlc.toml 2>/dev/null || echo "")

echo "最新: ${LATEST_VERSION:-取得失敗}, 現在: ${CURRENT_VERSION:-なし}"
```

**判定ロジック**:
| LATEST_VERSION | CURRENT_VERSION | 結果 |
|----------------|-----------------|------|
| 取得成功 | 存在 & 異なる（最新 > 現在） | アップグレード推奨 |
| 取得成功 | 存在 & 同じ | サイクル作成へ |
| 取得成功 | 存在しない | サイクル作成へ（aidlc.tomlなし） |
| 取得失敗 | - | サイクル作成へ（バージョン確認スキップ） |

**ユーザーへの通知（最新バージョンが新しい場合）**:
```
AI-DLCスターターキットの新しいバージョンが利用可能です。
- 現在: [CURRENT_VERSION]
- 最新: [LATEST_VERSION]

アップグレードを推奨します。どうしますか？
1. アップグレードする（setup-prompt.md を読み込み）
2. 現在のバージョンで続行する
```

**ネットワーク接続なし/取得失敗時**: バージョン確認をスキップし、1-2. サイクル作成へ進む

### 1-2. サイクルディレクトリ作成

**目的**: セットアップをスキップしてサイクルを直接作成

**ユーザーへの確認**:
```
サイクル {{CYCLE}} のディレクトリが存在しません。
新規作成しますか？（Y/n）
```

**処理（承認後）**: setup-cycle.md のステップ4〜6を実行

#### ステップ4相当: ディレクトリ構造作成

```bash
mkdir -p docs/cycles/{{CYCLE}}/plans
mkdir -p docs/cycles/{{CYCLE}}/requirements
mkdir -p docs/cycles/{{CYCLE}}/story-artifacts/units
mkdir -p docs/cycles/{{CYCLE}}/design-artifacts/domain-models
mkdir -p docs/cycles/{{CYCLE}}/design-artifacts/logical-designs
mkdir -p docs/cycles/{{CYCLE}}/design-artifacts/architecture
mkdir -p docs/cycles/{{CYCLE}}/inception
mkdir -p docs/cycles/{{CYCLE}}/construction/units
mkdir -p docs/cycles/{{CYCLE}}/operations
```

#### ステップ5相当: history.md初期化

```markdown
# プロンプト実行履歴

## サイクル
{{CYCLE}}

---

## [現在日時]

**フェーズ**: 準備
**実行内容**: サイクル開始（Inception Phaseから自動作成）
**成果物**:
- docs/cycles/{{CYCLE}}/（サイクルディレクトリ）

---
```

#### ステップ6相当: backlog.md作成

テンプレート `docs/aidlc/templates/cycle_backlog_template.md` を使用

#### Gitコミット（任意）

```
サイクル {{CYCLE}} を作成しました。

Gitコミットを作成しますか？（Y/n）
```

承認後:
```bash
git add docs/cycles/{{CYCLE}}/
git commit -m "feat: サイクル {{CYCLE}} 開始"
```

### 作成完了後

```
サイクル {{CYCLE}} の準備が完了しました！

作成されたファイル:
- docs/cycles/{{CYCLE}}/history.md
- docs/cycles/{{CYCLE}}/backlog.md
- docs/cycles/{{CYCLE}}/（各種ディレクトリ）

Inception Phase を継続します...
```

→ ステップ2（追加ルール確認）へ進む

## 非機能要件への対応

- **パフォーマンス**: 特になし（bashコマンド数回の実行のみ）
- **セキュリティ**: 特になし（ファイル作成のみ）
- **スケーラビリティ**: 特になし
- **可用性**: バージョンファイルが存在しない場合もエラーにならず処理継続

## 実装上の注意事項

- setup-cycle.md の処理をそのまま移植するのではなく、Inception Phaseの文脈に合わせて調整
- Gitブランチ作成の提案（setup-cycle.md ステップ3）は省略（Inception Phase開始時点でブランチは作成済みと想定）
- 完了メッセージ後、自動的にInception Phaseのステップ2へ継続

## 不明点と質問

（設計時点で不明点なし）
