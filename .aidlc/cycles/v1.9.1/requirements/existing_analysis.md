# 既存コード分析

## 対象Issue別の分析

### #94 サイクル一覧取得時の不要項目除外

**対象ファイル**: `prompts/package/prompts/setup.md`

**現状（234-235行目付近）**:
```bash
ls -d docs/cycles/* 2>/dev/null | sort -V
```

**問題点**:
- `docs/cycles/backlog/`、`docs/cycles/backlog-completed/`、`docs/cycles/operations.md`、`docs/cycles/rules.md` が含まれる

**修正案**:
```bash
ls -d docs/cycles/v*/ 2>/dev/null | sort -V
```

---

### #93 env確認の重複解消

**対象ファイル**: `prompts/package/prompts/setup.md`

**現状**:
- ステップ1（51-66行目）: `env-info.sh` と `check-backlog-mode.sh` で gh status を確認
- 63-66行目に「この出力を会話コンテキストに保持し、以降のステップでは再実行しない」と記載あり

**問題点**:
- Issue記載と現状に差異あり（ステップ4でのgh auth status重複は確認できず）
- 運用ルールとして記載はあるが、後続ステップで参照する仕組みが明確でない

**修正案**:
- 環境確認結果を変数として保持し、後続ステップで明示的に参照するフローを追加

---

### #97 setup-prompt.md: 確認系処理のスクリプト化

**対象ファイル**: `prompts/setup-prompt.md`

**スクリプト化候補**:
1. バージョン比較処理（109-126行目）: aidlc.toml vs version.txt
2. 設定ファイル存在確認（109-111行目）: aidlc.toml, project.toml
3. セットアップ種類判定ロジック（109-219行目）
4. マイグレーション対象の確認（223-274行目）

**既存スクリプト（参考）**:
- `docs/aidlc/bin/check-backlog-mode.sh`
- `docs/aidlc/bin/check-gh-status.sh`
- `docs/aidlc/bin/env-info.sh`

**修正案**:
- `check-setup-type.sh`: セットアップ種類を判定（初回/アップグレード/移行）
- `check-version.sh`: バージョン比較を実行

---

### #102 開始プロンプトの圧縮・統合

**対象ファイル**:
- `prompts/package/prompts/setup.md`
- `prompts/setup-prompt.md`

**圧縮候補**:
1. AI-DLC手法の要約（setup.md 5-24行目）: 他プロンプトと重複
2. ステップの統合: init-cycle-dir.sh でbacklogディレクトリも作成可能
3. 冗長な説明の削減: エラーケースの詳細説明等

**影響範囲**:
- inception.md, construction.md, operations.md にも共通セクションあり
- `common/intro.md` として既に共通化済みの部分もある

---

### #100 コンテキストコンパクション時のAIDLC情報保持

**対象ファイル**:
- `CLAUDE.md`（プロジェクトルート）
- `docs/aidlc/prompts/CLAUDE.md`

**現状**:
- CLAUDE.md は `@docs/aidlc/prompts/CLAUDE.md` を参照するのみ
- コンパクション時に保持すべき情報の指定なし

**失われる情報（Issue記載）**:
- フェーズ・サイクル情報
- コミット実行忘れ
- フェーズ完了後の次フェーズへの誘導

**修正案**:
- CLAUDE.md または AGENTS.md に「コンパクション時に保持すべき情報」セクションを追加
- 例: 「現在のサイクル: vX.X.X」「現在のフェーズ: Construction」「最後に完了したUnit: 002」

---

### #92 Co-Authored-By設定の柔軟化

**対象ファイル**:
- `docs/aidlc.toml`
- `prompts/package/prompts/common/rules.md`
- 各フェーズプロンプト（コミットメッセージ生成箇所）

**現状**:
- Co-Authored-By は各プロンプト内で固定値（`Claude Opus 4.5 <noreply@anthropic.com>`）
- aidlc.toml に設定項目なし

**修正案**:
1. `docs/aidlc.toml` に `[rules.commit]` セクション追加:
   ```toml
   [rules.commit]
   ai_author = "Claude Opus 4.5 <noreply@anthropic.com>"
   ```
2. 各プロンプトでこの設定を参照するよう修正
3. 未設定時のデフォルト値を定義

---

## 影響範囲まとめ

| Issue | 主な変更ファイル | 影響範囲 |
|-------|-----------------|---------|
| #94 | setup.md | 小（1箇所の修正） |
| #93 | setup.md | 小（フロー明確化） |
| #97 | setup-prompt.md, bin/ | 中（スクリプト追加） |
| #102 | 各プロンプト | 中（複数ファイル編集） |
| #100 | CLAUDE.md, AGENTS.md | 小（セクション追加） |
| #92 | aidlc.toml, 各プロンプト | 中（設定追加+参照修正） |
