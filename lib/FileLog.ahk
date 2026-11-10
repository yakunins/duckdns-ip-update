#Requires AutoHotkey v2.0
; Requires: PathUtils.ahk (ResolvePath)

; A small append-only log, bounded by rename-rotation: once the file reaches
; maxLines it becomes <name>.1 and a new one starts, so at most ~2*maxLines
; lines are kept. Writes are synchronous - a few lines every few minutes.
class FileLog {
    __New(enabled, location, anchorDir, maxLines := 1000) {
        this.enabled := enabled
        this.maxLines := maxLines
        this.fileLines := 0
        this.filePath := ""
        if !enabled
            return

        loc := (location != "") ? location : ".\duckdns.log"
        fallback := RTrim(anchorDir, "\") "\duckdns.log"
        this.filePath := ResolvePath(loc, anchorDir, fallback, &fellBack)

        ; The log persists across runs, so pick up the existing line count.
        try {
            StrReplace(FileRead(this.filePath, "UTF-8"), "`n", , , &count)
            this.fileLines := count
        }

        if fellBack
            this.Add("LOGPATH | " fellBack " unusable, falling back to " this.filePath)
    }

    Add(message) {
        if !this.enabled
            return
        try FileAppend("[" FormatTime(, "yyyy-MM-dd HH:mm:ss") "] " message "`n", this.filePath, "UTF-8")
        this.fileLines++

        if (this.fileLines >= this.maxLines) {
            try FileMove(this.filePath, this.filePath ".1", true)
            this.fileLines := 0
        }
    }
}
