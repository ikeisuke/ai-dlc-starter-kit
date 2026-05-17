# 実装記録: Unit 001 Inception 直近サイクル完了 Unit との重複検出フロー SoT 化

## 実装日時

2026-05-17（同日内で Inception Phase 完了 → Construction Phase Unit 001 完結）

## 作成ファイル

### ソースコード（ドキュメント SoT + 設定）

- `skills/aidlc/steps/inception/04-stories-units.md` - 「ステップ 4a: 直近サイクル完了 Unit との重複チェック」セクションを追加（サブステップ (0)〜(7) の SoT 手順）
- `skills/aidlc/config/defaults.toml` - `[rules.inception]` セクション + `dedup_lookback_cycles = 3` を追加
- `skills/aidlc-setup/config/defaults.toml` - 同上を sync コピー（`bin/check-defaults-sync.sh` ガード対応）

### テスト

本 Unit では新規 bats テストは追加しない（手順は AI エージェントが解釈実行する自然言語 SoT のため）。代替として以下を検証手段とした:

- `bin/check-defaults-sync.sh` で defaults.toml 2 系列の同期確認（sync:ok）
- `bin/check-bash-substitution.sh skills/aidlc/steps/inception` で `$(...)` / backtick 不在確認（no violations）
- `bin/check-markdownlint.sh` で markdown lint 通過確認（exit 0）
- `tests/config-defaults/defaults-resolution.bats` の既存 bats 群（16 ケース）が all pass（回帰なし）
- ドッグフーディング: v2.6.5 自身の Inception 結果を retrofit 検証し `.aidlc/cycles/v2.6.5/history/inception.md` に記録（「重複候補 0 件 → ステップ 4b へ進む」動作を確認）

### 設計ドキュメント

- `.aidlc/cycles/v2.6.5/design-artifacts/domain-models/unit_001_inception_recent_unit_dedup_detection_domain_model.md`
- `.aidlc/cycles/v2.6.5/design-artifacts/logical-designs/unit_001_inception_recent_unit_dedup_detection_logical_design.md`

## ビルド結果

**成功**（ビルド対象のコンパイル成果物はなし。markdownlint / bash 静的検査 / defaults sync チェックを通過）

```text
bin/check-markdownlint.sh: exit 0
bin/check-bash-substitution.sh skills/aidlc/steps/inception: no violations, 7 files checked
bin/check-defaults-sync.sh: sync:ok
```

## テスト結果

**成功**

- 実行テスト数: 16（既存 `tests/config-defaults/defaults-resolution.bats`）
- 成功: 16
- 失敗: 0

```text
ok 1〜16 すべて pass
新規キー rules.inception.dedup_lookback_cycles を read-config.sh で取得 → "3" を返すこと確認
```

## コードレビュー結果

- [x] セキュリティ: OK（dedup-warning 受理正規表現の許可エスケープを `\"` と `\\` のみに限定 / コマンド置換禁止規約遵守）
- [x] コーディング規約: OK（既存ステップファイルの記法と整合 / 表構造 / コードブロック構造）
- [x] エラーハンドリング: OK（gh 不可用時フォールバック / config 不正値時 fail-safe / `lookback=0` opt-out）
- [x] テストカバレッジ: OK（自然言語 SoT のため bats 不要、ドッグフーディング検証で代替）
- [x] ドキュメント: OK（4 層責務分離 / サブステップ (0)〜(7) / シリアライズ規約 / SoT 配置全て論理設計と整合）

## 技術的な決定事項

- **defaults.toml 二重 SoT への対処**: `skills/aidlc/config/defaults.toml` と `skills/aidlc-setup/config/defaults.toml` の sync は既存 `bin/check-defaults-sync.sh` ローカルガードに依存。Unit 004（CI ジョブとしての sync guard）の責務は別 Unit。Unit 001 / Unit 004 は独立完結可能
- **AskUserQuestion の種別位置づけ**: 「ゲート承認」ではなく「ユーザー選択」種別として SKILL.md「AskUserQuestion 使用ルール」に合致。`automation_mode=semi_auto` でも常時実行（自動化対象外）。本仕様を 04-stories-units.md ステップ 4a の実装メモに明記
- **`withdraw` 正規アクション**: 物理削除ではなく「実装状態 → 取り下げ」の状態変更のみ（履歴トレース保持）。AI レビュー Round 1 で確定
- **`dedup_lookback_cycles=0` の opt-out 動作**: 1 行ログのみで AskUserQuestion を起動せず、誤起動による中断を回避
- **受理正規表現の許可エスケープ限定**: `\"` / `\\` のみ受理（その他 `\X` 表現は不正値拒否）。AI コードレビュー Round 1 指摘 #1 への対応として明示限定

## 課題・改善点

- スラグ正規化（複数形 / 略語展開）は false positive 低減のため Unit 境界仕様で明示的にスコープ外。将来 issue として追跡候補
- `dedup_lookback_cycles` を 5〜10 に拡張する際の `gh issue view` レイテンシ管理は別 issue
- 本 Unit 自身ではドッグフーディング正例（重複なし）のみ確認。重複検出 true positive ケースは将来サイクルで蓄積

## 状態

**完了**

## 備考

- 関連 Issue: #712
- AI レビュー: 設計 4R / コード 2R で全 clean、統合レビューは構造化シグナル参照
- レビューサマリ: `.aidlc/cycles/v2.6.5/construction/units/001-review-summary.md`
- 計画書「Unit 004 との依存契約（ハード依存なし / 互換窓は Unit 004 側で保証）」は Unit 001 完了時点で Unit 004 計画書側に責務移譲
