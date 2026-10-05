param(
    [Parameter(Mandatory = $true)]
    [string]$ScriptingLog
)

$attributes = [ordered]@{
    Strength = 'StrengthAvailable'
    Reflexes = 'ReflexesAvailable'
    TechnicalAbility = 'TechnicalAbilityAvailable'
    Intelligence = 'IntelligenceAvailable'
    Cool = 'CoolAvailable'
}

$destination = Join-Path $PSScriptRoot '..\r6\tweaks\SDPSkills\SkillPassives.yaml'
$baseOffset = 3.0 - 17.0 / 59.0
$perSkill = 17.0 / 59.0
$invariant = [System.Globalization.CultureInfo]::InvariantCulture
$lines = [System.Collections.Generic.List[string]]::new()
$lines.Add('# Generated from the installed game TweakDB inventory (SDPFIND in CET scripting.log).')
$lines.Add('# Every attribute-reading stat modifier below reads a skill-derived proxy instead.')
$lines.Add('# The five *Available proxies equal 3 + (skillLevel - 1) * 17 / 59.')
$lines.Add('# Attributes remain computed for perk and dialogue checks, but no stat modifier')
$lines.Add('# listed here reads Strength, Reflexes, TechnicalAbility, Intelligence, or Cool.')
$lines.Add('Character.PlayerCyberwareSystem:')
$lines.Add('  statModifiers:')

$proxyInline = [ordered]@{
    Strength = 0
    Reflexes = 2
    Intelligence = 4
    TechnicalAbility = 6
    Cool = 8
}
foreach ($attribute in $attributes.Keys) {
    $proxy = $attributes[$attribute]
    $lines.Add('    - !append')
    $lines.Add('      $type: ConstantStatModifier')
    $lines.Add('      modifierType: Additive')
    $lines.Add("      statType: BaseStats.$proxy")
    $lines.Add('      value: ' + $baseOffset.ToString('0.000000000', $invariant))
}

$lines.Add('')
$lines.Add('# Reuse the original player modifiers so their reference object and')
$lines.Add('# other semantics remain intact; the constants above restore skill 1 = 3.')
foreach ($attribute in $attributes.Keys) {
    $id = "Character.PlayerCyberwareSystem_inline$($proxyInline[$attribute])"
    $lines.Add("$id.refStat: BaseStats.$($attribute)Skill")
    $lines.Add("$id.value: " + $perSkill.ToString('0.000000000', $invariant))
}

$records = [ordered]@{}
$pattern = 'SDPFIND gamedata(?:Combined|Curve)StatModifier_Record ([A-Za-z0-9_.]+) ref=(Strength|Reflexes|TechnicalAbility|Intelligence|Cool) stat='
foreach ($line in Get-Content -LiteralPath $ScriptingLog) {
    if ($line -match $pattern) {
        $id = $Matches[1]
        $attribute = $Matches[2]
        if ($id -notlike 'Character.PlayerCyberwareSystem_inline*') {
            $records[$id] = $attribute
        }
    }
}

if ($records.Count -lt 300) {
    throw "Only $($records.Count) attribute-linked records found; expected the full installed-game inventory."
}

$lines.Add('')
$lines.Add('# The existing curves, coefficients, and item effects stay intact.')
$lines.Add('# Only their reference stat changes to the matching skill-derived proxy.')
foreach ($id in ($records.Keys | Sort-Object)) {
    $lines.Add("$id.refStat: BaseStats.$($attributes[$records[$id]])")
}

[System.IO.File]::WriteAllLines($destination, $lines, [System.Text.UTF8Encoding]::new($false))
Write-Output "Wrote $($records.Count) record redirects to $destination"
