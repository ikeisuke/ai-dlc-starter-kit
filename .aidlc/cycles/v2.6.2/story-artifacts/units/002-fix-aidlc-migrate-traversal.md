# Unit: aidlc-migrate manifest 由来パスのトラバーサル検証

## 概要

`skills/aidlc-migrate/scripts/migrate-apply-config.sh` の `_apply_resource()` 系（`cp` / `rm` / `mkdir -p` / `mv` リソース処理）で manifest 由来の `path` / `dest` のトラバーサル検証を追加し、細工された fork manifest によるリポジトリ外ファイル書き込み攻撃を構造的に予防する。Issue #680（v2.6.0 Unit 003 R1〜R3 codex 連続指摘 defer）。

## 含まれるユーザーストーリー

- ストーリー 3: aidlc-migrate manifest 由来パスのトラバーサル検証

## 責務

- `_apply_resource()` 系で manifest 由来の `path` / `dest` を検証
- 許容形式: `AIDLC_PROJECT_ROOT` からの相対パスのみ
- 拒否形式: 絶対パス / `..` 含有 / `realpath` 解決後配下外 / シンボリックリンク経由の脱出
- macOS BSD `realpath` と GNU `realpath` の挙動差を吸収する shim 実装
- bats テスト追加（4 ケースの拒否シナリオ + クロスプラットフォーム検証）

## 境界

- aidlc-migrate スコープに閉じる。aidlc-setup / 他スクリプトのトラバーサル検証は本 Unit 対象外（必要なら別 Issue で defer）
- 信頼境界の前提（公式リポジトリ経由では発火しない）はドキュメント記述で扱い、コードでは無条件適用する（fail-closed）
- 本 Unit は manifest の `path` / `dest` 文字列レベルの検証のみ。manifest スキーマ全体の strict validation は対象外

## 依存関係

### 依存する Unit

- なし

### 外部依存

- bash + `realpath`（GNU `realpath -m` または BSD `realpath` の挙動差吸収が必要）
- bats / shellcheck / shellharden（既存テスト環境）
- macOS / Linux 双方のテスト環境

## 非機能要件（NFR）

- **セキュリティ**: トラバーサル攻撃 4 ケース（絶対パス / `..` / 配下外 / シンボリックリンク）すべてが exit 2 で停止（fail-closed）
- **パフォーマンス**: `realpath` 呼び出しのオーバーヘッドは manifest エントリあたり 10ms 未満
- **可搬性**: macOS BSD `realpath`（古い macOS では `-m` / `--strict` 不在）と GNU `realpath` の双方で同じ判定結果

## 技術的考慮事項

- `realpath` shim 実装方針: (a) `bin/lib/` 配下に shim 関数を新設、(b) `realpath -m` の存在確認 + フォールバック実装、(c) `python3` 等の他ツールへ委譲、のいずれか。Construction 設計レビューで採用方針を確定
- シンボリックリンク経由のトラバーサル検出は物理パス解決（`realpath` の `-P` または相当）が必要。論理パス解決のみだと検出できない
- 既存の正常な manifest（v2.6.x までの apply.json）が変更なしで動作することを検証する整合性テストを追加
- エラーメッセージは tab 区切り 4 フィールド固定（`error\tmigrate-apply:path-traversal\t<offending_path>\treason=<code>`）
- exit code は全拒否ケースで `2` 固定

## Intent 制約適合

- **破壊的変更なし**: 既存の正常な manifest（`AIDLC_PROJECT_ROOT` 配下の相対パスのみを使用するもの）は変更なしで動作。整合性テストで保証
- **ドッグフーディング特殊処理禁止**: トラバーサル検証は consumer プロジェクトでも同一に作動。自リポジトリ判定で fail-closed/fail-open を切り替えるロジックは導入しない（無条件 fail-closed）
- **コマンド置換禁止**: 検証実装で `$(...)` 形式のコマンド置換を新規導入しない。`realpath` shim 実装でも shellcheck SC2046 等を回避する書き方を選ぶ

## 関連Issue

- #680（type:security, type:defer-from-review, priority:high / v2.6.0 Unit 003 codex 連続指摘）

## 実装優先度

High（security:high）

## 見積もり

1〜1.5 日。trav 検証ロジック自体は小規模だが、cross-platform `realpath` shim 整備と bats fixture（攻撃ケース 4 種 + 物理パス解決検証）に時間がかかる。

---
## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
- **エクスプレス適格性**: -
- **適格性理由**: -
