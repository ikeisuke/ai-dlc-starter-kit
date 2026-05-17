# 論理設計: Unit 003 Operations §7.13 直前マージ前完結契約最終確認

## ステップ 0: 事前コード読込み

> 適用条件: depth_level != minimal の場合のみ必須。minimal は設計ステップ自体スキップ可のため N/A（U2 で規定した SoT に従う）。
>
> 本 Unit 自身の通常経路ドッグフーディングは本サイクル Operations Phase §7.13 通過時に retrofit で `.aidlc/cycles/v2.6.5/history/operations.md` に記録する（検証ケース (a) 通常）。

### (a) Read 対象ファイル + 目的

| ファイル | 目的 |
|---------|------|
| `skills/aidlc/steps/operations/operations-release.md` (line 443 周辺) | 「マージ実行確認」セクションの既存記法・引用ブロックを確認 |
| `skills/aidlc/steps/operations/02-deploy.md` (line 197) | サブステップ一覧 14 行目の表記スタイルを確認 |

### (b) 設計時に意識すべき挙動

- `operations-release.md` line 443 の `**マージ実行確認【ユーザー選択: automation_mode に関わらず常にユーザー確認必須】**:` 直前に新規セクションを挿入する
- 02-deploy.md line 197 の `14. 7.13 PRマージ【ユーザー選択: automation_mode に関わらずユーザー確認必須】` 配下にサブステップ箇条書きを追加して「マージ前完結契約最終確認 → マージ実行確認 → マージスクリプト実行」の順序を明示する

### (c) 既存実装に基づく代替案検討

- **採用**: `operations-release.md` 内に独立セクション「**マージ前完結契約最終確認【ユーザー選択: automation_mode 非依存・例外なし】**」を追加
- **却下**: `operations-release.md` 別ファイルに分離 → SoT 探索コスト増 / 既存セクションとの順序関係が見えにくい

## 概要

`operations-release.md` 内「マージ実行確認」直前に新規 AskUserQuestion セクションを追加。02-deploy.md 側は目次責務として存在のみ明示。

## アーキテクチャパターン

- **対称ゲートパターン**: 既存 post-merge ガード (`write-history.sh exit 3`) と対称な pre-merge ゲート。双方向防御
- **二重 SoT 禁止**: 文言・選択肢・例外条件の SoT は `operations-release.md` のみ。`02-deploy.md` は目次

## コンポーネント構成

```text
skills/aidlc/steps/operations/
├── operations-release.md     # §7.13 内「マージ実行確認」直前に新規セクション追加（SoT）
└── 02-deploy.md              # §7.13 サブステップ一覧 line 197 に確認の存在を 1 行追記（目次）
```

## インターフェース設計

### AskUserQuestion 仕様（operations-release.md SoT）

- **header**: `マージ前完結契約最終確認`
- **question**:

  ```text
  PR #{pr_number} のマージ前に、マージ前完結契約（progress.md ステップ7「完了」確定・修正コミット記録完了）を最終確認します。

  凍結対象ファイル（マージ後 write-history.sh exit 3 で編集ガードされます）:
  - .aidlc/cycles/{cycle}/operations/progress.md
  - 当該サイクル成果物全般（plans / story-artifacts / design-artifacts / construction / history）

  記録漏れ（修正コミット未追加、レビューサマリ未追記、history 未追記等）がないことを確認してください。
  ```

- **選択肢（choice_id 固定）**:

  | choice_id | label | 動作 |
  |-----------|-------|------|
  | `proceed_to_merge` | 記録漏れなし、マージに進む | 「マージ実行確認」へ進む |
  | `back_to_record` | 記録を追加する（§7.6 / §7.7 に戻る） | §7.6/§7.7 へ戻り、§7.8〜§7.12.6 を再通過してから本ゲートへ再到達 |

### 02-deploy.md line 197 への追記

```text
14. 7.13 PRマージ【ユーザー選択: automation_mode に関わらずユーザー確認必須】
    - マージ方法確定 → 設定保存フロー → 未コミット差分検出ガード → **マージ前完結契約最終確認** → マージ実行確認 → gh pr merge
    - 詳細は `operations-release.md §7.13` を SoT として参照
```

## 処理フロー概要

### §7.13 改修後の処理フロー

**ステップ**:

1. §7.13 マージ方法の確定（既存）
2. §7.13 設定保存フロー（既存）
3. §7.13 未コミット差分検出ガード（既存）
4. **§7.13 マージ前完結契約最終確認（新規 / 本 Unit）**
   - `proceed_to_merge` → ステップ 5 へ
   - `back_to_record` → §7.6/§7.7 へ戻り、§7.8〜§7.12.6 を再通過してから本ステップに再到達
5. §7.13 マージ実行確認（既存）
6. §7.13 `scripts/operations-release.sh merge-pr` 実行（既存）

## 非機能要件（NFR）への対応

- **可用性**: 既存マージフロー中断なし。ユーザー応答 1 回追加分のみ
- **セキュリティ**: 影響なし

## 実装上の注意事項

- 既存「マージ実行確認」の文言・選択肢は改変しない（責務直交維持）
- `operations-release.md` 内のみが SoT。02-deploy.md には文言・選択肢を書かない
- 本リポジトリ規約: Bash ツール引数文字列にコマンド置換 `$(...)` / backtick を含めない
