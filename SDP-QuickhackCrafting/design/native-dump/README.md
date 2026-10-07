# Using the compressed dump

For design discussions, attach `native-quickhacks-design-summary.md` first. For implementing or checking one hack, also attach its `families/*.json` file. Avoid loading every family at once: shared records repeat between these standalone files.

`native-quickhacks-compact.json` contains all 77 programs in one deduplicated registry (the actual count is also recorded in metadata). `compression-report.json` records coverage, source hash, truncation, conflicts and sizes. The original dump is unchanged.

## Reading the JSON

records[id]=[kind,variants]; variant=[overrides,computedNotes]. Reconstruct each variant fields as templates[kind] merged with overrides. All field values are verbatim source strings. Empty variants means no expanded fields. Templates are compression dictionaries, NOT game defaults. Multiple variants are conflicting observations, not tiers; retain all. program.records lists records observed in that program traversal. Depth limits are preserved per program; expansion elsewhere can fill that record globally. Referenced IDs absent from records are unexpanded, NOT evidence of missing behavior.

An omitted field inherits its exact value from the template for that record kind. A listed `false`, `0`, `none` or empty array is never silently discarded. Templates must travel with their records. This preserves parsed field values, not indentation or repeated traversal order. Source-side depth limits and unexpanded references remain limitations.

## Reading a program

`python tools/ExplainNativeQuickhack.py "Overheat T3"` prints what a program does to its target from these files; `--recreation` shows what the Build 14 importer rebuilds from it (see design/NATIVE_RECREATION.md).

Dumps from Build 13 lack the loose flats of effector and scripted prerequisite records (vfxName, activationSFXName, attackPositionSlotName, playerAsInstigator, invert...). Build 14 dumps list them.

## Regenerate

From the SDP-QuickhackCrafting repository:

```powershell
python tools/CompressNativeDump.py "C:\Program Files (x86)\Steam\steamapps\common\Cyberpunk 2077\bin\x64\plugins\cyber_engine_tweaks\mods\SDPQuickhackCrafting\native-quickhacks-dump.txt"
```

Use `--output PATH` to choose another destination. The script rejects unparsed lines and verifies every compacted record by expanding the templates back to the parsed fields.
