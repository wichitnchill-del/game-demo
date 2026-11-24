# Copy & Language

Reference: microcopy rules for the product UI — no emoji, short and scannable text.

## Rules

1. **No emoji** anywhere in the UI. Icons come from Lucide / SVG libraries only.
   Never decorative emoji, never emoji-as-icon.
2. **Short copy**:
   - CTA / primary action: ~3 words ("สั่งอาหาร", "Buy now", "เริ่มเล่น")
   - Form labels / buttons: ~5 words
   - Helper / hint text: ~10 words
   - Body sentences: ≤ ~12 words, one idea each
3. **Plain language**: no jargon, no internal terms, no English-only idioms when the
   primary audience is Thai (keep tone marks and numerals correct).
4. **Scannable**: headings short, bullets when > 2 items, progressive disclosure.

## Why

- Users scan; long copy hides hierarchy and kills conversion.
- Thai copy must fit mobile widths — short strings render cleanly.
- Emoji are inconsistent across platforms and read as decoration, not meaning.

## Review checklist (critique)

- [ ] Any emoji in UI? → remove, replace with icon.
- [ ] Any string over the limits above? → trim.
- [ ] Sentences understandable in ≤ 2 reads? → rewrite.
- [ ] Error messages short + actionable?
- [ ] CTA labels clear without context?

See also [design-principles.md](design-principles.md) and
[accessibility.md](accessibility.md).
