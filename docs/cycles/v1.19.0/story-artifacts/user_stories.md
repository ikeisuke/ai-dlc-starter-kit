# ユーザーストーリー

## Epic 1: Amazon AIDLCエッセンス取り込み

### ストーリー 1: AIの過信防止原則の導入
**優先順位**: Must-have

As a AI-DLCを利用するAIエージェント
I want to 確信度が低い場合は推測せず質問するルールが共通ルールに明文化されている
So that 推測による誤った実装や不要な手戻りを回避し、開発者の意図に沿った正確な作業ができる

**受け入れ基準**:
- [ ] `prompts/package/prompts/common/rules.md` に「Overconfidence Prevention原則」セクションが追加されている
- [ ] 原則として「確信度が低い場合は推測せず質問する」「複数の解釈が可能な場合はすべての選択肢を提示する」「仮定を置く場合は明示的に宣言する」が記載されている
- [ ] 既存の「予想禁止・一問一答質問ルール」（rules.md L52-80）を包含する形で再構成されており、重複するルールが統合され矛盾がない（差分確認: 旧ルールの各項目が新セクション内にマッピングされていること）
- [ ] 全フェーズ（Inception/Construction/Operations）で共通ルールとして適用される（各フェーズプロンプトのrules.md読み込み指示が既存のため、追加設定不要で適用されることを確認）
- [ ] 確信度の判定基準が不明確な場合のデフォルト動作として「質問する」がルールに明記されている

**技術的考慮事項**:
- 既存の「予想禁止・一問一答質問ルール」（rules.md L52-80）を包含する形で体系化
- Amazon AIDLC の overconfidence-prevention.md を参照元として活用（MIT-0ライセンス）

---

### ストーリー 2: 成果物詳細度の適応的制御
**優先順位**: Must-have

As a AI-DLCを利用する開発者
I want to タスクの複雑度に応じて成果物の詳細度をminimal/standard/comprehensiveの3段階で制御できる
So that シンプルなバグ修正に30分かかるInception Phaseを省力化し、複雑な機能開発では十分な検討を確保できる

**受け入れ基準**:
- [ ] `docs/aidlc.toml` に `[rules.depth_level]` セクションが追加され、`level = "minimal" | "standard" | "comprehensive"` を設定可能
- [ ] デフォルト値が `standard` であり、未設定時は現行動作（すべての成果物を標準的な詳細度で作成）と同等
- [ ] `minimal` 設定時: Inception PhaseでPRFAQ作成がスキップされ、ユーザーストーリーの受け入れ基準が簡略化される（ただし主要なエラーケースは維持）
- [ ] `comprehensive` 設定時: 各成果物に追加セクション（リスク分析、代替案検討等）が含まれる
- [ ] 各フェーズプロンプト（inception.md, construction.md, operations.md）にDepth Level判定ロジックが組み込まれている
- [ ] `common/rules.md` にDepth Levelの共通仕様（各レベルの定義、レベル別の成果物要件一覧）が記載されている
- [ ] 無効な `level` 値（typo等）が設定された場合、警告を表示し `standard` にフォールバックする旨がルールに記載されている

**技術的考慮事項**:
- テンプレートファイル自体は変更せず、プロンプト内の指示で詳細度を調整する方式を推奨
- `[rules.history].level` との混同を避ける命名（`depth_level`）
- Amazon AIDLC の depth-levels.md を参照元として活用
- 本ストーリーは設定・共通ルール・各フェーズプロンプトの3領域にまたがるため、Unit定義時に適切に分割する

---

### ストーリー 3: 既存コードベースの体系的解析
**優先順位**: Should-have

As a brownfieldプロジェクトにAI-DLCを適用する開発者
I want to Inception Phaseで既存コードベースの構造・パターン・技術スタックを体系的に解析できる
So that 既存コードとの整合性を保った設計ができ、既存パターンに反する実装による技術的負債を防止できる

**受け入れ基準**:
- [ ] Inception Phase ステップ2のプロンプトが「Reverse Engineering」として拡張され、解析手順が明記されている
- [ ] 解析手順に以下の4項目が含まれている:
  - ディレクトリ構造・ファイル構成の解析
  - 使用パターン・アーキテクチャの検出（MVC、レイヤードアーキテクチャ等）
  - 技術スタック推定（言語、フレームワーク、主要ライブラリ）
  - 依存関係マッピング（内部モジュール間、外部ライブラリ）
- [ ] 解析結果が `docs/cycles/{{CYCLE}}/requirements/existing_analysis.md` に、セクション見出し付きのMarkdown形式で記録される
- [ ] greenfieldプロジェクトでは引き続きスキップされる（プロンプト内のConditional分岐で制御）
- [ ] 解析中にエラーが発生した場合（ファイル読み取り不可、依存関係解決失敗等）、取得済みの解析結果を記録した上で未完了箇所を明示し、継続可否をユーザーに確認する旨がプロンプトに記載されている

**技術的考慮事項**:
- 既存のステップ2の基盤を活用し、手順を具体化する拡張
- Amazon AIDLC の reverse-engineering.md を参照元として活用
- 大規模コードベースではサブエージェントによる並行解析を推奨

---

### ストーリー 4: セッション中断・再開の正式サポート
**優先順位**: Must-have

As a 長時間の開発タスクを行う開発者
I want to セッション中断時に作業状態が自動保存され、再開時にコンテキスト喪失なく作業を継続できる
So that セッション中断後の状態再構築に費やす時間を削減し、中断前の作業をシームレスに継続できる

**受け入れ基準**:
- [ ] コンテキストリセット提示時およびユーザーの明示的な中断指示時に、`docs/cycles/{{CYCLE}}/{phase}/session-state.md` が自動生成される
- [ ] session-state.mdに以下の必須項目が含まれる: サイクル番号、フェーズ、現在のステップ、完了済みステップ一覧、未完了タスク、次のアクション
- [ ] 再開プロンプト実行時にsession-state.mdが存在すれば自動読み込みされ、中断時点のステップから作業が再開される
- [ ] 既存のcompaction.md（自動要約後の復元）・context-reset.md（手動リセット時の継続）の指示フローにsession-state.md生成ステップが追加されている
- [ ] session-state.mdの生成が失敗した場合（ファイル書き込みエラー等）でも、既存のprogress.md・履歴ファイルによる復元が可能（フォールバック）
- [ ] session-state.mdが存在しない状態での再開時は、既存のprogress.mdから状態を復元する（新規インストール環境との互換性）

**技術的考慮事項**:
- 既存のcompaction.md、context-reset.mdを発展させる形で実装
- progress.mdとの二重管理にならないよう、session-state.mdはprogress.mdの情報を包含する上位セットとする
- Amazon AIDLC の session-continuity.md を参照元として活用

---

## Epic 2: コードベース整理

### ストーリー 5: jjサポート関連処理の削除
**優先順位**: Must-have

As a AI-DLCスターターキットの保守者
I want to 別リポジトリに移植済みのjjサポート関連処理が本体から削除されている
So that jj関連コードの保守負担をなくし、プロンプトの可読性と保守性を向上できる

**受け入れ基準**:
- [ ] `prompts/package/skills/versioning-with-jj/` ディレクトリ全体が削除されている
- [ ] `prompts/package/prompts/common/rules.md` からjjサポート設定セクション（L20-21, L86-90）・コマンド読み替え指示（L157）が除去されている
- [ ] `prompts/package/prompts/common/commit-flow.md` からjj環境固有のフロー（状態確認・コミット・squash、計10箇所）が除去されている
- [ ] `prompts/package/prompts/common/ai-tools.md` からjjスキル参照行（L25）が除去されている
- [ ] `prompts/package/prompts/inception.md`、`construction.md`、`operations.md` からjj固有の注釈が除去されている
- [ ] `docs/aidlc.toml` の `[rules.jj]` セクションは設定キーとして残り、`enabled = true` の場合にプロンプト内で「jjサポートはv1.19.0で削除されました。versioning-with-jjスキルを別途インストールしてください」と警告が表示される
- [ ] スクリプト（env-info.sh、aidlc-cycle-info.sh、aidlc-env-check.sh、aidlc-git-info.sh、squash-unit.sh、migrate-config.sh）からjj関連処理が除去されている
- [ ] jj関連処理の除去後、git処理のみの環境で既存の動作が正常に機能する（確認対象: `squash-unit.sh`でのgit squash、`env-info.sh`でのブランチ情報取得、`commit-flow.md`に従ったコミットフロー）

**技術的考慮事項**:
- `docs/aidlc/` は `prompts/package/` のrsyncコピーなので、`prompts/package/` のみ編集（`docs/aidlc.toml` はプロジェクト設定ファイルであり直接編集対象）
- スクリプトからjj関連処理を除去する際、git処理への影響がないことを確認
- squash-unit.shのjj実装（約100行）は完全削除
- 本ストーリーはプロンプト除去とスクリプト除去の2領域にまたがるため、Unit定義時に適切に分割する
