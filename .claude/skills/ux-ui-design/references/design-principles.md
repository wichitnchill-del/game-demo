# Design Principles

Deep reference for the UX principles, heuristics and human factors the design
loop applies at every phase.

## Heuristic set (Nielsen, 10 heuristics)

| # | Heuristic | Design check |
|---|---|---|
| 1 | Visibility of system status | Loading, progress, success, errors always visible; no silent failures |
| 2 | Match between system & real world | Language, icons and metaphors users already know |
| 3 | User control & freedom | Back, undo, exit, cancel always available; escape hatches |
| 4 | Consistency & standards | Same action → same pattern, same words, same placement |
| 5 | Error prevention | Constraints, defaults, confirmation for destructive actions |
| 6 | Recognition rather than recall | Options visible; no memory-only UI |
| 7 | Flexibility & efficiency | Power-user shortcuts; don't hide them |
| 8 | Aesthetic & minimalist design | No irrelevant info competing with primary task |
| 9 | Help users recognize & recover from errors | Human wording, specific cause, recovery action |
| 10 | Help & docs | Contextual help, search, onboarding for complex tools |

## Human factors / cognitive laws

| Law / effect | Applied design rule |
|---|---|
| Fitts's law | Big, close, high-contrast targets reduce error & time |
| Hick's law | Limit simultaneous choices presented at once |
| Miller's law | Chunk information into groups of ~7±2 |
| Doherty / flow | Keep critical path short and free of friction |
| Cognitive load | Progressive disclosure, progressive onboarding |

## Interaction design principles

- **Feedback**: every action gets a state change (hover, active, disabled, loading,
  success, error). Feedback is immediate, specific and actionable.
- **Affordance / signifier**: controls should look and behave as clickable; labels
  carry the meaning.
- **Mapping**: controls and their effects should be spatially/logically related.
- **Constraints**: good design prevents bad actions rather than punishing them.
- **Error prevention & recovery**: validate early, inline, with clear messages; offer
  undo.

## Visual hierarchy principles

- One primary action per screen goal; hierarchy via size, weight, color, spacing, position.
- Squint test: primary element still dominant when blurred.
- Chunk related items; group by task.

## Ethics / anti-patterns to flag in critique

- Dark patterns (confirmshaming, hidden costs, forced continuity)
- Jargon / unexplained abbreviations
- Dead ends without recovery
- Hidden navigation / mystery meat
- Fake progress / misleading status
- Auto-playing heavy motion or content

See [references/accessibility.md](accessibility.md) for the a11y lens on each point.
