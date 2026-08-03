# `context-proxy` extension was never installed, silently

Found and fixed 2026-07-30.

**Symptom** Nothing visible: policy applied, four of five extensions present,
the fifth absent from `extensions.json`. Containers had separate cookies but
shared network. Console: `Download failed - ERROR_SIGNEDSTATE_REQUIRED`.

**Root cause** `zen-browser-bin 1.21.9b-1` is built with
`MOZ_REQUIRE_SIGNING: false`, which does not disable the signature check, only
turns it into the pref `xpinstall.signatures.required`
(`AddonSettings.sys.mjs` in `omni.ja`). Toolkit defaults it false; Zen's
application defaults, read later, set it true.

**Fix** `32-browser-extensions` (`$zenPrefs`) sets the pref false and `locked`
by policy, not `user.js` - policy is read before profile creation, so the
extension arrives on first launch. The same build flag is what allows that
policy override (`Policies.sys.mjs`); a build with it on would require signing
and forbid the override - see [workarounds.md](../workarounds.md). Same pass:
`43-zen-session` seeding now appends (it refused any profile with tabs; first
launch leaves four), and `40-zen-prefs` dropped `run_onchange_` so it reruns
on profile state.

**Recheck** `jq -r '.addons[]|select(.active)|.id'
~/.config/zen/*/extensions.json | grep context-proxy`.
