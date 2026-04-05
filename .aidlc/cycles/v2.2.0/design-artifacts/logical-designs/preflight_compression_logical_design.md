# 論理設計: プリフライト圧縮・バージョンチェック外部化

## 概要
preflight.md手順5のテーブル圧縮と、inception/01-setup.mdステップ6のガイド外部化の変更対象・手順を定義する。

## コンポーネント構成

```text
skills/aidlc/
├── steps/
│   ├── common/
│   │   └── preflight.md      [手順5テーブル圧縮]
│   └── inception/
│       └── 01-setup.md       [ステップ6外部化]
└── guides/
    └── version-check.md      [新規作成]
```

## タスクA: preflight.md手順5テーブル圧縮

### 現状（L127-162）
ghチェック、レビューツール確認、設定バリデーションが散文的に記述。各項目で条件分岐を複数行で説明。

### 圧縮後の構造

手順5を以下のテーブル形式に圧縮:

```markdown
### 5. オプションチェック実行

| チェック項目 | 条件 | 動作 | 表示内容 | severity |
|-------------|------|------|---------|----------|
| gh | `gh_status` != `available` | 警告表示、gh依存機能無効化 | `⚠ gh: {status}（gh依存機能は制限されます）` | warn |
| レビューツール | `review_mode == disabled` | スキップ（表示なし） | （なし） | - |
| レビューツール | `review_tools == []` | 情報表示してスキップ | `ℹ 外部CLIを使用しない設定です（tools = []）` | info |
| レビューツール | 上記以外（通常） | `which {先頭ツール}` で確認 | `ℹ レビューツール ({ツール名}): available / not found` | info |
| defaults.toml | `config/defaults.toml` 不在 | 警告表示 | `⚠ defaults.toml: 不在` | warn |
```

## タスクB: inception/01-setup.mdバージョンチェック外部化

### 外部化対象（01-setup.md L113-180付近）

取得元解決と参照先ポリシー依存部分は01-setup.mdに残し、ComparisonMode判定と比較パターンのみをガイドに外部化する。

**ガイドに移動する内容**:
- 6b. ComparisonMode決定テーブル
- 6c. 比較実行（THREE_WAY, REMOTE_LOCAL, SKILL_LOCAL, REMOTE_SKILL, SINGLE_OR_NONEの5モードパターンテーブル）
- 6d. starter_kit_version確認手順

**01-setup.md側に残す内容**:
- ステップ6のヘッダ
- スキップ条件（`rules.version_check.enabled` が `false`）
- 設定解決順（互換インターフェース、旧キーフォールバック）
- 6a. バージョン情報取得（3点）+ 正規化（取得元は参照先ポリシーに依存するため残す）
- ガイド参照指示: `guides/version-check.md` を参照

### guides/version-check.md の構成
01-setup.mdから移動した6b/6c/6dの内容を配置。冒頭に「このガイドは01-setup.mdのステップ6から参照される。バージョン情報の取得と正規化は01-setup.md側で完了している前提」と明記。見出しレベルは独立ガイドとして調整。

## 実装上の注意事項
- preflight.mdの手順1-3（blocker判定）は変更禁止
- バージョンチェックの全5モードが漏れなくガイドに移行されていることを確認
- ガイド参照は「`guides/version-check.md` を参照」の形式で統一
