# PRFAQ: AI-DLC Starter Kit v2.0.0

## Press Release（プレスリリース）

**見出し**: AI-DLC v2.0.0 - プラグイン化でゼロフットプリント開発を実現

**副見出し**: フェーズプロンプトをClaude Codeスキルに変換し、プロジェクトへのファイル同期が不要に

**発表日**: 2026年4月（予定）

**本文**:

AI-DLC Starter Kit v2.0.0をリリースしました。本バージョンでは、AI-DLCの全フェーズプロンプト（合計3,400行以上）をClaude Codeスキルとして再構成し、ユーザーレベルプラグインとして配布する方式に移行しました。

これまでAI-DLCを利用するプロジェクトでは、`docs/aidlc/` 配下に大量のプロンプトファイル・スクリプト・テンプレートを同期する必要がありました。v2.0.0ではこの制約がなくなり、プロジェクト側に必要なのは `.aidlc/config.toml`（設定ファイル）と `.aidlc/cycles/`（サイクル成果物）のみです。

「AI-DLCを使い始めるのに30ファイル以上の同期が必要だったのが、configファイル1つで済むようになった。プラグインの更新も簡単で、常に最新のワークフローを使える。」（想定利用者）

今後はスキルの拡張性を活かし、カスタムフェーズやプロジェクト固有のワークフロー統合をさらに容易にしていく予定です。

## FAQ（よくある質問）

### Q1: v1からv2への移行は簡単ですか？
A: `/aidlc setup` コマンドで自動移行できます。既存の `docs/aidlc.toml` の設定値は `.aidlc/config.toml` に、`docs/cycles/` のサイクル成果物は `.aidlc/cycles/` に移行されます。

### Q2: v2ではLite版はどうなりましたか？
A: Lite版は廃止し、express/autoモードで代替しています。`start express` コマンドで簡略化されたフローを利用でき、`automation_mode=semi_auto` でAIレビュー通過後の自動承認が可能です。

### Q3: 既存のreviewing-*スキルは使えますか？
A: はい。reviewing-code, reviewing-architecture, reviewing-inception, reviewing-securityの各スキルは引き続き独立して使用可能です。加えて、aidlcスキルのレビューフロー内からも自動的に呼び出されます。

### Q4: プラグインのインストール方法は？
A: Claude Codeのプラグイン機構を使用してインストールします。`marketplace.json` に基づき、全スキルが一括でインストールされます。
