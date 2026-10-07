"""Condense NativeDump.reds output for quickhack design, without changing the source.

Usage: python tools/CompressNativeDump.py path/to/native-quickhacks-dump.txt
"""
from __future__ import annotations

import argparse
from collections import Counter, defaultdict
import hashlib
import json
from pathlib import Path
import re


NODE = re.compile(r"^( *)(Action|->): (.*?) \[([^]]+)\](?: \((listed above)\))?$")
MISSING = re.compile(r"^( *)(Action|->): (.*?) \(no record\)$")
FIELD = re.compile(r"^([A-Za-z_][A-Za-z_0-9]*) = (.*)$")


def parse(text):
    header, programs, occurrences, unknown = [], [], [], []
    stack = []
    program = None
    for number, line in enumerate(text.splitlines(), 1):
        stripped = line.strip()
        if not stripped:
            continue
        if line.startswith("=== "):
            title, item = line[4:].split(" | ", 1)
            program = dict(title=title, item=item, family=re.sub(r" T\d+$", "", title),
                           notes=[], records=[], depthLimited=[], missingRecords=[])
            programs.append(program)
            stack = []
            continue
        if program is None:
            header.append(line)
            continue
        match = NODE.match(line)
        if match:
            spaces, label, record_id, kind, listed = match.groups()
            indent = len(spaces)
            while stack and stack[-1][0] >= indent:
                stack.pop()
            occurrence = dict(id=record_id, kind=kind, fields={}, computed=[])
            occurrences.append(occurrence)
            stack.append((indent, occurrence))
            if record_id not in program['records']:
                program['records'].append(record_id)
            if label == 'Action':
                program['action'] = record_id
            continue
        missing = MISSING.match(line)
        if missing:
            program['missingRecords'].append(missing.group(3))
            continue
        indent = len(line) - len(line.lstrip())
        if indent == 2:
            program['notes'].append(stripped)
            continue
        if stack and indent > stack[-1][0]:
            occurrence = stack[-1][1]
            field = FIELD.match(stripped)
            if field:
                key, value = field.groups()
                if key in occurrence['fields']:
                    raise ValueError(f'Duplicate field at line {number}: {key}')
                occurrence['fields'][key] = value
                continue
            if stripped.startswith('(computed ') and stripped.endswith(')'):
                occurrence['computed'].append(stripped[1:-1])
                continue
            if stripped == '(depth limit)':
                program['depthLimited'].append(occurrence['id'])
                continue
        unknown.append(dict(line=number, text=line))
    records = {}
    for occurrence in occurrences:
        record_id = occurrence['id']
        record = records.setdefault(record_id, dict(kind=occurrence['kind'], variants=[]))
        if record['kind'] != occurrence['kind']:
            raise ValueError(f'Conflicting record types: {record_id}')
        variant = dict(fields=occurrence['fields'], computed=occurrence['computed'])
        if (variant['fields'] or variant['computed']) and variant not in record['variants']:
            record['variants'].append(variant)
    return header, programs, records, unknown, len(occurrences)


def pack(records):
    """Common values are explicit per-type templates, not inferred game defaults."""
    by_kind = defaultdict(list)
    for record in records.values():
        by_kind[record['kind']].extend(v['fields'] for v in record['variants'])
    templates = {}
    for kind, variants in by_kind.items():
        common = set.intersection(*(set(v) for v in variants)) if variants else set()
        template = {}
        for key in sorted(common):
            value, count = Counter(v[key] for v in variants).most_common(1)[0]
            if count > 1:
                template[key] = value
        templates[kind] = template
    compact = {}
    for record_id, record in records.items():
        variants = []
        for variant in record['variants']:
            overrides = {k: v for k, v in variant['fields'].items()
                         if templates[record['kind']].get(k) != v}
            variants.append([overrides, variant['computed']])
        compact[record_id] = [record['kind'], variants]
    # Round-trip verification checks every explicit field, including false/zero/none.
    for record_id, (kind, variants) in compact.items():
        restored = [dict(fields={**templates[kind], **override}, computed=computed)
                    for override, computed in variants]
        assert restored == records[record_id]['variants'], record_id
    return dict(templates=templates, records=compact)


def fields(records, record_id):
    variants = records.get(record_id, {}).get('variants', [])
    return variants[0]['fields'] if variants else {}


def array(value):
    return value[1:-1].split(', ') if value.startswith('[') and value != '[]' else []


def slug(text):
    return re.sub(r'[^a-z0-9]+', '-', text.lower()).strip('-')


def write_json(path, data):
    # One top-level entry per line, with one record per line in the registry.
    def dump(value):
        return json.dumps(value, ensure_ascii=False, separators=(',', ':'))
    entries = []
    for key, value in data.items():
        if key == 'records':
            encoded = '{\n' + ',\n'.join(dump(k) + ':' + dump(v) for k, v in value.items()) + '\n}'
        else:
            encoded = dump(value)
        entries.append(dump(key) + ':' + encoded)
    path.write_text('{\n' + ',\n'.join(entries) + '\n}\n', encoding='utf-8')
    if json.loads(path.read_text(encoding='utf-8')) != data:
        raise ValueError(f'Serialized JSON did not round-trip: {path}')


def build(source, output):
    raw = source.read_bytes()
    header, programs, records, unknown, occurrences = parse(raw.decode('utf-8-sig'))
    if unknown:
        raise ValueError(f'Unparsed source lines (no outputs written): {unknown[:10]}')
    if not programs or not records:
        raise ValueError('No programs or records found')
    declared = re.search(r'\b(\d+) programs\b', '\n'.join(header))
    if declared and int(declared.group(1)) != len(programs):
        raise ValueError('Program count does not match source header')
    metadata = dict(source=str(source.resolve()), sha256=hashlib.sha256(raw).hexdigest(),
                    header=header, sourceBytes=len(raw), sourceLines=len(raw.splitlines()),
                    programs=len(programs), families=len({p['family'] for p in programs}),
                    recordOccurrences=occurrences, uniqueRecords=len(records),
                    conflictingRecordVariants=[key for key, r in records.items() if len(r['variants']) > 1],
                    recordsWithoutExpandedFields=[key for key, r in records.items() if not r['variants']],
                    depthLimitedOccurrences=sum(len(p['depthLimited']) for p in programs),
                    unparsedLines=0, roundTripVerified=True)
    output.mkdir(parents=True, exist_ok=True)
    family_dir = output / 'families'
    family_dir.mkdir(exist_ok=True)
    schema = ('records[id]=[kind,variants]; variant=[overrides,computedNotes]. '
              'Reconstruct each variant fields as templates[kind] merged with overrides. '
              'All field values are verbatim source strings. Empty variants means no expanded fields. '
              'Templates are compression dictionaries, NOT game defaults. '
              'Multiple variants are conflicting observations, not tiers; retain all. '
              'program.records lists records observed in that program traversal. '
              'Depth limits are preserved per program; expansion elsewhere can fill that record globally. '
              'Referenced IDs absent from records are unexpanded, NOT evidence of missing behavior.')
    write_json(output / 'native-quickhacks-compact.json',
               dict(schema=schema, metadata=metadata, programs=programs, **pack(records)))
    families = defaultdict(list)
    for program in programs:
        families[program['family']].append(program)
    for family, entries in families.items():
        ids = {key for p in entries for key in p['records']}
        subset = {key: value for key, value in records.items() if key in ids}
        write_json(family_dir / (slug(family) + '.json'),
                   dict(schema=schema, sourceSha256=metadata['sha256'], context=header,
                        programs=entries, **pack(subset)))
    lines = ['# Native quickhacks: compact design reference', '',
             'Start here; load only the family JSON needed for exact conditions and formulas. '
             'The full compact JSON is a lookup archive, not required context for every design.', '',
             f"Source: {len(programs)} programs, {len(families)} families; "
             f"{occurrences:,} record occurrences reduced to {len(records):,} unique IDs.", '',
             '## Interpretation limits', '',
             '- Snapshot: ' + ' / '.join(header) + '.',
             '- RAM/upload/duration/spread below are the workbench extractor’s snapshot values. '
             'Computed modifier/attack values use the player as both source and target; they are not measured damage against an enemy.',
             '- “Recreated part” and “Not recreated” describe the importer’s current coverage. '
             'They do not establish that a primitive exactly reproduces native behavior.',
             '- Native status tags, prerequisites, scripted effector classes and AI behavior matter. '
             'This dump contains record data, not the implementation of those classes.',
             '- Same-title T5 variants stay separate by item ID. Do not merge their values. '
             'The original traversal stops at depth >12 and only expands selected record classes.', '',
             '## Suggested primitive boundaries', '',
             'This is a design proposal, not a claim that these custom features already exist:', '',
             '1. Trigger: upload completion, hit, headshot, reload, or status change; carry source and target identities.',
             '2. Conditions: target type, combat state, tags/status stacks, distance, immunity and resource thresholds.',
             '3. Payload: sensory blindness, accuracy modifier, weapon malfunction, damage burst/pulses, '
             'movement restriction, cyberware suppression, AI command or information reveal. Keep these independently selectable.',
             '4. Timing: upload, duration, pulse interval, cooldown, charges and removal rules.',
             '5. Propagation: which payload transfers, eligible recipients, radius, delay, hop/target budget and reinfection policy.',
             '6. Presentation: animation, icon and VFX/SFX. A blind animation alone is not evidence that shooting or tracking stopped.', '',
             'Rebuild a native tier from its own action → effect → status → package → effector/modifier chain. '
             'Preserve application conditions and recipients before experimenting with cross-family combinations.', '',
             '## Program catalog', '',
             'Timings are seconds. “++” below means the item ID contains `PlusPlus`; the source title itself does not distinguish it.', '',
             '| Program | Item ID (after `Items.`) | Snapshot |',
             '|---|---|---|']
    for p in programs:
        measured = next((n.split(': ', 1)[1] for n in p['notes'] if n.startswith('Measured for you:')), 'unavailable')
        measured = measured.replace(' | ', '; ')
        lines.append(f"| {p['title']}{' ++' if 'PlusPlus' in p['item'] else ''} | `{p['item'].removeprefix('Items.')}` | {measured} |")
    lines.extend(['', '## Family components and importer coverage', '',
                  'Native start/completion entries below resolve direct action effects to their status or effector IDs, with recipients. '
                  'They are an index, not a full effect chain; recipient and prerequisite details remain in the JSON.', ''])
    for family, entries in families.items():
        lines.extend([f'### {family}', '', f'Exact records: [families/{slug(family)}.json](families/{slug(family)}.json)', ''])
        effects = defaultdict(set)
        recreated, missing = set(), set()
        for p in entries:
            action = fields(records, p.get('action', ''))
            for phase in ('startEffects', 'completionEffects'):
                for effect in array(action.get(phase, '[]')):
                    ef = fields(records, effect)
                    components = [ef[k] for k in ('statusEffect', 'effectorToTrigger')
                                  if ef.get(k, 'none') != 'none']
                    recipient = ef.get('recipient', 'none')
                    # Keep an explicit unset recipient: do not infer target/source semantics.
                    for component in components or [effect]:
                        effects[phase].add(component + ' (recipient=' + recipient + ')')
            for note in p['notes']:
                if note.startswith('Recreated part '):
                    recreated.add(re.sub(r'^Recreated part \d+: ', '', note))
                if note.startswith('Not recreated: '):
                    missing.add(note.removeprefix('Not recreated: '))
        for phase, values in effects.items():
            lines.append(f"- Native {phase}: " + '; '.join(f'`{v}`' for v in sorted(values)))
        lines.append('- Importer extracted payloads (tier values may differ): ' + ('; '.join(sorted(recreated)) or 'none reported'))
        lines.append('- Importer gaps: ' + ('; '.join(f'`{v}`' for v in sorted(missing)) or 'none reported; not proof of complete equivalence'))
        lines.append('')
    (output / 'native-quickhacks-design-summary.md').write_text('\n'.join(lines).rstrip() + '\n', encoding='utf-8')
    (output / 'README.md').write_text(
        '# Using the compressed dump\n\n'
        'For design discussions, attach `native-quickhacks-design-summary.md` first. '
        'For implementing or checking one hack, also attach its `families/*.json` file. '
        'Avoid loading every family at once: shared records repeat between these standalone files.\n\n'
        f'`native-quickhacks-compact.json` contains all {len(programs)} programs in one deduplicated registry '
        '(the actual count is also recorded in metadata). `compression-report.json` records coverage, '
        'source hash, truncation, conflicts and sizes. The original dump is unchanged.\n\n'
        '## Reading the JSON\n\n' + schema + '\n\n'
        'An omitted field inherits its exact value from the template for that record kind. '
        'A listed `false`, `0`, `none` or empty array is never silently discarded. '
        'Templates must travel with their records. This preserves parsed field values, '
        'not indentation or repeated traversal order. Source-side depth limits and unexpanded references remain limitations.\n\n'
        '## Regenerate\n\nFrom the SDP-QuickhackCrafting repository:\n\n'
        '```powershell\npython tools/CompressNativeDump.py "C:\\Program Files (x86)\\Steam\\steamapps\\common\\Cyberpunk 2077\\bin\\x64\\plugins\\cyber_engine_tweaks\\mods\\SDPQuickhackCrafting\\native-quickhacks-dump.txt"\n```\n\n'
        'Use `--output PATH` to choose another destination. The script rejects unparsed lines '
        'and verifies every compacted record by expanding the templates back to the parsed fields.\n', encoding='utf-8')
    metadata['outputsBytes'] = {str(p.relative_to(output)): p.stat().st_size
                                for p in sorted(output.rglob('*')) if p.is_file() and p.name != 'compression-report.json'}
    write_json(output / 'compression-report.json', metadata)
    print(json.dumps(metadata, indent=2))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('source', type=Path)
    parser.add_argument('--output', type=Path,
                        default=Path(__file__).resolve().parents[1] / 'design' / 'native-dump')
    args = parser.parse_args()
    build(args.source, args.output)
