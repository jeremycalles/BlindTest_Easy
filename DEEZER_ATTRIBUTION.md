# Deezer API attribution

This app uses the [Deezer API](https://developers.deezer.com/). Deezer’s terms require **visible attribution** in your app.

## What you must do

1. **Mention Deezer**  
   The app already shows a “Powered by Deezer” link on the splash screen and on the dashboard. That satisfies the requirement to mention Deezer.

2. **Use the official Deezer logo**  
   Deezer’s [Logo Guidelines](https://developers.deezer.com/guidelines/logo) state that **each application using the Deezer API must include a clearly visible Deezer logo**. Respecting these guidelines is mandatory.

   - Get the official logo and usage rules from: **[deezerbrand.com](https://deezerbrand.com)** or [Deezer developers – Logo](https://developers.deezer.com/guidelines/logo).
   - Do **not** use old Deezer logos (e.g. with curve & reflection); use only the current versions provided by Deezer.

## Adding the logo in this project

1. Download the official logo (e.g. for light or dark background) from Deezer’s brand site.
2. Add it to the app’s asset catalog:
   - In Xcode: **Assets.xcassets** → right‑click → **New Image Set** → name it `DeezerLogo`.
   - Drag the logo image(s) into the set (e.g. 1x, 2x, 3x as required by the guidelines).
3. Show it in the UI:
   - In `DeezerAttributionView` (in `DashboardView.swift`), add an `Image("DeezerLogo")` above or beside the “Powered by Deezer” link, sized and styled according to Deezer’s guidelines (clearly visible and identified).

## References

- [Deezer API Terms of use](https://developers.deezer.com/termsofuse)
- [Deezer Logo Guidelines](https://developers.deezer.com/guidelines/logo)
- [Deezer Brand](https://deezerbrand.com)
