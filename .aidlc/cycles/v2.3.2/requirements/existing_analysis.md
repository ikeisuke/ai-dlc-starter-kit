# AI-DLC Starter Kit - Existing Codebase Analysis

**Document Purpose**: Comprehensive codebase analysis focusing on three GitHub issues (#561, #556, #546) with architecture patterns, dependencies, and implementation considerations.

**Analysis Date**: 2026-04-11  
**Scope**: `skills/aidlc/` directory structure, configuration system, phase execution model, and issue-specific code paths

---

## 1. Directory Structure Summary

### Top-Level Organization

```
skills/aidlc/
├── config/                 # Configuration layer (defaults + overrides)
│   ├── defaults.toml       # Default rule settings (automation mode, git rules, etc.)
│   └── [aliases.toml]      # Configuration key aliases (legacy support)
├── guides/                 # User-facing documentation
│   ├── branch-protection.md
│   ├── ios-version-update.md
│   ├── commit-flow.md      # Git commit patterns (Issue #546 related)
│   └── phase-recovery-spec.md
├── scripts/                # Executable infrastructure (bash/shell)
│   ├── bootstrap.sh        # Entrypoint and shared utils
│   ├── read-config.sh      # 4-layer config hierarchy (Issue #556 related)
│   ├── pr-ops.sh           # PR operations (Issue #546 related)
│   ├── operations-release.sh  # Release automation
│   ├── suggest-version.sh
│   ├── ios-build-check.sh
│   ├── validate-git.sh
│   └── lib/                # Shared libraries
│       ├── aidlc-common.sh
│       ├── toml-reader.sh
│       └── [other utilities]
├── steps/                  # Phase execution logic (markdown + checkpoints)
│   ├── common/             # Shared across phases
│   │   ├── rules-automation.md   # Semi-auto gate logic (Issue #561 core)
│   │   ├── commit-flow.md
│   │   ├── review-flow.md
│   │   └── [other shared rules]
│   ├── inception/          # Phase 1: Requirements & Planning
│   │   ├── index.md        # Phase entrypoint (binds 5 steps)
│   │   ├── 01-context.md
│   │   ├── 02-discovery.md
│   │   ├── 03-intent.md
│   │   ├── 04-stories-units.md
│   │   └── 05-completion.md
│   ├── construction/       # Phase 2: Implementation
│   │   ├── index.md
│   │   ├── 01-setup.md
│   │   ├── 02-design.md
│   │   ├── 03-implementation.md
│   │   ├── 04-integration.md
│   │   └── 05-completion.md
│   └── operations/         # Phase 3: Release & Operations
│       ├── index.md
│       ├── 01-validation.md
│       ├── 02-deploy.md
│       ├── operations-release.md  # Release workflow (Issue #546 step)
│       └── [other steps]
├── templates/              # PR/decision/context templates
│   ├── inception_pr_body_template.md
│   ├── pr_body_template.md
│   ├── context_reset_template.md
│   ├── decision_record_template.md
│   └── [other templates]
├── SKILL.md               # Master orchestration spec
└── version.txt            # Framework version

```

### Depth 2-3 Coverage

**steps/inception/** (5 step files + index binding):
- `index.md`: 239+ lines, master Inception phase coordination
  - §2.4: automation_mode branching (8 decision checkpoints)
  - §2.7: draft_pr branching logic (resolveDraftPrAction)
  - §3: Checkpoint table mapping to phase-recovery-spec
  - Binds all 5 step files via "ステップ読み込み契約"

- `04-stories-units.md`: 150 lines, Unit creation (Issue #561 context for express mode)
  - §ステップ3: User story acceptance criteria
  - §ステップ4b: Express mode complexity judgment
  - Calls "セミオートゲート判定" at line 101

- `05-completion.md`: 228 lines, Inception wrap-up
  - §ステップ5e (lines 168-185): Draft PR creation
  - Lines 170-171: Extract related Issue numbers
  - Line 185: Warning about auto-closure on merge (Issue #546 related)

**steps/operations/** (release workflow for Issue #546):
- `index.md`: 200+ lines, Operations phase coordination
  - §2.6: automation_mode branching with ユーザー選択 distinction
  - Line 107: PRマージ marked as "ユーザー選択", not gate approval

- `operations-release.md`: 79 lines, Release execution
  - §7.8 (lines 34-44): PR Ready preparation
  - **Line 44 critical**: Manual step "全関連 Issue の `Closes #XX` 記載漏れを手動照合"
  - §7.13: PR merge with final Closes confirmation

**scripts/** (executable infrastructure):
- `read-config.sh`: 452 lines (Issue #556 architecture)
  - `resolve_key()` (lines 148-261): 4-layer hierarchy evaluation
  - `resolve_with_aliases()` (lines 311-393): Canonical/legacy key normalization
  - Batch mode (lines 419-450): `--keys` flag for multiple queries
  - **No write/save functionality** (Issue #556 gap)

- `pr-ops.sh`: 401 lines (Issue #546 baseline)
  - `cmd_get_related_issues()` (lines 193-212): Issue extraction
  - Line 205: `grep -ohE '#[0-9]+' "${units_dir}"/*.md | sort -u`
  - Returns all Issues from Unit files, no Closes validation

---

## 2. Architecture Patterns Relevant to Three Issues

### Pattern A: Semi-Auto Gate Approval Model (Issue #561)

**Core Principle**: Reduce unnecessary user confirmations at phase progression checkpoints while maintaining control over critical decisions.

**Key Components**:
1. **Gate Definition** (rules-automation.md)
   - Lines 3-26: Decision logic (manual → semi_auto → auto_approved/fallback)
   - Fallback conditions: `review_not_executed`, `error`, `review_issues`, `incomplete_conditions`, `decision_required`
   - Priority ordering ensures deterministic fallback selection

2. **Automation Mode States** (defaults.toml, read-config.sh)
   - `manual`: All gates require explicit user confirmation
   - `semi_auto`: Gates auto-approve if fallback conditions absent
   - `full_auto`: (Not yet implemented; reserved for future)

3. **Gate Approval Points** (scattered across step files)
   - inception/03-intent.md line 49: "セミオートゲート判定"
   - inception/04-stories-units.md line 101: Express mode judgment
   - inception/index.md §2.4: 8 checkpoints with branching logic

4. **Critical SKILL.md Rule** (lines 84-99)
   - Gate Approval (自動化対象): `AskUserQuestion` + semi_auto fallback logic
   - ユーザー選択 (User Selection): `AskUserQuestion` only, no automation
   - 情報収集 (Information Gathering): `AskUserQuestion` only, no automation
   - **Issue #561 Root**: operations/index.md line 107 marks PRマージ as "ユーザー選択" (user selection), meaning it should NEVER auto-approve even in semi_auto mode

**Pattern Specifics**:
- Each gate calls `resolveSemiAutoGate()` logic from rules-automation.md
- Returns `auto_approved` (no confirmation needed) OR `fallback` (revert to manual)
- Fallback triggered by ANY condition in priority list

### Pattern B: 4-Layer Configuration Hierarchy (Issue #556)

**Precedence Chain** (read-config.sh resolve_key function):
```
1. Project-local:     .aidlc/config.local.toml    (highest priority)
2. Project:           .aidlc/config.toml
3. User:              ~/.aidlc/config.toml
4. System defaults:   skills/aidlc/config/defaults.toml  (lowest priority)
```

**Implementation Details**:
- `resolve_key()` evaluates all 4 layers with proper override semantics
- `resolve_with_aliases()` wraps resolve_key with legacy key mapping via `aidlc_normalize_key()` and `aidlc_get_legacy_key()`
- Batch mode (`--keys`) allows multiple key queries in single call for performance
- Config values sourced from TOML files parsed by `toml-reader.sh`

**Key Configuration Sections**:
- `[rules.automation]`: `mode` (manual/semi_auto)
- `[rules.git]`: `draft_pr`, `merge_method`, `branch_mode`, `squash_enabled`
- `[rules.depth_level]`: `level` (minimal/standard/comprehensive)
- `[project]`: `type` (general/ios)

**Issue #556 Gap**: No built-in "save to config" mechanism. All reads are one-way; no corresponding write/persist functionality exists in codebase.

### Pattern C: Issue Extraction & PR Closure Tracking (Issue #546)

**Current Implementation** (pr-ops.sh + operations-release.md):

1. **Extraction Phase** (inception/05-completion.md, pr-ops.sh)
   - Unit definition files contain "関連Issue" section with `#NNN` format
   - `get-related-issues` extracts all Issues via regex: `grep -ohE '#[0-9]+' "${units_dir}"/*.md`
   - Returns comma-separated list (e.g., "81,72")
   - Used to generate `Closes #XX` statements in PR body

2. **PR Creation** (inception/05-completion.md §ステップ5e)
   - Lines 170-171: Extract Issues, format as `Closes #XX`
   - Template: `inception_pr_body_template.md`
   - Line 185: Warning about GitHub auto-closure on merge

3. **Manual Reconciliation** (operations-release.md §7.8, line 44)
   - **Critical Manual Step**: "全関連 Issue の `Closes #XX` 記載漏れを手動照合"
   - Human must verify that ALL extracted Issues appear in PR body Closes statements
   - No automation currently validates this
   - Failure mode: Partial Issues not mentioned in Closes won't auto-close on merge

4. **Final Confirmation** (operations-release.md §7.13)
   - Line 60: PR body Closes statements checked before merge
   - Still manual validation, no automated detection

**Issue #546 Gap**: Process extracts Issues but doesn't validate that Issues in extraction match Issues in PR Closes statements. Creates manual reconciliation burden and risk of partial closure.

---

## 3. Technology Stack

### Languages & Formats
- **Markdown** (`.md`): All step instructions, templates, guides, configuration documentation
- **TOML** (`.toml`): Configuration files (defaults.toml, config.toml)
- **Bash/Shell Script** (`.sh`): All automation and execution (bootstrap.sh, read-config.sh, pr-ops.sh, operations-release.sh)

### Key Tools & Libraries
- **bash**: Primary scripting language (POSIX-compatible shell)
- **toml-reader.sh**: Custom TOML parser for configuration loading
- **gh**: GitHub CLI (used in pr-ops.sh, operations-release.sh for PR/Issue operations)
- **git**: Source control operations (branching, committing, merging)
- **grep/sed/awk**: Text processing for Issue extraction, log parsing
- **read-config.sh**: Configuration loader (not a library, but acts as configuration service)

### External APIs/Services
- **GitHub API** (via `gh` CLI): PR creation, Issue labeling, review state queries
- **Local Git Repository**: Branch management, commit history, merge operations

---

## 4. Key Files and Their Roles for Each Issue

### Issue #561: Semi-Auto Mode Causing Unnecessary Confirmations

**Primary Files**:

| File | Location | Role | Issue-Specific Content |
|------|----------|------|------------------------|
| `SKILL.md` | `/skills/aidlc/SKILL.md` | Master orchestration + AskUserQuestion rules | Lines 84-99: Defines 3 interaction types; line 98-99 specifies "ユーザー選択" NEVER auto-approves |
| `rules-automation.md` | `/skills/aidlc/steps/common/rules-automation.md` | Semi-auto gate specification + fallback conditions | Lines 3-26: Decision logic; lines 18-24: Fallback condition priority table |
| `inception/index.md` | `/skills/aidlc/steps/inception/index.md` | Phase entrypoint with 8 gate checkpoints | §2.4 (lines 72-85): Gate branching; §2.7: draft_pr logic |
| `inception/04-stories-units.md` | `/skills/aidlc/steps/inception/04-stories-units.md` | Unit creation + express mode judgment | Line 101: Calls "セミオートゲート判定" for Unit selection |
| `operations/index.md` | `/skills/aidlc/steps/operations/index.md` | Operations phase coordination | §2.6 (lines 92-111): automation_mode branching; line 107: PRマージ is "ユーザー選択" |
| `operations-release.md` | `/skills/aidlc/steps/operations/operations-release.md` | Release workflow | §7.13 (line 60): PR merge gate (ユーザー選択) |

**Key Concepts**:
- **Gate Approval** (자동화 가능): Responds to semi_auto with fallback logic
- **ユーザー選択** (User Selection): ALWAYS requires AskUserQuestion, NO automation in any mode
- **PRマージ** (PR Merge): Classified as ユーザー選択, not gate approval
- **Root Cause of #561**: Some gates currently treat PRマージ as gate approval when spec says it must always ask

**Code Patterns to Review**:
- Search for "セミオートゲート判定" calls and verify they DON'T apply to PRマージ
- Verify all `AskUserQuestion` calls for user selections don't check `automation_mode` variable
- Check that only gate approvals use `resolveSemiAutoGate()` logic

**Fix Strategy**:
1. Identify which gate confirmations are incorrectly triggering in semi_auto
2. Reclassify them as ユーザー選択 if not true phase progression gates
3. Remove automation_mode fallback logic from those AskUserQuestion calls
4. Add explicit test cases for semi_auto mode with PRマージ scenario

---

### Issue #556: Add "Save to Config" Option to Dialog UI

**Primary Files**:

| File | Location | Role | Issue-Specific Content |
|------|----------|------|------------------------|
| `read-config.sh` | `/skills/aidlc/scripts/read-config.sh` | Configuration reading (4-layer hierarchy) | Lines 148-261: resolve_key(); lines 311-393: resolve_with_aliases() |
| `defaults.toml` | `/skills/aidlc/config/defaults.toml` | Default rule values | Lines 22-46: automation, git, depth_level rules |
| `SKILL.md` | `/skills/aidlc/SKILL.md` | AskUserQuestion specification | Lines 84-99: Define dialog interaction types |
| `bootstrap.sh` | `/skills/aidlc/scripts/bootstrap.sh` | Entrypoint + shared utilities | Where AskUserQuestion results are captured |

**Architecture Context**:

Current flow:
```
AskUserQuestion (user input)
  ↓ (capture response)
Script execution (use response)
  ↓ (no persistence)
[Response lost after script execution]
```

Needed flow:
```
AskUserQuestion (user input) + "Save to config?" option
  ↓ (capture response + optional config key)
Script execution (use response)
  ↓ (if save selected)
Write-config function (add to .aidlc/config.toml)
  ↓ (on next run)
read-config.sh (reads persisted value)
```

**Implementation Considerations**:

1. **Config Layer Selection**: User must choose which layer to save to:
   - `.aidlc/config.local.toml` (project-local, highest priority)
   - `.aidlc/config.toml` (project-level)
   - `~/.aidlc/config.toml` (user-level)

2. **Key Mapping**: Must use canonical key names (via aidlc_normalize_key from toml-reader.sh)

3. **TOML Serialization**: Need function to append/update TOML section:value pairs
   - Current: read-config.sh only READS
   - Missing: write-config.sh (or similar) to WRITE

4. **AskUserQuestion Integration**: Tool must:
   - Show dialog with option checkbox: "[ ] Save this preference"
   - Accept optional `--config-key` parameter
   - Return both value + save_preference flag

5. **Affected Configuration Sections**:
   - `rules.automation.mode` (Issue #561 related)
   - `rules.git.draft_pr`
   - `rules.git.merge_method`
   - `rules.git.branch_mode`
   - `rules.depth_level.level`

**File Dependencies**:
- read-config.sh: Source to understand current precedence (no changes needed)
- toml-reader.sh: May need enhancement for write capability
- bootstrap.sh: Hook point for "save to config" action
- AskUserQuestion tool: Must support save checkbox option

---

### Issue #546: PR Closes Partial Issue Detection

**Primary Files**:

| File | Location | Role | Issue-Specific Content |
|------|----------|------|------------------------|
| `pr-ops.sh` | `/skills/aidlc/scripts/pr-ops.sh` | PR operations orchestrator | Lines 193-212: cmd_get_related_issues() extracts all Issues |
| `operations-release.md` | `/skills/aidlc/steps/operations/operations-release.md` | Release workflow (critical step) | **Line 44**: Manual reconciliation step (the gap) |
| `inception/05-completion.md` | `/skills/aidlc/steps/inception/05-completion.md` | Inception phase wrap-up | Lines 170-171: Issue extraction for Closes statements |
| `templates/pr_body_template.md` | `/skills/aidlc/templates/pr_body_template.md` | PR body structure | Where Closes statements are inserted |
| `templates/inception_pr_body_template.md` | `/skills/aidlc/templates/inception_pr_body_template.md` | PR body for Inception PRs | Template for initial Closes statements |

**Current Workflow** (Line-by-line):

1. **Inception Phase** (inception/05-completion.md §5e)
   - Extract Issues from Unit "関連Issue" sections
   - Format as Closes statements: `Closes #81, Closes #72`
   - Insert into PR body template
   - Create draft PR

2. **Operations Phase** (operations-release.md §7.8)
   - Prepare PR body for Ready-for-Review conversion
   - Line 44 **Manual Step**: "全関連 Issue の `Closes #XX` 記載漏れを手動照合"
   - Current: Human visually compares extracted Issues vs PR body Closes
   - Problem: Manual validation is error-prone, no automation

3. **PR Merge** (operations-release.md §7.13)
   - Final confirmation of Closes statements in PR body
   - Still manual: Human re-checks PR body before merge approval
   - At this point, it's too late to fix missing Closes

**Issue #546 Root Cause**:
- `get-related-issues` extracts ALL Issues from Unit files (exhaustive)
- No validation that ALL extracted Issues appear in PR body Closes statements
- Manual reconciliation step (line 44) creates friction and miss risk
- If any Issue is not in Closes, it won't auto-close on merge (product defect)

**Gap Locations**:
1. No function validates extracted_issues ⊆ pr_body_closes
2. No diff output showing "Issues not in Closes" or "Closes without extracted Issues"
3. No enforcement preventing PR merge until validation passes

**Implementation Strategy**:

New function needed:
```bash
validate_pr_closes() {
  # Input: PR body file path, cycle number
  # Extract Issues from Units: get-related-issues $cycle → $extracted_issues
  # Extract Closes from PR body: grep 'Closes #' → $closes_issues
  # Compare: $extracted_issues vs $closes_issues
  # Output: validation:success OR validation:failure with missing/extra Issues
}
```

Integration points:
1. **operations-release.md §7.8**: Call validate_pr_closes before ready-for-review
2. **operations-release.sh**: Add subcommand `validate-closes` using above function
3. **operations-release.md §7.13**: Add automated pre-merge validation step

---

## 5. Dependencies Between Components

### Dependency Chains

#### Chain 1: Configuration System Dependencies (Issue #556 Context)

```
SKILL.md
  ↓ (references automation_mode in AskUserQuestion rules)
read-config.sh
  ↓ (reads automation_mode from)
defaults.toml
  ↓ (fallback to)
.aidlc/config.toml
  ↓ (overridden by)
.aidlc/config.local.toml
```

**Missing Link**: No write/persist function (Issue #556 gap)

#### Chain 2: Phase Execution Binding (Issue #561 Context)

```
SKILL.md (Master orchestration)
  ↓ (delegates to phase)
inception/index.md
  ├─ (binds via "ステップ読み込み契約")
  ├─ 01-context.md
  ├─ 02-discovery.md
  ├─ 03-intent.md
  ├─ 04-stories-units.md (line 101: calls セミオートゲート判定)
  └─ 05-completion.md (lines 170-171: Issue extraction)
      ↓ (uses)
      pr-ops.sh (get-related-issues)
      ↓ (to populate)
      templates/inception_pr_body_template.md
      
operations/index.md (§2.6: automation_mode branching)
  ↓ (delegates to)
operations-release.md (§7.8: PR ready, §7.13: PR merge)
  ├─ (line 44: Manual reconciliation gap — Issue #546)
  └─ (line 60: Final merge gate — Issue #561 context)
```

#### Chain 3: Issue Tracking & PR Closure (Issue #546 Context)

```
inception/04-stories-units.md (Unit creation)
  ↓ (defines "関連Issue")
inception/05-completion.md (§5e: extract Issues)
  ├─ pr-ops.sh (get-related-issues)
  └─ templates/inception_pr_body_template.md
      ↓ (generates)
      Draft PR (with Closes #XX statements)
      
operations-release.md (§7.8: PR ready)
  ├─ [Current: Manual reconciliation step, line 44]
  └─ [Missing: Automated validation function — Issue #546 gap]
      ↓
      operations-release.sh (future: validate-closes subcommand)
```

### Cross-Phase Dependencies

| Dependency Type | Source | Target | Context |
|-----------------|--------|--------|---------|
| **Configuration Read** | Any step script | read-config.sh | All phases read automation_mode at gate points |
| **Phase Binding** | SKILL.md | index.md files | Each phase's index.md implements phase orchestration |
| **Step Sequencing** | Phase index.md | Step files (01-05) | Index defines execution order + gate approvals |
| **Issue Extraction** | inception/05-completion.md | pr-ops.sh | Extracts Issues from Unit files for PR body |
| **Closes Validation** | operations-release.md | pr-ops.sh (future) | Must validate extracted Issues vs PR body Closes |
| **Git Operations** | All release steps | scripts/pr-ops.sh, validate-git.sh | Create/validate/merge PRs |

### Conditional Dependencies (automation_mode)

When `automation_mode=semi_auto`:
```
rules-automation.md (resolve fallback conditions)
  ↓
inception/index.md §2.4 (gate checkpoints)
  ├─ Unit selection: auto-approve if no fallback
  ├─ Story review: auto-approve if no fallback
  └─ ... (7 other checkpoints)
  
operations/index.md §2.6 (operations gates)
  ├─ Deployment approval: auto-approve if no fallback
  ├─ [PRマージ: ALWAYS asks, never auto — Issue #561]
  └─ ...
```

---

## 6. Architecture Patterns Summary

### Pattern 1: Phase Index Binding Model

Each phase (`inception/index.md`, `construction/index.md`, `operations/index.md`) acts as a master coordinator:
- Defines execution sequence of 5 steps
- Implements gate approval logic at key checkpoints
- Binds to "ステップ読み込み契約" (step loading contract) for detail files
- Delegates automation_mode branching to rules-automation.md

**Why This Matters for Issues**:
- Issue #561: Gate approvals defined in index.md §2.4/§2.6; need to verify PRマージ is NOT included
- Issue #546: Inception index triggers Issue extraction; Operations index should add validation

### Pattern 2: Materialized Binding to External Specs

Phase files reference external specifications by section number:
- SKILL.md §2.4: automation_mode rules
- rules-automation.md: Semi-auto gate fallback conditions
- phase-recovery-spec.md: Checkpoint evaluation criteria

This binding pattern allows:
- Single source of truth (no duplication)
- Consistent automation semantics across phases
- Clear contracts for AI agent implementation

**Risk**: Binding references break silently if target files change. No validation currently exists.

### Pattern 3: Layered Configuration with Fallback

read-config.sh implements 4-layer precedence:
1. Project-local (highest)
2. Project-level
3. User-level
4. System defaults (lowest)

Supports:
- User preferences (layer 3)
- Per-project overrides (layers 1-2)
- Safe defaults (layer 4)

**Gap for Issue #556**: No reverse path to persist user responses back to config layers.

### Pattern 4: Manual Gate Checkpoints

Critical decisions require explicit human judgment:
- Yes/No approvals (承認)
- Multi-option selections (選択)
- Free-form input (入力)

Implementation:
- `AskUserQuestion` tool presents option
- Script captures response
- Automation_mode determines if fallback allowed
- Decision recorded in progress.md / history.md

**Issue #561 Problem**: Some gates incorrectly treat non-gate decisions (like PRマージ) as automation candidates.

---

## 7. Technical Debt & Known Gaps

| Issue # | Category | Gap | Impact | Notes |
|---------|----------|-----|--------|-------|
| #561 | Semi-Auto Logic | PRマージ classified as gate approval instead of user selection | Unnecessary automation in semi_auto mode | SKILL.md line 98-99 spec says ユーザー選択 never auto-approves |
| #556 | Configuration | No "save to config" capability | Users must re-answer same questions across sessions | read-config.sh is read-only; write-config.sh missing |
| #546 | Issue Tracking | Manual reconciliation of Closes statements | Risk of partial Issue closure on PR merge | Line 44 operations-release.md documents manual step; no automation |

---

## 8. Key Files by Function

### Configuration & Orchestration
- **SKILL.md**: Master specification for all phase execution + AskUserQuestion rules
- **read-config.sh**: Configuration reading (4-layer hierarchy)
- **bootstrap.sh**: Entrypoint + shared utilities

### Phase Execution
- **inception/index.md**: Inception phase coordinator (5 steps + 8 gates)
- **construction/index.md**: Construction phase coordinator
- **operations/index.md**: Operations phase coordinator

### Issue-Specific Automation
- **rules-automation.md**: Semi-auto gate fallback conditions
- **pr-ops.sh**: PR operations including Issue extraction
- **operations-release.md**: Release workflow (manual Closes validation at line 44)

### Templates & Configuration
- **defaults.toml**: Default rule values
- **inception_pr_body_template.md**: PR body structure for Inception
- **pr_body_template.md**: PR body structure for Operations

---

## 9. Implementation Notes for Issue Resolution

### Issue #561: Fix Unnecessary Confirmations
1. Audit all `AskUserQuestion` calls in operation phases for automation_mode checks
2. Reclassify PRマージ as ユーザー選択 (user selection) per SKILL.md line 98-99
3. Remove fallback logic from PRマージ gate
4. Add test case: semi_auto mode should still ask for PR merge confirmation

### Issue #556: Implement Save to Config
1. Design AskUserQuestion enhancement with optional save checkbox
2. Create write-config.sh function (inverse of read-config.sh)
3. Add --config-key parameter to gate approval questions
4. Implement persistence layer in bootstrap.sh
5. Update affected config keys: automation.mode, git.{draft_pr, merge_method, branch_mode}, depth_level.level

### Issue #546: Automate Closes Validation
1. Create validate_pr_closes() function in pr-ops.sh
2. Integration point: operations-release.md §7.8 (before PR ready)
3. Output format: List of missing Issues + extra Closes statements
4. Enforcement: Block PR ready/merge if validation fails
5. Add subcommand to operations-release.sh: validate-closes --cycle {{CYCLE}}

---

## 10. References & Document Links

**Within Codebase**:
- `/skills/aidlc/SKILL.md`: Master orchestration specification
- `/skills/aidlc/steps/common/rules-automation.md`: Semi-auto gate logic
- `/skills/aidlc/scripts/read-config.sh`: Configuration reading architecture
- `/skills/aidlc/scripts/pr-ops.sh`: PR operations including Issue extraction
- `/skills/aidlc/steps/operations/operations-release.md`: Release workflow with manual step at line 44
- `/skills/aidlc/config/defaults.toml`: Default configuration values

**Related GitHub Issues**:
- #561: Semi-auto mode causing unnecessary user confirmations
- #556: Add "save to config" option to dialog UI
- #546: PR Closes partial issue detection

---

**Document End**
