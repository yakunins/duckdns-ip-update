# DuckDNS IP Update

Keeps the IP address of your [Duck DNS](https://www.duckdns.org/) domain(s) up to date on Windows.

A small tray app: it sends the update request on start and then every few minutes, and shows the last result and current public IP in the tray menu. An AutoHotkey take on [duckdns-powershell](https://github.com/ataylor32/duckdns-powershell), without the need for Task Scheduler.

Built with [AutoHotkey v2](https://www.autohotkey.com/v2/). Executable compiled with [Ahk2Exe](https://github.com/AutoHotkey/Ahk2Exe).

## Install

1. Put the files into a permanent folder (e.g. `C:\duckdns-ip-update\`)
2. Run `install.cmd` — creates `config.json` from `config.example.json` and a startup shortcut, so the app launches after Windows logon
3. Set `domains` and `token` in `config.json`
4. Start `duckdns-ip-update.exe` (or `duckdns-ip-update.ahk` if you have AutoHotkey v2 installed)

`uninstall.cmd` removes the startup shortcut.

## Usage

Click the tray icon to open the menu:

- **Status / IP** — result of the last update and the IP Duck DNS has on record
- **Update now** — send an update immediately
- **Edit config.json** — opens the config in Notepad (creates it if missing)
- **Reload config** — restart the app to apply config changes
- **Open log**

The icon turns into a warning sign while updates are failing. A failed update is retried within a minute; a tray notification is shown once when updates start failing and once when they recover.

## Configure

Edit `config.json`, then choose **Reload config** from the tray menu.

The comments below explain each setting. JSON itself does not allow comments,
so they are documentation only - do not paste them into the file.

<pre>
{
    // Subdomains to update, comma-separated: "foo,bar".
    // An array ["foo", "bar"] and full names ("foo.duckdns.org") also work.
    "domains": "foo,bar",

    // Your Duck DNS token, from https://www.duckdns.org/ after signing in.
    "token": "my-duck-dns-token",

    // IP address to set. Leave blank and Duck DNS detects your public IP.
    "ip": "",

    // How often to send the update, in minutes. Minimum 1. Default: 5
    "intervalMinutes": 5,

    // Tray notification when updates start failing and when they recover.
    "notifyOnError": true,

    "logging": {
        "enabled": true,

        // A relative path resolves against the app folder. %VARS% are
        // expanded, so "%LOCALAPPDATA%\\duckdns\\duckdns.log" works.
        "fileLocation": ".\\duckdns.log",

        // Lines per log file before it rotates to &lt;name&gt;.1
        "maxLines": 1000
    }
}
</pre>

Settings that are absent fall back to their defaults.

`config.json` holds your token and is listed in `.gitignore`. The token is never written to the log.

## Build

`tools\compile.cmd` compiles `duckdns-ip-update.exe`; `tools\release-github.cmd` zips the files listed in `tools\release-files.txt` and publishes a GitHub release tagged with the version from `duckdns-ip-update.ahk`.

## License
MIT
