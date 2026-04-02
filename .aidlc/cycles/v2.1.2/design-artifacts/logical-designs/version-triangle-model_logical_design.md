# 論理設計: バージョン三角モデル比較

## コンポーネント構成

### ステップ6の処理フロー（改訂版）

```
ステップ6: スターターキットバージョン確認
├── スキップ条件判定（既存と同じ）
│   ├── STARTER_KIT_DEV → スキップ
│   └── upgrade_check.enabled != true → スキップ
│
├── 6a. バージョン情報取得（3点）+ 正規化
│   ├── リモート: curl → GitHub main/version.txt（既存）→ 正規化
│   ├── スキル: skills/aidlc/version.txt を Read ツールで取得 → 正規化
│   │   └── パス特定: skills/aidlc/SKILL.md の親ディレクトリ直下の version.txt
│   └── ローカル設定: read-config.sh → starter_kit_version（既存）→ 正規化
│   ※ 正規化: vプレフィックス除去、空白トリム、semverパース検証
│   ※ パース失敗は取得失敗と同等扱い（available=false）
│
├── 6b. ComparisonMode決定
│   ├── 3点全available → THREE_WAY
│   ├── skillのみunavailable → REMOTE_LOCAL（従来フォールバック）
│   ├── remoteのみunavailable → SKILL_LOCAL
│   ├── localのみunavailable → REMOTE_SKILL
│   └── 2点以上unavailable → SINGLE_OR_NONE（比較スキップ、警告のみ）
│
├── 6c. 比較実行（ComparisonModeに応じて分岐）
│   ├── THREE_WAY:
│   │   ├── 全一致 → ALL_MATCH
│   │   ├── remote > skill = local → REMOTE_NEWER
│   │   ├── remote = local > skill → SKILL_OLDER
│   │   ├── remote = skill > local → LOCAL_OLDER
│   │   ├── local > remote = skill → LOCAL_AHEAD
│   │   └── それ以外 → MULTIPLE_MISMATCH
│   ├── REMOTE_LOCAL:
│   │   ├── 一致 → PARTIAL_MATCH + skill unavailable警告
│   │   ├── remote > local → LOCAL_OLDER
│   │   └── local > remote → LOCAL_AHEAD
│   ├── SKILL_LOCAL:
│   │   ├── 一致 → PARTIAL_MATCH + remote unavailable警告
│   │   └── 不一致 → PARTIAL_MISMATCH + 差分表示 + 警告
│   ├── REMOTE_SKILL:
│   │   ├── 一致 → PARTIAL_MATCH + local unavailable警告
│   │   ├── remote > skill → PARTIAL_MISMATCH + スキル更新案内 + 警告
│   │   └── skill > remote → PARTIAL_MISMATCH + 「スキルが先行」警告
│   └── SINGLE_OR_NONE: 比較スキップ、unavailableソースの警告のみ
│
└── 6d. 結果表示（ComparisonResult）
    ├── バージョン情報（available分のみ表示、unavailableは「取得失敗」と表示）
    ├── 判定パターンとアクション
    └── 警告メッセージ（unavailableソースの理由）
```

## インターフェース定義

### バージョン取得

| ソース | 取得方法 | パス解決 | タイムアウト | エラー時 |
|--------|---------|---------|-----------|---------|
| リモート | `curl -s --max-time 5 https://...version.txt` | 固定URL | 5秒 | available=false |
| スキル | Readツールで `skills/aidlc/version.txt` を読み込み | `skills/aidlc/SKILL.md` の親ディレクトリ直下 | なし | available=false, mode→REMOTE_LOCAL |
| ローカル | `read-config.sh starter_kit_version` | config.toml | なし | available=false |

### アクション表示テンプレート

```text
【バージョン比較結果】（{comparison_mode}モード）

■ バージョン情報
  リモート（最新リリース）: {remote_version | "取得失敗（理由: {error_reason}）"}
  スキル（インストール済み）: {skill_version | "取得失敗（理由: {error_reason}）"}
  ローカル設定: {local_version | "取得失敗（理由: {error_reason}）"}

■ 判定: {パターン名}
  {アクションメッセージ}

{warnings があれば}
■ 警告
  {各警告メッセージ}
```

### starter_kit_version確認手順（LOCAL_OLDERパターン時に追加表示）

```text
アップグレード後、以下を確認してください:
1. `/aidlc setup` を実行してアップグレードモードを完了
2. `.aidlc/config.toml` の `starter_kit_version` がスキルバージョンと一致するか確認
```

## aidlc-setup同期廃止の設計

### 変更対象と変更内容

1. **`.aidlc/rules.md`**:
   - 「### aidlc-setup同期【重要】」セクション（L149-159）を削除
   - 「### パーミッション管理【重要】」セクション内の「aidlc-setup同期前」参照を「次のカスタムワークフロー前」に修正

2. **`.aidlc/operations.md`**:
   - 「### aidlc-setup同期（v2プラグイン構造）」セクション（L76-80）を削除
