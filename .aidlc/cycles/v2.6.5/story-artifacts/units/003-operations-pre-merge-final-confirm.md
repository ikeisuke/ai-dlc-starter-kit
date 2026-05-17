# Unit: Operations §7.13 直前マージ前完結契約最終確認プロンプト追加

## 概要

Operations Phase §7.13（PR マージ実行）の AskUserQuestion 直前に、マージ前完結契約最終確認の AskUserQuestion を automation_mode 非依存・例外なしで常時実行するプロンプトを追加する。既存 §4 post-merge ガード（write-history.sh exit 3）と双方向に対称な pre-merge 予防として機能させる。

## 含まれるユーザーストーリー

- ストーリー 3: Operations §7.13 直前にマージ前完結契約最終確認を常時表示する

## 責務

- `skills/aidlc/steps/operations/02-deploy.md` §7.13 直前にマージ前完結契約最終確認の AskUserQuestion ステップを挿入
- `operations-release.md` の該当 PR マージ実行箇所にも同じ挿入を反映（記述箇所が分かれている場合）
- 提示メッセージの仕様策定: 凍結対象ファイル一覧 + マージ後 write-history.sh exit 3 ガード説明 + 選択肢「記録漏れなし、マージに進む」「記録を追加する（§7.6 / §7.7 に戻る）」
- automation_mode 非依存・例外なし常時実行ルールを SKILL.md「AskUserQuestion 使用ルール」内「ユーザー選択」種別として整合
- 検証ケース (a) 通常 / (b) 修正コミット欠落 / (c) 空 PR / (d) 緊急マージ / (e) semi_auto の網羅証跡を定義
- 本サイクル自身の Operations Phase で (a) 通常経路をドッグフーディング検証

## 境界

- post-merge ガード（write-history.sh exit 3）自体は既存仕様維持、改修対象外
- §7.13 以外の AskUserQuestion ポイントへの拡張は対象外
- `automation_mode=full_auto` 仕様自体の見直しは対象外（既存仕様に従い「ユーザー選択」種別は full_auto でも自動化対象外として扱う）
- 「記録を追加する」選択時の §7.6/§7.7 への戻りロジック自体は既存実装に従い、新規分岐は導入しない

## 依存関係

### 依存する Unit

- なし

### 外部依存

- なし（既存 `steps/operations/` 内 + `SKILL.md` 整合のみ）

## 非機能要件（NFR）

- **パフォーマンス**: AskUserQuestion 1 回追加分のユーザー応答コストのみ
- **セキュリティ**: 影響なし
- **スケーラビリティ**: 同パターンを他フェーズ間の不可逆操作直前にも将来適用可
- **可用性**: 既存マージフローを中断しない（ユーザー応答後、(a) マージ続行 or (b) §7.6/§7.7 戻りに分岐）

## 技術的考慮事項

- 「ユーザー選択」種別として SKILL.md ルールに整合（automation_mode に関わらず AskUserQuestion 必須）
- 選択肢配列 / 質問文字列は明示的に SoT 化し、表現揺れを防ぐ
- 「区切り判断での AskUserQuestion 禁止」横断ルールの例外として位置付ける（破壊的・不可逆操作の最終確認）

## 関連Issue

- #641（このサイクルで Closes）

## 実装優先度

High

## 見積もり

0.5 日（プロンプト挿入 + 検証ケース定義 + ドッグフーディング検証）

---

## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 完了
- **開始日**: 2026-05-17
- **完了日**: 2026-05-17
- **担当**: AI (Claude Code)
- **エクスプレス適格性**: -
- **適格性理由**: -
