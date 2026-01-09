# Unit 004: UnitブランチPR自動作成 - 計画

## 概要

Unitブランチ作成時にドラフトPRを自動作成する機能を `prompts/package/prompts/construction.md` に追加する。

## 目標

- Unitブランチ作成時に、サイクルブランチへのドラフトPRを自動作成
- PRタイトル・ボディをUnit定義から自動生成
- GitHub CLI利用不可時のフォールバック案内

## 修正対象ファイル

- `prompts/package/prompts/construction.md`

## 計画

### Phase 1: 設計

#### ステップ1: ドメインモデル設計

このUnitはプロンプトファイル（Markdown）の修正のみで実装コードは不要。
ドメインモデルはシンプルに以下を定義：

- **概念**: Unitブランチ、ドラフトPR、PRタイトル、PRボディ
- **責務**: Unitブランチ作成後にドラフトPRを作成する

#### ステップ2: 論理設計

現在の「6. Unitブランチ作成【推奨】」セクションに以下を追加：

1. ブランチ作成・プッシュ後のドラフトPR作成フロー
2. PRタイトル形式: `[Draft][Unit {NNN}] {Unit名}`
3. PRボディ形式: Unit定義の概要を抽出
4. GitHub CLI利用不可時: スキップ（ブランチ作成自体もスキップされるため追加対応不要）

#### ステップ3: 設計レビュー

設計内容をユーザーに提示し、承認を得る

### Phase 2: 実装

#### ステップ4: コード生成

`prompts/package/prompts/construction.md` の「6. Unitブランチ作成【推奨】」セクションを修正：

現在のフロー:
```
「はい」の場合:
  1. Unitブランチ作成・切り替え
  2. git push
```

修正後のフロー:
```
「はい」の場合:
  1. Unitブランチ作成・切り替え
  2. git push
  3. ドラフトPR作成（追加）
  4. PR URL表示（追加）
```

#### ステップ5: テスト生成

プロンプトファイルの修正のため、自動テストは不要。
手動確認項目:
- construction.md の構文が正しいこと
- 追加したbashコマンドが正しく動作すること

#### ステップ6: 統合とレビュー

- markdownlint で構文確認
- 実装記録を作成

## 成果物

- `prompts/package/prompts/construction.md`（修正）
- `docs/cycles/v1.5.4/design-artifacts/domain-models/unit-004_domain_model.md`
- `docs/cycles/v1.5.4/design-artifacts/logical-designs/unit-004_logical_design.md`
- `docs/cycles/v1.5.4/construction/units/unit-004_implementation.md`

## 注意事項

- `docs/aidlc/` は直接編集禁止（`prompts/package/` を編集すること）
- 既存のUnit完了時のPRマージフローは変更しない
