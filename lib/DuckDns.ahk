#Requires AutoHotkey v2.0

; The DuckDNS update call: https://www.duckdns.org/spec.jsp
; Nothing here logs or returns the token.

; Accepts "foo, bar.duckdns.org" or ["foo", "bar"] and returns "foo,bar" -
; the bare comma-separated subdomain list the API expects.
DuckDnsNormalizeDomains(domains) {
    parts := (domains is Array) ? domains : StrSplit(String(domains), ",")
    result := ""
    for part in parts {
        name := StrLower(Trim(String(part)))
        name := RegExReplace(name, "\.duckdns\.org$")
        if (name != "")
            result .= (result = "" ? "" : ",") name
    }
    return result
}

; Sends one update request. A blank `ip` lets DuckDNS use the address the
; request came from.
;
; Returns { ok, ip, ipv6, changed, error }. With verbose=true the response is
;     OK | KO
;     <ipv4>
;     <ipv6>
;     UPDATED | NOCHANGE
; This blocks for at most the timeouts below; with no hooks or hotkeys in the
; app a briefly unresponsive tray icon is the whole cost.
DuckDnsUpdate(domains, token, ip := "") {
    result := { ok: false, ip: "", ipv6: "", changed: false, error: "" }
    url := "https://www.duckdns.org/update?domains=" domains "&token=" token "&ip=" ip "&verbose=true"

    try {
        whr := ComObject("WinHttp.WinHttpRequest.5.1")
        whr.SetTimeouts(5000, 5000, 10000, 10000)  ; resolve, connect, send, receive (ms)
        whr.Open("GET", url, false)
        whr.Send()
        status := whr.Status
        body := whr.ResponseText
    } catch Error as e {
        ; COM messages are multi-line; the first line with text is the reason.
        msg := "unknown error"
        for line in StrSplit(e.Message, "`n", "`r `t") {
            if (line != "") {
                msg := line
                break
            }
        }
        result.error := "Request failed: " msg
        return result
    }

    if (status != 200) {
        result.error := "HTTP " status
        return result
    }

    lines := StrSplit(Trim(body, " `t`r`n"), "`n", "`r `t")
    verdict := lines.Length ? lines[1] : ""

    if (verdict = "OK") {
        result.ok := true
        result.ip := lines.Length >= 2 ? lines[2] : ""
        result.ipv6 := lines.Length >= 3 ? lines[3] : ""
        result.changed := lines.Length >= 4 && lines[4] = "UPDATED"
    } else if (verdict = "KO") {
        result.error := "DuckDNS rejected the update (KO): check domains and token"
    } else {
        result.error := "Unexpected response: " SubStr(verdict, 1, 60)
    }
    return result
}
