# Construction Phase: Unit4（README.mdの更新）実行計画

## 実行日時
2025-11-24

## 対象Unit
**Unit4: README.mdの更新**

## 目的
README.mdを新しいディレクトリ構造（`docs/versions/v1.0.0/`）とセットアップ手順に対応させる

## 含まれるユーザーストーリー
- ストーリー 8: 新しいディレクトリ構造の説明
- ストーリー 9: セットアップ手順の更新

## 実行内容

### Phase 1: 設計【このUnitでは不要】
Unit4はドキュメント更新のみのため、設計フェーズをスキップし、直接実装（更新）に進みます。

### Phase 2: 実装（README.md更新）

#### 更新対象セクション

1. **リポジトリ構成セクション**
   - 現在: `docs/example/v1/` を例として記載
   - 更新後: `docs/versions/v1.0.0/` と `docs/aidlc/` の説明を追加
     - `docs/example/`: 旧バージョンのsetup-prompt.mdで生成された参考例（そのまま残す）
     - `docs/versions/v1.0.0/`: 実際のプロジェクトファイル（バージョン依存）
     - `docs/aidlc/`: バージョン非依存の共通ファイル置き場（現在は空）

2. **クイックスタート - セットアップ手順**
   - セットアップ時の `setup-prompt.md` のパスをスターターキットの絶対パスで記載
   - セットアップ後に `docs/versions/v1.0.0/` が作成されることを明記

3. **各フェーズの読み込み方法**
   - 現在: `prompts/common.md` と `prompts/inception.md` を読み込む
   - 更新後: `common.md` は削除されたため、各フェーズのプロンプトのみを読み込む
     - Inception Phase: `docs/versions/v1.0.0/prompts/inception.md`
     - Construction Phase: `docs/versions/v1.0.0/prompts/construction.md`
     - Operations Phase: `docs/versions/v1.0.0/prompts/operations.md`

4. **次バージョン開発の説明**
   - 現在: `{DOCS_ROOT}/v1.0/` を例として記載
   - 更新後: `docs/versions/v2.0.0/` を例として記載（実際のディレクトリ構造に合わせる）

#### 維持する内容
- AI-DLC 翻訳文書へのリンク
- 主要な機能の説明
- 設計原則
- ライセンス情報

## 期待される成果物
- 更新された `README.md`（新しいディレクトリ構造とセットアップ手順に対応）
- 更新された `docs/versions/v1.0.0/construction/progress.md`（Unit4の状態を「完了」に変更）
- Gitコミット（Unit4完了）

## 完了基準
- [ ] README.mdのリポジトリ構成セクションが新しい構造に対応している
- [ ] クイックスタートセクションのセットアップ手順が正確
- [ ] 各フェーズの読み込み方法が新しいパスに対応している
- [ ] progress.mdでUnit4が「完了」になっている
- [ ] Gitコミットが作成されている

## 見積もり
半日

## 備考
- このUnitはドキュメント更新のみのため、ドメインモデル設計・論理設計・テスト生成は不要
- README.mdの既存の説明も可能な限り保持（後方互換性）
