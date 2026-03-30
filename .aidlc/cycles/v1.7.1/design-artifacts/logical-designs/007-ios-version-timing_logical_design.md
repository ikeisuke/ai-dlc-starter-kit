# 論理設計: iOSバージョン更新タイミング

## 概要

iOSプロジェクト（project.type=ios）において、バージョン更新をInception Phaseで実施するオプションを追加する。aidlc.tomlに設定を追加し、inception.mdとoperations.mdにロジックを追加する。

**重要**: この論理設計では**コードは書かず**、コンポーネント構成とインターフェース定義のみを行います。

## アーキテクチャパターン

プロンプトエンジニアリングにおける条件分岐パターンを採用。設定ファイル（aidlc.toml）から値を読み取り、プロンプト内で条件分岐する。

## コンポーネント構成

### ファイル構成

```text
prompts/package/
├── aidlc.toml          # 設定追加
└── prompts/
    ├── inception.md    # バージョン更新提案追加
    └── operations.md   # 条件分岐追加
```

### コンポーネント詳細

#### aidlc.toml

- **責務**: プロジェクトタイプ設定の保持
- **変更内容**: `[project]`セクションに`type`設定を追加
- **デフォルト値**: `"general"`（未設定時）

#### inception.md

- **責務**: Inception Phase完了時のバージョン更新提案
- **依存**: aidlc.tomlの`project.type`設定
- **変更箇所**: 「完了時の必須作業」セクション

#### operations.md

- **責務**: バージョン確認時のInception更新済み判定
- **依存**: aidlc.tomlの`project.type`設定
- **変更箇所**: ステップ1「デプロイ準備」のバージョン確認セクション

## データモデル概要

### 設定ファイル形式（aidlc.toml）

追加する設定:

```toml
[project]
# ... 既存設定 ...
type = "general"  # "general" | "web" | "backend" | "cli" | "desktop" | "ios" | "android"
```

**フィールド定義**:
- **type**: String - プロジェクトタイプ

**デフォルト値のフォールバックルール**:
- `type`キーが存在しない場合: `"general"`として扱う
- `type`キーが空文字の場合: `"general"`として扱う
- `type`キーが不正な値の場合: 警告を表示し`"general"`として扱う
- フォールバック判定はプロンプトロジック内で実施（設定ファイル自体には書き込まない）

## 処理フロー概要

### Inception Phase完了時の処理フロー

**ステップ**:

1. `project.type`設定を読み取る
2. `project.type = "ios"`か判定
3. `"ios"`の場合: バージョン更新提案を表示
4. ユーザーが承認した場合: Info.plistまたは対象ファイルのバージョンを更新
5. 更新後、通常の完了処理を継続

**関与するコンポーネント**: aidlc.toml, inception.md

### Operations Phase バージョン確認の処理フロー

**ステップ**:

1. `project.type`設定を読み取る
2. `project.type = "ios"`か判定
3. `"ios"`の場合: Inception Phase履歴（`history/inception.md`）を確認
4. 履歴に「iOSバージョン更新実施」の記録がある場合: 「Inception Phaseで更新済み」と表示、更新をスキップ
5. 記録がない場合: 従来通り更新を提案

**関与するコンポーネント**: aidlc.toml, operations.md, history/inception.md

**注意**: バージョン値の比較ではなく履歴記録を使用する。これにより、すでに同じバージョンだった場合でも正確に判定できる。

## 変更詳細設計

### 1. aidlc.toml への設定追加

**追加位置**: `[project]`セクション内（tech_stackの後）

**追加内容**:

```toml
# プロジェクトタイプ（v1.7.1で追加）
# type: "general" | "web" | "backend" | "cli" | "desktop" | "ios" | "android"
# - general: 一般的なプロジェクト（デフォルト）
# - web: Webアプリケーション
# - backend: バックエンドサービス
# - cli: コマンドラインツール
# - desktop: デスクトップアプリケーション
# - ios: iOSアプリケーション（Inception Phaseでバージョン更新を提案）
# - android: Androidアプリケーション
# type = "general"
```

**設計判断**: デフォルトはコメントアウト状態で提供し、必要に応じてユーザーが有効化する形式を採用。

### 2. inception.md への変更

**追加位置**: 「完了時の必須作業」セクション内、ステップ0（サイクルラベル作成）の後、ステップ1（履歴記録）の前

**追加セクション名**: 「0.5 iOSバージョン更新【project.type=iosの場合のみ】」

**処理内容**:

1. `project.type`読み取り
2. `"ios"`判定
3. 対象外の場合はスキップ
4. バージョン更新提案の表示
5. ユーザー承認後にバージョン更新

**バージョン形式の正規化**:
- サイクルバージョン（`{{CYCLE}}`）: `v1.7.1`形式
- iOS用バージョン: `1.7.1`形式（vプレフィックスなし）
- 正規化処理: `${CYCLE#v}` でvプレフィックスを除去

**質問フォーマット**:

```text
【iOSプロジェクト向け】バージョン更新の確認

project.type=iosのため、Inception Phaseでバージョンを更新することを推奨します。

これにより、Construction Phase中のTestFlight配布が可能になります。

現在のバージョン: [現在バージョン]
更新後のバージョン: [CYCLE_VERSIONからvを除去した値、例: 1.7.1]

バージョンを更新しますか？

1. はい - バージョンを更新する（推奨）
2. いいえ - Operations Phaseで更新する
```

**スコープ外の明記**:
- ビルド番号（CFBundleVersion）の管理はこの機能のスコープ外
- ビルド番号はCIツール（fastlane等）で自動管理することを推奨

### 3. operations.md への変更

**変更位置**: ステップ1「デプロイ準備」→「バージョン確認【必須】」セクション

**変更内容**: iOSプロジェクトの場合、Inception Phase履歴を確認する処理を追加

**追加処理**:

1. `project.type = "ios"`の場合
2. Inception Phase履歴（`docs/cycles/{{CYCLE}}/history/inception.md`）を確認
3. 「iOSバージョン更新実施」の記録がある場合: 「Inception Phaseで更新済み」と表示してスキップ
4. 記録がない場合: 従来通りバージョン更新を提案

**履歴確認方法**:

```bash
grep -q "iOSバージョン更新実施" docs/cycles/{{CYCLE}}/history/inception.md && echo "UPDATED_IN_INCEPTION" || echo "NOT_UPDATED"
```

**メッセージ例（更新済みの場合）**:

```text
バージョン確認結果:
- project.type: ios
- Inception Phase履歴: バージョン更新実施済み

Inception Phaseでバージョン更新済みです。このステップをスキップします。
```

**メッセージ例（未更新の場合）**:

```text
バージョン確認結果:
- project.type: ios
- Inception Phase履歴: バージョン更新未実施

バージョンを更新しますか？
現在のバージョン: [現在バージョン]
更新後のバージョン: [サイクルバージョンからvを除去した値]
```

## 非機能要件（NFR）への対応

### パフォーマンス

- **要件**: 設定読み込みは即座に完了すること
- **対応策**: 既存の設定読み込みパターン（dasel or 直接読み取り）を使用

### 後方互換性

- **要件**: 既存プロジェクトへの影響なし
- **対応策**:
  - `type`設定が未設定の場合はデフォルト`"general"`として動作
  - `"general"`の場合は従来通りOperations Phaseでバージョン更新

## 技術選定

- **言語**: Markdown（プロンプト）、TOML（設定）
- **設定読み取り**: dasel（利用可能時）または AIによる直接読み取り

## 実装上の注意事項

1. **メタ開発のため編集対象は`prompts/package/`配下**
   - `docs/aidlc/`は直接編集しない（rsyncで上書きされる）

2. **既存の設定読み込みパターンに従う**
   - Unit 004で改善したawkパターンを使用

3. **バージョン更新対象ファイルはプロジェクトごとに異なる**
   - iOSの場合: Info.plist（CFBundleShortVersionString）
   - 運用引き継ぎ（docs/cycles/operations.md）に記録されている場合はそれを参照

## 不明点と質問

現時点で不明点はありません。
