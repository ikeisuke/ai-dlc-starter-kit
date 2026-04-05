# 既存コードベース分析

## ディレクトリ構造・ファイル構成

### 設定体系
```
.aidlc/
├── config.toml              # プロジェクト共有設定
├── config.local.toml        # 個人設定（Git管理外）
├── rules.md                 # プロジェクト固有ルール（#437: 既に.aidlc/直下に配置済み）
├── operations.md            # 運用引き継ぎ情報（#437: 既に.aidlc/直下に配置済み）
└── cycles/
    └── v2.1.8/              # サイクル固有成果物
        ├── requirements/
        ├── story-artifacts/units/
        ├── design-artifacts/
        ├── construction/units/
        ├── inception/
        ├── operations/
        ├── plans/
        └── history/

skills/aidlc/
├── config/
│   └── defaults.toml        # デフォルト値定義（正本）
├── scripts/
│   ├── read-config.sh       # 設定読み取り（4階層マージ）
│   ├── init-cycle-dir.sh    # サイクルディレクトリ初期化
│   └── bootstrap.sh         # dasel v2/v3互換ブートストラップ
└── steps/                   # フェーズステップファイル群
```

## アーキテクチャ・パターン

### 設定読み取りの4階層マージ
- defaults.toml → ~/.aidlc/config.toml → .aidlc/config.toml → .aidlc/config.local.toml
- 後勝ちルール（後のファイルに同キーがあれば上書き）
- dasel v2/v3の両方に対応（bootstrap.shで自動検出）

### Git関連設定キーの現状分散（#521の対象）
| セクション | キー | デフォルト値 |
|-----------|------|-----------|
| `rules.branch` | `mode` | `"ask"` |
| `rules.worktree` | `enabled` | `false` |
| `rules.unit_branch` | `enabled` | `false` |
| `rules.squash` | `enabled` | `false` |
| `rules.commit` | `ai_author` | `""` |
| `rules.commit` | `ai_author_auto_detect` | `true` |

### 参照箇所（ステップファイル）
| ファイル | 参照キー |
|---------|---------|
| `steps/inception/01-setup.md:233` | `rules.branch.mode` |
| `steps/inception/01-setup.md:238` | `rules.worktree.enabled` |
| `steps/construction/01-setup.md:132` | `rules.unit_branch.enabled` |
| `steps/common/commit-flow.md:53` | `rules.commit.ai_author` |
| `steps/common/commit-flow.md:74` | `rules.squash.enabled` |
| `steps/common/preflight.md:61` | `rules.squash.enabled`, `rules.unit_branch.enabled`（バッチ取得） |

## 技術スタック

| 項目 | 値 | 根拠ファイル |
|------|-----|-------------|
| 設定フォーマット | TOML | `.aidlc/config.toml`, `defaults.toml` |
| 設定パーサー | dasel (v2/v3) | `scripts/read-config.sh`, `scripts/bootstrap.sh` |
| スクリプト言語 | Bash | `scripts/*.sh` |
| プロンプト形式 | Markdown | `steps/**/*.md` |

## 依存関係

### #521 Git設定キー統合の影響範囲
- **defaults.toml**: キー名変更（`rules.branch.mode` → `rules.git.branch_mode` 等）
- **read-config.sh**: フォールバック読み取りロジック追加
- **preflight.md**: バッチ取得キーリスト更新
- **inception/01-setup.md**: `rules.branch.mode`, `rules.worktree.enabled` 参照更新
- **construction/01-setup.md**: `rules.unit_branch.enabled` 参照更新
- **commit-flow.md**: `rules.commit.*`, `rules.squash.enabled` 参照更新

### #437 共通設定ファイル配置統合の状況
- **発見**: `.aidlc/rules.md` と `.aidlc/operations.md` は既に `.aidlc/` 直下に配置済み
- サイクルディレクトリ配下には `rules.md` / `operations.md`（非history）は存在しない
- `init-cycle-dir.sh` も当該ファイルを生成していない
- **#437の実態**: 既に対応済みの可能性あり。残作業の有無を確認する必要がある

### #528 daselエラー修正の影響範囲
- **aidlc-setup内のdasel使用箇所**:
  - `scripts/detect-missing-keys.sh`: dasel v2/v3対応済み（bootstrap.sh経由）
  - `steps/01-detect.md`: `dasel -f .aidlc/config.toml 'starter_kit_version'`（v2形式のみ）
  - `steps/02-generate-config.md`: `dasel put` コマンド（v2形式のみ）
- **read-config.sh**: bootstrap.sh経由でv2/v3互換済み

## 特記事項

- **#437の再確認が必要**: Issue記述では「`.aidlc/cycles/{rules.md, operations.md}` が配置されている」とあるが、現状では既に `.aidlc/` 直下にある。Issueが古い状態を指しているか、残作業（参照パスの整理等）があるか要確認
- **read-config.sh のフォールバック実装パターン**: 既に `rules.history.level` → `rules.depth_level.history_level` のフォールバック例が存在する。#521でも同パターンを適用可能
- **bootstrap.sh のdasel互換**: `read-config.sh` は既にv2/v3対応済みだが、aidlc-setupの `01-detect.md` と `02-generate-config.md` はプロンプト内にv2形式のコマンド例を直接記載しており、スクリプト化されていない箇所がある
