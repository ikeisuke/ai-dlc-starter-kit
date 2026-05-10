# Unit: squash-unit.sh の CI 構造チェック fail-open 化

## 概要

`skills/aidlc/scripts/squash-unit.sh:985-996` の 3 種 CI 構造チェック（check-skill-references / check-bash-substitution / check-test-isolation）が「ファイル不在 → 即 exit 1」で全 consumer プロジェクトに必須化されており、starter kit 自身のソースツリー前提の検査が consumer プロジェクトで常時 fail する問題を修正する。

starter kit リポジトリ判定（リポジトリルート直下に `skills/aidlc/` ディレクトリが存在するか）で fail-closed / fail-open を切り替え、starter kit 自身では従来どおり fail-closed を維持しつつ、consumer プロジェクトでは fail-open + info ログでスキップする。

Construction Phase 中に発生した割り込み（分類2「別 Unit」）として追加。

## 含まれるユーザーストーリー

- なし（バグ修正 / Construction 中の割り込み追加）

## 責務

1. **starter kit リポジトリ判定ロジック追加**: `${repo_root_for_checks}/skills/aidlc/` ディレクトリ存在確認
2. **3 種チェックを fail-open / fail-closed で分岐**:
    - starter kit 自身（`skills/aidlc/` 存在）: 従来どおり 3 種チェックを必須実行（fail-closed 維持）
    - consumer プロジェクト（`skills/aidlc/` 不在）: 3 種チェックをスキップ + info ログ出力
3. **info ログ仕様**: `info: skipping starter-kit internal CI checks (consumer project)` を stderr に出力
4. **bats テスト追加**: starter kit 経路 / consumer 経路の両方を検証
5. **影響確認**: visitory v1.16.2 サイクル Unit 005 で発生した manual squash 回避が解消されること（consumer プロジェクトで `squash-unit.sh` が完走すること）

## 境界

- 3 種チェック（check-skill-references / check-bash-substitution / check-test-isolation）自体の振る舞いは変更しない
- starter kit 自身での挙動は完全互換（fail-closed 維持）
- 他の `squash-unit.sh` 内チェック（commit count / merge conflict 等）の変更は対象外
- consumer プロジェクト向けの代替チェック追加は対象外（スキップのみ）

## 依存関係

### 依存する Unit

- なし（独立して実装可能 / Unit 006 完了後に着手するが直接依存なし）

### 外部依存

- bash 3.x / 4.x（既存依存維持）
- bats v1.8+（既存依存）

## 非機能要件（NFR）

- **後方互換性**: starter kit 自身の squash-unit.sh の挙動は完全に従来通り（fail-closed 3 種チェック実行）
- **明示性**: consumer プロジェクトでスキップする際は info ログで「なぜスキップしたか」を明示
- **テスタビリティ**: starter kit 経路 / consumer 経路の両方を bats モックで検証可能

## 技術的考慮事項

- 判定ロジック: `if [[ -d "${repo_root_for_checks}/skills/aidlc" ]]; then ...` の単純な if 分岐
- info ログは stderr 出力（既存の squash-unit.sh の出力規約に準拠）
- bats モック: `mktemp -d` で starter kit 構造 / consumer 構造を擬装してテスト
- 修正対象は `skills/aidlc/scripts/squash-unit.sh` の 1 関数（〜10 行追加）

## 関連Issue

- なし（ユーザーから直接指示された割り込み）
- 影響発生元: visitory v1.16.2 サイクル Unit 005 (consumer プロジェクト)
- 関連ファイル: `skills/aidlc/scripts/squash-unit.sh:985-996`

## 実装優先度

High（consumer プロジェクトのブロッカー）

## 見積もり

30〜60 分（実装 10 分 + bats 2 件追加 20 分 + レビュー 10 分 + 完了処理）

---
## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 完了
- **開始日**: 2026-05-10
- **完了日**: 2026-05-10
- **担当**: AI-DLC (Claude Code)
- **エクスプレス適格性**: -
- **適格性理由**: -
