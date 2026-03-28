# Intent（開発意図）

## プロジェクト名

AI-DLC Starter Kit v2.0.2 — v2系MVP品質向上

## 開発の目的

v2.0.0/v2.0.1で残存するバグ・改善点を修正し、v2系のMVP品質を完成させる。v1の痕跡を完全に除去し、v2への移行パスを整備する。

## ターゲットユーザー

AI-DLCスターターキットの利用者（v1からのアップグレードユーザーを含む）

## ビジネス価値

- v1→v2移行の障壁を除去し、スムーズなアップグレード体験を提供
- v1時代の不要なファイル・設定を一掃し、メンテナンスコストを削減
- バグ修正・改善により、日常的なAI-DLC利用の信頼性を向上

## 成功基準

- `/aidlc migrate` 実行後、config.tomlのパス更新・cyclesデータ移行（rules.md/operations.md/backlog.md）・v1専用シンボリックリンク削除が自動で完了する
- v1由来の不要シンボリックリンク（`.agents/skills/*`→`docs/aidlc/`、`.kiro/skills/*`→`docs/aidlc/`、`.kiro/agents/*`→`docs/aidlc/`）が削除される
- `.aidlc/cycles/backlog/` ディレクトリが削除される（issue-onlyモードで不要）
- Kiroエージェント設定は `examples/kiro/` に実体ファイルとして配置され、ユーザーが手動コピーで利用可能
- Inception完了メッセージに `/aidlc` スキル前提の表現（`/aidlc construction` 等）が含まれず、ツール非依存の表現になっている
- コンパクション復帰後、compaction.mdの手順に従って再読み込みを実行すれば、直前フェーズに必要なスキル群が再利用可能になる
- パス参照がconfig.tomlの `[paths]` セクション経由に統一され、ステップファイル内の物理パス直接参照（`docs/aidlc/`等）が解消される
- v1→v2アップグレード時にcycles配下のrules.md・operations.md・backlog.mdが移行される
- `/aidlc setup` 実行時に `.claude/settings.json` が所定のパーミッション設定付きで生成される

## 期限とマイルストーン

v2.0.xシリーズでのMVP完成。特定期限なし。

## 制約事項

- 既存のv2.0.1ユーザーへの後方互換性を維持（`/aidlc` コマンド体系、`.aidlc/` ディレクトリ構造、config.tomlの設定キーは変更しない）
- 破壊的変更はv1専用要素（`docs/aidlc/`へのシンボリックリンク、v1パス参照）に限定
- スターターキットのディレクトリ構造（prompts/package/）との整合性を維持
- SKILL.md本文500行制限
- `prompts/` ディレクトリの整理はスコープ外

## スコープ

### 含まれるもの

- #416: v1→v2移行スキル（`/aidlc migrate`）の作成
- #418: Inception完了メッセージのスキル前提表現を修正
- #419: コンパクション復帰時にスキルを再起動するフローの整備
- #420: パス参照の抽象化レイヤー導入（物理パス直接参照の解消）
- #421: v1→v2アップグレード時のcyclesデータ移行漏れ修正
- v1痕跡の完全除去（シンボリックリンク、v1専用スキル、スターターキットから導入したIssueテンプレート等）
- Kiroエージェント設定: v1のシンボリックリンク方式を廃止し、`examples/kiro/` にコピー用サンプルとして配置（Kiro Power正式リリース後はそちらでサポート）
- `.claude/settings.json` のパーミッション設定を `/aidlc setup` で生成対象に含める

### 除外するもの

- #423: ローカルバックログの仕組みの廃止（次サイクル以降）
- #405以前のバックログ項目
- `prompts/` ディレクトリの整理

## 不明点と質問（Inception Phase中に記録）

[Question] #416の移行スキルの対象範囲は？
[Answer] config.tomlのパス更新、cyclesデータ移行に加え、v1でのみ使用するシンボリックリンク・スキルを全て削除し、v1の痕跡を残さないこと。Kiroエージェント設定はv1方式（シンボリックリンク）を廃止するが、v2向けにexamples/にコピー用サンプルとして提供。

[Question] 全5件（#416〜#421）を1サイクルに含めて問題ないか？
[Answer] はい。v2.0.xはv2系のMVP完成がゴール。

[Question] `.claude/settings.json` や `.kiro/` の設定もコピーが必要では？
[Answer] `.claude/settings.json` は `/aidlc setup` で生成対象に含める。Kiroは `examples/kiro/` にサンプルを置き、ユーザーが手動コピー。Kiro Power正式版でサポート予定。

[Question] `prompts/` は削除対象か？
[Answer] スコープ外。このリポジトリはスターターキット本体であり、利用者リポジトリには `prompts/` は存在しない。
