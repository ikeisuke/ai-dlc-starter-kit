# Unit: セットアップスクリプトのシェル互換性修正

## 概要
setup-prompt.md および setup.md のスクリプトで使用している grep -oP を、macOS/zsh でも動作する代替実装に置き換える。

## 含まれるユーザーストーリー
- ストーリー 1.1: zsh互換性の確保

## 責務
- grep -oP を grep -E + sed に置き換え
- bash/zsh 両方で同一スクリプトが動作することを保証

## 境界
- スクリプトの構文修正のみ
- 新機能の追加は行わない

## 依存関係

### 依存する Unit
- なし

### 外部依存
- grep (POSIX互換)
- sed (POSIX互換)

## 非機能要件（NFR）
- **パフォーマンス**: 現状と同等
- **セキュリティ**: 該当なし
- **スケーラビリティ**: 該当なし
- **可用性**: macOS (zsh), Linux (bash) で動作

## 技術的考慮事項
- macOS のデフォルト grep は BSD grep であり、-P オプションをサポートしない
- grep -E (拡張正規表現) + sed の組み合わせで同等の機能を実現

**修正前**:
```bash
grep -oP 'starter_kit_version\s*=\s*"\K[^"]+' docs/aidlc.toml
```

**修正後**:
```bash
grep -E 'starter_kit_version\s*=\s*"[^"]+"' docs/aidlc.toml | sed 's/.*"\([^"]*\)".*/\1/'
```

## 対象ファイル
- prompts/setup-prompt.md (行56付近)
- prompts/package/prompts/setup.md (行73付近)

## 実装優先度
High

## 見積もり
小規模な文字列置換のみ

---
## 実装状態

- **状態**: 完了
- **開始日**: 2025-12-29
- **完了日**: 2025-12-29
- **担当**: AI
