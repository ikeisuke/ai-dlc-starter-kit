# Unit 001 論理設計: v3 RFC・core/extension 境界・設計判断

> docs-only の設計文書 Unit のため、ドメインモデルは N/A。本 logical design に「設計判断の結論一覧 + core/extension 境界基準 + RFC アウトライン」を集約する。これが Phase 2（`docs/v3/rfc.md` 執筆）の設計入力となる。

## 1. 設計判断の結論（Decision Gate Log / DR-004 由来・ユーザー承認済み）

各論点を一から検討し、ユーザー承認ゲートで確定（2026-06-10）。計画書推奨は一入力。

| ID | 論点 | 結論 | 不採用案 | 理由 |
|----|------|------|---------|------|
| DG-1 | 表面コマンド名 | **define / develop / release / reflect** を主表示・正式名とする。**別案（build / implement 等の不採用動詞）はエイリアスにしない**（却下案を別名登録しない）。旧名（inception/construction/operations/retrospective）は後方互換エイリアスとして維持 | A 新名のみ / B 旧名維持 / build 案 | 行為を直接表現しつつ継続性を確保。"build" は compile を連想させるため "develop"（設計+実装+テストの広義開発）を採用。不採用動詞は混乱要因になるため別名にせず、旧名のみ移行用エイリアスとして残す |
| DG-2 | Express モード | **維持**（define+develop+release 連続実行） | 廃止 | 小規模変更の体験が良く、実装は SKILL.md ルーティングのみで低コスト |
| DG-3 | v2 サポート期間 | **条件付き EOL** | 即 EOL | consumer 保護。EOL 条件: ①マイグレーション 2 プロジェクトでテスト済 ②v3 で 1 cycle ドッグフーディング完了 ③EOL 告知を 1 バージョン前から掲載。充足まで v2 はセキュリティ/クリティカル修正のみメンテ |
| DG-4 | review 統合粒度 | **aidlc-review 1 skill + perspective** | 3 skills / v2 10 skills 維持 | 10 スキルの重複と sync スクリプトを解消。観点は perspectives/*.md に全数移植し品質維持 |
| DG-5 | GitHub 前提 | **core に git + Issue/PR、Projects/Milestone/Release は extension** | git のみ / GitHub 前提強化 | Issue/PR は汎用的で defer 戦略・PR マージに必須。重い依存（Projects/Milestone/Release）だけ extension |
| DG-6 | state format | **ハイブリッド**（cycle=JSON state.json / work item=Markdown frontmatter） | 全 JSON / 全 TOML / 全 frontmatter | cycle は書き込み少・schema validation したい→JSON。work item は per-item 並行編集→分散 frontmatter でコンフリクト回避 |

**DG-3 ↔ 共存方針の相互参照**: 条件付き EOL 期間中、v2 `skills/aidlc` は変更しない（クリーンカット）。runtime 互換は維持せず migration で担保（consumer runtime 非影響 = v3 を導入するまで v2 がそのまま動く）。コマンド名衝突（DG-1）は v3 を別スキル系統（aidlc-v3 → 本流化時に aidlc 置換）で構築するため、移行期間中は v2/v3 が別インストールで共存しうる。本流化時に旧名をエイリアス化して衝突回避。

## 2. core / extension 境界基準（必須設計成果物 / 計画レビュー #2 由来）

境界一覧（何が core/何が extension か）だけでなく、**分類の判断軸**を明文化する。

### 2.1 境界原則

> **core = 「AI-DLC の方法論を最小構成で回すために不可欠な責務」**。それ以外は extension。

### 2.2 分類基準（判断軸）

ある機能を core に入れるかは以下で判定する:

| 軸 | core 条件 | extension 条件 |
|----|----------|---------------|
| 方法論必須性 | define→develop→release→reflect の遂行に不可欠 | 無くても 1 cycle を完走できる |
| 汎用性 | git / Issue / PR など広く前提にできる | 特定ツール/サービス固有（Projects/Milestone/Kiro 等） |
| 依存の重さ | 軽量（git CLI / gh の Issue・PR まで） | 重い（GraphQL / field option / view / workflow 等） |
| 安全境界 | atomic 性・schema validation 等の安全境界が必要 | 単純処理で AI inline 可能 |
| ドッグフーディング固有性 | consumer 全員に必要 | starter kit 自身の運用固有（upstream feedback 等） |

### 2.3 代表コンポーネント分類

分類値は次の 4 つに正規化し、各コンポーネントは**単一分類**を持つ:

- **core**: v3 本体に常に含まれる
- **extension(opt-in)**: v3 同梱だが既定 off（設定で有効化）
- **別リポジトリ**: 外部リポジトリに分離
- **廃止**: v3 では提供しない

| コンポーネント | 分類 | 根拠（適用軸） |
|--------------|------|--------------|
| config.toml / state.json / work item 管理 | core | 方法論必須・安全境界 |
| define / develop / release / reflect / status / doctor（コマンド本体） | core | 方法論必須。**reflect 本体の最小責務（journal を読み reflect.md / Issue を生成）も core** |
| git branch / commit / PR の最低限操作 | core | 汎用・軽量 |
| Issue 操作（defer 自動起票・PR Closes） | core | 汎用・方法論必須（DG-5） |
| aidlc-review（perspective 統合） | core | 方法論必須（品質ゲート） |
| journal 軽量記録 | core | 方法論必須（reflect への入力） |
| Express | core | 方法論（フロー）の一部（DG-2） |
| Milestone 自動管理 | extension(opt-in) | 特定機能固有（既定 off） |
| GitHub Release / version_tag 自動作成 | extension(opt-in) | 特定機能固有（既定 off） |
| v1/v2 migration（aidlc-migrate） | extension(opt-in) | 一時的・移行専用（v3 同梱） |
| Kiro agent install | 別リポジトリ | ツール固有 |
| GitHub ProjectsV2 連携 | 廃止 | 重い依存・プロジェクト管理ツールの責務 |
| Retrospective mirror / upstream feedback | 廃止 | starter kit 固有（ドッグフーディング固有性） |

### 2.4 例外ルール

- **ドッグフーディング特殊処理を本体に埋めない**（プロジェクトルール準拠）: starter kit 自身固有の処理は core 本体に分岐を埋めず、opt-in シグナル / 明示フラグ / wrapper 分離で表現する
- core が GitHub に依存するのは Issue/PR まで（DG-5）。それ以深（Projects/Milestone/Release）は extension に隔離し、core は extension 不在でも動作する

## 3. RFC アウトライン（docs/v3/rfc.md の章立て）

Phase 2 で以下の構成で執筆する。

```text
1. 概要 / 目的（なぜ v3 か: v2 の課題＝防御ロジック 60%・推論復帰 819 行・10 レビュースキル重複）
2. v3 AI-DLC Principles（7 原則を計画書「v3 AI-DLC Principles」節を参照元として正式列挙）
3. 方法論の保全（削減対象は実装の複雑さであり方法論の深さではない）
4. core / extension 境界
   4.1 境界原則
   4.2 分類基準（判断軸）
   4.3 代表コンポーネント分類
   4.4 例外ルール
5. 設計判断（Decision Gate Log）
   5.1〜5.6 DG-1〜DG-6 各論点の案・trade-off・結論・理由
   5.7 v2 共存方針（DG-3 と相互参照）
6. 削減目標（現状ベースライン / 目標値 / 削減数・削減率 / 対象外理由。計画書定量表と整合）
7. 後続フェーズへの引き継ぎ（workflow / data-model / migration が参照する確定事項）
```

### 削減目標（計画書定量表に基づくベースライン）

> **重要（数値の位置づけ）**: 下表の v2/v3 数値は**計画書 `docs/v3-renewal-plan.md` の概算分析値**をそのまま転記したもので、下記「測定定義」に基づく厳密な再計測値ではない。計画書の集計範囲と測定定義のカウント単位は厳密には一致しない（例: 復帰仕様行数 819 は `phase-recovery-spec.md` 単体ベース、測定定義は関連 3 ファイル合算で約 1,019 行。スクリプトも集計範囲差で 138 本 vs 97 本等のズレがある）。**測定定義に基づく v2 ベースラインの再計測と v3 目標の確定値の記載は Phase 2（`docs/v3/rfc.md` §6 執筆時）で行う**。本表は方向性と概算規模の提示が目的。

| 指標 | v2（概算/計画書） | v3（概算目標） | 削減数 | 削減率 | 対象外/注 |
|------|-----------------|-----------|-------|-------|----------|
| スキル数 | 17 | 5 | 12 | 71% | extension 分離分は別管理 |
| ステップ MD 行数 | 6,436 | ~730 | ~5,706 | 89% | 防御ロジック削減が主因 |
| スクリプト本数 | 138 | ~40 | ~98 | 71% | 安全境界必要分は残す |
| スクリプト行数 | 30,303 | ~12,000 | ~18,303 | 60% | - |
| 設定キー数 | 34 | 8 | 26 | 76% | 情報フィールドは intent.md へ |
| 復帰仕様行数 | 819 | ~50 | ~769 | 94% | 推論→明示状態 |
| 保守対象ファイル総数 | ~280 | ~80 | ~200 | 71% | - |

**測定定義（カウント単位）**: RFC §6 では各指標のカウント単位と extension 分離分の帰属のみ定義する（厳密な計測コマンド・許容誤差は後続実装フェーズの検証項目）:

- スキル数 = `skills/` 配下のスキルディレクトリ数（SKILL.md を持つもの）。extension(opt-in) / 別リポジトリ分は v3 列に含めない（core スキル数で数える）
- ステップ MD 行数 = `skills/aidlc/steps/**/*.md` の合計行数
- スクリプト本数 = `skills/aidlc/scripts/**/*.sh` + `bin/**/*.sh` の数。廃止分は v3 列から除外
- 設定キー数 = `config/defaults.toml` のキー数（情報フィールドは intent.md へ移すため除外）
- スクリプト行数 = `skills/aidlc/scripts/**/*.sh` + `bin/**/*.sh` の合計行数。extension(opt-in) / 別リポジトリ分は v3 core 目標に含めない
- 復帰仕様行数 = v2 ベースラインは `skills/aidlc/steps/common/phase-recovery-spec.md` + `session-continuity.md` + `compaction.md` の合計行数。v3 は明示状態管理ベースの recovery 仕様（後続 Unit で確定する `recovery.md` 相当 + `docs/v3/data-model.md` のフェーズ導出/破損時方針記述）の合計行数。v3 側の正確なファイルパスは後続フェーズで確定する
- 保守対象ファイル総数 = v3 core として保守するファイル数（core スキルの SKILL.md / steps / scripts / templates / config + core 用 `bin/` + `docs/v3/`）。extension(opt-in) / 別リポジトリ / 廃止分は含めない
- v3 列の `~` は概算目標であり、実装時に再計測して確定する（RFC は方向性と目標の提示が主目的）

## 3.1 後続ドキュメント入力マトリクス（決定 ID → 後続成果物が参照すべき制約）

本 logical design / RFC は Phase 2 以降の設計入力。各決定が後続成果物に与える制約を明示する（粒度: 影響領域 + 制約要旨。具体ファイル確定は後続 Unit 着手時）。

| 決定 | 影響する後続成果物 | 参照すべき制約（要旨） |
|------|------------------|---------------------|
| DG-1 コマンド名 | workflow.md（Unit 002） | 主表示 define/develop/release/reflect、旧名のみエイリアス、build/implement は別名にしない。SKILL.md ルーティング設計に反映 |
| DG-2 Express | workflow.md（Unit 002） | express = define+develop+release チェーン。SKILL.md ルーティングに含める |
| DG-3 条件付き EOL | migration.md（Unit 004） | EOL 3 条件・移行期間中 v2 非変更・runtime 非影響・片方向移行 |
| DG-4 review 統合 | workflow.md（Unit 002）+ aidlc-review 設計 | 各フェーズの review 呼び出しは perspective 指定。size×review マトリクス |
| DG-5 GitHub 前提 | workflow.md / data-model.md | core は Issue/PR まで。Projects/Milestone/Release は extension として参照しない |
| DG-6 state format | data-model.md（Unit 003） | cycle=state.json（JSON schema）、work item=Markdown frontmatter。フェーズ導出ロジックの正本は data-model.md |
| 境界基準（§2） | 全後続成果物 | 新機能の core/extension 分類は §2.2 の判断軸で行う |

## 4. 完了条件への対応（unit-001-plan.md チェックリスト）

| 完了条件 | RFC での対応箇所 |
|---------|----------------|
| 7 principles + 参照元 | §2 |
| core/extension 境界 + 分類基準 | §4 |
| 削減目標（baseline/目標/削減数・率/対象外） | §6 |
| 6 設計判断の trade-off + 結論 | §5.1〜5.6 |
| Decision Gate Log（分岐論点・承認結果・採用判断） | §5 |
| v2 共存方針 + EOL 相互参照 | §5.7 |
| docs/v3 限定・コード非生成 | 成果物が rfc.md のみ |
| markdownlint | Phase 2 で実行 |
