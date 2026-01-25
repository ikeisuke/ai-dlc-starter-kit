# 論理設計: プロンプトの圧縮・統合

## 概要

init-cycle-dir.shに共通バックログディレクトリ作成機能を追加し、setup.mdの手動コマンドを削除して重複を解消する。

**重要**: この論理設計では**コードは書かず**、コンポーネント構成とインターフェース定義のみを行います。

## アーキテクチャパターン

単一責任の原則（SRP）に基づき、ディレクトリ初期化処理をinit-cycle-dir.shに集約する。

## コンポーネント構成

### スクリプト構成

```text
prompts/package/bin/
└── init-cycle-dir.sh
    ├── サイクル固有ディレクトリ作成（既存）
    ├── history/inception.md 初期化（既存）
    └── 共通バックログディレクトリ作成（新規追加）
```

### ドキュメント構成

```text
prompts/package/prompts/
├── setup.md（簡略化）
└── common/
    └── intro.md（変更なし）
```

## インターフェース設計

### コマンド

#### init-cycle-dir.sh

**既存インターフェース（変更なし）**:
- **引数**: `<VERSION>` - サイクルバージョン（例: v1.8.0）
- **オプション**: `--dry-run` - 作成せず予定を表示
- **戻り値**: 0=成功, 1=引数エラー, 2=作成エラー

**出力形式（拡張）**:

```text
# 既存出力
dir:docs/cycles/v1.8.0/plans:created
dir:docs/cycles/v1.8.0/history:created
file:docs/cycles/v1.8.0/history/inception.md:created

# 新規追加出力
dir:docs/cycles/backlog:created
dir:docs/cycles/backlog-completed:created
```

## 処理フロー概要

### init-cycle-dir.sh 実行フロー（更新後）

**ステップ**:
1. 引数解析とバージョン検証
2. サイクル固有ディレクトリ（10個）を作成
3. history/inception.md を初期化
4. **backlog mode判定（新規）**
   - `docs/aidlc.toml`から`[backlog].mode`を取得
   - daselが利用可能な場合: `dasel -f docs/aidlc.toml -r toml 'backlog.mode'`
   - daselが利用不可の場合: grepで簡易取得
   - 取得失敗時のデフォルト: `git`
5. **共通バックログディレクトリを作成（条件付き・新規）**
   - modeが`issue-only`の場合: スキップ（出力: `dir:docs/cycles/backlog:skipped-issue-only`）
   - それ以外の場合: docs/cycles/backlog/ と docs/cycles/backlog-completed/ を作成
6. 終了コード返却

**関与するコンポーネント**: init-cycle-dir.sh

### 共通バックログディレクトリ作成の詳細

**処理内容**:
- **mode判定**: `issue-only`の場合は作成をスキップ
- 共通バックログディレクトリはサイクル非依存
- 既に存在する場合は「exists」として出力（エラーではない）
- --dry-run時は「would-create」または「would-skip」として出力

## 非機能要件（NFR）への対応

### パフォーマンス

- **要件**: コンテキスト消費の削減
- **対応策**: setup.mdの手動コマンド削除により、約3行削減

### セキュリティ

- 該当なし

### スケーラビリティ

- 該当なし

### 可用性

- 該当なし

## 技術選定

- **言語**: Bash
- **フレームワーク**: なし
- **ライブラリ**: なし

## 実装上の注意事項

- 共通バックログディレクトリの作成は、サイクル固有ディレクトリ作成後に実行
- 既存の出力形式（`dir:パス:状態`）を維持
- --dry-runオプション時も新規ディレクトリが出力されるよう対応
- **mode判定**: daselが利用不可でもgrepでフォールバック取得
- **issue-onlyモード**: backlogディレクトリ作成をスキップし、状態として`skipped-issue-only`を出力
- ヘルプメッセージの更新: 出力例にbacklogディレクトリを追加

## setup.md の変更詳細

### 削除対象（ステップ10内）

```text
**共通バックログディレクトリ確認**:
mkdir -p docs/cycles/backlog
mkdir -p docs/cycles/backlog-completed
```

### 追加/更新対象

- スクリプト実行結果の説明に共通バックログディレクトリを追加

## 不明点と質問（設計中に記録）

なし（要件が明確）
