# Unit: init-label修正とbacklogディレクトリ条件分岐

## 概要

Issue駆動モード利用者向けの不具合修正。init-label処理のセットアップ・アップグレード対応と、backlogディレクトリ作成条件の修正を行う。

**グルーピングの理由**: 両方とも「Issue駆動モード（backlog.mode=issue/issue-only）」に関連するバグ修正であり、同じユーザーペルソナに影響する。また、同時にテスト・リリースすることで整合性を確保しやすい。

## 含まれるユーザーストーリー

- US1: init-label処理の修正 (#169)
- US2: backlogディレクトリ作成の条件分岐 (#162)

## 関連Issue

- #169
- #162

## 責務

- `prompts/setup-prompt.md` にinit-labels.sh呼び出しを追加（セットアップ・アップグレード両方）
- `prompts/package/bin/init-cycle-dir.sh` のbacklogディレクトリ作成条件を修正（issue/issue-only両方でスキップ）

## 境界

- スクリプトのロジック変更のみ
- 新規スクリプトの作成は行わない

## 依存関係

### 依存するUnit

- なし（独立して実装可能）

### 外部依存

- GitHub CLI（gh）: ラベル作成に使用
- dasel: 設定ファイル読み取りに使用（フォールバックあり）

## 非機能要件（NFR）

- **冪等性**: 既存ラベル・ディレクトリは上書きせずスキップ
- **後方互換性**: gitモード利用者への影響なし

## 技術的考慮事項

- `init-labels.sh` はrsync同期対象（`prompts/package/bin/` → `docs/aidlc/bin/`）
- backlogモード判定は `get_backlog_mode()` 関数を使用

## 実装優先度

High（バグ修正）

## 見積もり

小規模（スクリプト修正のみ）

---
## 実装状態

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
