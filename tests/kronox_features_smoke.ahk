#Requires AutoHotkey v2.0
#Include "%A_LineFile%\..\..\lib\TowerXP.ahk"
#Include "%A_LineFile%\..\..\lib\KronoxFeatures.ahk"

failures := []
testRoot := A_Temp "\KronoxFeaturesSmoke-" DllCall("GetCurrentProcessId") "-" A_TickCount
DirCreate(testRoot)
settingsFile := testRoot "\settings.ini"
stateFile := testRoot "\state.ini"
profileFile := testRoot "\strategy_profiles.csv"
contextFile := testRoot "\run_context.csv"

Assert(condition, message) {
    global failures
    if (!condition)
        failures.Push(message)
}

Assert(KronoxStrategyDisplayName("", "enforcer.strat") = "Enforcer", "strategy filename fallback did not replace an empty title")
Assert(KronoxStrategyDisplayName("Community Title", "ignored.strat") = "Community Title", "strategy metadata title was not preserved")
favoriteStrategies := KronoxStrategyFavoritesParse("Frost Farm.strat|easy farm.strat|FROST FARM.STRAT")
Assert(favoriteStrategies.Count = 2, "strategy favorites were not deduplicated case-insensitively")
Assert(favoriteStrategies.Has("frost farm.strat"), "strategy favorite keys were not normalized")
Assert(KronoxStrategyFavoritesSerialize(favoriteStrategies) = "easy farm.strat|FROST FARM.STRAT", "strategy favorites were not serialized stably")
Assert(KronoxStrategyMatchesLibraryFilter("Frost", "Frost Farm.strat", "Favorites", favoriteStrategies), "Favorites filter rejected a favorite strategy")
Assert(!KronoxStrategyMatchesLibraryFilter("Frost", "Other.strat", "Favorites", favoriteStrategies), "Favorites filter included a non-favorite strategy")
Assert(KronoxStrategyMatchesLibraryFilter("Hardcore", "Other.strat", "hardcore", favoriteStrategies), "gamemode filter was not case-insensitive")
Assert(!KronoxStrategyMatchesLibraryFilter("Easy", "Other.strat", "Frost", favoriteStrategies), "gamemode filter included the wrong mode")

IniWrite(1, settingsFile, "EvolutionQueue", "Enabled")
Assert(KronoxEvolutionTokens("Operator; Juggernaut`nKingpin").Length = 3, "evolution queue did not accept supported separators")
IniWrite("Operator; Juggernaut, Kingpin", settingsFile, "EvolutionQueue", "Towers")
IniWrite(0, settingsFile, TowerXPSectionName("Operator"), "Level")
IniWrite(0, settingsFile, TowerXPSectionName("Juggernaut"), "Level")
IniWrite(0, settingsFile, TowerXPSectionName("Kingpin"), "Level")

prepared := KronoxEvolutionPrepare(settingsFile, stateFile, [2, 4])
Assert(prepared.enabled && prepared.assignments.Count = 2, "evolution queue did not fill two Abstract slots")
Assert(prepared.assignments.Has(2) && prepared.assignments[2] = "Operator", "slot 2 did not receive the first queued tower")
Assert(prepared.assignments.Has(4) && prepared.assignments[4] = "Juggernaut", "slot 4 did not receive the second queued tower")

loadout := KronoxEvolutionBuildLoadout("G Soldier, Abstract, Engineer, Abstract, DJ", [2, 4], settingsFile, stateFile)
Assert(loadout.valid, "evolution queue did not build a valid effective loadout")
Assert(loadout.text = "G Soldier, Operator, Engineer, Juggernaut, DJ", "effective loadout order was incorrect: " loadout.text)

IniWrite(20, settingsFile, TowerXPSectionName("Operator"), "Level")
advanced := KronoxEvolutionAdvanceCompleted(settingsFile, stateFile)
Assert(advanced.changed, "completed evolution tower did not advance the queue")
Assert(advanced.assignments.Has(2) && advanced.assignments[2] = "Kingpin", "next evolution tower was not assigned to the freed slot")

IniWrite(20, settingsFile, TowerXPSectionName("Juggernaut"), "Level")
IniWrite(20, settingsFile, TowerXPSectionName("Kingpin"), "Level")
complete := KronoxEvolutionAdvanceCompleted(settingsFile, stateFile)
Assert(complete.complete, "evolution queue did not report completion at level 20")

Assert(Abs(KronoxModifierMultiplier("Exploding, Speedy") - 1.56) < 0.001, "modifier multiplier was not compounded")
Assert(KronoxCanonicalModifierSet("Speedy, Exploding") = KronoxCanonicalModifierSet("Exploding, Speedy"), "modifier sets split when their selection order changed")
IniWrite(1, settingsFile, "Analytics", "WeekendXPBoost")
IniWrite(1, settingsFile, "Analytics", "VIPXPBoost")
IniWrite("1.1", settingsFile, "Analytics", "OtherXPBoost")
boost := KronoxXPBoostContext(settingsFile, 6)
Assert(Abs(boost.factor - 2.475) < 0.001, "XP boost context did not combine weekend, VIP, and custom factors")
Assert(!KronoxXPBoostContext(settingsFile, 1).weekend, "weekend XP window incorrectly included Sunday UTC")
Assert(KronoxXPBoostContext(settingsFile).factor > 0, "UTC boost-window detection did not produce a valid factor")

IniWrite(1, settingsFile, "ResourceBudget", "TimeScaleEnabled")
IniWrite(3, settingsFile, "ResourceBudget", "TicketBalance")
IniWrite(1, settingsFile, "ResourceBudget", "TicketReserve")
IniWrite(1, settingsFile, "ResourceBudget", "TicketCostPerRun")
IniWrite(2, settingsFile, "ResourceBudget", "TicketMaxPerSession")
Assert(KronoxBudgetCheckTimeScale(settingsFile, stateFile).allowed, "first timescale ticket was incorrectly blocked")
KronoxBudgetRecordTimeScale(settingsFile, stateFile)
Assert(KronoxBudgetCheckTimeScale(settingsFile, stateFile).allowed, "second timescale ticket was incorrectly blocked")
KronoxBudgetRecordTimeScale(settingsFile, stateFile)
Assert(!KronoxBudgetCheckTimeScale(settingsFile, stateFile).allowed, "timescale reserve/session cap did not block a third ticket")
Assert(Integer(IniRead(settingsFile, "ResourceBudget", "TicketBalance", 0)) = 1, "timescale balance was not decremented")

IniWrite(1, settingsFile, "ResourceBudget", "ConsumableEnabled")
IniWrite(2, settingsFile, "ResourceBudget", "ConsumableMaxPerRun")
IniWrite(3, settingsFile, "ResourceBudget", "ConsumableMaxPerSession")
KronoxBudgetBeginRun(stateFile)
Assert(KronoxBudgetRecordConsumable(settingsFile, stateFile), "first consumable was incorrectly blocked")
Assert(KronoxBudgetRecordConsumable(settingsFile, stateFile), "second consumable was incorrectly blocked")
Assert(!KronoxBudgetRecordConsumable(settingsFile, stateFile), "per-run consumable cap did not block the third use")

KronoxProfilerBegin(true, "run-1", "Smoke Strategy", "ABC123", profileFile, stateFile)
KronoxProfilerStepEnd(1, "SpawnTower(1,2,3,test)", A_TickCount - 40)
KronoxProfilerRetry("SpawnTower", "placement retry")
Assert(FileExist(profileFile) && InStr(FileRead(profileFile), "placement retry"), "strategy profiler did not persist step/retry telemetry")
Assert(InStr(KronoxProfilerSummary(stateFile), "1 steps"), "strategy profiler summary was not published")

KronoxAppendRunContextEvent(contextFile, "run-1", "STARTED", boost.profile, boost.factor,
    "Exploding, Speedy", 1.56, "2x", "v2.6.1", "Normal")
Assert(FileExist(contextFile) && InStr(FileRead(contextFile), "Weekend 2x"), "run context ledger did not store boost/modifier context")

Assert(KronoxExtractTDSVersion("Tower Defense Simulator v2.6.1") = "v2.6.1", "TDS version text was not parsed")
baseline := KronoxCanaryPrepare(settingsFile, stateFile, "ABC123", "v2.6.1")
Assert(!baseline.active, "first observed TDS version should only establish a baseline")
changed := KronoxCanaryPrepare(settingsFile, stateFile, "ABC123", "v2.6.2")
Assert(changed.active && changed.changed, "TDS version change did not arm a canary")
passed := KronoxCanaryRecordResult(settingsFile, stateFile, "triumph")
Assert(passed.active && !passed.stop, "successful canary was not accepted")
changedAgain := KronoxCanaryPrepare(settingsFile, stateFile, "ABC123", "v2.6.3")
failed := KronoxCanaryRecordResult(settingsFile, stateFile, "loss")
Assert(changedAgain.active && failed.stop, "failed canary did not stop unattended looping")
recoveryCanary := KronoxCanaryPrepare(settingsFile, stateFile, "ABC123", "v2.6.4")
IniWrite(1, stateFile, "State", "Running")
Assert(recoveryCanary.active && KronoxCanaryBlockRecovery(settingsFile, stateFile, "join timeout"), "watchdog recovery was not blocked during a canary")
Assert(Integer(IniRead(stateFile, "State", "Running", 1)) = 0, "canary recovery block did not stop the macro")

IniWrite(1, settingsFile, "Reliability", "AbsoluteMode")
IniWrite(300000, settingsFile, "Reliability", "JoinTimeoutMs")
IniWrite(600000, settingsFile, "Reliability", "IdleTimeoutMs")
IniWrite(1, stateFile, "State", "Running")
IniWrite(4242, stateFile, "Health", "OwnerPID")
IniWrite("join-select-difficulty-selected", stateFile, "Health", "Phase")
IniWrite(1000, stateFile, "Health", "PhaseStartedTick")
IniWrite(1000, stateFile, "Health", "ProgressTick")
Assert(KronoxAbsoluteStallReason(settingsFile, stateFile, 4242, 300999) = "", "Absolute Mode fired before the five-minute join deadline")
Assert(KronoxAbsoluteStallReason(settingsFile, stateFile, 4242, 301000) = "join-timeout:join-select-difficulty-selected", "Absolute Mode did not detect a five-minute join stall")
IniWrite("strategy-maintenance", stateFile, "Health", "Phase")
IniWrite(400000, stateFile, "Health", "PhaseStartedTick")
IniWrite(2000, stateFile, "Health", "ProgressTick")
Assert(KronoxAbsoluteStallReason(settingsFile, stateFile, 4242, 602000) = "no-progress:strategy-maintenance", "Absolute Mode did not detect ten minutes without progress")
IniWrite(602000, stateFile, "Health", "ProgressTick")
Assert(KronoxAbsoluteStallReason(settingsFile, stateFile, 4242, 602001) = "", "fresh progress did not clear the Absolute Mode stall")

if (InStr(testRoot, A_Temp "\KronoxFeaturesSmoke-") = 1)
    DirDelete(testRoot, true)

if (failures.Length > 0) {
    for failure in failures
        FileAppend("FAIL " failure "`n", "*")
    ExitApp(1)
}
FileAppend("PASS strategy metadata, evolution queue, profiler, ROI context, boosts, budgets, update canary, and Absolute Mode`n", "*")
ExitApp(0)
