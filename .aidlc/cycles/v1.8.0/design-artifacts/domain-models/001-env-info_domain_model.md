# ドメインモデル: 環境情報一覧スクリプト（Unit 001）

## 1. 概要

依存ツール（gh, dasel, jj, git）の状態を一覧で出力するスクリプトのドメインモデル。

## 2. ドメイン概念

### 2.1 ツール（Tool）

AI-DLCで使用する外部ツール。

| プロパティ | 型 | 説明 |
|-----------|------|------|
| name | string | ツール名（gh, dasel, jj, git） |
| status | ToolStatus | ツールの状態 |

### 2.2 ツール状態（ToolStatus）

ツールの利用可能状態を表す列挙型。

| 値 | 説明 |
|----|------|
| available | 利用可能（インストール済み、認証済み） |
| not-installed | 未インストール |
| not-authenticated | インストール済みだが認証されていない（ghのみ） |

## 3. 対象ツールと判定ロジック

### 3.1 gh（GitHub CLI）

```text
if command -v gh not found → not-installed
elif gh auth status fails → not-authenticated
else → available
```

### 3.2 dasel

```text
if command -v dasel not found → not-installed
else → available
```

### 3.3 jj（Jujutsu）

```text
if command -v jj not found → not-installed
else → available
```

### 3.4 git

```text
if command -v git not found → not-installed
else → available
```

## 4. 出力フォーマット

各ツールの状態を1行ずつ出力：

```text
{tool_name}:{status}
```

**出力例**:

```text
gh:available
dasel:not-installed
jj:available
git:available
```

## 5. 境界と制約

### 5.1 スコープ内

- ツールの存在確認（command -v）
- ghの認証状態確認（gh auth status）
- 統一フォーマットでの出力
- ヘルプオプション（`-h`, `--help`）のサポート

### 5.2 スコープ外

- ツールのインストール
- ツールのバージョン確認
- ツールの設定変更
- JSON形式出力（将来の拡張として検討）

### 5.3 出力順序

出力は以下の固定順序とする（将来の拡張時も互換性を維持）：
1. gh
2. dasel
3. jj
4. git

## 6. 非機能要件

- **オフライン動作**: ネットワーク接続なしで動作すること
  - 注: `gh auth status` はローカルの認証情報を確認するためネットワーク不要
- **即時応答**: 数秒以内に完了すること
- **ポータビリティ**: bash環境で動作すること
