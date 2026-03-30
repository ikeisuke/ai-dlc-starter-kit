# ステップ4: Unit定義 計画

## 作成するファイル
- `docs/cycles/v1.2.3/story-artifacts/units/unit1_lite_path.md`
- `docs/cycles/v1.2.3/story-artifacts/units/unit2_phase_guardrail.md`
- `docs/cycles/v1.2.3/story-artifacts/units/unit3_version_field.md`
- `docs/cycles/v1.2.3/story-artifacts/units/unit4_migration_confirm.md`
- `docs/cycles/v1.2.3/story-artifacts/units/unit5_timestamp.md`
- `docs/cycles/v1.2.3/story-artifacts/units/unit6_inception_step6.md`

## Unit構成

全6項目が独立しているため、各項目を1Unitとして定義。

| Unit | 名前 | 対象ストーリー | 依存関係 |
|------|------|----------------|----------|
| 1 | Lite版パス解決安定化 | US-1 | なし |
| 2 | フェーズ遷移ガードレール強化 | US-2 | なし |
| 3 | starter_kit_versionフィールド追加 | US-3 | なし |
| 4 | 移行時ファイル削除確認追加 | US-4 | なし |
| 5 | 日時記録必須ルール化 | US-5 | なし |
| 6 | Inception Phaseステップ6削除 | US-6 | なし |

## 作業内容
1. 各Unitの定義ファイルを作成
2. 修正対象ファイル、修正内容を記載
3. 依存関係（なし）を明記
