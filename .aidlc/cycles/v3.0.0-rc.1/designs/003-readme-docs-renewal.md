# Design 003: README・ドキュメント刷新

- trace: work item 003-readme-docs-renewal
- matrix_case: normal_standard
- design_mode: simple

## Goal

README を v3 前提（`/aidlc` = v3 / define → develop → release → reflect）に刷新し、
v2-maintenance branch への参照案内と v2→v3 migration 導線（`/aidlc-migrate`）を整備する。
あわせて docs 内の残存 `/aidlc-v3` 表記・v2 前提記述を整合させ、consumer が v3 を
導入・移行できる導線を完成させる（AC-006）。

## Context

- 002（本流化置換）完了済み: `skills/aidlc` = v3 実体、marketplace は `3.0.0-rc.1` で
  9 スキル（aidlc / aidlc-migrate / aidlc-feedback / reviewing-construction-plan・design・
  code・integration / reviewing-operations-deploy・premerge）を配布。v2 専用 8 スキル
  （aidlc-setup / aidlc-retrospective / reviewing-inception-\* / squash-unit / write-history 等）は撤去済み
- v3 の初期導線: 専用 setup スキルは無く、`/aidlc define` が `.aidlc/config.toml` の存在を
  前提とする（不在時はセットアップ案内で中断 / define.md Step 1）。`.aidlc` ディレクトリ・
  `state.json` は define Step 4 が生成する
- migration: `/aidlc-migrate` が世代ルーティング（v1 は v2-maintenance へ案内 / v2→v3 は
  new-cycle-only + archive-only で実行）
- v3 の cycle 識別子は `/` を許容しない（define.md Step 2）ため、v2 の「名前付きサイクル」
  （`waf/v1.0.0` 形式）は v3 では利用不可
- 現 README は全面 v2 前提（`/aidlc-v3` beta 表記 / aidlc-setup / inception 系コマンド /
  progress.md / Unit / 名前付きサイクル / retrospective 等）。badge も `3.0.0-beta.1` のまま
- docs 残存箇所: `docs/configuration.md`（`/aidlc setup` で生成・aidlc-setup 言及）/
  `docs/v3-renewal-plan.md:923`（正本ポインタが撤去済みパス `skills/aidlc-v3/steps/doctor.md`）/
  `docs/development/github-projects-setup.md`（v2 フェーズ語彙）。`docs/v3/rfc.md:247` は
  docs/v3/ の履歴的記述のためスコープ外

## Design

### 1. README.md 全面刷新（主成果物）

構成と主な変更:

- **badge**: `3.0.0-rc.1` へ更新
- **概要**: 3 フェーズ（Inception/Construction/Operations）記述を v3 サイクル
  （define → develop → release、reflect は任意）へ差し替え
- **v3 セクション**: 「v3 ベータ版について」を「v3 について」へ改稿。`/aidlc` = v3 が既定である
  こと、v2 は `v2-maintenance` branch で取得可能なこと、v2 利用者向け `/aidlc-migrate`
  導線（new-cycle-only / archive-only）を記載。beta 既知の制約（#744/#745）記述は削除
- **インストール**: スキル一覧表を marketplace 配布の 9 スキルに更新。aidlc-setup 手順を削除し、
  「`.aidlc/config.toml` を作成（最小例を提示）→ `/aidlc define`」の初期導線に置換
- **クイックスタート**: v3 コマンド体系表（define / develop / release / reflect / status /
  doctor）、引数なし `/aidlc` の自動ルーティング、express、旧名エイリアス
  （inception→define 等）を記載
- **リポジトリ構成**: 現構造（skills/aidlc = v3 の steps/scripts/templates、.aidlc/state.json、
  docs/v3 設計正本）へ更新
- **主要機能**: v3 の特徴（state.json + frontmatter からの明示的フェーズ導出 / size×depth_level
  マトリクスによる design・review 要否判定 / work item 単位 commit / 承認ゲート /
  AI レビュー統合）へ書き換え。v2 固有機能（progress.md / Unit 依存管理 / バックトラック /
  名前付きサイクル / retrospective スキル）は削除
- **GitHub Projects 連携**: bin/ スクリプトは現存するため記述は残し、v2 フェーズ語彙のみ除去
- **v1/v2 ブランチ案内**: v1 branch 案内に加えて v2-maintenance branch 案内を追加
- **翻訳文書・ライセンス・フィードバック**: 現状維持（v2 語彙があれば微修正）

### 2. docs 整合（最小差分）

| ファイル | 変更 |
|---------|------|
| `docs/configuration.md` | 「`/aidlc setup` で生成」→ 手動作成 / `/aidlc-migrate` 生成へ修正。`starter_kit_version` の説明から aidlc-setup 言及を除去 |
| `docs/v3-renewal-plan.md` | L923 の正本ポインタのみ `skills/aidlc/steps/doctor.md` へ更新（Phase 計画等の履歴的記述は残置） |
| `docs/development/github-projects-setup.md` | v2 フェーズ語彙（Inception ステップ番号等）を v3 相当へ最小置換 |

`docs/v3/` 配下の履歴的記述（rfc.md:247 等）は work item スコープにより変更しない。

### 3. 検証

- markdownlint（README + 変更 docs）0 errors
- skill-reference-check green（撤去済みスキル名への参照を README から排除したことの機械検証）
- README 目視レビュー（v3 コマンド体系・v2-maintenance 案内・migration 導線の 3 点）
