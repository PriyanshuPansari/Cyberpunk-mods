"""Make declaration stubs from decompiled game scripts, for type-checking without the game.

Use this when the game's final.redscripts is not available (for example in a
cloud session). With the game installed, compile against the real bundle instead.

1. Clone the decompiled scripts for the target patch:
   git clone --depth 1 https://codeberg.org/adamsmasher/cyberpunk.git
2. python tools/MakeScriptStubs.py <cyberpunk-clone> .stage/stubs
3. Build redscript 1.0 from https://github.com/jac3km4/redscript. In
   crates/compiler/frontend/src/stages/resolution.rs, let annotations target
   source-defined symbols by making the `is_user_defined()` checks that report
   UserSymbolAnnotation skip when the RS_ALLOW_USER_ANN environment variable is set.
4. Make a base bundle that defines only the native class IScriptable (for example
   with redscript_io: ScriptBundle::default() plus Class::new("IScriptable", Public, native)).
5. Copy this mod's scripts, drop their `module SkillDrivenProgression` line, and run:
   RS_ALLOW_USER_ANN=1 redscript-cli lint -s .stage/stubs -s <TweakXL scripts> -s <mod copy> -b <base bundle>

Function bodies become `{ }`, so decompiler-only syntax inside them does not
matter. A clean lint proves names, signatures and types; it does not prove gameplay.
"""
import re
import sys
from pathlib import Path

FUNC = re.compile(r"\bfunc\s+\w+\s*\(")
FIELD_LINE = re.compile(r"^([ \t]*)((?:\w+[ \t]+)*?)let[ \t]", re.M)
DROP = {"edit", "inline", "instanceeditable", "replicated", "const"}


def clean_field(m):
    words = [w for w in m.group(2).split() if w not in DROP]
    return m.group(1) + "".join(w + " " for w in words) + "let "


def strip_bodies(text: str) -> str:
    out = []
    i = 0
    n = len(text)
    while i < n:
        m = FUNC.search(text, i)
        if not m:
            out.append(text[i:])
            break
        # Find the end of the signature: the first '{' or ';' at paren depth 0.
        j = m.end()
        depth = 1
        while j < n and depth > 0:
            if text[j] == "(":
                depth += 1
            elif text[j] == ")":
                depth -= 1
            j += 1
        k = j
        brackets = 0  # static array return types: [Int32; 45]
        while k < n and (text[k] not in "{;" or brackets > 0):
            if text[k] == "[":
                brackets += 1
            elif text[k] == "]":
                brackets -= 1
            k += 1
        if k >= n or text[k] == ";":
            # Script declarations without a body (abstract-style) get an empty one.
            line_start = text.rfind("\n", 0, m.start()) + 1
            if k < n and "native" not in text[line_start:m.start()]:
                out.append(text[i:k] + " { }")
            else:
                out.append(text[i:k + 1])
            i = k + 1
            continue
        out.append(text[i:k])
        # Skip the body, honouring strings.
        depth = 0
        p = k
        while p < n:
            c = text[p]
            if c == '"':
                p += 1
                while p < n and text[p] != '"':
                    if text[p] == "\\":
                        p += 1
                    p += 1
            elif c == "{":
                depth += 1
            elif c == "}":
                depth -= 1
                if depth == 0:
                    break
            p += 1
        out.append("{ }")
        i = p + 1
    return "".join(out)


def main():
    src, dst = Path(sys.argv[1]), Path(sys.argv[2])
    for path in src.rglob("*.swift"):
        text = path.read_text(encoding="utf-8", errors="replace")
        text = strip_bodies(text)
        text = FIELD_LINE.sub(clean_field, text)
        text = re.sub(r"^\s*@default\(.*\)\s*$", "", text, flags=re.M)
        # The compiler predefines IScriptable; redeclaring it never terminates.
        text = re.sub(r"^public native class IScriptable \{.*?^\}\n", "", text, flags=re.M | re.S)
        # Overrides in the game bundle may narrow visibility; the compiler rejects that.
        text = re.sub(r"^([ \t]*)(?:private|protected)\b(?=[^\n]*\bfunc\b)", r"\1public", text, flags=re.M)
        # Static and instance overloads that share a name are rejected; keep the instance one.
        text = re.sub(r"^[ \t]*public final static func (GetAttitudeTowards|ForceVisionAppearance|IsMagazineEmpty|SendForceRevealObjectEvent)\(.*$", "", text, flags=re.M)
        # Top-level `static` drops free natives (operators, NameToString) from the bundle.
        text = re.sub(r"^public static (native )?func\b", r"public \1func", text, flags=re.M)
        target = dst / path.relative_to(src).with_suffix(".reds")
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(text, encoding="utf-8")


BUILTINS = """public native struct NodeRef {}
public native struct CRUID {}
public native struct LocalizationString {}
public native struct redResourceReferenceScriptToken {}
"""


if __name__ == "__main__":
    main()
    (Path(sys.argv[2]) / "_builtins.reds").write_text(BUILTINS, encoding="utf-8")
