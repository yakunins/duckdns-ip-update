#Requires AutoHotkey v2.0

; Windows path handling: expansion, normalization, and writability probing.
; Nothing here knows what the path is for.

ExpandEnvVars(s) {
    if !InStr(s, "%")
        return s
    size := DllCall("ExpandEnvironmentStrings", "Str", s, "Ptr", 0, "UInt", 0, "UInt")
    if !size
        return s
    buf := Buffer(size * 2)
    if !DllCall("ExpandEnvironmentStrings", "Str", s, "Ptr", buf, "UInt", size, "UInt")
        return s
    return StrGet(buf)
}

; "X:\..." (drive-qualified) or "\\server\share" (UNC). Everything else,
; including a bare leading backslash, counts as relative.
IsAbsolutePath(p) {
    return (StrLen(p) >= 3 && SubStr(p, 2, 2) = ":\") || SubStr(p, 1, 2) = "\\"
}

; Collapse . and .. segments. Note this resolves a relative path against the
; CURRENT WORKING DIRECTORY, so callers that mean "relative to something else"
; must join it themselves first — see ResolvePath.
FullPath(p) {
    size := DllCall("GetFullPathName", "Str", p, "UInt", 0, "Ptr", 0, "Ptr", 0, "UInt")
    if !size
        return p
    buf := Buffer(size * 2)
    if !DllCall("GetFullPathName", "Str", p, "UInt", size, "Ptr", buf, "Ptr", 0, "UInt")
        return p
    return StrGet(buf)
}

; Creates intermediate levels too. Returns true if the directory exists afterwards.
EnsureDir(dir) {
    if (dir = "")
        return false
    if DirExist(dir)
        return true
    try DirCreate(dir)
    return DirExist(dir) ? true : false
}

; Probe rather than guess: permissions, missing drives and read-only media all
; surface the same way here. Creates the file if it does not exist.
CanWriteFile(path) {
    try {
        f := FileOpen(path, "a")
        if !IsObject(f)
            return false
        f.Close()
        return true
    } catch
        return false
}

; Turn a configured location into a usable absolute file path.
;
; Relative paths resolve against `anchorDir` rather than the working directory —
; that is whatever Explorer felt like when a Startup shortcut fired, so a file
; written relative to it would land unpredictably. %VARS% expand first, which is
; what makes a location such as "%LOCALAPPDATA%\app\x.log" expressible without
; hardcoding a username.
;
; On success the parent directory exists and the path is writable. If it is not,
; `fallbackPath` is returned instead and `&fellBackFrom` receives the path that
; could not be used, so the caller can report it.
ResolvePath(location, anchorDir, fallbackPath := "", &fellBackFrom?) {
    fellBackFrom := ""

    path := ExpandEnvVars(location)
    if !IsAbsolutePath(path)
        path := RTrim(anchorDir, "\") "\" LTrim(path, "\")
    path := FullPath(path)

    SplitPath(path, , &dir)
    EnsureDir(dir)

    if CanWriteFile(path)
        return path

    if (fallbackPath = "" || fallbackPath = path)
        return path

    fellBackFrom := path
    return fallbackPath
}
