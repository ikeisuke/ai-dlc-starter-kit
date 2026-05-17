# Unit 002 実装計画: Construction Phase 1 設計起草前の事前コード Read 工程組み込み

## 対象 Unit

- **Unit**: 002 - Construction Phase 1 設計起草前の事前コード Read 工程組み込み
- **関連 Issue**: #679（クローズ対象）
- **優先度**: High
- **depth_level**: standard（Phase 1 設計を実施）

## 背景・目的

Construction Phase 1（設計フェーズ）で AI エージェントが「既存実装の挙動を読まずに設計起草」を行うと、Round 1 設計レビューでの反復が増加する。事前コード Read 工程をステップ SoT として必須化し、設計起草前に既存実装の挙動を確認させることで、Round 1 反復を構造的に予防する。

## スコープ調整（Unit 定義からの解釈変更）

Unit 定義の元責務は `skills/aidlc/templates/construction_plan_template.md` への追加だが、v2.6.5 時点で当該テンプレファイルは**存在しない**ことが Construction Phase 着手時の調査で判明した。Intent §含まれるもの「`skills/aidlc/steps/construction` 配下: design 起草前の事前コード Read 必須化」と整合する形で、改修対象を以下に調整する:

- **改修対象 (主)**: `skills/aidlc/steps/construction/02-design.md` のドメインモデル設計ステップ冒頭への「事前コード読込み」サブステップ追加
- **改修対象 (副)**: `skills/reviewing-construction-design/SKILL.md` の architecture focus 観点への「事前コード読込みセクション存在 / 内容充足」観点追加

この調整は Intent 範囲内であり、スコープ縮小には該当しない（実装方法の合理調整）。

## スコープ

### 含まれるもの（責務）

- **必須対応 1**: `skills/aidlc/steps/construction/02-design.md` のステップ 1（ドメインモデル設計）冒頭に「ステップ 0: 事前コード読込み」サブステップを追加
- **必須対応 2**: 3 観点を SoT 化
  - (a) Read 対象ファイル + 目的（改修予定の既存実装ファイルを明示的に列挙）
  - (b) 設計時に意識すべき挙動（既存実装のエッジケース・副作用・依存関係）
  - (c) 既存実装に基づく代替案検討（refactor / extend / replace の選択肢評価）
- **必須対応 3**: `skills/reviewing-construction-design/SKILL.md` に**新設**「### 設計プロセス」セクションを追加し、その配下に「事前コード読込みセクション存在 / 内容充足」観点を配置（配置先を 1 か所に固定）
  - **責務分離（明文化）**: 既存「### 構造」「### パターン」「### API設計」「### 依存関係」は**成果物品質**を扱い、新設「### 設計プロセス」は**事前コード読込みの実施検証**を扱う
  - **判定適用条件（固定）**: `depth_level != minimal` のときのみ必須。`depth_level=minimal` は設計ステップ自体スキップ可のため本観点は N/A 判定とする（共通スキル側 / 02-design.md 側で同一条件を SoT 化）
  - 判定条件（適用時）: 設計成果物（ドメインモデル）先頭にステップ 0 セクション見出しが存在し、(a)(b)(c) 3 観点すべてに具体記述があること
  - 失敗時アクション: 設計レビューで「事前コード読込み不足」指摘 → 修正されるまで Round 反復
- **必須対応 4**: 本 Unit 自身の Construction Phase でドッグフーディング検証（U2 のドメインモデル / 論理設計に事前コード読込みセクションが書かれている状態を確認）
- **設計ドキュメント**: ドメインモデル + 論理設計を作成
- AI レビュー（設計 / コード / 統合）を codex で実施

### 含まれないもの（境界）

- 既存 `02-design.md` の破壊的変更（追加方式）
- `reviewing-construction-code` / `reviewing-construction-integration` への観点追加
- `templates/construction_plan_template.md` の新規作成（Unit 002 スコープ外、将来 issue として追跡候補）
- #633（責務領域全体を広視野で検討するプロンプト指示）/ #692（副作用境界 / ドメイン層分離評価軸追加）の改修

## 実装方針

### Phase 1: 設計

- **ドメインモデル**: 「事前コード読込み (PreCodeReadSession)」を中心とした概念モデル。サブステップ・(a)(b)(c) 観点・判定条件を整理
- **論理設計**: 改修対象ファイル 2 つ（`02-design.md` / `reviewing-construction-design/SKILL.md`）への挿入位置・追加内容構造を確定

### Phase 2: 実装

1. `skills/aidlc/steps/construction/02-design.md` にステップ 0 を追加
2. `skills/reviewing-construction-design/SKILL.md` に観点を追加
3. ドッグフーディング検証: U2 自身のドメインモデル / 論理設計に事前コード読込みセクションが書かれているか確認 → `history/construction_unit02.md` に記録

## 完了条件チェックリスト

### #679 受け入れ基準

- [x] `skills/aidlc/steps/construction/02-design.md` に「ステップ 0: 事前コード読込み」サブステップが追加されている
- [x] `02-design.md` 上で「事前コード Read → 設計起草」の二段階分離が独立ステップとして定義され、順序制約（ステップ 0 → ステップ 1）が明示されている
- [x] (a)(b)(c) 3 観点が SoT として記述されている
- [x] `skills/reviewing-construction-design/SKILL.md` の**新設**「### 設計プロセス」セクション配下に「事前コード読込みセクション存在 / 内容充足」が追加されている
- [x] 判定条件・適用条件（`depth_level != minimal` 時のみ必須 / `minimal` は N/A）・失敗時アクション（Round 反復）が明文化されている
- [x] `02-design.md` と `reviewing-construction-design/SKILL.md` の両方で `depth_level=minimal` 時の N/A 条件が同一 SoT として記述されている
- [x] 本 Unit 自身の Construction Phase でドッグフーディング検証を実施し `history/construction_unit02.md` に記録

### 共通

- [x] markdownlint で新規エラー 0 件
- [x] AI レビュー（設計 / コード / 統合）が `review_mode=required` に従い codex で実施されている

## リスク・考慮事項

- 既存 `02-design.md` の「ステップ1: ドメインモデル設計」より前にステップ 0 を追加するため、既存ステップ番号 (1〜3) を保持しつつ「ステップ 0」を冒頭に置く方式
- `reviewing-construction-design/SKILL.md` への観点追加は既存「### 構造」「### パターン」「### API設計」「### 依存関係」に並列する新規セクション「### 設計プロセス」または「### 構造」内サブ項目として配置
- 本リポジトリ規約: Bash ツール引数文字列にコマンド置換 `$(...)` / backtick を含めない
