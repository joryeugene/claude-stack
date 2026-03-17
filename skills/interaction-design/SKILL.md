---
name: interaction-design
description: Use when designing how a UI feels to use. Covers audience dimensions, discoverability, mode communication, keyboard-first UX, feedback timing, empty states, and information density. Includes WCAG 2.1 AA compliance audit. Companion to visual-design.
---

# Interaction Design

Interaction design answers "what does it feel like to use?" Visual design answers the color and typography question. This skill answers the behavioral question: can the full range of users find what they need, understand where they are, recover from mistakes, and move faster over time?

The audience is not uniform. Different hand sizes, physical abilities, keyboard vs. mouse preference, cognitive load tolerance, focus styles, and visual acuity are not edge cases. They are the actual distribution of people who use the product. Video game designers learn this quickly: every interaction decision (button placement, trigger resistance, response window, color palette) implicitly chooses who can play and who cannot. Designing for the extremes almost always improves the center.

---

## Audience Dimensions

Before designing any interaction, name the range of users it must serve.

| Dimension | Range | Design implication |
|-----------|-------|--------------------|
| Motor | High-precision mouse, trackpad, touch, one-handed, switch access, tremor | Never require hover to access function. Keyboard covers everything. Touch targets 44x44px minimum. No time-limited interactions. |
| Visual | 20/20 to low vision, color blindness (8% of men), photosensitivity | Contrast 4.5:1 minimum. Never color as the only signal. No flashing above 3Hz. Works at 200% zoom. |
| Cognitive | Deep focus, ADHD, working memory variation, anxiety, fatigue | Undo over confirm. One task per screen. Progress always visible. Error messages say what to do, not just what went wrong. |
| Input preference | Mouse power user, vim keyboard, touch-first, voice, gamepad | Keyboard covers all functionality. Mouse is faster at some tasks but never required for any task. |
| Experience | First session to three-year expert | Progressive disclosure. Hints degrade. Shortcuts emerge. Help always reachable. |

The keyboard shortcut for power users is the accessibility path for motor-impaired users. They are the same design decision. An undo-over-confirm for flow state is the safety net for error-prone users. These are not separate requirements.

---

## The Discoverability Test

Three rules that function as a quality gate before any UI ships:

- **10s rule**: A new user should know what to do within 10 seconds of landing on any screen. If they cannot, the affordances are wrong or buried.
- **Mode escape rule**: Users must always know how to leave the current mode. A trapped user is a frustrated user.
- **100ms feedback rule**: Every action must produce a visible response within 100ms. A silent UI feels broken even when it is not.

Anti-patterns that fail this test:

- Disabled buttons with no explanation (user cannot tell why or how to enable)
- Modal confirmation dialogs for reversible actions (undo is better)
- Hidden modes with no indicator (user lost, no escape)
- Trapped focus without an escape affordance
- Uniform empty states that teach nothing

## Progressive Disclosure

Show what is needed now. Surface more as the user demonstrates readiness.

Three layers:

1. **First-run**: Guided affordances, visible hints, reduced noise. Everything labeled.
2. **Regular user**: Hints fade after N interactions. Power features emerge. Keyboard shortcuts appear on hover.
3. **Power user**: Dense mode. Hints gone. Muscle memory owns the interaction.

Implementation pattern: track feature usage counts in local state. Degrade hints after threshold. Never remove hints permanently. A returning user who forgot is not a power user.

## Mode Communication

Every mode change requires a visible indicator. Users must never guess where they are.

Patterns that work:

- Mode bar with active mode label and available actions as contextual pills
- Breadcrumb trail for nested modes
- Color shift at the border or background level (subtle, not alarming)
- ESC always exits to the previous mode (never to a different mode)

Anti-patterns:

- Color as the only mode indicator (fails for color-blind users and low-contrast environments)
- Mode changes triggered by keyboard shortcuts without visual confirmation
- Nested modes with no breadcrumb

## Keyboard-First UX

The keyboard is the power interface and the accessibility interface. Design for it from the start.

Vim grammar: operator + motion. `d w` = delete word. Composable actions beat modal menus.

Discoverability ladder:

1. Hover tooltips show the shortcut on first encounter
2. Shortcut shown in the button or action label
3. Command palette as the escape hatch for everything else (Linear/Raycast model)
4. `?` always shows the shortcut map

Hesitation detection: if a user hovers for more than 800ms without acting, show the shortcut. They are looking for the keyboard path.

## Feedback Timing

Three timing tiers that map to user perception:

| Window | What it means | Pattern |
|--------|--------------|---------|
| 0-100ms | Instant, user feels immediate | Optimistic UI, visual state change before confirmation |
| 100-300ms | Fast, user feels responsive | Show spinner or skeleton |
| 300-1000ms | Noticeable, user notices delay | Progress indicator with estimated completion |
| 1000ms+ | Slow, user questions if it worked | Toast with cancel option |

Undo over confirm: never ask "Are you sure?" for reversible actions. Do it and offer undo. Confirmation dialogs interrupt flow. Undo restores trust.

Toast patterns: bottom-right, 3-second auto-dismiss, action available (undo, view, dismiss). Never stack more than 3.

## Spatial Memory

Users build mental maps of where things live. Violate the map and they lose trust.

Rules:

- Primary actions stay in the same position across all states (loaded, empty, error)
- Animation direction must be consistent: drill-in goes right or down, back goes left or up
- Panels that appear always animate from the edge they logically come from
- Never shift content unexpectedly to accommodate a new element. Insert in place.

The squint test for spatial memory: blur your vision. Can you still find the primary action from memory alone? If yes, the spatial design is stable.

## Empty States

Every empty state is an onboarding moment. It has one job: teach the next action.

Pattern:

- Name what is missing ("No tasks yet")
- Explain why it matters ("Tasks track what needs doing")
- Show how to create one (button, shortcut, or gesture)
- Make the hint contextual (the hint changes based on where in the app the empty state appears)

Anti-patterns:

- Generic "Nothing here yet" with no action
- Empty states that show only an illustration (decoration, not direction)
- Identical empty state copy across different contexts

## Information Density

Default to density. Let users zoom.

The F1 cockpit principle: all information the user needs, nothing more. Every element earns its space or is removed.

Three levels:

1. **Dense default**: all data visible, compact rows, no wasted whitespace
2. **Focused view**: single item expanded, peripheral data faded
3. **Progressive detail**: click to reveal more depth on demand

Anti-patterns:

- Padding-heavy layouts that hide data count ("only 3 items visible when 20 fit")
- Card grids that waste horizontal space on whitespace
- Infinite scroll without a count ("how many total?")

## Contextual Actions

Show what is possible. Hide what is impossible. Change both with mode.

Implementation:

- Action set changes based on selection state (nothing selected vs one selected vs many selected)
- Destructive actions require confirmation only when irreversible and bulk
- Disabled states always explain why (tooltip with unmet condition)

Pattern: the action bar is always present, but its contents are context-driven. An empty selection shows "select items to act." A single selection shows item-specific actions. A multi-selection shows bulk actions only.

## Shared Environment Agency

When AI agents work in the same interface as humans, the interaction model must treat them as residents, not visitors.

Principles:

- **Traces that outlast sessions**: agents leave visible artifacts (notes, labels, state changes) that humans can read and act on
- **Co-authored identity**: work done by an agent is attributed but not hidden ("Claude organized these" as a visible label, not a background event)
- **Symmetric affordances**: if a human can move a card, the agent can move a card. The same actions, the same constraints.
- **No invisible mutations**: agents never change state without a visible trace in the UI

---

## Compliance Floor (WCAG 2.1 AA)

The audience dimensions above describe the goal. WCAG 2.1 AA describes the legal and ethical floor. The checklist below catches the failures. Meeting it is necessary but not sufficient.

### Perceivable

| Criterion | Requirement | How to check |
|-----------|-------------|--------------|
| 1.1.1 Non-text content | All images have meaningful alt text (or empty alt for decorative) | Inspect every `<img>`, `<svg>`, `role="img"` element |
| 1.3.1 Info and relationships | Structure conveyed semantically, not just visually | Check heading hierarchy (h1-h6), landmark roles, table markup |
| 1.4.3 Contrast (normal text) | Ratio >= 4.5:1 | Measure foreground vs background color |
| 1.4.3 Contrast (large text) | Ratio >= 3:1 (18px+ or 14px+ bold) | Same measurement, different threshold |
| 1.4.11 Non-text contrast | UI components and graphics >= 3:1 against adjacent colors | Check borders, icons, focus rings, form controls |

### Operable

| Criterion | Requirement | How to check |
|-----------|-------------|--------------|
| 2.1.1 Keyboard | All functionality available via keyboard | Tab through every interactive element |
| 2.4.3 Focus order | Logical tab sequence matches visual layout | Tab through and verify order |
| 2.4.7 Focus visible | Clear visible focus indicator on all interactive elements | Tab and verify each element shows focus |
| 2.5.5 Target size | Touch targets >= 44x44 CSS pixels | Measure interactive element dimensions |

### Understandable

| Criterion | Requirement | How to check |
|-----------|-------------|--------------|
| 3.2.1 On focus | No unexpected context changes on focus | Tab to every element, verify no surprise navigation |
| 3.3.1 Error identification | Errors described in text, not just color | Trigger form validation, check error messages |
| 3.3.2 Labels | All inputs have visible labels or instructions | Check every form field for associated label |

### Robust

| Criterion | Requirement | How to check |
|-----------|-------------|--------------|
| 4.1.2 Name, role, value | All custom UI components have accessible name and role | Inspect ARIA attributes on custom widgets |

---

## Audit Protocol

Run these in order before shipping any UI. Each layer catches what the previous one misses.

### 1. Automated scan (catches ~30% of issues)

Run axe-core or the browser's accessibility audit. Catches: missing alt text, contrast failures, missing form labels, duplicate IDs, missing landmarks. Misses: logical focus order, meaningful alt text quality, keyboard trap detection, screen reader announcement accuracy.

### 2. Keyboard navigation

Tab through every interactive element:

- Can you reach every link, button, input, and control?
- Can you activate each one with Enter or Space?
- Can you escape modals and dropdowns with Escape?
- Does focus order match the visual layout?
- Are there keyboard traps (focus enters but cannot leave)?
- Is focus visible on every element?

### 3. Screen reader check

With VoiceOver (macOS) or NVDA:

- Do headings create a navigable outline?
- Are buttons and links announced with their purpose?
- Do images announce meaningful descriptions?
- Are form fields associated with their labels?
- Do status messages announce without stealing focus?
- Do custom components announce their role and state?

### 4. Visual verification

- Zoom to 200%. No horizontal scrolling?
- Works without color (high contrast mode or grayscale)?
- Interactive states (hover, focus, active, disabled) visually distinct?
- Error states use text and icon, not just color?

### Common issues (check first)

1. Insufficient color contrast. Gray text on white backgrounds.
2. Missing form labels. Placeholder text is not a label.
3. No keyboard access. Click handlers on divs without keyboard event handlers.
4. Missing alt text.
5. Focus traps in modals.
6. Missing ARIA landmarks.
7. Auto-playing media without a pause control.

### Audit output format

```markdown
## Interaction + Accessibility Audit: [Page/Component Name]
**Standard:** WCAG 2.1 AA | **Date:** [Date]

### Discoverability Score
- 10s rule: Pass / Fail
- Mode escape: Pass / Fail
- 100ms feedback: Pass / Fail

### Audience Coverage
| Dimension | Issues found |
|-----------|-------------|
| Motor | ... |
| Visual | ... |
| Cognitive | ... |

### Critical Issues (must fix before ship)
| # | Category | Issue | Location | Fix |
|---|----------|-------|----------|-----|

### Major Issues (fix before next release)
| # | Category | Issue | Location | Fix |
|---|----------|-------|----------|-----|
```

---

## The Cutting Edge

Interfaces worth studying for each principle:

| Principle | Reference |
|-----------|-----------|
| Spatial interfaces | Bret Victor, Explorable Explanations |
| Local-first state | Ink & Switch, Local-First Software |
| Composable keyboard grammar | Helix editor, operator + motion model |
| Command palette as escape hatch | Linear, Raycast (`Cmd+K` for everything) |
| Progressive materialization | Ghost card pattern |
| Mode-aware empty states | Column-contextual hints that teach the system model |

---

## Anti-Patterns

- Treating accessibility as a post-launch polish task. Retrofitting costs 10x more than building it in.
- Using ARIA as a bandaid for bad HTML. A `<button>` is better than `<div role="button" tabindex="0">`. Semantic HTML first.
- Testing with mouse only. If you never press Tab, you never find keyboard issues.
- Color as the only indicator. Add text and icons.
- Designing for "the user" (singular). The audience is a distribution. Name the dimensions.
- Relying only on automated scans. They catch 30% of issues.

## The Floor

The visual layer answers what an interface looks like. Interaction design answers what it feels like to use -- for the full range of people who use it. A keyboard shortcut, a 44px touch target, sufficient contrast, and an undo action serve different users through the same design decision. The compliance floor (WCAG) is where legal liability starts. The audience dimensions table is where good design starts. Run `/visual-design` for the visual identity question. This skill handles everything about behavior, range, and feel.
