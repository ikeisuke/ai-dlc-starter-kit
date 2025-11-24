# 実装記録: Unit1 - setup-prompt.mdのリファクタリング

## 実装日時
2025-11-24 開始 〜 2025-11-24 完了

## 作成ファイル

### 設計ドキュメント
- docs/versions/v1.0.0/design-artifacts/domain-models/unit1_domain_model.md - DDDに基づくドメインモデル設計
- docs/versions/v1.0.0/design-artifacts/logical-designs/unit1_logical_design.md - 論理設計（ディレクトリ構造、変数処理、ファイル生成フロー）

### ソースコード
- prompts/setup-prompt.md - リファクタリング済み（新しいディレクトリ構造対応）

## 変更内容

### 1. 変数定義の追加
`prompts/setup-prompt.md:28-30` に以下の派生変数を追加：
```
# 派生変数（v1.0.0以降）
AIDLC_ROOT = ${DOCS_ROOT}/aidlc        # 共通プロンプト・テンプレートのルート
VERSIONS_ROOT = ${DOCS_ROOT}/versions  # バージョン固有成果物のルート
```

### 2. ディレクトリ構造の変更
以下の構造に対応：

**共通ディレクトリ**（`${AIDLC_ROOT}/`）:
- prompts/ - 全バージョン共有のプロンプトファイル
- templates/ - 全バージョン共有のテンプレートファイル
- version.txt - スターターキットのバージョン

**バージョン固有ディレクトリ**（`${VERSIONS_ROOT}/${VERSION}/`）:
- plans/, requirements/, story-artifacts/, design-artifacts/, construction/, operations/
- history.md - バージョン固有の実行履歴

### 3. パス参照の一括置換

以下のパスを置換：

| 旧パス | 新パス | 対象 |
|-------|-------|------|
| `{{DOCS_ROOT}}/{{VERSION}}/prompts/additional-rules.md` | `{{AIDLC_ROOT}}/prompts/additional-rules.md` | 共通ルール |
| `{{DOCS_ROOT}}/{{VERSION}}/templates/` | `{{AIDLC_ROOT}}/templates/` | テンプレート全般 |
| `{{DOCS_ROOT}}/{{VERSION}}/requirements/` | `{{VERSIONS_ROOT}}/{{VERSION}}/requirements/` | バージョン固有 |
| `{{DOCS_ROOT}}/{{VERSION}}/story-artifacts/` | `{{VERSIONS_ROOT}}/{{VERSION}}/story-artifacts/` | バージョン固有 |
| `{{DOCS_ROOT}}/{{VERSION}}/design-artifacts/` | `{{VERSIONS_ROOT}}/{{VERSION}}/design-artifacts/` | バージョン固有 |
| `{{DOCS_ROOT}}/{{VERSION}}/construction/` | `{{VERSIONS_ROOT}}/{{VERSION}}/construction/` | バージョン固有 |
| `{{DOCS_ROOT}}/{{VERSION}}/operations/` | `{{VERSIONS_ROOT}}/{{VERSION}}/operations/` | バージョン固有 |
| `{{DOCS_ROOT}}/{{VERSION}}/plans/` | `{{VERSIONS_ROOT}}/{{VERSION}}/plans/` | バージョン固有 |
| `{{DOCS_ROOT}}/{{VERSION}}/prompts/history.md` | `{{VERSIONS_ROOT}}/{{VERSION}}/history.md` | バージョン固有 |

### 4. common.md埋め込み方式の採用
各フェーズプロンプト（inception.md, construction.md, operations.md）に共通知識を直接埋め込む方式に変更。common.mdという中間ファイルは生成しない。

### 5. version.txt生成の追加
`prompts/setup-prompt.md:1369-1377` に以下のセクションを追加：
```
#### 4. バージョン記録ファイルの作成
`{{AIDLC_ROOT}}/version.txt` を作成し、スターターキットのバージョンを記録
```

### 6. 完了メッセージの更新
共通ファイルとバージョン固有ファイルを明確に区別した表示に変更。

## ビルド結果
該当なし（プロンプトファイルのため）

## テスト結果
パス整合性確認:
- ✅ `{{AIDLC_ROOT}}` 参照: 26箇所
- ✅ `{{VERSIONS_ROOT}}` 参照: 27箇所
- ✅ 旧パス（`{{DOCS_ROOT}}/{{VERSION}}/prompts/`, `{{DOCS_ROOT}}/{{VERSION}}/templates/`）は適切に置換済み
- ✅ 派生変数セクション存在確認: OK
- ✅ version.txt生成セクション存在確認: OK

## コードレビュー結果
- [x] セキュリティ: OK（ファイル操作の安全性を設計に含めた）
- [x] コーディング規約: OK（Markdown形式、UTF-8エンコーディング）
- [x] エラーハンドリング: OK（設計に含めた）
- [x] ドキュメント: OK（設計ドキュメント完備）

## 技術的な決定事項

### 1. common.md埋め込み方式の選択
**決定**: common.mdを中間ファイルとして生成せず、各フェーズプロンプトに直接埋め込む

**理由**:
- ユーザーは各フェーズで1ファイルだけ読めばOK（Intent.mdの目標に合致）
- 重複は許容（スターターキット側で管理）
- ユーザーが誤ってcommon.mdを直接読み込む混乱を回避

### 2. 派生変数の設計
**決定**: `AIDLC_ROOT = ${DOCS_ROOT}/aidlc`, `VERSIONS_ROOT = ${DOCS_ROOT}/versions`

**理由**:
- `DOCS_ROOT`配下に配置することで、既存のディレクトリ構造と整合性を保つ
- 明示的な名前で役割が明確
- 後方互換性を維持（既存の`DOCS_ROOT`, `VERSION`変数も使用可能）

### 3. history.mdの配置
**決定**: `${VERSIONS_ROOT}/${VERSION}/history.md`（プロンプトディレクトリの外）

**理由**:
- 新構造では `${VERSIONS_ROOT}/${VERSION}/prompts/` ディレクトリは存在しない（プロンプトは全て共通化）
- history.mdはバージョン固有の成果物なので、バージョンルート直下が適切

## 課題・改善点
なし

## 状態
**完了**

## 備考
- Unit2（各フェーズプロンプトのパス参照更新）で、生成される各フェーズプロンプトの内部パス参照も更新する必要がある
- この実装により、v1.0.0以降のバージョンでは共通プロンプト・テンプレートが全バージョンで共有され、イニシャルコストが大幅に削減される
