# Stage 11 Jam Balance Notes

## Mineral values and quota curve

Goal: one playable quota curve for the current jam build.

Mineral value tiers:

- Common: Astro Quartz = 10
- Uncommon: Cosmo Crystal = 20
- Rare: Wonder Dust = 35
- Epic: Infinite Shard = 55
- Legendary: Moon Rock = 75
- Chosen: Zenith Stone = 95

Quota curve:

- Level 1: 20
- Level 2: 45
- Level 3: 55
- Level 4: 65
- Level 5: 75

Jam intent:

- A normal three-attempt level should be possible with decent play.
- Rare minerals feel exciting, but one rare mineral should not automatically solve every level.
- Level 1 stays easy enough to teach the loop.

## Suit price tiers

Cheap / early-test tier:

- Pioneer Suit = 15
- Pilot Suit = 16

Mid tier:

- Acrobat Suit = 20
- Magnetic Suit = 20

Expensive / stronger utility tier:

- Second Chance Suit = 28
- Emergency Stabilizer Suit = 28

Jam intent:

- A player can buy something useful after an okay early level.
- Stronger safety suits still feel like a spending decision.

## Alien ability usefulness

Each alien keeps one clear job:

- Grey: mineral sell multiplier
- Blue: grip bonus
- Purple: suit discount
- Orange: rare mineral spawn boost
- Green: extra attempts
- Yellow: rare alien spawn boost

Jam tuning:

- Multipliers were softened instead of redesigned.
- Stacking still works, but dangerous totals are capped in `AlienCollection`.

## Scary combo spot-check targets

Combos to smoke test before release:

- Money combo: Grey sale multiplier plus high-value minerals.
- Safety combo: Green extra attempts plus Second Chance or Blue grip.
- Spawn combo: Yellow rare alien boost plus Orange rare mineral boost.

Current safety caps:

- Sale multiplier max: 2.0
- Suit discount floor: 0.55x price
- Extra attempts max: +2
- Rare alien spawn multiplier max: 3.0
- Rare mineral spawn multiplier max: 3.0
- Grip multiplier max: 2.0

## Final balance smoke test

Run once before export:

- Start a fresh run.
- Complete or fail at least one full three-attempt level.
- Confirm wallet and quota are readable.
- Confirm the shop opens between levels and at least one cheap suit is realistically buyable.
- Confirm failed run resets wallet, attempts, and suits.
- Confirm collected aliens persist.
- Confirm no crash, softlock, infinite money, or impossible quota appears.

Jam rule:

If it is playable, understandable, and only mildly weird, ship it.

## Alien collection persistence checklist

Jam-scope checks:

- Start with an empty alien save and confirm the collection panel opens.
- Collect one alien and confirm it appears in the collection panel.
- Fail a run and confirm collected aliens remain.
- Start a new run and confirm wallet, attempts, and suits reset.
- Quit to title, restart the game, and confirm collected aliens reload.

Known post-jam cleanup:

- Formal fixture saves for empty, partial, complete, corrupted, and migrated saves.
- Automated duplicate-ID and missing-resource migration tests.

## Playtest form fields

Use this structure for any last-minute tester notes:

- Build/version:
- Level reached:
- Seed, if visible:
- Input device:
- Aliens collected/equipped:
- Suits bought:
- What happened:
- What the player thought was happening:
- Severity: cosmetic / confusing / balance issue / blocker
- Reproducible: yes / no / unknown

Checklist prompts:

- Did the player understand movement, tilt, and drop?
- Did three attempts feel fair?
- Did quota feel impossible, trivial, or close?
- Did rare minerals feel exciting?
- Did aliens feel useful?
- Did suits feel worth buying?
- Did fail-state behavior make sense?

## Claw and physics jam check

Do not move claw tuning into resources for the jam build unless a blocker appears.

Smoke test:

- Light minerals should be easy to lift.
- Medium minerals should feel normal.
- Heavy minerals should be possible but riskier.
- Magnetic, grip, and Second Chance effects should help without making every grab guaranteed.
- Crowded piles should jitter briefly, then settle enough to play.

Known post-jam cleanup:

- Dedicated claw tuning resource.
- Seeded physics test scene.
- Capture reliability logger.

## Alien rarity and acquisition check

Current rule:

- Mineral money remains the only spendable currency.
- Aliens are permanent progression.
- Rare aliens are useful bonuses, not required for quota.

Smoke test:

- Duplicate alien captures increase stacks.
- Six-of-six collection remains possible over multiple runs.
- Common aliens appear often enough to teach collection.
- Rare aliens feel special when they appear.

## Input and menu smoke test

Keyboard:

- Move left/right.
- Tilt with mouse.
- Drop claw.
- Pause/resume.
- Open/close Help, Collection, Abilities, Suit Inventory, Settings.
- Buy/equip/continue through shop.

Controller:

- Move left/right.
- Tilt with right stick.
- Drop claw.
- Pause/resume.
- Navigate menus without getting trapped.

Known post-jam cleanup:

- Glyph swapping.
- Full remap fixture.
- Controller disconnect/reconnect matrix.

## Performance smoke test

Run one crowded layout and watch for:

- Physics spikes that change claw timing.
- Audio stutter.
- Particle/win feedback spikes.
- Excessive prize jitter.
- Menu lag.

Jam rule:

- Only optimize if it hurts playability.
- Do not reduce prize readability just to chase perfect profiler numbers.

## Core regression checklist

Run this after major fixes:

- Timed three-attempt level works.
- Quota win transitions correctly.
- Lost run can restart.
- Aliens persist after run failure.
- Wallet resets on failed run.
- Suits reset on failed run.
- Shop can buy and equip a suit.
- Settings open and close.
- Help/collection/abilities panels pause timer while open.
- Main menu starts game and credits opens/scrolls.

## Release candidate criteria

Block release only for:

- Crash.
- Softlock.
- Save loss.
- Impossible quota.
- Infinite money exploit.
- Controls that prevent completing the loop.
- Unreadable critical HUD.

Do not block release for:

- Slightly imperfect economy.
- Minor visual overlap.
- Non-critical polish.
- Known rare combo weirdness that does not break the run.
