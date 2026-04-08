# 論理設計: session-state.md廃止

## 概要

7つのステップファイル・ガイドからsession-state.md関連ロジックを除去し、セッション復元をprogress.md / Unit定義ベースに一本化する。

## アーキテクチャパターン

除去パターン: 中間レイヤー（session-state.md）を廃止し、各フェーズが直接進捗源（progress.md / Unit定義）を参照する構造に簡素化する。

## コンポーネント構成

### 変更対象コンポーネント

```text
steps/common/
├── session-continuity.md  [大幅簡略化]
├── context-reset.md       [session-state.md参照除去]
└── compaction.md           [session-state.md判定除去]

steps/{inception,construction,operations}/
└── 01-setup.md             [session-state.md参照除去・ステップ番号調整]

guides/
└── troubleshooting.md      [session-state.md参照除去]
```

### コンポーネント詳細

#### session-continuity.md [大幅簡略化]

- **現状の責務**: session-state.md生成・復元・バリデーション + フェーズ別進捗源テーブル + コンパクション復帰指示
- **変更後の責務**: フェーズ別進捗源テーブル + コンパクション復帰指示
- **除去対象**: 「session-state.md の生成」セクション全体、「session-state.md の復元」セクション全体
- **残す内容**: フェーズ別の進捗源（フォールバック先）テーブル、コンパクション復帰の指示

#### context-reset.md [session-state.md参照除去]

- **現状の責務**: 中断検出 → 状態確認 → 履歴記録 → session-state.md生成 → 継続プロンプト提示
- **変更後の責務**: 中断検出 → 状態確認 → 履歴記録 → 継続プロンプト提示
- **除去対象**: 手順4（session-state.md生成）、「session-state.md の生成」サブセクション全体、再開説明のsession-state.md言及、セミオート判定文のsession-state.md依存部分
- **残す内容**: 手順1-3（状態確認、進捗保持、履歴記録）、手順5（継続プロンプト提示）、セミオート判定の基本ロジック
- **修正**: 手順番号を繰り上げ（4→削除、5→4）。再開説明をprogress.md / Unit定義ベースに差し替え

#### compaction.md [session-state.md判定除去]

- **現状の責務**: session-state.mdでフェーズ判定 → 成果物ベースフォールバック → automation_mode復元
- **変更後の責務**: 成果物ベースのフェーズ判定（直接） → automation_mode復元
- **除去対象**: フェーズ判定・再開手順・コンパクション前保存におけるsession-state.md依存全体（復帰フロー手順2のフェーズ判定、「session-state.md がない場合のフォールバック」前文、「session-state.md またはフォールバック進捗源から再開」文言、「session-state.md の生成【コンパクション前】」セクション）
- **残す内容**: 成果物ベース判定テーブル（主判定に昇格）、automation_mode復元手順、スキル再読み込み手順
- **修正**: フォールバック判定テーブルの前文を「フォールバック」から「フェーズ判定」に変更。復帰フロー手順番号を再編

#### inception/01-setup.md [参照除去]

- **除去対象**: 開発ルール内の「session-state.mdを生成」指示（行16-19周辺）
- **修正**: コンテキストリセット対応の手順番号を調整（3→session-state.md生成削除→手順番号繰り上げ）

#### construction/01-setup.md [参照除去・ステップ番号調整]

- **除去対象**: ステップ6（session-state.md復元）
- **修正**: ステップ7以降を1つ繰り上げ（7→6, 8→7, ...）。「なければステップ7で復元」→ 直接的にUnit定義から復元する記述に変更

#### operations/01-setup.md [参照除去・ステップ番号調整]

- **除去対象**: ステップ6（session-state.md復元）
- **修正**: ステップ7以降を1つ繰り上げ（7→6, 8→7, ...）。「なければステップ7で復元」→ 直接的にprogress.mdから復元する記述に変更

#### guides/troubleshooting.md [参照除去]

- **除去対象**: カテゴリ5の手順1（session-state.md確認指示）
- **修正**: 手順1をフェーズプロンプト再読み込みに置き換え、手順番号を調整

## 処理フロー概要

### セッション復元フロー（変更後）

1. フェーズ再開コマンド実行（`/aidlc {phase}`）
2. プリフライトチェック
3. フェーズ別進捗源から直接復元:
   - Inception: `inception/progress.md`
   - Construction: Unit定義ファイルの「実装状態」
   - Operations: `operations/progress.md`
4. 中断ポイントから作業再開

### コンテキストリセットフロー（変更後）

1. 中断検出
2. 作業状態確認
3. 履歴記録（中断状態追記）
4. 継続プロンプト提示

### コンパクション復帰フロー（変更後）

1. ブランチ名からサイクル特定
2. 成果物ベースでフェーズ判定（operations/progress.md → units/*.md → inception/progress.md）
3. automation_mode再取得
4. フェーズプロンプト再読み込み
5. 作業継続

## 番号影響一覧

| ファイル | 影響箇所 | 変更内容 |
|---------|---------|---------|
| context-reset.md | 手順4（削除）→ 手順5を手順4に繰り上げ | session-state.md生成手順削除、後続手順番号-1 |
| construction/01-setup.md | ステップ6（削除）→ ステップ7〜12を1つ繰り上げ | session-state.md復元ステップ削除、「なければステップ7で復元」等の相互参照文言更新 |
| operations/01-setup.md | ステップ6（削除）→ ステップ7〜11を1つ繰り上げ | 同上 |
| compaction.md | 復帰フロー手順2（削除）→ 手順3以降を繰り上げ | session-state.mdフェーズ判定手順削除、後続手順番号-1 |

## 実装上の注意事項

- ステップ番号繰り上げ時、他ステップ内の相互参照（「ステップNで〜」）も一括更新する
- session-continuity.mdは内容が大幅に減るが、ファイル自体は残す（Unit定義の境界に明記）
- 「フォールバック」という表現は、session-state.md廃止後は「フォールバック」ではなく主たる復元手段になるため、文言を適宜調整する

## 不明点と質問（設計中に記録）

なし
