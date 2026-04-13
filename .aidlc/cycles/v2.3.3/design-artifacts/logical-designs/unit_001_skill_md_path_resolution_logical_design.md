# 論理設計: Unit 001 SKILL.mdパス解決ルール修正

## 変更箇所
`skills/aidlc/SKILL.md` L238

## Before
```
- **パス解決**: `steps/` および `scripts/` で始まるパスは...
```

## After
```
- **パス解決**: `steps/`、`scripts/`、`config/`、`templates/`、`guides/`、`references/` で始まるパスは...
```

## 設計判断
- 既存の記述パターン（中黒区切り）に合わせる
- ステップファイル内相互参照の例文は `steps/` のまま維持（代表例として十分）
- SKILL.md 500行制約: 行数増加なし（同一行内での文言追加）
