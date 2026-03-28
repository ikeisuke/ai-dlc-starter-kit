# Unit: v1インフラ廃止・スクリプトv2対応・ルール追加

## 概要
v1セットアップインフラの廃止、スクリプトのv2対応、バックログルール追加、旧エントリポイント誘導設置を行う。

## 含まれるユーザーストーリー
- ストーリー 5: v1セットアップインフラの廃止
- ストーリー 6: スクリプトのv2対応
- ストーリー 7: バックログ即時実装ルール追加
- ストーリー 8: 旧エントリポイントの誘導設置

## 責務
- `prompts/bin/sync-package.sh` の削除
- `prompts/setup/` 配下のv1パスハードコードをv2パスに更新
- `aidlc-setup.sh` の `resolve_starter_kit_root()` でシンボリックリンク解決対応
- `update-version.sh` の `docs/aidlc.toml` 参照除去
- `steps/common/agents-rules.md` に即時実装ルール追加
- `prompts/setup-prompt.md` を誘導文付きに簡略化

## 境界
- `skills/aidlc/steps/` 内のパス参照更新は行わない（Unit 002で完了済み）
- ファイルの物理移動は行わない（Unit 001で完了済み）

## 依存関係

### 依存する Unit
- Unit 002: パス参照一括更新・aidlc_dir設定廃止（依存理由: prompts/setup/ のパス更新時に aidlc_dir 廃止後の新パス体系を前提とするため。ルール追加・誘導設置は依存不要だが、同一Unit内で順序制御）

### 外部依存
- なし

## 非機能要件（NFR）
- **パフォーマンス**: 該当なし
- **セキュリティ**: 該当なし
- **スケーラビリティ**: macOS（BSD readlink）とLinux（GNU readlink）の両方で動作
- **可用性**: シンボリックリンク破損時に明確なエラーメッセージを出力

## 技術的考慮事項
- macOS の `readlink` はGNU互換でないため、`readlink -f` の代替実装が必要な場合あり
- `prompts/setup/` で `/aidlc setup` が参照する機能は維持し、rsync前提の機能のみ廃止
- `rules.md` の「改善提案のバックログ登録ルール」と即時実装ルールの適用場面の違いを明記

## 対応するIntent項目
- 2: prompts/ のv1インフラ廃止
- 4: aidlc-setup.sh パス解決修正
- 5: update-version.sh v2対応
- 6: バックログ即時実装ルール追加
- 7: 旧エントリポイントの誘導

## 関連Issue
- #447: aidlc-setup.shのスターターキットパス解決がプラグインモデルで機能しない
- #450: setup-prompt.mdのsetup_promptパス設定を廃止しv2表示用に簡略化
- #449: rsync同期インフラの廃止
- #448: prompts/setup/配下のv1パスハードコードをv2構造に更新
- #444: update-version.shをv2プラグイン構造に対応させる
- #439: バックログ管理に即時実装優先ルールを追加

## 実装優先度
High

## 見積もり
中〜大規模（スクリプト修正2件: aidlc-setup.sh + update-version.sh、prompts/setup/ パス更新3+ファイル、rsync削除、setup-prompt.md簡略化、agents-rules.md更新、OS互換テスト）

---
## 実装状態

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
- **エクスプレス適格性**: -
- **適格性理由**: -
