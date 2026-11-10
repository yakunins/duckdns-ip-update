#Requires AutoHotkey v2.0

; Every setting the app understands, with the value used when config.json omits
; it. User settings are deep-merged over this.
DefaultConfig() {
    return {
        domains: "",            ; "foo,bar" or ["foo", "bar"]; ".duckdns.org" suffix optional
        token: "",              ; DuckDNS account token
        ip: "",                 ; blank = DuckDNS detects the public IP itself
        intervalMinutes: 5,     ; how often to send the update (minimum 1)
        notifyOnError: true,    ; tray balloon when updates start failing / recover

        logging: {
            enabled: true,
            fileLocation: ".\duckdns.log",  ; relative to the app folder, or absolute (%VARS% expanded)
            maxLines: 1000      ; lines per log file before rotating to <name>.1
        }
    }
}
