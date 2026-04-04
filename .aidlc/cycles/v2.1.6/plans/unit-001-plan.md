# 計画: Unit 001 - 設定キー整理

## 概要

config.tomlの不要・重複・スコープ違いの設定キーを整理する。preflight設定の削除、named_enabledとcycle.modeの統合、size_checkのスコープ見直し、旧キー名の更新を一括で実施する。

## スコープとIntent要件の対応

本UnitはIntent全体のうち **#520（config.toml設定キーの整理・不要設定の削除）** のみを担当する。

| Intent要件 | 担当Unit |
|-----------|---------|
| #520: config.toml設定キーの整理・不要設定の削除 | **Unit 001（本Unit）** |
| #522: rules.historyとrules.depth_levelの統合 | Unit 002 |
| #523: rules.lintingにカスタムコマンド指定を追加 | Unit 003 |
| #434: .aidlc/cycles/をgit管理外にするオプション | Unit 004 |

### Intent成功基準との対応

| 成功基準 | 対応状況 |
|---------|---------|
| #520-1: preflight設定が削除され常時実行 | 本Unitで実施 |
| #520-2: named_enabledが削除されcycle.modeのみで制御 | 本Unitで実施 |
| #520-3: size_checkがdefaults.tomlから除外 | 本Unitで実施 |
| #520-4: upgrade_check→version_checkに更新 | 本Unitで実施 |

## 関連Issue

- #520

## 変更対象ファイル

### スキル内リソース（メタ開発: `skills/aidlc/` 配下）

| ファイル | 変更内容 |
|---------|---------|
| `config/defaults.toml` | preflight.enabled/checks、named_enabled、size_check関連キーを削除 |
| `steps/common/preflight.md` | オプションチェック分岐ロジック簡素化（preflight_enabled/preflight_checks判定を除去、常時全項目実行） |
| `steps/common/rules.md` | 設定仕様リファレンスからpreflight関連キーを除去、upgrade_check→version_checkに更新 |
| `steps/inception/01-setup.md` | ステップ7からnamed_enabledチェックを除去、cycle.mode直接参照に変更 |
| `templates/config_toml_template.toml`（存在すれば） | preflight・size_check設定を除外 |

### プロジェクト設定

| ファイル | 変更内容 |
|---------|---------|
| `.aidlc/config.toml` | preflight関連キーが残っていれば削除（後方互換: 残っていても無視される） |

### 確認のみ（変更なし）

| ファイル | 確認内容 |
|---------|---------|
| `bin/check-size.sh` | キー不在時にread-config.sh exit 1で無効扱いとなる既存契約を確認 |

## 実装方針

1. **defaults.tomlの整理**: 不要キーの削除
2. **preflight.mdの簡素化**: `preflight_enabled`/`preflight_checks`による分岐ロジックを除去し、全チェックを常時実行に変更。設定値一括取得からpreflight関連キーを除去
3. **01-setup.mdの修正**: named_enabledチェックロジックを除去し、cycle.modeを直接参照
4. **rules.mdの更新**: 設定仕様リファレンスの更新
5. **setupテンプレートの更新**: preflight・size_check設定を除外
6. **size_checkの配置**: defaults.tomlから除外、メタ開発config.tomlに直接記載を維持。bin/check-size.shの既存契約（キー不在時exit 1で無効扱い）を確認

## 後方互換性

### 互換性分類

| 設定キー | 分類 | 互換ポリシー |
|---------|------|------------|
| `rules.preflight.enabled` | 削除 | 旧config.tomlに残っていても無視（フォールバック不要） |
| `rules.preflight.checks` | 削除 | 旧config.tomlに残っていても無視（フォールバック不要） |
| `rules.unit_branch.named_enabled` | 削除 | 旧config.tomlに残っていても無視（フォールバック不要。cycle.modeが独立して機能） |
| `rules.size_check.*` | スコープ変更 | defaults.tomlから除外。メタ開発config.tomlに直接記載を維持。read-config.shのキー不在時exit 1で無効扱い（既存契約） |
| `rules.upgrade_check.enabled` → `rules.version_check.enabled` | 文書更新のみ | rules.md内の設定仕様リファレンスを更新。read-config.sh内の既存フォールバックは維持 |

### size_checkの責務分離

- **定義場所**: メタ開発リポジトリの`.aidlc/config.toml`に直接記載（defaults.tomlからは除外）
- **読取主体**: `bin/check-size.sh` → `read-config.sh` 経由
- **キー不在時の契約**: `read-config.sh` がexit 1を返し、`bin/check-size.sh`が無効扱いとする（既存の契約。本Unitでは確認のみ、変更なし）

## 完了条件チェックリスト

- [ ] defaults.tomlからpreflight.enabled、preflight.checks、named_enabled、size_check関連キーが削除されていること
- [ ] preflight.mdのオプションチェック分岐ロジックが簡素化され、常時全項目実行になっていること
- [ ] preflight.mdの設定値一括取得からpreflight関連キーが除去されていること
- [ ] 01-setup.mdのステップ7からnamed_enabledチェックが除去され、cycle.mode直接参照になっていること
- [ ] cycle.mode=default/named/askの3値で従来と同等の動作をすること（01-setup.mdのステップ7が担当）
- [ ] setupテンプレートからpreflight・size_check設定が除外されていること
- [ ] common/rules.mdの設定仕様リファレンスでupgrade_check.enabledがversion_check.enabledに更新されていること
- [ ] 旧config.tomlに削除済みキーが残っていてもエラーにならないこと
- [ ] size_checkキーがないconfig.tomlでbin/check-size.shがエラーにならないこと（read-config.sh exit 1で無効扱い。既存契約の確認）
