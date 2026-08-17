#Requires AutoHotkey v2.0

; Shared, side-effect-light feature rules used by both Main.ahk and the
; watchdog. Keeping the decisions here prevents the two processes from
; disagreeing about queue state, budgets, boost context, or canary results.

KronoxFeatureBool(value) {
    text := StrLower(Trim(String(value)))
    return text = "1" || text = "on" || text = "true" || text = "yes"
}

KronoxJoin(values, separator := ", ") {
    result := ""
    for index, value in values
        result .= (index > 1 ? separator : "") String(value)
    return result
}

KronoxArrayContains(values, expected) {
    expected := StrLower(Trim(String(expected)))
    for value in values {
        if (StrLower(Trim(String(value))) = expected)
            return true
    }
    return false
}

KronoxStrategyDisplayName(title, fileName) {
    title := Trim(String(title))
    if (title != "")
        return title

    name := String(fileName)
    SplitPath(name, , , , &nameNoExt)
    nameNoExt := StrReplace(nameNoExt, "_", " ")
    nameNoExt := RegExReplace(nameNoExt, "\s+", " ")
    nameNoExt := Trim(nameNoExt, " .-_`t")
    if (nameNoExt != "" && nameNoExt = StrLower(nameNoExt))
        nameNoExt := StrTitle(nameNoExt)
    return nameNoExt != "" ? nameNoExt : "Unnamed Strategy"
}

KronoxStrategyFavoriteKey(fileName) {
    return StrLower(Trim(String(fileName)))
}

KronoxStrategyFavoritesParse(value) {
    favorites := Map()
    for rawName in StrSplit(String(value), "|") {
        fileName := Trim(rawName)
        key := KronoxStrategyFavoriteKey(fileName)
        if (key != "")
            favorites[key] := fileName
    }
    return favorites
}

KronoxStrategyFavoritesSerialize(favorites) {
    names := []
    for key, fileName in favorites {
        fileName := Trim(String(fileName))
        if (fileName != "")
            names.Push(fileName)
    }

    ; Stable output keeps Settings.tds readable and avoids unnecessary rewrites.
    if (names.Length > 1) {
        Loop names.Length - 1 {
            swapped := false
            Loop names.Length - A_Index {
                index := A_Index
                if (StrCompare(StrLower(names[index]), StrLower(names[index + 1])) > 0) {
                    temp := names[index]
                    names[index] := names[index + 1]
                    names[index + 1] := temp
                    swapped := true
                }
            }
            if (!swapped)
                break
        }
    }
    return KronoxJoin(names, "|")
}

KronoxStrategyMatchesLibraryFilter(difficulty, fileName, filterName, favorites) {
    filterName := Trim(String(filterName))
    if (filterName = "" || StrLower(filterName) = "all")
        return true
    if (StrLower(filterName) = "favorites")
        return favorites.Has(KronoxStrategyFavoriteKey(fileName))
    return StrLower(Trim(String(difficulty))) = StrLower(filterName)
}

KronoxTowerDefinition(towerName) {
    normalized := RegExReplace(StrLower(Trim(String(towerName))), "[^a-z0-9]+", "")
    for definition in TowerXPDefinitions() {
        candidate := RegExReplace(StrLower(definition.name), "[^a-z0-9]+", "")
        if (candidate = normalized)
            return definition
    }
    return ""
}

KronoxEvolutionQueue(settingsFile) {
    queue := []
    seen := Map()
    rawQueue := IniRead(settingsFile, "EvolutionQueue", "Towers", "")
    for rawName in KronoxEvolutionTokens(rawQueue) {
        definition := KronoxTowerDefinition(rawName)
        if (!IsObject(definition))
            continue
        key := StrLower(definition.name)
        if (seen.Has(key))
            continue
        seen[key] := true
        queue.Push(definition.name)
    }
    return queue
}

KronoxEvolutionTokens(value) {
    normalized := StrReplace(String(value), "`r`n", ",")
    normalized := StrReplace(normalized, "`n", ",")
    normalized := StrReplace(normalized, ";", ",")
    return StrSplit(normalized, ",")
}

KronoxAbsoluteStallReason(settingsFile, stateFile, ownerPid, nowTick := "") {
    if (!KronoxFeatureBool(IniRead(settingsFile, "Reliability", "AbsoluteMode", 0)))
        return ""
    if (!KronoxFeatureBool(IniRead(stateFile, "State", "Running", 0)))
        return ""
    if (String(IniRead(stateFile, "Health", "OwnerPID", "")) != String(ownerPid))
        return ""

    phase := Trim(IniRead(stateFile, "Health", "Phase", ""))
    if (phase = "" || RegExMatch(phase, "i)^(idle|stopped|strategy-stopping|reloading|watchdog-restarting)$"))
        return ""

    if (nowTick = "")
        nowTick := A_TickCount
    nowTick := Integer(nowTick)

    phaseStarted := Integer(IniRead(stateFile, "Health", "PhaseStartedTick", 0))
    if (phaseStarted > 0 && nowTick >= phaseStarted
        && RegExMatch(phase, "i)^(roblox-launch|roblox-lobby|join-|map-voting|match-setup)")) {
        joinTimeoutMs := Max(60000, Integer(IniRead(settingsFile, "Reliability", "JoinTimeoutMs", 300000)))
        if ((nowTick - phaseStarted) >= joinTimeoutMs)
            return "join-timeout:" phase
    }

    progressTick := Integer(IniRead(stateFile, "Health", "ProgressTick", 0))
    if (progressTick <= 0 || nowTick < progressTick)
        return ""
    idleTimeoutMs := Max(120000, Integer(IniRead(settingsFile, "Reliability", "IdleTimeoutMs", 600000)))
    if ((nowTick - progressTick) >= idleTimeoutMs)
        return "no-progress:" phase
    return ""
}

KronoxEvolutionParseSlots(value) {
    slots := []
    seen := Map()
    for rawSlot in StrSplit(String(value), ",") {
        rawSlot := Trim(rawSlot)
        if (!IsNumber(rawSlot))
            continue
        slot := Integer(rawSlot)
        if (slot < 1 || slot > 5 || seen.Has(slot))
            continue
        seen[slot] := true
        slots.Push(slot)
    }
    return slots
}

KronoxEvolutionParseAssignments(value) {
    assignments := Map()
    for pairText in StrSplit(String(value), "|") {
        if !RegExMatch(Trim(pairText), "^([1-5])\s*=\s*(.+)$", &pair)
            continue
        definition := KronoxTowerDefinition(pair[2])
        if (IsObject(definition))
            assignments[Integer(pair[1])] := definition.name
    }
    return assignments
}

KronoxEvolutionSerializeAssignments(assignments) {
    text := ""
    Loop 5 {
        slot := A_Index
        if (assignments.Has(slot))
            text .= (text != "" ? "|" : "") slot "=" assignments[slot]
    }
    return text
}

KronoxEvolutionTowerIsMax(settingsFile, towerName) {
    definition := KronoxTowerDefinition(towerName)
    if (!IsObject(definition))
        return false
    section := TowerXPSectionName(definition.name)
    return Integer(IniRead(settingsFile, section, "Level", 0)) >= definition.maxLevel
}

KronoxEvolutionPrepare(settingsFile, stateFile, activeSlots := "") {
    result := {enabled: false, changed: false, complete: false, assignments: Map(), message: ""}
    if (!KronoxFeatureBool(IniRead(settingsFile, "EvolutionQueue", "Enabled", 0)))
        return result

    queue := KronoxEvolutionQueue(settingsFile)
    if (queue.Length = 0) {
        result.message := "Evolution Queue is enabled but contains no supported Tower Evolution towers."
        return result
    }
    result.enabled := true

    if (!IsObject(activeSlots))
        activeSlots := KronoxEvolutionParseSlots(activeSlots = "" ? IniRead(stateFile, "State", "EvolutionActiveSlots", "") : activeSlots)
    if (activeSlots.Length = 0) {
        result.message := "Evolution Queue needs at least one active Abstract strategy slot."
        return result
    }

    activeSlotSet := Map()
    for slot in activeSlots
        activeSlotSet[Integer(slot)] := true
    IniWrite(KronoxJoin(activeSlots), stateFile, "State", "EvolutionActiveSlots")

    assignments := KronoxEvolutionParseAssignments(IniRead(settingsFile, "EvolutionQueue", "Assignments", ""))
    originalText := KronoxEvolutionSerializeAssignments(assignments)
    for slot, towerName in assignments.Clone() {
        if (!activeSlotSet.Has(slot) || !KronoxArrayContains(queue, towerName) || KronoxEvolutionTowerIsMax(settingsFile, towerName))
            assignments.Delete(slot)
    }

    assignedTowers := []
    for slot, towerName in assignments
        assignedTowers.Push(towerName)

    for slot in activeSlots {
        if (assignments.Has(slot))
            continue
        for towerName in queue {
            if (KronoxEvolutionTowerIsMax(settingsFile, towerName) || KronoxArrayContains(assignedTowers, towerName))
                continue
            assignments[slot] := towerName
            assignedTowers.Push(towerName)
            section := TowerXPSectionName(towerName)
            IniWrite(1, settingsFile, section, "Tracked")
            break
        }
    }

    serialized := KronoxEvolutionSerializeAssignments(assignments)
    if (serialized != originalText) {
        IniWrite(serialized, settingsFile, "EvolutionQueue", "Assignments")
        IniWrite(1, stateFile, "State", "EvolutionQueuePendingEquip")
        result.changed := true
    }

    allComplete := true
    for towerName in queue {
        if (!KronoxEvolutionTowerIsMax(settingsFile, towerName)) {
            allComplete := false
            break
        }
    }
    result.complete := allComplete
    result.assignments := assignments
    if (allComplete)
        result.message := "Evolution Queue complete: " KronoxJoin(queue)
    else if (assignments.Count = 0)
        result.message := "Evolution Queue has unfinished towers but no free Abstract assignment."
    return result
}

KronoxEvolutionBuildLoadout(requiredTowers, activeSlots, settingsFile, stateFile) {
    prepared := KronoxEvolutionPrepare(settingsFile, stateFile, activeSlots)
    result := {valid: false, text: "", message: prepared.message, prepared: prepared}
    if (!prepared.enabled || prepared.complete || prepared.assignments.Count = 0)
        return result

    activeSlotSet := Map()
    for slot in activeSlots
        activeSlotSet[Integer(slot)] := true
    loadout := []
    slot := 0
    for rawTower in StrSplit(requiredTowers, ",") {
        towerName := Trim(rawTower)
        if (towerName = "")
            continue
        slot += 1
        if (RegExReplace(StrLower(towerName), "[^a-z0-9]+", "") = "abstract") {
            if (activeSlotSet.Has(slot) && prepared.assignments.Has(slot))
                loadout.Push(prepared.assignments[slot])
            continue
        }
        loadout.Push(towerName)
    }

    if (loadout.Length = 0 || loadout.Length > 5) {
        result.message := "Evolution Queue produced an invalid " loadout.Length "-tower loadout."
        return result
    }
    result.valid := true
    result.text := KronoxJoin(loadout)
    return result
}

KronoxEvolutionAdvanceCompleted(settingsFile, stateFile) {
    result := {enabled: false, changed: false, complete: false, advanced: [], assignments: Map(), message: ""}
    if (!KronoxFeatureBool(IniRead(settingsFile, "EvolutionQueue", "Enabled", 0)))
        return result
    result.enabled := true

    assignments := KronoxEvolutionParseAssignments(IniRead(settingsFile, "EvolutionQueue", "Assignments", ""))
    for slot, towerName in assignments.Clone() {
        if (!KronoxEvolutionTowerIsMax(settingsFile, towerName))
            continue
        assignments.Delete(slot)
        result.advanced.Push(towerName)
        result.changed := true
    }
    if (result.changed)
        IniWrite(KronoxEvolutionSerializeAssignments(assignments), settingsFile, "EvolutionQueue", "Assignments")

    activeSlots := KronoxEvolutionParseSlots(IniRead(stateFile, "State", "EvolutionActiveSlots", ""))
    prepared := KronoxEvolutionPrepare(settingsFile, stateFile, activeSlots)
    result.changed := result.changed || prepared.changed
    result.complete := prepared.complete
    result.assignments := prepared.assignments
    if (result.changed)
        IniWrite(1, stateFile, "State", "EvolutionQueuePendingEquip")

    if (result.complete)
        result.message := "All queued Tower Evolutions reached level 20"
    else if (result.advanced.Length > 0)
        result.message := KronoxJoin(result.advanced) " completed; next queued tower assigned"
    else
        result.message := prepared.message
    return result
}

KronoxEvolutionAssignmentText(settingsFile) {
    assignments := KronoxEvolutionParseAssignments(IniRead(settingsFile, "EvolutionQueue", "Assignments", ""))
    parts := []
    Loop 5 {
        if (assignments.Has(A_Index))
            parts.Push("S" A_Index " " assignments[A_Index])
    }
    return parts.Length > 0 ? KronoxJoin(parts, " | ") : "Waiting for an Abstract strategy"
}

KronoxModifierMultiplier(modifiersText) {
    static multipliers := Map(
        "glass", 1.1, "flying", 1.2, "flying enemies", 1.2,
        "hidden", 1.2, "hidden enemies", 1.2,
        "healthy", 1.2, "healthy enemies", 1.2,
        "speedy", 1.2, "speedy enemies", 1.2,
        "exploding", 1.3, "exploding enemies", 1.3, "committed", 1.1,
        "limitation", 1.1, "limitations", 1.1, "quarantine", 1.3,
        "fog", 1.3, "broke", 1.2, "inflation", 1.2, "jailed", 1.2)
    multiplier := 1.0
    for rawModifier in StrSplit(String(modifiersText), ",") {
        name := StrLower(Trim(rawModifier))
        if (multipliers.Has(name))
            multiplier *= multipliers[name]
    }
    return Round(multiplier, 3)
}

KronoxCanonicalModifierSet(modifiersText) {
    names := []
    seen := Map()
    for rawModifier in StrSplit(String(modifiersText), ",") {
        name := Trim(rawModifier)
        key := StrLower(name)
        if (name = "" || seen.Has(key))
            continue
        seen[key] := true
        names.Push(name)
    }
    ; A set selected in a different UI order is still the same experiment.
    ; Stable alphabetical storage prevents duplicate analytics buckets.
    if (names.Length > 1) {
        Loop names.Length - 1 {
            swapped := false
            Loop names.Length - A_Index {
                index := A_Index
                if (StrCompare(StrLower(names[index]), StrLower(names[index + 1])) > 0) {
                    temp := names[index]
                    names[index] := names[index + 1]
                    names[index + 1] := temp
                    swapped := true
                }
            }
            if (!swapped)
                break
        }
    }
    return names.Length > 0 ? KronoxJoin(names) : "No modifiers"
}

KronoxXPBoostContext(settingsFile, dayOfWeek := 0) {
    if (dayOfWeek <= 0) {
        ; TDS schedules its recurring XP window in UTC. 1601-01-01 was a
        ; Monday, so this produces AutoHotkey's Sunday=1 ... Saturday=7 form
        ; without depending on the user's locale or local time zone.
        try dayOfWeek := Mod(DateDiff(A_NowUTC, "16010101", "Days") + 1, 7) + 1
        catch
            dayOfWeek := A_WDay
    }
    weekendEnabled := KronoxFeatureBool(IniRead(settingsFile, "Analytics", "WeekendXPBoost", 1))
    vipEnabled := KronoxFeatureBool(IniRead(settingsFile, "Analytics", "VIPXPBoost", 0))
    otherText := IniRead(settingsFile, "Analytics", "OtherXPBoost", "1.0")
    otherMultiplier := IsNumber(otherText) ? Max(0.1, Number(otherText)) : 1.0
    weekendActive := weekendEnabled && (dayOfWeek = 6 || dayOfWeek = 7)
    ; Weekend (+100%) and VIP (+25%) stack additively in TDS. User-entered
    ; boosts remain an explicit multiplier because their source may differ.
    factor := (1.0 + (weekendActive ? 1.0 : 0.0) + (vipEnabled ? 0.25 : 0.0)) * otherMultiplier
    parts := []
    if (weekendActive)
        parts.Push("Weekend 2x")
    if (vipEnabled)
        parts.Push("VIP 1.25x")
    if (Abs(otherMultiplier - 1.0) > 0.001)
        parts.Push("Other " Round(otherMultiplier, 2) "x")
    profile := parts.Length > 0 ? KronoxJoin(parts, " + ") : "Base XP"
    return {factor: Round(factor, 3), profile: profile, weekend: weekendActive, vip: vipEnabled}
}

KronoxBudgetCheckTimeScale(settingsFile, stateFile) {
    if (!KronoxFeatureBool(IniRead(settingsFile, "ResourceBudget", "TimeScaleEnabled", 0)))
        return {allowed: true, managed: false, reason: "Budget disabled"}
    balance := Max(0, Integer(IniRead(settingsFile, "ResourceBudget", "TicketBalance", 0)))
    reserve := Max(0, Integer(IniRead(settingsFile, "ResourceBudget", "TicketReserve", 0)))
    cost := Max(1, Integer(IniRead(settingsFile, "ResourceBudget", "TicketCostPerRun", 1)))
    maxSession := Max(0, Integer(IniRead(settingsFile, "ResourceBudget", "TicketMaxPerSession", 0)))
    used := Max(0, Integer(IniRead(stateFile, "State", "BudgetTimescaleUsed", 0)))
    if (balance - cost < reserve)
        return {allowed: false, managed: true, reason: "ticket reserve would fall below " reserve, balance: balance, used: used, cost: cost}
    if (maxSession > 0 && used + cost > maxSession)
        return {allowed: false, managed: true, reason: "session ticket cap " maxSession " reached", balance: balance, used: used, cost: cost}
    return {allowed: true, managed: true, reason: "", balance: balance, used: used, cost: cost}
}

KronoxBudgetRecordTimeScale(settingsFile, stateFile, cost := 0) {
    check := KronoxBudgetCheckTimeScale(settingsFile, stateFile)
    if (!check.managed)
        return
    if (cost <= 0)
        cost := check.cost
    IniWrite(Max(0, check.balance - cost), settingsFile, "ResourceBudget", "TicketBalance")
    IniWrite(check.used + cost, stateFile, "State", "BudgetTimescaleUsed")
}

KronoxBudgetCheckConsumable(settingsFile, stateFile, amount := 1) {
    if (!KronoxFeatureBool(IniRead(settingsFile, "ResourceBudget", "ConsumableEnabled", 0)))
        return {allowed: true, managed: false, reason: "Budget disabled"}
    perRun := Max(0, Integer(IniRead(settingsFile, "ResourceBudget", "ConsumableMaxPerRun", 0)))
    perSession := Max(0, Integer(IniRead(settingsFile, "ResourceBudget", "ConsumableMaxPerSession", 0)))
    runUsed := Max(0, Integer(IniRead(stateFile, "State", "BudgetConsumablesRun", 0)))
    sessionUsed := Max(0, Integer(IniRead(stateFile, "State", "BudgetConsumablesSession", 0)))
    if (perRun > 0 && runUsed + amount > perRun)
        return {allowed: false, managed: true, reason: "per-run consumable cap " perRun " reached"}
    if (perSession > 0 && sessionUsed + amount > perSession)
        return {allowed: false, managed: true, reason: "session consumable cap " perSession " reached"}
    return {allowed: true, managed: true, reason: ""}
}

KronoxBudgetRecordConsumable(settingsFile, stateFile, amount := 1) {
    check := KronoxBudgetCheckConsumable(settingsFile, stateFile, amount)
    if (!check.allowed)
        return false
    IniWrite(Integer(IniRead(stateFile, "State", "BudgetConsumablesRun", 0)) + amount, stateFile, "State", "BudgetConsumablesRun")
    IniWrite(Integer(IniRead(stateFile, "State", "BudgetConsumablesSession", 0)) + amount, stateFile, "State", "BudgetConsumablesSession")
    return true
}

KronoxBudgetResetSession(stateFile) {
    IniWrite(0, stateFile, "State", "BudgetTimescaleUsed")
    IniWrite(0, stateFile, "State", "BudgetConsumablesSession")
    IniWrite(0, stateFile, "State", "BudgetConsumablesRun")
}

KronoxBudgetBeginRun(stateFile) {
    IniWrite(0, stateFile, "State", "BudgetConsumablesRun")
}

KronoxProfilerState() {
    static state := {enabled: false, runId: "", strategy: "", fingerprint: "", file: "",
        stateFile: "", steps: 0, errors: 0, retries: 0, totalMs: 0, slowestMs: 0,
        slowestStep: 0, slowestAction: ""}
    return state
}

KronoxProfilerBegin(enabled, runId, strategyName, fingerprint, profileFile, stateFile) {
    state := KronoxProfilerState()
    state.enabled := enabled
    state.runId := runId
    state.strategy := strategyName
    state.fingerprint := fingerprint
    state.file := profileFile
    state.stateFile := stateFile
    state.steps := 0, state.errors := 0, state.retries := 0, state.totalMs := 0
    state.slowestMs := 0, state.slowestStep := 0, state.slowestAction := ""
    if (!enabled)
        return
    if (!FileExist(profileFile))
        FileAppend("Timestamp,RunId,Strategy,Fingerprint,StepIndex,Event,Status,DurationMs,Action,Detail`n", profileFile, "UTF-8")
    IniWrite(runId, stateFile, "Profiler", "ActiveRunId")
    IniWrite(strategyName, stateFile, "Profiler", "Strategy")
    IniWrite(fingerprint, stateFile, "Profiler", "Fingerprint")
}

KronoxProfilerAppend(eventName, stepIndex, status, durationMs, action, detail := "") {
    state := KronoxProfilerState()
    if (!state.enabled)
        return
    row := KronoxCsvField(FormatTime(, "yyyy-MM-dd HH:mm:ss")) "," KronoxCsvField(state.runId) ","
        . KronoxCsvField(state.strategy) "," KronoxCsvField(state.fingerprint) "," Integer(stepIndex) ","
        . KronoxCsvField(eventName) "," KronoxCsvField(status) "," Integer(durationMs) ","
        . KronoxCsvField(action) "," KronoxCsvField(detail) "`n"
    FileAppend(row, state.file, "UTF-8")
}

KronoxProfilerStepStart(stepIndex, action) {
    state := KronoxProfilerState()
    return state.enabled ? A_TickCount : 0
}

KronoxProfilerStepEnd(stepIndex, action, startedTick, status := "OK", detail := "") {
    state := KronoxProfilerState()
    if (!state.enabled || startedTick <= 0)
        return
    duration := Max(0, A_TickCount - startedTick)
    state.steps += 1
    state.totalMs += duration
    if (StrUpper(status) != "OK")
        state.errors += 1
    if (duration > state.slowestMs) {
        state.slowestMs := duration
        state.slowestStep := stepIndex
        state.slowestAction := action
    }
    KronoxProfilerAppend("STEP", stepIndex, status, duration, action, detail)
    KronoxProfilerPublish()
}

KronoxProfilerRetry(action, detail := "") {
    state := KronoxProfilerState()
    if (!state.enabled)
        return
    state.retries += 1
    KronoxProfilerAppend("RETRY", state.steps + 1, "RETRY", 0, action, detail)
    KronoxProfilerPublish()
}

KronoxProfilerPublish() {
    state := KronoxProfilerState()
    if (!state.enabled || state.stateFile = "")
        return
    IniWrite(state.steps, state.stateFile, "Profiler", "Steps")
    IniWrite(state.errors, state.stateFile, "Profiler", "Errors")
    IniWrite(state.retries, state.stateFile, "Profiler", "Retries")
    IniWrite(state.totalMs, state.stateFile, "Profiler", "TotalMs")
    IniWrite(state.slowestMs, state.stateFile, "Profiler", "SlowestMs")
    IniWrite(state.slowestStep, state.stateFile, "Profiler", "SlowestStep")
    IniWrite(SubStr(state.slowestAction, 1, 180), state.stateFile, "Profiler", "SlowestAction")
    IniWrite(FormatTime(, "yyyy-MM-dd HH:mm:ss"), state.stateFile, "Profiler", "UpdatedAt")
}

KronoxProfilerRecordResult(profileFile, stateFile, runId, resultStatus) {
    if (!KronoxFeatureBool(IniRead(stateFile, "Profiler", "Enabled", 0)))
        return
    if (!FileExist(profileFile))
        FileAppend("Timestamp,RunId,Strategy,Fingerprint,StepIndex,Event,Status,DurationMs,Action,Detail`n", profileFile, "UTF-8")
    strategy := IniRead(stateFile, "Profiler", "Strategy", "Unknown")
    fingerprint := IniRead(stateFile, "Profiler", "Fingerprint", "legacy")
    row := KronoxCsvField(FormatTime(, "yyyy-MM-dd HH:mm:ss")) "," KronoxCsvField(runId) ","
        . KronoxCsvField(strategy) "," KronoxCsvField(fingerprint) ",0,RESULT,"
        . KronoxCsvField(resultStatus) ",0,Result," KronoxCsvField("confirmed result") "`n"
    FileAppend(row, profileFile, "UTF-8")
    IniWrite(resultStatus, stateFile, "Profiler", "LastResult")
    IniWrite(runId, stateFile, "Profiler", "LastRunId")
}

KronoxProfilerSummary(stateFile) {
    steps := Integer(IniRead(stateFile, "Profiler", "Steps", 0))
    if (steps = 0)
        return "No profiled strategy steps yet"
    retries := Integer(IniRead(stateFile, "Profiler", "Retries", 0))
    errors := Integer(IniRead(stateFile, "Profiler", "Errors", 0))
    totalMs := Integer(IniRead(stateFile, "Profiler", "TotalMs", 0))
    slowestMs := Integer(IniRead(stateFile, "Profiler", "SlowestMs", 0))
    slowestStep := Integer(IniRead(stateFile, "Profiler", "SlowestStep", 0))
    return steps " steps · " retries " retries · " errors " errors · " Round(totalMs / 1000, 1)
        . "s action time · slowest #" slowestStep " " Round(slowestMs / 1000, 1) "s"
}

KronoxCsvField(value) {
    return '"' StrReplace(String(value), '"', '""') '"'
}

KronoxAppendRunContextEvent(file, runId, eventName, boostProfile, boostFactor, modifierSet,
    modifierMultiplier, timeScaleMode, tdsVersion, canaryStatus) {
    if (!FileExist(file))
        FileAppend("Timestamp,RunId,Event,XPBoostProfile,XPBoostFactor,ModifierSet,ModifierMultiplier,TimeScale,TDSVersion,CanaryStatus`n", file, "UTF-8")
    row := KronoxCsvField(FormatTime(, "yyyy-MM-dd HH:mm:ss")) ","
        . KronoxCsvField(runId) "," KronoxCsvField(eventName) ","
        . KronoxCsvField(boostProfile) "," boostFactor "," KronoxCsvField(modifierSet) ","
        . modifierMultiplier "," KronoxCsvField(timeScaleMode) "," KronoxCsvField(tdsVersion) ","
        . KronoxCsvField(canaryStatus) "`n"
    FileAppend(row, file, "UTF-8")
}

KronoxExtractTDSVersion(text) {
    if RegExMatch(String(text), "i)\bv\s*(\d+\.\d+(?:\.\d+)?(?:[a-z0-9.-]*)?)", &versionMatch)
        return "v" versionMatch[1]
    return ""
}

KronoxCanaryPrepare(settingsFile, stateFile, strategyFingerprint, detectedVersion) {
    result := {enabled: false, active: false, changed: false, message: ""}
    if (!KronoxFeatureBool(IniRead(settingsFile, "UpdateCanary", "Enabled", 1)))
        return result
    result.enabled := true
    detectedVersion := Trim(detectedVersion)
    if (detectedVersion = "") {
        result.message := "TDS version could not be read; canary was not armed."
        return result
    }

    previousVersion := IniRead(settingsFile, "UpdateCanary", "LastObservedVersion", "")
    IniWrite(detectedVersion, stateFile, "State", "ActiveTDSVersion")
    if (previousVersion = "") {
        IniWrite(detectedVersion, settingsFile, "UpdateCanary", "LastObservedVersion")
        result.message := "TDS version baseline saved as " detectedVersion
        return result
    }

    if (StrLower(previousVersion) != StrLower(detectedVersion)) {
        IniWrite(1, stateFile, "State", "CanaryActive")
        IniWrite(previousVersion, stateFile, "State", "CanaryPreviousVersion")
        IniWrite(detectedVersion, stateFile, "State", "CanaryVersion")
        IniWrite(strategyFingerprint, stateFile, "State", "CanaryStrategyFingerprint")
        IniWrite(detectedVersion, settingsFile, "UpdateCanary", "LastObservedVersion")
        result.active := true
        result.changed := true
        result.message := "TDS changed from " previousVersion " to " detectedVersion "; one guarded canary run is active."
        return result
    }

    result.active := KronoxFeatureBool(IniRead(stateFile, "State", "CanaryActive", 0))
    result.message := result.active ? "A guarded " detectedVersion " canary run is active." : "TDS " detectedVersion " matches the last observed version."
    return result
}

KronoxCanaryRecordResult(settingsFile, stateFile, resultStatus) {
    result := {active: false, stop: false, message: ""}
    if (!KronoxFeatureBool(IniRead(stateFile, "State", "CanaryActive", 0)))
        return result
    result.active := true
    version := IniRead(stateFile, "State", "CanaryVersion", "Unknown")
    fingerprint := IniRead(stateFile, "State", "CanaryStrategyFingerprint", "legacy")
    if (StrLower(resultStatus) = "triumph") {
        IniWrite(version, settingsFile, "UpdateCanary", "LastVerifiedVersion")
        IniWrite(fingerprint, settingsFile, "UpdateCanary", "LastVerifiedStrategy")
        result.message := "Canary passed on " version
    } else {
        result.stop := true
        result.message := "Canary failed on " version "; unattended looping stopped"
        IniWrite(0, stateFile, "State", "Running")
        IniWrite(result.message, stateFile, "State", "LastStopReason")
    }
    IniWrite(0, stateFile, "State", "CanaryActive")
    IniWrite(resultStatus, settingsFile, "UpdateCanary", "LastCanaryResult")
    IniWrite(FormatTime(, "yyyy-MM-dd HH:mm:ss"), settingsFile, "UpdateCanary", "LastCanaryAt")
    return result
}

KronoxCanaryBlockRecovery(settingsFile, stateFile, reason) {
    if (!KronoxFeatureBool(IniRead(settingsFile, "UpdateCanary", "Enabled", 1))
        || !KronoxFeatureBool(IniRead(stateFile, "State", "CanaryActive", 0)))
        return false
    IniWrite(0, stateFile, "State", "Running")
    IniWrite("Canary recovery blocked: " reason, stateFile, "State", "LastStopReason")
    IniWrite(reason, settingsFile, "UpdateCanary", "LastCanaryResult")
    IniWrite(FormatTime(, "yyyy-MM-dd HH:mm:ss"), settingsFile, "UpdateCanary", "LastCanaryAt")
    return true
}
