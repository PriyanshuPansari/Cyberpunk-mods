"""Read the compressed native quickhack dump: behavior trees and Build 14 recreations.

    python tools/ExplainNativeQuickhack.py "Overheat T3"              # what the native program does
    python tools/ExplainNativeQuickhack.py --family short-circuit       # every tier of a family
    python tools/ExplainNativeQuickhack.py --recreation "Overheat T3"   # what the importer rebuilds
    python tools/ExplainNativeQuickhack.py --recreation --all --markdown

A program is named by its title ("Reboot Optics T5", ambiguous T5 variants match
both) or item ("Items.BlindLvl4PlusPlusProgram"). The default source is
design/native-dump/native-quickhacks-compact.json; --dump PATH reads another
compact file (a family file works too).

The behavior view lists what reaches the target: each status with its type,
duration, tags, AI data, VFX/SFX and packages (stats, animation overrides,
effectors with their attacks and conditions), plus the upload-phase effects.

The recreation view mirrors SDPQHNativeRef.Measure in NativeReferences.reds on
the dump's records and its "computed for you" values: parts, the native look
each part wears (and what the look keeps or drops), native hits, chip
effectors, native-bug fixes and what is not recreated. It is a preview made
from the dump; the in-game importer, using live stats, is authoritative.
"""
import argparse
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DEFAULT = ROOT / "design/native-dump/native-quickhacks-compact.json"
FAMILIES = ROOT / "design/native-dump/families"

PAYLOAD_TEXT = {1: "blindness", 2: "thermal damage pulses", 3: "electrical damage pulses", 4: "stun",
                6: "movement restriction (speed x0.2)", 7: "chemical damage pulses", 8: "physical damage pulses",
                9: "immobilization", 10: "weapon jam", 11: "deafness and comms jam", 12: "cyberware malfunction",
                13: "native behavior"}
DAMAGE_PAYLOAD = {"DamageTypes.Thermal": 2, "DamageTypes.Electric": 3, "DamageTypes.Chemical": 7, "DamageTypes.Physical": 8}
CONTROL_TYPES = {"QuickHackStaggerLocomotion": 9, "Jam": 10, "CommsNoise": 11, "QuickHackStaggerCyberware": 12, "Stunned": 4}
ATTACK_EFFECTORS = {"TriggerAttackEffector", "ContinuousAttackEffector"}
CHIP_DROPS = {"SpreadEffector", "SpreadInitEffector", "NotifyPoliceEffector", "RewardPlayerWithCrimeScoreEffector"}
# Completion effectors the chip runs from script (SDPQHPorts in NativeReferences.reds).
PORTS = {"NotifyPoliceEffector": "police notice", "RewardPlayerWithCrimeScoreEffector": "crime score",
         "ModifyStatusEffectDurationEffector": "duration change of the target's quickhacks",
         "SystemCollapseModifyRevealBarEffector": "trace reveal-bar change", "DestroyBreachEffector": "breach destruction",
         "ApplyLegendaryWhistleEffector": None}
PORTED_STATUS = {"ApplyLegendaryWhistleEffector": "BaseStatusEffect.WhistleLvl4"}
PORT_GAPS = {"ApplyLegendaryWhistleEffector": "WhistleLvl4_TurnAway (re-uploading on a lured target out of combat turns it away)"}
BOOKKEEPING = {"BaseStatusEffect.WasQuickHacked", "BaseStatusEffect.QuickHackUploaded"}
COMPARISON = {"Less": "<", "LessOrEqual": "<=", "Greater": ">", "GreaterOrEqual": ">=", "NotEqual": "!=", "Equal": "="}
MAX_PARTS = 6


def items(value):
    """A dump list value ("[a, b]") as a list; none/None/empty as []."""
    value = (value or "").strip()
    if value.startswith("[") and value.endswith("]"):
        value = value[1:-1]
    return [v.strip() for v in value.split(",") if v.strip() and v.strip() not in ("none", "None")]


def short(record_id):
    return record_id.split(".", 1)[1] if "." in record_id else record_id


def num(value):
    value = float(value)
    if abs(value - round(value)) < 0.005:
        return str(int(round(value)))
    return f"{value:.2f}".rstrip("0").rstrip(".")


class Dump:
    def __init__(self, path):
        data = json.loads(Path(path).read_text(encoding="utf-8"))
        self.templates = data["templates"]
        self.records = data["records"]
        self.programs = data["programs"]

    def get(self, record_id):
        """(kind, fields, notes); fields None when the record was not expanded."""
        if record_id not in self.records:
            return None, None, []
        kind, variants = self.records[record_id]
        if not variants:
            return kind, {}, []
        overrides, notes = variants[0]
        fields = dict(self.templates.get(kind, {}))
        fields.update(overrides)
        return kind, fields, notes

    def fields(self, record_id):
        return self.get(record_id)[1] or {}

    def computed(self, record_id):
        for note in self.get(record_id)[2]:
            match = re.search(r"computed(?: damage)? for you = (-?[\d.]+)", note)
            if match:
                return float(match.group(1))
        return None

    def find(self, name):
        found = [p for p in self.programs if name in (p["title"], p["item"], p["item"].split(".", 1)[-1])]
        if not found:
            sys.exit(f"No program named {name!r}. Titles look like 'Overheat T3'.")
        return found

    # ---- descriptions -------------------------------------------------------

    def modifier(self, record_id):
        kind, f, _ = self.get(record_id)
        if not f:
            return short(record_id)
        stat = f.get("statType", "").replace("BaseStats.", "")
        if kind == "ConstantStatModifier":
            return f"{stat} {f.get('modifierType')} {num(f.get('value', 0))}"
        if kind == "CombinedStatModifier":
            return (f"{stat} {f.get('modifierType')} {num(f.get('value', 0))} {f.get('opSymbol')} "
                    f"{f.get('refObject')}.{f.get('refStat', '').replace('BaseStats.', '')}")
        if kind == "CurveStatModifier":
            return f"{stat} {f.get('modifierType')} curve {f.get('id', '?')}({f.get('refObject')}.{f.get('refStat', '').replace('BaseStats.', '')})"
        return f"{kind} {short(record_id)}"

    def group(self, record_id):
        mods = "; ".join(self.modifier(m) for m in items(self.fields(record_id).get("statModifiers")))
        value = self.computed(record_id)
        return "{" + mods + "}" + (f" = {num(value)}" if value is not None else "")

    def condition(self, effector_fields):
        """Empty when the effector always fires, else its prerequisite in words."""
        prereq = effector_fields.get("prereqRecord", "none")
        if prereq in ("none", "None", "Prereqs.AlwaysTruePrereq"):
            return ""
        kind, f, _ = self.get(prereq)
        if not f:
            return short(prereq)
        cls = f.get("prereqClassName", kind)
        if cls == "AlwaysTruePrereq":
            return ""
        if cls == "StatPrereq" or kind == "StatPrereq":
            who = "your " if f.get("objectToCheck") == "Player" else ""
            return f"{who}{f.get('statType')} {COMPARISON.get(f.get('comparisonType'), '=')} {num(f.get('valueToCheck', 0))}"
        if kind == "StatusEffectPrereq":
            what = short(f["statusEffect"]) if f.get("statusEffect", "none") != "none" else f.get("tagToCheck")
            return ("without " if f.get("invert") == "true" else "with ") + what
        if kind == "MultiPrereq":
            nested = [self.condition({"prereqRecord": n}) or "always" for n in items(f.get("nestedPrereqs"))]
            return f" {f.get('aggregationType', 'AND')} ".join(nested)
        detail = {k: v for k, v in f.items() if k != "prereqClassName" and v not in ("none", "None", "[]", "false")}
        return cls + (f" {detail}" if detail else "")

    def supported(self, prereq_id):
        """True when SDPQHConditions can check this prerequisite per target."""
        if prereq_id in ("none", "None", None, "Prereqs.AlwaysTruePrereq"):
            return True
        kind, f, _ = self.get(prereq_id)
        if not f:
            return False
        if f.get("prereqClassName") == "AlwaysTruePrereq":
            return True
        owner_ok = f.get("objectToCheck", "None") in ("Owner", "Player", "None")
        if kind == "StatPrereq":
            return owner_ok
        if kind == "StatusEffectPrereq":
            return owner_ok and (f.get("statusEffect", "none") != "none" or f.get("tagToCheck", "None") != "None")
        if kind == "MultiPrereq":
            return all(self.supported(n) for n in items(f.get("nestedPrereqs")))
        return False

    def attack_of(self, effector_id):
        kind, f, _ = self.get(effector_id)
        if kind in ATTACK_EFFECTORS and f:
            return f.get("attackRecord")
        return None

    def damage(self, attack_id):
        """True for an attack our pulses stand in for: typed damage with values.
        An attack the dump did not expand counts as damage (its type is unknown)."""
        if not attack_id:
            return False
        kind, f, _ = self.get(attack_id)
        if kind and not f:
            return True
        return bool(items((f or {}).get("statModifiers"))) and (f or {}).get("damageType") in DAMAGE_PAYLOAD

    def effector_class(self, effector_id):
        kind, f, _ = self.get(effector_id)
        return (f or {}).get("effectorClassName", kind or "?")

    def attack_text(self, attack_id):
        f = self.fields(attack_id)
        if not f:
            return f"{short(attack_id)} (not expanded in the dump)"
        value = self.computed(attack_id)
        flags = ", ".join(items(f.get("hitFlags")))
        return (f"{short(attack_id)} {f.get('damageType', '?').replace('DamageTypes.', '')} "
                f"{num(value) if value is not None else '?'} [{flags}] effect {f.get('effectName')}")

    def status_duration(self, status_id):
        """As SDPQHNativeRef.StatusDuration: computed duration plus Overheat's package bonus; 600 when open."""
        f = self.fields(status_id)
        group = f.get("duration", "none")
        value = self.computed(group) if group not in ("none", "None") else None
        if value is None:
            return 600.0
        if "Overheat" in items(f.get("gameplayTags")):
            for package in items(f.get("packages")):
                for stat in items(self.fields(package).get("stats")):
                    sf = self.fields(stat)
                    if sf.get("statType") == "BaseStats.OverheatDurationIncrease" and sf.get("modifierType") == "Additive":
                        value += float(sf.get("value", 0))
        return min(value, 600.0) if value > 0 else 600.0

    # ---- behavior view ------------------------------------------------------

    def describe_status(self, status_id, pad, out, seen, depth=0):
        kind, f, _ = self.get(status_id)
        if f is None:
            out.append(f"{pad}status {status_id} (not expanded)")
            return
        if status_id in seen:
            out.append(f"{pad}status {short(status_id)} (above)")
            return
        seen.add(status_id)
        kind_text = f.get("statusEffectType", "?").replace("BaseStatusEffectTypes.", "")
        stacks = self.computed(f.get("maxStacks", "none"))
        out.append(f"{pad}status {short(status_id)}: type {kind_text}, {num(self.status_duration(status_id))}s"
                   + (f", up to {num(stacks)} stacks" if stacks and stacks > 1 else ""))
        out.append(f"{pad}  tags {items(f.get('gameplayTags'))}"
                   + (f", immune with {items(f.get('immunityStats'))}" if items(f.get("immunityStats")) else ""))
        if f.get("AIData", "none") != "none":
            ai = self.fields(f["AIData"])
            conditions = [self.condition({"prereqRecord": p}) for p in items(ai.get("activationPrereqs"))]
            out.append(f"{pad}  AI {ai.get('behaviorType', '?').split('.')[-1]}, priority {num(ai.get('priority', 0))}"
                       + (", delayed" if ai.get("shouldDelayStatusEffectApplication") == "true" else "")
                       + (f", when {'; '.join(conditions)}" if conditions else ""))
        for label in ("VFX", "SFX"):
            names = [self.fields(x).get("name", short(x)) for x in items(f.get(label))]
            if names:
                out.append(f"{pad}  {label} {names}")
        for package in items(f.get("packages")):
            pf = self.fields(package)
            extras = []
            if items(pf.get("animationWrapperOverrides")):
                extras.append(f"animation {items(pf.get('animationWrapperOverrides'))}")
            if pf.get("stackable") == "true":
                extras.append("stackable")
            out.append(f"{pad}  package {short(package)}" + (f" ({', '.join(extras)})" if extras else ""))
            stats = [self.modifier(s) for s in items(pf.get("stats"))]
            if stats:
                out.append(f"{pad}    stats: {'; '.join(stats)}")
            for effector in items(pf.get("effectors")):
                self.describe_effector(effector, pad + "    ", out, seen, depth)

    def describe_effector(self, effector_id, pad, out, seen, depth=0):
        kind, f, _ = self.get(effector_id)
        if f is None:
            out.append(f"{pad}effector {effector_id} (not expanded)")
            return
        cls = f.get("effectorClassName", kind)
        skip = {"effectorClassName", "prereqRecord", "removeAfterActionCall", "removeAfterPrereqCheck", "statModifierGroups",
                "attackRecord", "statGroup", "statusEffect"}
        detail = {k: v for k, v in f.items() if k not in skip and v not in ("none", "None", "[]")}
        condition = self.condition(f)
        out.append(f"{pad}{cls}" + (f" {detail}" if detail else "") + (f" only when {condition}" if condition else ""))
        if f.get("statGroup"):
            out.append(f"{pad}  stats {self.group(f['statGroup'])}")
        if f.get("attackRecord"):
            out.append(f"{pad}  attack {self.attack_text(f['attackRecord'])}")
            for mod in items(self.fields(f["attackRecord"]).get("statModifiers")):
                out.append(f"{pad}    {self.modifier(mod)}")
        if f.get("statusEffect", "none") not in ("none", "None") and depth < 3:
            self.describe_status(f["statusEffect"], pad + "  ", out, seen, depth + 1)

    def behavior(self, program):
        out = [f"{program['title']} ({program['item']})"]
        out += [f"  {n}" for n in program["notes"] if n.startswith("Measured")]
        _, action, _ = self.get(program["action"])
        seen = set()
        for phase, label in (("startEffects", "upload start"), ("completionEffects", "upload complete")):
            for effect in items(action.get(phase)):
                ef = self.fields(effect)
                recipient = ef.get("recipient", "none").replace("ObjectActionReference.", "")
                if ef.get("statusEffect", "none") not in ("none", "None"):
                    if ef["statusEffect"] in BOOKKEEPING:
                        continue
                    out.append(f"  {label} -> {recipient}:")
                    self.describe_status(ef["statusEffect"], "    ", out, seen)
                elif ef.get("effectorToTrigger", "none") not in ("none", "None"):
                    if self.effector_class(ef["effectorToTrigger"]) == "SpreadEffector":
                        continue
                    out.append(f"  {label} -> {recipient}:")
                    self.describe_effector(ef["effectorToTrigger"], "    ", out, seen)
        return "\n".join(out)

    # ---- recreation view (mirrors SDPQHNativeRef.Measure) -------------------

    def control_payload(self, f):
        kind = f.get("statusEffectType", "").split(".")[-1]
        tags = items(f.get("gameplayTags"))
        if kind == "Blind":
            return 0 if "MemoryWipe" in tags else 1
        if kind in CONTROL_TYPES:
            return CONTROL_TYPES[kind]
        if kind != "Misc":
            return 0
        if "QuickHackBlind" in tags or "Blind" in tags:
            return 1
        if "LocomotionMalfunction" in tags:
            return 9
        if "JamWeapon" in tags or "WeaponJam" in tags:
            return 10
        if {"CommsNoiseJam", "CommsNoise", "Deaf"} & set(tags):
            return 11
        if "CyberwareMalfunction" in tags:
            return 12
        return 0

    def chip_keeps(self):
        """Optics' completion effects a program chip keeps (CustomProgramRecords.KeepsCompletion)."""
        kept = set()
        for effect in items(self.fields("QuickHack.BlindHack").get("completionEffects")):
            ef = self.fields(effect)
            if ef.get("statusEffect", "none") not in ("none", "None"):
                if ef["statusEffect"] in BOOKKEEPING:
                    kept.add(effect)
            elif ef.get("effectorToTrigger", "none") not in ("none", "None"):
                if self.effector_class(ef["effectorToTrigger"]) not in CHIP_DROPS:
                    kept.add(effect)
        return kept

    def look(self, status_id):
        """What the native look keeps (SDPQHLook.Make) and drops."""
        f = self.fields(status_id)
        keeps, drops = [], []
        keeps.append(f.get("statusEffectType", "?").replace("BaseStatusEffectTypes.", "") + " type")
        if f.get("AIData", "none") != "none":
            keeps.append("AI reaction")
        for label in ("VFX", "SFX"):
            names = [self.fields(x).get("name", "?") for x in items(f.get(label))]
            if names:
                keeps.append(f"{label} {', '.join(names)}")
        for package in items(f.get("packages")):
            pf = self.fields(package)
            if items(pf.get("animationWrapperOverrides")):
                keeps.append(f"animation {', '.join(items(pf['animationWrapperOverrides']))}")
            stats = [self.modifier(s) for s in items(pf.get("stats"))]
            if stats:
                keeps.append("stats " + "; ".join(stats))
            for effector in items(pf.get("effectors")):
                ef = self.fields(effector)
                cls = ef.get("effectorClassName", self.get(effector)[0])
                if cls in ("SpreadEffector", "SpreadInitEffector") or (
                        self.damage(self.attack_of(effector)) and not self.condition(ef)):
                    drops.append(f"{cls} {short(self.attack_of(effector) or effector)}")
                else:
                    condition = self.condition(ef)
                    keeps.append(cls + (f" (only when {condition})" if condition else ""))
        return keeps, drops

    def recreation(self, program):
        _, action, _ = self.get(program["action"])
        rec = dict(parts=[], missing=[], fixes=[], damage=[], ports=[], kept=[], spread=None, statuses=set(), when=None)

        def add_part(payload, length, amount, interval, source, look, attack):
            if len(rec["parts"]) >= MAX_PARTS:
                rec["missing"].append(f"{PAYLOAD_TEXT[payload]} ({source}; too many effects)")
                return False
            after = bool(rec["when"]) and any(not p["when"] for p in rec["parts"])
            rec["parts"].append(dict(payload=payload, duration=length, amount=amount, interval=interval,
                                     source=source, look=look, attack=attack, stacks=False, when=rec["when"], after=after))
            return True

        def damage_effector(effector, length, source, look, stackable=False, in_look=False):
            attack = self.attack_of(effector)
            if not self.damage(attack):
                return 0
            af = self.fields(attack)
            payload = DAMAGE_PAYLOAD.get(af.get("damageType"), 0)
            if not payload:
                # Not expanded in the dump: the in-game importer reads the record itself.
                payload = {"Overload": 3, "BrainMelt": 8, "Overheat": 2, "Contagion": 7}.get(
                    next((k for k in ("Overload", "BrainMelt", "Overheat", "Contagion") if k in attack), ""), 3)
            condition = self.condition(self.fields(effector))
            if condition:
                text = f"{short(attack)} {PAYLOAD_TEXT[payload].split()[0]} damage (only when {condition})"
                rec["kept" if in_look else "missing"].append(text)
                return 2
            kind = self.get(effector)[0]
            interval = 0.0
            if kind == "ContinuousAttackEffector":
                delay = float(self.fields(effector).get("delayTime", 0) or 0)
                interval = delay if delay > 0 else 1.0
            computed = self.computed(attack)
            # None: the dump did not expand the attack, so its value is unknown here.
            amount = max(1.0, computed) if computed is not None else None
            reads_bonus = any("BonusQuickHackDamage" in self.fields(m).get("refStat", "") for m in items(af.get("statModifiers")))
            if not reads_bonus:
                fix = "quickhack damage bonus applies"
                if fix not in rec["fixes"]:
                    rec["fixes"].append(fix)
            pulse = max(interval, 0.1) if length >= 600 else length
            rec["damage"].append(f"{num(amount) if amount is not None else '?'} {PAYLOAD_TEXT[payload].split()[0]}"
                                 + (f" every {num(interval)}s for {num(pulse)}s" if interval > 0 else " in one hit"))
            part_length = pulse if interval > 0 else (1.0 if length >= 600 else max(0.1, length))
            if not add_part(payload, part_length, amount, interval, source, look, attack):
                return 2
            rec["parts"][-1]["stacks"] = stackable and interval > 0
            return 1

        def add_status(status_id):
            if status_id in rec["statuses"]:
                return
            rec["statuses"].add(status_id)
            if status_id not in self.records:
                # Applied by an effector, so the dump did not walk it; the game has it.
                add_part(13, 600.0, 0.0, 1.0, short(status_id) + " (not in the dump)", status_id, None)
                return
            f = self.fields(status_id)
            source = short(status_id)
            length = self.status_duration(status_id)
            look = status_id
            control = self.control_payload(f)
            if control and add_part(control, length, 0.0, 1.0, source, look, None):
                look = None
            for package in items(f.get("packages")):
                pf = self.fields(package)
                for effector in items(pf.get("effectors")):
                    if damage_effector(effector, length, source, look, pf.get("stackable") == "true", True) == 1:
                        look = None
            if look:
                add_part(13, length, 0.0, 1.0, source, look, None)

        def completion_effector(effector):
            ef = self.fields(effector)
            kind = self.get(effector)[0]
            cls = ef.get("effectorClassName", kind)
            if cls == "SpreadEffector":
                return
            condition = self.condition(ef)
            checkable = not condition or self.supported(ef.get("prereqRecord"))
            if cls in PORTS and checkable:
                if cls in PORTED_STATUS:
                    add_status(PORTED_STATUS[cls])
                    rec["missing"].append(PORT_GAPS[cls])
                else:
                    rec["ports"].append(PORTS[cls] + (f" (only when {condition})" if condition else ""))
                return
            if kind == "SpreadInitEffector":
                rec["missing"].append(f"spread on completion ({short(ef.get('objectAction', '?'))})")
                return
            if kind == "ApplyStatusEffectEffector" and ef.get("statusEffect", "none") not in ("none", "None"):
                if not condition:
                    add_status(ef["statusEffect"])
                elif checkable:
                    # Checked per target at upload (SDPQHConditions).
                    rec["when"] = condition
                    add_status(ef["statusEffect"])
                    rec["when"] = None
                else:
                    rec["missing"].append(f"{short(ef['statusEffect'])} (only when {condition})")
                return
            if damage_effector(effector, 0.0, cls, None):
                return
            rec["missing"].append(cls + (f" (only when {condition})" if condition else ""))

        for effect in items(action.get("startEffects")):
            effector = self.fields(effect).get("effectorToTrigger", "none")
            if self.get(effector)[0] == "SpreadInitEffector":
                sf = self.fields(effector)
                rec["spread"] = dict(count=int(sf.get("spreadCount", 0)), range=float(sf.get("spreadDistance", -1)),
                                     bonus=int(sf.get("bonusJumps", 0)), overclock=sf.get("applyOverclock", "true") == "true")
        kept = self.chip_keeps()
        for effect in items(action.get("completionEffects")):
            ef = self.fields(effect)
            if ef.get("recipient", "none") not in ("none", "ObjectActionReference.Target") or effect in kept:
                continue
            if ef.get("statusEffect", "none") not in ("none", "None"):
                if ef["statusEffect"] not in BOOKKEEPING:
                    add_status(ef["statusEffect"])
            elif ef.get("effectorToTrigger", "none") not in ("none", "None"):
                completion_effector(ef["effectorToTrigger"])
        return rec

    def part_text(self, part):
        payload = part["payload"]
        amount = num(part["amount"]) if part["amount"] is not None else "?"
        if payload in (2, 3, 7, 8) and part["interval"] <= 0:
            what = f"{amount} {PAYLOAD_TEXT[payload].split()[0]} damage in one hit"
        else:
            what = PAYLOAD_TEXT[payload] + (" with no time limit" if part["duration"] >= 600 else f" for {num(part['duration'])}s")
            if payload in (2, 3, 7, 8):
                what += f", {amount} every {num(part['interval'])}s" + (" per stack" if part["stacks"] else "")
        if part["when"]:
            what = f"only when {part['when']} ({'after' if part['after'] else 'before'} the upload's statuses): " + what
        return what

    def explain_recreation(self, program):
        rec = self.recreation(program)
        out = [f"{program['title']} ({program['item']}) - " + self.coverage(rec)]
        for i, part in enumerate(rec["parts"], 1):
            out.append(f"  part {i}: {self.part_text(part)}")
            if part["look"] and part["look"] not in self.records:
                out.append(f"    wears {short(part['look'])} (not in the dump)")
            elif part["look"]:
                keeps, drops = self.look(part["look"])
                out.append(f"    wears {short(part['look'])}: keeps {' | '.join(keeps)}")
                if drops:
                    out.append(f"    look drops (our pulses replace): {', '.join(drops)}")
            else:
                out.append(f"    our status ({part['source']} is worn by another part)")
            if part["attack"]:
                out.append(f"    native hit: {self.attack_text(part['attack'])}")
        if rec["spread"]:
            s = rec["spread"]
            count = "perks" if s["count"] < 0 else str(s["count"] + s["bonus"])
            rng = "spread distance stat" if s["range"] < 0 else f"{num(s['range'])}m"
            out.append(f"  upload spread: {count} targets within {rng}" + (", plus the Overclock roll" if s["overclock"] else ""))
        if rec["ports"]:
            out.append("  chip runs: " + ", ".join(rec["ports"]))
        if rec["kept"]:
            out.append("  kept native in its look: " + "; ".join(rec["kept"]))
        if rec["fixes"]:
            out.append("  native bugs fixed: " + "; ".join(rec["fixes"]))
        if rec["missing"]:
            out.append("  not recreated: " + "; ".join(rec["missing"]))
        return "\n".join(out)

    @staticmethod
    def coverage(rec):
        if not any(not p["when"] for p in rec["parts"]):
            return "native only"
        return "recreated" if not rec["missing"] else "partly recreated"

    def markdown_row(self, program):
        rec = self.recreation(program)
        parts = "<br>".join(f"{self.part_text(p)} ({'look ' + short(p['look']) if p['look'] else 'our status'})"
                            for p in rec["parts"]) or "none"
        missing = "<br>".join(rec["missing"]) or "-"
        title = program["title"] + (" ++" if "PlusPlus" in program["item"] else "")
        return f"| {title} | {parts} | {missing} |"


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("program", nargs="?", help="title or item ID")
    parser.add_argument("--family", help="family file name, e.g. reboot-optics (reads families/<name>.json)")
    parser.add_argument("--all", action="store_true", help="every program in the dump")
    parser.add_argument("--recreation", action="store_true", help="show what the Build 14 importer rebuilds")
    parser.add_argument("--markdown", action="store_true", help="with --recreation: one table row per program")
    parser.add_argument("--dump", default=None, help="compact dump to read")
    args = parser.parse_args()
    path = Path(args.dump) if args.dump else (FAMILIES / f"{args.family}.json" if args.family else DEFAULT)
    dump = Dump(path)
    if args.all or args.family:
        programs = dump.programs
    elif args.program:
        programs = dump.find(args.program)
    else:
        parser.error("name a program, or use --family or --all")
    if args.markdown:
        print("| Program | Recreated parts (look) | Not recreated |\n|---|---|---|")
        for program in programs:
            print(dump.markdown_row(program))
        return
    for program in programs:
        print(dump.explain_recreation(program) if args.recreation else dump.behavior(program))
        print()


if __name__ == "__main__":
    main()
