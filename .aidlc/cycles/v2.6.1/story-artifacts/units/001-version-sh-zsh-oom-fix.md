# Unit: version.sh の zsh OOM クラッシュ修正

## 概要

`/aidlc v` 相当の version 取得操作が Claude Code の Bash ツール（zsh 環境）から実行された際に、`scripts/lib/version.sh` 内のコマンド置換が zsh `command_not_found_handler` の無限再帰を引き起こし OOM クラッシュする問題を修正する。SKILL.md の指示と `version.sh` の呼び出し経路を、zsh 環境でも安全に動作する形へ再設計する。

## 含まれるユーザーストーリー

- ストーリー 1: zsh 環境での `/aidlc v` OOM クラッシュ回避

## 責務

- **必須サポート経路（Bash ツール経由）の安全化**: zsh 環境の Claude Code Bash ツールから `bash <path>`（CLI モード）または `bash -c "source <path>; ..."` で呼び出される経路で、`scripts/lib/version.sh::read_marketplace_version` が OOM を起こさず正常終了するように経路を整備する（CLI モード追加 / 専用ラッパー / SKILL.md 改訂のいずれか / 組合せ）
- **AI エージェント誘導の明確化**: SKILL.md の「version 表示」アクション記述で、AI エージェントに対して必須サポート経路と非対象経路を曖昧さなく区別して提示する
- **テスト整備**: 既存 `test_*.sh` 基盤（`skills/aidlc/scripts/tests/test_read_marketplace_version.sh`）に CLI モード経由テストケースを追加し、必須サポート経路の動作（正常系・異常系）を検証する。bats への移行は本 Unit のスコープ外（DR-004 で確認済 / プロジェクトの現行テスト基盤を踏襲）

## 境界

- **非対象経路**: ユーザーが対話 zsh シェルで手動 `source <path>` してから関数を直接呼び出す経路は本 Unit の対象外。zsh 補完 hook との衝突は zsh 側の挙動に依存するため、SKILL.md 注意書きで案内するに留める
- **SoT 維持**: `marketplace.json.metadata.version` の SoT 化方針自体は変更しない（v2.6.0 Unit 1 の決定を維持）
- **影響範囲限定**: `bin/update-version.sh` の振る舞いは変更しない（読み取り経路の修正に閉じる）
- **波及監査の非対象**: `read-config.sh` 等の他の lib スクリプトの zsh 互換性監査は本 Unit の対象外（必要なら次サイクル）

## 依存関係

### 依存する Unit

- なし（独立 Unit）

### 外部依存

- `dasel` v3（`metadata.version` 抽出）
- `jq`（dasel 不在時の fallback）
- bash（CLI モード or `bash -c` ラッパー実行用）

## 非機能要件（NFR）

- **パフォーマンス**: 既存 version 取得経路に対して 100ms 以内のオーバーヘッド許容
- **セキュリティ**: 外部入力（path 引数）のサニタイズを維持（既存挙動）
- **スケーラビリティ**: N/A（CLI 単発実行）
- **可用性**: zsh 環境で 100% 成功（Bash ツール経由）

## 技術的考慮事項

- Issue #688 が提示する 3 案のうち、案 3（`version.sh` 末尾に `if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then read_marketplace_version "$@"; fi` を追加し `bash scripts/lib/version.sh <path>` で直接呼び出せるようにする）を Construction 設計レビューで第一候補として検討する
- v2.6.0 Unit 007 の `squash-unit.sh` で同パターン（CLI モード ガード）を採用しており、整合性が取れる
- SKILL.md 改訂は AI エージェントへの誘導効果が高く、案 3 と組み合わせる前提で記述する

## 関連Issue

- #688

## 実装優先度

High（致命的バグ）

## 見積もり

0.5 day（実装 + テスト + SKILL.md 改訂）

---

## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 完了
- **開始日**: 2026-05-10
- **完了日**: 2026-05-10
- **担当**: AI-DLC（Claude Code）
- **エクスプレス適格性**: -
- **適格性理由**: -
