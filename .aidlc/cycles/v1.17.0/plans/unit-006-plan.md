# Unit 006 計画: Inception Phase完了時のsquashルール追加

## 概要

Inception Phase完了時に中間コミットを1つのfeatコミットにsquashするルールを、commit-flow.mdとinception.mdに追加する。既存のUnit用Squash統合フローとDRY原則を維持しつつ、Inception Phase固有の差分のみ追加する。

## 変更対象ファイル

| ファイル | 変更内容 |
|---------|---------|
| `prompts/package/prompts/common/commit-flow.md` | Squash統合フローにInception Phase用の差分を追加 |
| `prompts/package/prompts/inception.md` | ステップ5（Gitコミット）をSquash統合フロー参照に変更 |

## 実装計画

### 1. commit-flow.md の変更

現在のSquash統合フローはUnit完了時のみを対象としている。以下の方針でInception Phase対応を追加する:

**方針**: 既存のUnit用フロー構造を維持しつつ、フェーズ固有の差分セクションを最小限追加する

#### 1.1 適用対象判定セクションの追加

Squash統合フローの冒頭に、呼び出し元フェーズに応じた適用対象判定を追加する:

| 呼び出し元 | 適用対象 | 参照手順 |
|-----------|---------|---------|
| Construction Phase（Unit完了時） | Unit完了squash | 「Unit完了squash」手順 |
| Inception Phase（Phase完了時） | Inception squash | 「Inception Phase完了squash」手順 |

#### 1.2 セクション構成

- **設定確認・VCS判定**: 変更なし（共通）
- **ユーザー確認**: 変更なし（共通）
- **中間コミット**: フェーズ別の2パターンを記載
  - Unit用: `chore: [{{CYCLE}}] Unit {NNN}完了 - 完了準備`（既存）
  - Inception用: `chore: [{{CYCLE}}] Inception Phase完了 - 完了準備`（新規追加）
- **起点コミット特定**: フェーズ × VCS の決定表を記載

  | フェーズ | git | jj |
  |---------|-----|-----|
  | Unit完了 | 前Unitの `feat:` コミットまたは `Inception Phase完了` コミット（既存） | `jj log` から同様に判定（既存） |
  | Inception | `git merge-base origin/main HEAD`（サイクルブランチの分岐点）。`origin/main` が存在しない場合はユーザーに起点コミットを確認 | `jj log` で `main` ブランチとの分岐リビジョンを特定 |

- **squash実行**: フェーズ別の呼び出し方を記載
  - Unit用: `--unit` あり（既存）
  - Inception用: `--unit` なし、`--base` を起点コミットで指定
- **結果分岐**: 既存の戻り値仕様に統一
  - `squash:success` → squash完了
  - `squash:skipped:no-commits` → squash対象なし、通常コミットへ
  - `squash:error` → エラーリカバリ

#### 1.3 コミットメッセージフォーマット一覧への追加

`INCEPTION_SQUASH_PREP` を追加:
- prefix: `chore:`
- テンプレート: `chore: [{{CYCLE}}] Inception Phase完了 - 完了準備`
- 使用場面: Inception Phase完了squash前の中間コミット

### 2. inception.md の変更

ステップ5「Gitコミット」を以下のように変更:

**現在**:
```
### 5. Gitコミット
Inception Phaseで作成・変更したすべてのファイル（**inception/progress.md、履歴ファイルを含む**）をコミット。
`docs/aidlc/prompts/common/commit-flow.md` の「Inception Phase完了コミット」手順に従ってください。
```

**変更後**:
- ステップ4.5として「Squash（コミット統合）【オプション】」を追加（construction.mdのステップ3.5と同様の構造）
  - `docs/aidlc/prompts/common/commit-flow.md` の「Squash統合フロー」を参照（Inception Phase用手順を実行）
  - squash結果に応じた分岐を記載:
    - `squash:success` → ステップ5をスキップ
    - `squash:skipped:no-commits` → ステップ5に進む
    - `squash:error` → commit-flow.mdのエラーリカバリ手順に従い、対応後にステップ5に進む
- ステップ5のGitコミットに、squash実行済みの場合のスキップ注記を追加

## 完了条件チェックリスト

- [ ] commit-flow.md にInception Phase完了時のsquash統合フローを追加
- [ ] inception.md の完了時手順（ステップ5: Gitコミット）をsquash統合フロー参照に変更
- [ ] squash設定確認 → VCS判定 → ユーザー確認 → squash実行のフロー記載
- [ ] squash-unit.sh 自体のコード変更を行っていないこと（境界条件）
- [ ] Unit型のsquash統合フローとDRY原則が維持されていること
