#Requires AutoHotkey v2.0

class TrayMenu {
    __New(app) {
        this.app := app
        this.ready := false
    }

    Setup() {
        tray := A_TrayMenu
        tray.Delete()
        ; The first two items are read-only status lines, renamed by position
        ; ("1&", "2&") in Refresh().
        tray.Add("Status", (*) => 0)
        tray.Add("IP", (*) => 0)
        tray.Disable("1&")
        tray.Disable("2&")
        tray.Add() ; divider
        tray.Add("Update now", ObjBindMethod(this.app, "Update"))
        tray.Add() ; divider
        tray.Add("Edit config.json", ObjBindMethod(this, "EditConfig"))
        tray.Add("Reload config", (*) => Reload())
        tray.Add("Open log", ObjBindMethod(this, "OpenLog"))
        tray.Add() ; divider
        tray.Add("Exit", (*) => ExitApp())
        tray.Default := "Update now"

        if !this.app.log.enabled
            tray.Disable("Open log")

        ; Open the menu on left click as well as right click.
        OnMessage(0x0404, TrayClickHandler)
        TrayClickHandler(wP, lP, *) {
            if (lP = 0x0202) {  ; WM_LBUTTONUP
                SetTimer(() => A_TrayMenu.Show(), -1)
                return 1
            }
        }

        this.ready := true
        this.Refresh()
    }

    Refresh() {
        if !this.ready
            return
        app := this.app
        tray := A_TrayMenu

        ipLabel := "IP: " (app.currentIp != "" ? app.currentIp : "unknown")
        tray.Rename("1&", app.statusText)
        tray.Rename("2&", ipLabel)

        ; Tooltips are capped at 127 characters.
        A_IconTip := SubStr("DuckDNS IP Update v" DuckDnsUpdater.Version "`n" app.domains "`n" app.statusText "`n" ipLabel, 1, 127)

        ; Stock Windows icons: shell32 #14 is the globe, user32 #2 the warning sign.
        try {
            if (app.state = "error")
                TraySetIcon("user32.dll", 2)
            else
                TraySetIcon("shell32.dll", 14)
        }
    }

    EditConfig(*) {
        if !ConfigEnsureExists() {
            MsgBox("Could not create " ConfigPath(), "DuckDNS IP Update", "Iconx")
            return
        }
        Run('notepad.exe "' ConfigPath() '"')
    }

    OpenLog(*) {
        path := this.app.log.filePath
        if FileExist(path)
            Run('notepad.exe "' path '"')
        else
            MsgBox("No log yet: " path, "DuckDNS IP Update", "Iconi")
    }
}
