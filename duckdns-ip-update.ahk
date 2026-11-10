#requires AutoHotkey v2.0
#singleinstance force
Persistent

#include lib/Jsons.ahk
#include lib/MergeObjects.ahk

#include lib/PathUtils.ahk           ; path expansion, normalization, writability
#include lib/DefaultConfig.ahk       ; every setting and its default value
#include lib/Config.ahk              ; config.json path, load, create-from-example
#include lib/FileLog.ahk             ; small rotating log file
#include lib/DuckDns.ahk             ; the DuckDNS update request itself
#include lib/TrayMenu.ahk            ; system tray menu, icon and tooltip

class DuckDnsUpdater {
    static Version := "0.1"

    __New() {
        defaultCfg := DefaultConfig()
        userCfg := ConfigLoad()
        this.cfg := userCfg ? MergeObjects(defaultCfg, userCfg) : defaultCfg

        this.domains := DuckDnsNormalizeDomains(this.cfg.domains)
        this.token := Trim(String(this.cfg.token))
        this.ip := Trim(String(this.cfg.ip))

        minutes := this.cfg.intervalMinutes
        if !(minutes is Number) || minutes < 1
            minutes := 5
        this.intervalMs := Round(minutes * 60000)

        ; Why the app cannot run, or "" when it can.
        this.configError := ""
        if !FileExist(ConfigPath())
            this.configError := "config.json not found"
        else if !userCfg
            this.configError := "config.json is not valid JSON"
        else if (this.domains = "" || this.token = "")
            this.configError := "Set domains and token in config.json"

        this.state := "starting"      ; starting | ok | error
        this.statusText := "Starting..."
        this.currentIp := ""
        this.timerFn := ObjBindMethod(this, "Update")

        log := this.cfg.logging
        this.log := FileLog(log.enabled, log.fileLocation, A_ScriptDir, log.maxLines)
        this.tray := TrayMenu(this)
    }

    Run() {
        this.tray.Setup()
        this.log.Add("App started | v" DuckDnsUpdater.Version " | domains=" this.domains " | interval=" Round(this.intervalMs / 60000, 2) "min")
        OnExit((*) => this.log.Add("App exited"))
        this.Update()
    }

    ; Sends one update and schedules the next. Also the "Update now" menu action.
    Update(*) {
        if (this.configError != "") {
            ; Nothing to retry until the user edits the config and reloads.
            this.SetState("error", this.configError)
            return
        }

        r := DuckDnsUpdate(this.domains, this.token, this.ip)
        time := FormatTime(, "HH:mm:ss")

        if r.ok {
            this.currentIp := r.ip
            this.SetState("ok", (r.changed ? "IP updated" : "OK, no change") " at " time)
            this.log.Add((r.changed ? "UPDATED" : "NOCHANGE") " | ip=" r.ip (r.ipv6 != "" ? " ipv6=" r.ipv6 : ""))
        } else {
            this.SetState("error", r.error " (" time ")")
            this.log.Add("ERROR | " r.error)
        }

        ; After a failure retry within a minute: the usual cause is the network
        ; not being up yet at logon or after wake.
        next := r.ok ? this.intervalMs : Min(this.intervalMs, 60000)
        SetTimer(this.timerFn, -next)
    }

    SetState(state, text) {
        prev := this.state
        this.state := state
        this.statusText := text
        this.tray.Refresh()

        ; Notify on transitions only, so a long outage is one balloon, not one
        ; every minute.
        if !this.cfg.notifyOnError || state = prev
            return
        if (state = "error")
            TrayTip(text, "DuckDNS update failed", "Iconx")
        else if (prev = "error")
            TrayTip(text, "DuckDNS update recovered", "Iconi")
    }
}

; Application entry point
global app := DuckDnsUpdater()
app.Run()
