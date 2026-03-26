# ユーザーストーリー

## Epic: AI-DLC品質保証機能と運用安定性の向上

### ストーリー 1: セキュリティレビュー観点の拡充（#278）

**優先順位**: Must-have

As a AI-DLCを使う開発者
I want to セキュリティレビューでインフラ・ログ・設計原則を含む包括的な観点でチェックされる
So that セキュリティの見落としリスクを低減できる

**受け入れ基準**:

- [ ] reviewing-securityスキルのSKILL.mdに、Amazon AIDLC SECURITY-01〜15の全ルールに対応するレビュー観点が記載されている（15/15カバーを対応表で検証可能）
- [ ] 既存の3観点（OWASP Top 10、認証・認可、依存関係脆弱性）は維持されている
- [ ] 新規追加の観点は以下をカバーしている:
  - SECURITY-01: 暗号化（保存時/通信時）
  - SECURITY-02: ネットワーク中間点のアクセスログ
  - SECURITY-03: アプリケーションレベルのログ
  - SECURITY-04: HTTPセキュリティヘッダー
  - SECURITY-07: ネットワーク設定制限
  - SECURITY-09: セキュリティ硬化（既存観点の補強）
  - SECURITY-11: セキュアデザイン原則
  - SECURITY-13: ソフトウェア/データ整合性検証
  - SECURITY-14: アラート・モニタリング
  - SECURITY-15: 例外処理・フェイルセーフ
- [ ] スキルのインターフェース（呼び出し方式・出力フォーマット）は変更されていない
- [ ] プロジェクトに該当しない観点（例: ネットワーク構成がないプロジェクト）は、レビュー時にN/A判定できる旨が記載されている

**技術的考慮事項**:

- 変更対象: `prompts/package/skills/reviewing-security/SKILL.md`
- 既存の観点構造（大カテゴリ→小項目）を維持しつつ、新カテゴリを追加する

---

### ストーリー 2: 監査ログの強化（#277）

**優先順位**: Must-have

As a AI-DLCを使う開発者
I want to 履歴ログにISO 8601タイムスタンプが含まれている
So that 作業のトレーサビリティが向上し、デバッグ時に時系列を正確に追える

**受け入れ基準**:

- [ ] write-history.shの出力エントリにISO 8601形式のタイムスタンプ（`YYYY-MM-DDTHH:mm:ss±HH:MM` 形式、例: `2026-03-10T15:30:00+09:00`）が含まれている
- [ ] 既存の履歴ファイル（`history/*.md`）のMarkdownフォーマットは維持されている
- [ ] タイムスタンプは既存エントリの補完情報として追加され、既存の `grep` パターンによるステップ名・フェーズ名の読み取りに影響しない
- [ ] 旧バージョンで作成されたタイムスタンプなしの履歴エントリも引き続き読み取り可能である
- [ ] タイムスタンプの取得に失敗した場合（date コマンドエラー等）、エントリ自体の書き込みは継続され、タイムスタンプ部分のみ省略される

**技術的考慮事項**:

- 変更対象: `prompts/package/bin/write-history.sh`
- write-history.shは既にdate取得ロジックを持っているため、出力フォーマットの拡張で対応可能

---

### ストーリー 3: コンテンツバリデーション（#279）

**優先順位**: Should-have

As a AI-DLCを使う開発者
I want to コードレビュー時にASCII図やMermaid図の品質も検証される
So that 成果物ドキュメント内の図表が正確で一貫性のある状態を保てる

**受け入れ基準**:

- [ ] reviewing-codeスキルのSKILL.mdに、ASCII図・Mermaid図のバリデーション観点が追加されている
- [ ] ASCII図のバリデーション観点に以下が含まれている:
  - 罫線の接続が途切れていないこと
  - ラベルとボックスの対応が正しいこと
  - 交差線がゼロであること（不可避な場合のみ許容し、理由をコメントで記録）
- [ ] Mermaid図のバリデーション観点に以下が含まれている:
  - 対象図種別: flowchart, sequenceDiagram, classDiagram, stateDiagram, erDiagram, gantt
  - 構文が対象図種別の仕様に準拠していること
  - ノードID・ラベルに重複がないこと
- [ ] 未対応のMermaid図種別（pie, mindmap等）が含まれる場合、構文検証対象外である旨がレビュー結果に示されること

**技術的考慮事項**:

- 変更対象: `prompts/package/skills/reviewing-code/SKILL.md`
- レビュー観点の追加のみで、ツール実行ロジックの変更は不要

---

### ストーリー 4: テンポラリファイル出力先規約の策定

**優先順位**: Must-have

As a AI-DLCプロンプトの保守者
I want to テンポラリファイルの出力先ディレクトリの規約が定義されている
So that プロンプト記述の一貫性が保たれ、ファイルパスの衝突や散在を防げる

**受け入れ基準**:

- [ ] `common/rules.md` にテンポラリファイル出力先ディレクトリの規約が定義されている
- [ ] 規約には以下が含まれている:
  - 出力先ディレクトリパス（例: `/tmp/aidlc/`）
  - ファイル命名規則（例: `{用途}-{ランダム}.txt`）
  - 使用後の削除義務
- [ ] 規約外のパスを使用した場合、AIがプロンプト指示に従い規約パスを使用する旨が明記されている

**技術的考慮事項**:

- 変更対象: `prompts/package/prompts/common/rules.md`

---

### ストーリー 5: 既存プロンプトのテンポラリファイルパス統一

**優先順位**: Must-have

As a AI-DLCプロンプトの保守者
I want to 既存プロンプト内のテンポラリファイルパス記述がストーリー4の規約に統一されている
So that 全プロンプトで一貫したファイルパス管理が実現される

**受け入れ基準**:

- [ ] `CLAUDE.md` 内の固定パス（`/tmp/commit-msg.txt`）がストーリー4の規約に従ったパスに更新されている
- [ ] `common/rules.md` 内の `<一時ファイルパス>` プレースホルダーの説明が規約セクションを参照する形に更新されている
- [ ] `common/commit-flow.md` 内の一時ファイル記述が規約と整合していること
- [ ] `common/review-flow.md` 内の一時ファイル記述が規約と整合していること
- [ ] `squash-unit/SKILL.md` 内のテンポラリファイルパス（`/tmp/squash-msg.txt`）が規約に統一されている
- [ ] 上記5ファイルの全一時ファイルパス記述が規約準拠であることをチェックリストで検証済みであること

**技術的考慮事項**:

- 変更対象ファイル一覧（5ファイル）:
  1. `prompts/package/prompts/CLAUDE.md`
  2. `prompts/package/prompts/common/rules.md`
  3. `prompts/package/prompts/common/commit-flow.md`
  4. `prompts/package/prompts/common/review-flow.md`
  5. `prompts/package/skills/squash-unit/SKILL.md`
- ストーリー4（規約策定）完了後に実施
