# Unit 001: アーキテクチャスタイル宣言と違反検出 - 実行計画

## 概要

`docs/aidlc.toml` に `[rules.architecture]` セクションを追加し、プロジェクトのアーキテクチャスタイル（layered, hexagonal, clean 等）を宣言できるようにする。reviewing-architecture スキルがこの設定を参照し、宣言されたスタイルに基づいた違反検出を行えるようにする。

## 変更対象ファイル

| ファイル | 変更内容 |
|---------|---------|
| `prompts/package/config/defaults.toml` | `[rules.architecture]` セクションのデフォルト値追加 |
| `docs/aidlc/skills/reviewing-architecture/SKILL.md` | toml設定参照のレビュー観点追加 |
| `docs/aidlc.toml` | （任意）プロジェクト固有のアーキテクチャスタイル設定例 |

## 実装計画

### Phase 1: 設計

1. **ドメインモデル設計**: `[rules.architecture]` の設定スキーマを定義
   - `style`: アーキテクチャスタイル（layered, hexagonal, clean, event-driven, modular 等）
   - `layers`: レイヤー定義（順序付き配列）
   - `dependency_direction`: 依存方向（top-down, inward 等）
   - 未知のstyle値に対するグレースフルデグラデーション設計

2. **論理設計**: 設定の読み取り方法とスキルへの統合方法を設計
   - `read-config.sh` での読み取り（dasel によるTOML配列対応確認）
   - reviewing-architecture スキルの設定参照フロー

3. **設計レビュー**

### Phase 2: 実装

4. **コード生成**:
   - `defaults.toml` にデフォルト値追加
   - SKILL.md にtoml設定参照レビュー観点追加

5. **テスト生成**: 設定読み取りの動作確認

6. **統合とレビュー**

## 完了条件チェックリスト

- [ ] `[rules.architecture]` の仕様が確定し、defaults.toml に反映されている
- [ ] reviewing-architecture スキルがその仕様を利用して違反検出できる状態になっている
- [ ] `[rules.architecture]` セクションの設計（キー定義: style, layers, dependency_direction）が完了
- [ ] `defaults.toml` へのデフォルト値追加が完了
- [ ] reviewing-architecture スキルへの toml 設定参照レビュー観点追加が完了
