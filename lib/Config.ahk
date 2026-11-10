#Requires AutoHotkey v2.0
; Requires: Jsons.ahk (Jsons.Load), MergeObjects.ahk (MapToObj)

; config.json: where it is, reading it, and creating it for first-time setup.
; It holds the DuckDNS token, so it is gitignored; config.example.json is the
; committed template.

ConfigPath() {
    return A_ScriptDir "\config.json"
}

ConfigExamplePath() {
    return A_ScriptDir "\config.example.json"
}

; Returns the parsed config as a plain object, or false if the file is absent or
; unparseable. False is deliberate rather than an empty object, so a malformed
; file cannot silently look like "user set nothing".
ConfigLoad() {
    path := ConfigPath()
    if !FileExist(path)
        return false
    try {
        jsonStr := FileRead(path, "UTF-8")
        return MapToObj(Jsons.Load(&jsonStr))
    } catch {
        return false
    }
}

; Make sure there is a config.json to edit: copy the example, or write a minimal
; template if the example is missing too. Never overwrites an existing file.
ConfigEnsureExists() {
    path := ConfigPath()
    if FileExist(path)
        return true
    try {
        if FileExist(ConfigExamplePath())
            FileCopy(ConfigExamplePath(), path)
        else
            FileAppend('{`n    "domains": "",`n    "token": "",`n    "intervalMinutes": 5`n}`n', path, "UTF-8-RAW")
        return true
    } catch {
        return false
    }
}
