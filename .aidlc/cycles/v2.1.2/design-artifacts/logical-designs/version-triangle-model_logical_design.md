# 論理設計: バージョン三角モデル比較

## コンポーネント構成

### ステップ6の処理フロー（改訂版）

```
ステップ6: スターターキットバージョン確認
├── スキップ条件判定（既存と同じ）
│   ├── STARTER_KIT_DEV → スキップ
│   └── upgrade_check.enabled != true → スキップ
│
├── 6a. バージョン情報取得（3点）
│   ├── リモート: curl → GitHub main/version.txt（既存）
│   ├── スキル: スキルベースディレクトリの version.txt を Read ツールで取得
│   │   └── パス: SKILL.md と同じベースディレクトリ / version.txt
│   └── ローカル設定: read-config.sh → starter_kit_version（既存）
│
├── 6b. 取得結果の確認
│   ├── スキルバージョン取得失敗 → フォールバック（従来の2点間比較）
│   ├── リモート取得失敗 → 残り2点で比較（skill vs local）
│   └── ローカル取得失敗 → 続行（スキップ、既存動作維持）
│
├── 6c. 三角モデル比較（3点全取得成功時）
│   ├── 全一致 → 「最新バージョンです」
│   ├── REMOTE_NEWER → スキル更新案内
│   ├── SKILL_OLDER → スキル更新案内
│   ├── LOCAL_OLDER → `/aidlc setup` 案内 + starter_kit_version確認手順
│   ├── LOCAL_AHEAD → 警告表示
│   └── MULTIPLE_MISMATCH → 差分表示 + スキル更新→ローカル更新の順に案内
│
└── 6d. フォールバック（スキル取得失敗時）
    └── 従来の2点間比較（remote vs local）をそのまま実行
```

## インターフェース定義

### バージョン取得

| ソース | 取得方法 | タイムアウト | エラー時 |
|--------|---------|-----------|---------|
| リモート | `curl -s --max-time 5 https://raw.githubusercontent.com/ikeisuke/ai-dlc-starter-kit/main/version.txt` | 5秒 | 空として扱う |
| スキル | Readツールでスキルベースディレクトリの`version.txt`を読み込み | なし | フォールバック |
| ローカル | `read-config.sh starter_kit_version` | なし | 空として扱う |

### アクション表示テンプレート

```text
【バージョン比較結果】

■ バージョン情報
  リモート（最新リリース）: {remote_version}
  スキル（インストール済み）: {skill_version}
  ローカル設定: {local_version}

■ 判定: {パターン名}
  {アクションメッセージ}
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
   - 「### パーミッション管理【重要】」セクション内の「aidlc-setup同期前」参照を修正

2. **`.aidlc/operations.md`**:
   - 「### aidlc-setup同期（v2プラグイン構造）」セクション（L76-80）を削除
