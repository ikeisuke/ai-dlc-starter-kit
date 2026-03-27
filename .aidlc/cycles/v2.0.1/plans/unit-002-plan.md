# Unit 002 計画: 旧ディレクトリ移行・削除

## 概要

`docs/aidlc/` 配下の旧ディレクトリ（templates, bin, config, skills）は既に削除済み。残る作業は以下3点:

1. **旧パス参照の更新**: `prompts/package/`, `skills/`, `docs/aidlc/guides/`, `bin/`, `.kiro/agents/` 内の旧パス参照をv2パスに一括更新
2. **`.kiro/agents/aidlc-poc.json` の修正**: `docs/aidlc/bin/` → `skills/aidlc/scripts/`、`docs/aidlc/prompts/AGENTS.md` → `skills/aidlc/AGENTS.md`
3. **`.claude/skills/` シンボリックリンク確認**: 既に正しく設定済み（`../../skills/aidlc` 等）であることを確認

## コンテキスト境界

| コンポーネント | 役割 | 依存方向 |
|-------------|------|---------|
| `skills/aidlc/` | 正本（Canonical Source） | なし（最上位） |
| `skills/aidlc/templates/`, `skills/aidlc/config/` | 正本の一部 | `skills/aidlc/` に内包 |
| `.claude/skills/` | Adapter（シンボリックリンク） | → `skills/` を参照 |
| `.kiro/agents/` | Adapter（エージェント定義） | → `skills/aidlc/`, `docs/aidlc/kiro/` を参照 |
| `docs/aidlc/guides/` | Documentation Consumer | → `skills/aidlc/` を参照可 |
| `prompts/package/` | Legacy Source（v2.0.2で廃止予定） | → `skills/aidlc/` を参照 |

**依存ルール**: Adapter/Consumer → Canonical Source の単方向のみ許可。逆方向は禁止。

## 変更対象ファイル

### 旧パス参照更新対象（53ファイル）

| カテゴリ | ファイル数 | 主な置換 |
|---------|----------|---------|
| `prompts/package/` | 35 | `docs/aidlc/templates/` → `skills/aidlc/templates/`、`docs/aidlc/config/` → `skills/aidlc/config/`、`docs/aidlc/bin/` → `skills/aidlc/scripts/`、`docs/aidlc/skills/` → `skills/`、`docs/aidlc/prompts/` → `skills/aidlc/steps/` |
| `skills/` | 5 | 同上 |
| `docs/aidlc/guides/` | 12 | 同上 |
| `.kiro/agents/aidlc-poc.json` | 1 | `docs/aidlc/bin/.*` → `skills/aidlc/scripts/.*`、`file://docs/aidlc/prompts/AGENTS.md` → `file://skills/aidlc/AGENTS.md` |

### 確認のみ（変更不要）

- `.claude/skills/` シンボリックリンク: 7件すべて `../../skills/*` を正しく参照
- `docs/aidlc/guides/`, `docs/aidlc/kiro/`, `docs/aidlc/lib/`: 削除対象外（境界で維持）

### 後方互換性

- `.kiro/agents/aidlc-poc.json` はリポジトリ内部のPoC設定であり外部公開APIではない。直接パス更新で問題なし
- `prompts/package/` 内の参照更新は、次回 `/aidlc-setup` 実行時にユーザープロジェクトに反映される

## 実装計画

### Phase 1: 設計

1. **ドメインモデル**: パス置換マッピングの定義
2. **論理設計**: 置換ルールと影響範囲の特定

### Phase 2: 実装

1. パス置換マッピングに基づく一括更新
2. `.kiro/agents/aidlc-poc.json` の個別修正
3. 動作確認（既存テスト実行 + 参照整合性チェック）

## 完了条件チェックリスト

- [x] #415 B1: `docs/aidlc/templates/` 参照が活性ファイルから0件
- [x] #415 B3: `docs/aidlc/config/` 参照が活性ファイルから0件
- [x] #415 B4: `docs/aidlc/skills/` 参照が活性ファイルから0件（`.claude/skills/` シンボリックリンク確認済み）
- [x] #415 B7: `.claude/skills/` シンボリックリンクが正しく設定済み（7件すべてOK）
- [x] #414 D3: `docs/aidlc/prompts/CLAUDE.md` 参照が更新済み
- [x] #414 D5: `.kiro/agents/aidlc-poc.json` の旧パスが修正済み
- [x] `docs/aidlc/bin/` 参照が活性ファイルから0件（v1フォールバック除く）
- [x] エントリポイントMD: 不要（`docs/aidlc/` 直下にMDファイルは既に存在しない）
- [x] 参照整合性チェック: grep検査で旧パスの残存が0件（活性ファイル対象）
- [x] JSON resource確認: `.kiro/agents/aidlc-poc.json` のresources参照先が存在
- [x] シンボリックリンク解決確認: `.claude/skills/` 全リンクのターゲットが存在
