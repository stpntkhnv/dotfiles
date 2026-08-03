# AVD / Windows App web client: grey screen in Zen

Found and fixed 2026-08-02. No repo code changed - the fix is a User-Agent
Switcher setting in the profile.

**Symptom** `windows.cloud.microsoft` (JTI tenant) in Zen: session
established, desktop a grey canvas. Chromium works.

**Root cause** RDP came up completely - only video decode was dead, looping on
`Initializing WebCodecs` / `WebCodecs Error`. Its flag telemetry carries
`"Nh_Disable_WebCodecs_Firefox": true`: Microsoft knows that path is broken on
Firefox and routes it to the software decoder, keyed on the User-Agent. JTI
Conditional Access blocks non-Windows, so UA spoofing to Edge was on
(`Edg/148`), so the client took the WebCodecs branch Gecko cannot serve.

**Fix** Spoof as Firefox on Windows instead, per-site: `Mozilla/5.0 (Windows
NT 10.0; Win64; x64; rv:141.0) Gecko/20100101 Firefox/141.0` - the platform
passes CA, `Firefox/141.0` turns the flag on. Rejected: hiding
`window.VideoDecoder` via `+js(set, VideoDecoder, undefined)` - in Edge mode
the client assumes WebCodecs exists and dies on `isConfigSupported`. If JTI
later filters on browser too: pre-WebCodecs Chrome UA, or native FreeRDP.

**Recheck** With an Edge UA the console still loops `WebCodecs Error`; the
Firefox-on-Windows UA gives a desktop.
