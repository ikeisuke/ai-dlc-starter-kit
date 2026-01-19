# Unit 001 計画: env-info-integration

## 概要

setup.mdの依存ツール確認セクションで`env-info.sh`を活用し、個別のツール確認bashコマンドを統合する。

## 変更対象ファイル

- `prompts/package/prompts/setup.md` - 依存コマンド確認セクションを修正

## 背景と制約

### 現状

setup.mdのステップ1「依存コマンド確認」では、ghとdaselを個別にチェックするbashコードが記載されている：

```bash
# ghの判定
if ! command -v gh >/dev/null 2>&1; then
  GH_STATUS="未インストール"
elif ! gh auth status >/dev/null 2>&1; then
  GH_STATUS="未認証"
else
  GH_STATUS="利用可能"
fi

# daselの判定
if command -v dasel >/dev/null 2>&1; then
  DASEL_STATUS="利用可能"
else
  DASEL_STATUS="未インストール"
fi
```

### env-info.shの出力形式

```
gh:available
dasel:not-installed
jj:available
git:available
```

状態値:
- `available`: 利用可能
- `not-installed`: 未インストール
- `not-authenticated`: 未認証（ghのみ）

### 制約（Unit定義より）

- **env-info.sh自体の修正は行わない**（既存スクリプトをそのまま利用）
- 新しい依存ツールの追加は行わない（別Unitで対応）

## 実装計画

### Phase 1: 設計

1. **ドメインモデル設計**: 依存ツール確認フローの構造を定義
2. **論理設計**: env-info.sh出力の解析ロジックと表示フォーマットを設計

### Phase 2: 実装

1. setup.mdのステップ1を修正:
   - env-info.shを呼び出す
   - 出力から必要なツール（gh, dasel）の状態を抽出
   - 状態値を日本語（利用可能/未インストール/未認証）に変換して表示
2. markdownlintでフォーマット確認

## 設計方針

### 出力解析ロジック

env-info.shの出力を行ごとに解析し、必要な情報を抽出する：

```bash
# env-info.shを実行して結果を取得
ENV_INFO=$(docs/aidlc/bin/env-info.sh)

# 各ツールの状態を抽出
GH_RAW=$(echo "$ENV_INFO" | grep "^gh:" | cut -d: -f2)
DASEL_RAW=$(echo "$ENV_INFO" | grep "^dasel:" | cut -d: -f2)

# 状態値を日本語に変換
case "$GH_RAW" in
  available) GH_STATUS="利用可能" ;;
  not-installed) GH_STATUS="未インストール" ;;
  not-authenticated) GH_STATUS="未認証" ;;
  *) GH_STATUS="不明" ;;
esac

case "$DASEL_RAW" in
  available) DASEL_STATUS="利用可能" ;;
  not-installed) DASEL_STATUS="未インストール" ;;
  *) DASEL_STATUS="不明" ;;
esac
```

## 完了条件チェックリスト

- [x] setup.mdの依存ツール確認セクションでenv-info.shを呼び出す
- [x] 個別のツール確認bashコマンドをenv-info.sh呼び出しに置き換える
- [x] 出力結果に基づいて状態を判定するロジックを記載
- [x] 変更後のsetup.mdがmarkdownlintをパスすることを確認（設定が有効な場合）- スキップ（設定無効）

## 関連Issue

- #81: env-info.shにセットアップ情報を追加（将来的な拡張提案、本Unitではenv-info.sh自体の修正は行わない）
