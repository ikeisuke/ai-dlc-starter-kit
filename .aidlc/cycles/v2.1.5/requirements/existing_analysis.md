# 既存コードベース分析

## ディレクトリ構造・ファイル構成

今回のIntentに関連するファイル構成:

```
bin/
  post-merge-sync.sh          # #515: 出力ステータス変更対象
skills/
  aidlc/
    scripts/
      read-config.sh           # #516: aidlc-setupから参照できないスクリプト
      lib/bootstrap.sh         # スクリプト共通初期化
    config/
      defaults.toml            # #517: スキーマとして利用する設定デフォルト
  aidlc-setup/
    SKILL.md                   # aidlc-setupスキル定義
    scripts/                   # read-config.shが存在しない
      read-version.sh
      migrate-config.sh
      setup-ai-tools.sh
      init-labels.sh
      migrate-backlog.sh
    steps/
      01-detect.md             # #516: read-config.shを参照している箇所
      02-generate-config.md
.aidlc/
  config.toml                  # プロジェクト設定
```

## アーキテクチャ・パターン

- **スキルプラグイン構成**: `skills/aidlc/`と`skills/aidlc-setup/`は独立したスキル。各スキルは自身の`scripts/`からの相対パスでスクリプトを参照する（パス解決ルール）
- **4層カスケード設定マージ**: `read-config.sh`がdefaults.toml→HOME→project→localの順でキー単位マージを実行
- **スキル間依存ルール**: 他スキルの内部実装（`scripts/`等）への直接参照は禁止。公開インターフェイス（スキル呼び出し名と入出力引数）のみ依存可

根拠: `skills/aidlc/SKILL.md`のパス解決ルール、`.aidlc/rules.md`のスキル間依存ルール

## 技術スタック

| 項目 | 値 | 根拠ファイル |
|------|-----|-------------|
| 言語 | Bash (シェルスクリプト) | `bin/post-merge-sync.sh`, `skills/aidlc/scripts/read-config.sh` |
| TOML解析 | dasel (v2/v3互換) | `skills/aidlc/scripts/lib/bootstrap.sh` |
| 設定フォーマット | TOML | `.aidlc/config.toml`, `skills/aidlc/config/defaults.toml` |

## 依存関係

### #515: post-merge-sync.sh
- **出力パーサー**: なし（既存スクリプトで出力をパースするものは確認されず）
- **関連スクリプト**: `skills/aidlc/scripts/post-merge-cleanup.sh`（独自の出力形式を使用、post-merge-sync.shの出力はパースしない）
- **出力形式**: `status:success` / `status:success(warn:N)` → `status:success` / `status:warning` に変更予定

### #516: aidlc-setup read-config.shパス解決
- **問題**: `skills/aidlc-setup/steps/01-detect.md`（101行目）が`scripts/read-config.sh`を参照するが、aidlc-setupの`scripts/`には存在しない
- **フェイルセーフ**: 現状はバージョン比較スキップとして続行（実害軽微）
- **制約**: スキル間依存ルールにより`skills/aidlc/scripts/read-config.sh`を直接参照できない

### #517: defaults.toml欠落キー検出
- **defaults.toml**: 28リーフキー（15セクション）
- **config.toml**: 26ユニークキー
- **欠落キー**: `rules.commit.ai_author_auto_detect`, `rules.cycle.named_enabled`, `rules.reviewing.exclude_patterns`（3件）
- **マージロジック**: `read-config.sh`のキー単位マージにより動作上は問題なし（defaults.tomlがフォールバック）

## 特記事項

- `post-merge-cleanup.sh`は`status:success|warning|error`形式を既に使用しており、`post-merge-sync.sh`を同じ形式に統一するのは一貫性の観点で妥当
- #516の対応方法として、スキル間依存ルールを遵守するには`01-detect.md`のプロンプト内容変更またはaidlc-setup側に代替スクリプト配置が必要
