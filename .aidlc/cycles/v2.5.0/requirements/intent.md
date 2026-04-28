# Intent（開発意図）

## プロジェクト名

AI-DLC Starter Kit v2.5.0（自己改善ループ導入）

## 開発の目的

empirical-prompt-tuning（v2.3.6 サイクルで試行）の知見である「skill 構造の改善余地」を運用データとして継続的に蓄積し、AI-DLC 自身が改善ループを回せる仕組みを導入する。具体的には:

1. 各 Operations 完了時に **「なぜ間違えたか」を記録する retrospective フロー** を組み込み、修正コミットだけでは残らないプロセス学習を残す
2. retrospective から **skill 起因の問題を切り出して upstream（本リポジトリ）にフィードバック** する経路を `mirror` モードとして整備する
3. 上記を実現する前提として、現状 `config.toml.template` に書かれている **「個人好み」設定を 4 階層設計（skill/defaults・user-global・project 共有・project 個人）に整理** し、利用者ごとの設定揺れを user-global に寄せる

## ターゲットユーザー

| 区分 | 想定ペルソナ | 期待効果 |
|------|-------------|---------|
| **AI-DLC 利用開発者**（個人/チーム） | 自プロジェクトで AI-DLC を運用する | retrospective.md でプロセス学習。`mirror` モードで upstream への改善提案を「下書き + 承認送信」で安全に実施 |
| **メタ開発者**（本リポジトリ） | AI-DLC 自体を開発する | retrospective から skill 構造欠陥が定量的に蓄積され、次サイクルの改善 Issue の根拠として使える |
| **チームリード** | 複数プロジェクトで AI-DLC 設定を統一したい | `~/.aidlc/config.toml` で個人好みを一括制御、project 共有が軽量化 |

## ビジネス価値

- **改善の根拠が「事故後」から「retrospective + 自動下書き」へ前倒し**: v2.3.6 サイクルでは Codex マージ前レビューで 5 反復した。同種の指摘を retrospective でクラスタリングして次サイクル冒頭に共有することで、Construction Phase の指摘反復回数を削減する
- **個人好みの project 共有漏出を防止**: 現状 `rules.reviewing.mode` 等 7 キーが setup 時に `project .aidlc/config.toml` に固定書き込みされる。本サイクル後は user-global 推奨に切り替わり、チーム開発時の「特定メンバー選好の混入事故」を防ぐ
- **AI-DLC スターターキット自体の進化サイクルが短縮される**: メタ開発リポで `mirror` モードを実運用し、利用者から Issue が上がる前に自分たちで改善 PR を発行できる経路が整う

### 観測指標（KPI）

| KPI | ベースライン | 目標 | 測定タイミング |
|-----|------------|------|--------------|
| Operations Phase の Codex マージ前レビュー指摘件数（中・高重要度） | v2.3.6 サイクル: 5 反復で 7〜8 件相当 | **v2.5.0 + 2 サイクル時点で平均 30% 減** | v2.5.0 後の 2 サイクル分の Codex レビュー指摘ログを比較 |
| skill 起因として `mirror` 経由で起票される upstream Issue 件数 | v2.5.0 以前: 0 件 | **v2.5.0 リリース後初回 Operations で 1〜3 件**（feedback_max_per_cycle のデフォルト 3 を上限） | retrospective.md の skill 起因判定数を集計 |

## 成功基準

| # | 基準 | 検証方法 |
|---|------|---------|
| 1 | v2.5.0 リリース後の最初の Operations Phase 完了時に `operations/retrospective.md` が自動生成される | テンプレートインスタンス化 + 自記録の 3 問自問が記録されている |
| 2 | `feedback_mode=mirror` 設定下で、retrospective から「下書き提示 → ユーザー承認 → upstream Issue 起票」のフローが動作する | E2E 手順で **(a)** 下書き本文生成（Markdown スニペット出力）、**(b)** `AskUserQuestion` で承認取得（`はい` 選択時に進行）、**(c)** `gh issue create` 成功（Issue URL 採番を stdout で確認） の 3 段階すべてが順に完了する |
| 3 | 個人好み 7 キー（`rules.reviewing.mode` / `rules.reviewing.tools` / `rules.automation.mode` / `rules.git.squash_enabled` / `rules.git.ai_author` / `rules.git.ai_author_auto_detect` / `rules.linting.enabled`）が `defaults.toml` + user-global で完結する | template から削除済み + defaults.toml にデフォルト値あり + user-global で上書き可能なテストケース通過 |
| 4 | 既存プロジェクトが `aidlc-migrate` 実行時に「個人好みキーを user-global へ移動するか」を提案するが強制しない | migrate のドライラン出力を確認、ユーザーが「いいえ」を選んだ場合に既存ファイルを変更しないことを確認 |
| 5 | 同一サイクル内で同種の retrospective 項目（重複）が検出され、「サイクル毎上限」を超えると以後はローカル記録のみに切り替わる | 重複検出 + 上限ロジックのユニットテストがパス |
| 6 | `aidlc-setup` 新規セットアップ時、ウィザードが「個人好みは ~/.aidlc/config.toml に書くことを推奨」する案内を出す | セットアップ画面の手動確認、または対話ログ録画で確認 |

## 期限とマイルストーン

| マイルストーン | 想定タイミング |
|---------------|--------------|
| Inception 完了（本ドキュメント承認 + Unit 定義承認） | 本セッション内 |
| Construction Phase 1（#592 完全完了） | 1 セッション以内 |
| Construction Phase 2（#590 コア完了） | Phase 1 直後 |
| Operations / リリース（v2.5.0 タグ） | Construction 完了直後 |

## 制約事項

### 技術的制約

- **依存順序**: `#592 4 階層設計の整理` を完全完了してから `#590 振り返りステップ` に着手する。`#590` は `defaults.toml` の `retrospective.feedback_mode` 配置先に `#592` の整理結果を前提とする
- **skill 起因判定の厳格化**: 緩い判定だと upstream Issue が氾濫するため、3 問自問の少なくとも 1 つで「Yes」と明示できないものは upstream 候補にしない（retrospective ローカル記録のみ）
- **後方互換**: 既存プロジェクトの `.aidlc/config.toml` に書かれた「個人好み」キーは引き続き読み取り可能。新規 setup と migrate 提案でのみ整理を促す

### 4 階層設定の優先順位【確定】

`#592` の前提に基づき、4 階層は以下の優先度（**右に行くほど勝つ**）で動作する。本サイクルは本順序を不変前提として設計する:

```text
defaults.toml  <  ~/.aidlc/config.toml  <  .aidlc/config.toml  <  .aidlc/config.local.toml
（skill内蔵）       （user-global）          （project共有）       （project個人）
```

**設定キー競合時の挙動**:

- 同一キーが複数階層に存在 → 上記優先順序の右側が勝つ（既存 `read-config.sh` のマージ仕様を維持）
- 配列値（例: `rules.reviewing.tools`）は完全置換（マージしない、既存仕様）
- 旧プロジェクトで `.aidlc/config.toml` に「個人好みキー」が残っている場合: project 共有の値が引き続き有効。`aidlc-migrate` が「user-global へ移動するか」を**毎回**提案するが、ユーザーが「いいえ」を選択した場合は黙って続行する

### 重複検出のスコープ【確定】

`#590` (7-a) 重複検出は **同一サイクル内 retrospective 内** に限定する。過去サイクル横断（`gh issue list --search` で類似性 AI 判定）は v2.6.x 以降の拡張として分離する（解釈ブレ防止のため）。

### feedback_mode 値の正式定義【確定】

`[rules.retrospective] feedback_mode` の許容値と挙動を本ドキュメントで一元定義する。各 Unit / ストーリーは本テーブルの語彙に揃える:

| 値 | retrospective.md 自動生成 | mirror フロー（下書き生成 → 承認 → 起票） | 既定値 |
|----|--------------------------|----------------------------------------|--------|
| `silent`（デフォルト） | 行う（ローカル記録のみ） | 行わない | ○ |
| `mirror` | 行う | 行う（`AskUserQuestion` で承認、`gh issue create` で upstream Issue 起票） | - |
| `disabled` | **行わない**（テンプレート生成・サブステップ実行を全てスキップ） | 行わない | - |

**注**: `on` モード（自動起票）は v2.5.0 スコープ外。v2.6.x 以降で追加予定。

### 含まれるもの【スコープ】

| 区分 | 項目 | 出典 |
|------|------|------|
| #592 全項目 | (a) `config.toml.template` から個人好み 7 キー除去 | #592 実装スコープ 1 |
| #592 全項目 | (b) `defaults.toml` に未収録分のデフォルト値追加 | #592 実装スコープ 2 |
| #592 全項目 | (c) `aidlc-setup` ウィザードの推奨案内追加 | #592 実装スコープ 3 |
| #592 全項目 | (d) `aidlc-migrate` の「個人好みキー移動」提案ロジック追加 | #592 実装スコープ 4 |
| #590 コア | (1) `templates/retrospective_template.md` 作成 | #590 実装スコープ 1 |
| #590 コア | (2) `steps/operations/04-completion.md` に retrospective ステップ追加 | #590 実装スコープ 2 |
| #590 コア | (3) skill 起因判定フレーム（3 問自問）の組み込み | #590 実装スコープ 3 |
| #590 コア | (4) `defaults.toml` に `retrospective.feedback_mode = "silent"` 追加 | #590 実装スコープ 4 |
| #590 コア | (5) `mirror` モード時の `/aidlc-feedback` 連動（下書き生成 + 送信確認） | #590 実装スコープ 5 |
| #590 コア | (7-a) 氾濫緩和: 重複 Issue 検出 | #590 実装スコープ 7 |
| #590 コア | (7-b) 氾濫緩和: サイクル毎上限（`feedback_max_per_cycle` のデフォルト 3） | #590 実装スコープ 7 |

### 含まれないもの【スコープ外】

| 区分 | 項目 | 取り扱い |
|------|------|---------|
| #590 | (6) `on` モード（メタ開発向け）自動起票フロー | 運用データ蓄積後、v2.6.x 以降で別 Issue として再評価 |
| #590 | (7-c) 氾濫緩和: 優先度フィルタ（自動起票候補/Mirror 推奨の振り分け） | 同上、`on` モード追加と同サイクルで実装 |
| #590 関連 | A1-3 パッチ提案（upstream PR 自動生成） | 別 Issue で追跡。運用データが溜まってから検討 |
| #590 関連 | review-flow.md の指摘対応判断フローと連動（過去指摘クラスタリング） | 機能が独立、別 Issue |
| 既存サイクル | retrospective.md の遡及生成 | 行わない。v2.5.0 リリース後に開始する Operations Phase からのみ生成 |
| #617 | version 管理を marketplace.json に一本化 | priority:high だが今サイクル out of scope（次サイクル候補） |

## 不明点と質問（Inception Phase中に記録）

### Q1. retrospective.md の格納パス【確定】

[Question] retrospective.md は `.aidlc/cycles/{{CYCLE}}/operations/retrospective.md` でよいか? それとも `history/` 配下か?
[Answer] **`.aidlc/cycles/{{CYCLE}}/operations/retrospective.md` に確定**。理由: 「サイクル単位の振り返り」は operations 完了の成果物として位置付け、`history/` は AI 対話ログの追記専用とする既存慣行を踏襲する

### Q2. mirror モードの送信先【確定】

[Question] `mirror` モードで作成される upstream Issue のリポジトリは `ikeisuke/ai-dlc-starter-kit` 固定か、設定可能にするか?
[Answer] **既存 `/aidlc-feedback` スキルの送信先設定を流用**することに確定。固有設定は追加しない。`/aidlc-feedback` がリポジトリ指定機能を持っていれば自動的に同じ機能が `mirror` モードでも使える（実装上はスキル呼び出しの引数で `--reason mirror` 等のフラグを渡すのみ）

### Q3. 重複検出のスコープ【確定】

[Question] 「重複 Issue 検出」は同サイクル内 retrospective での重複か、過去サイクルも含めるか?
[Answer] **同一サイクル内 retrospective に限定**。過去サイクル横断（AI 類似判定）は v2.6.x 以降に分離する（本ドキュメント上「重複検出のスコープ」セクション参照）

### Q4. 個人好みキーの旧プロジェクト互換【Construction 設計時に確定】

[Question] migrate 時に「移動を提案する」だけだが、ユーザーが「いいえ」を継続選択した場合のガイドラインはあるか?
[Answer] **本 Intent では「黙って続行する」までを確定**（4階層設定の優先順位セクション参照）。提案 UI の細部（「次回も提案する」「再提案抑制」のオプション化等）は Construction 設計時に確定する。**Inception 完了条件としては Q1〜Q3 のみ要求**し、Q4 は Construction 設計時に詳細化する

---

**進捗**: 本 Intent はステップ1（Intent 明確化）の成果物。AI レビュー（codex）後、ユーザー承認を経て Unit 定義へ進む。
