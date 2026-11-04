# BITE! – Custom App Icon (Light, Dark, Tinted/Monochrome)

The app icon has been replaced using the exact SVG artwork from the user-supplied `APPLOGO_BITE!_SHADED(1).icon` file. Original Icon Composer document (including `icon.json` and SVG) is preserved under `DesignReferences/OriginalIcon/` for future editing in Icon Composer.

For predictable Xcode compatibility, the active icon is the `AppIcon.appiconset` asset catalog, with **three 1024 × 1024 PNGs**:
- `AppIcon.png`: original colored vector artwork on a white-gray gradient, matching the original Icon Composer background.
- `AppIcon-Dark.png`: same colored artwork on a dark background.
- `AppIcon-Monochrome.png`: grayscale artwork for iOS Tinted/Monochrome appearance (iOS controls the user's tint color).

`Assets.xcassets/AppIcon.appiconset/Contents.json` has `luminosity=dark` and `luminosity=tinted` selectors. The active target setting in Debug and Release stays `ASSETCATALOG_COMPILER_APPICON_NAME=AppIcon`.

Do not add the preserved `.icon` file to BITE target membership at the same time as `AppIcon.appiconset`: two competing icon sources can cause build issues. If later switching entirely to Icon Composer, set up its target membership, remove the catalog app icon, and review its variants in Xcode.

To verify on Mac: open `BITE.xcodeproj`; Product > Clean Build Folder; Run on iOS Simulator; go to Settings > Home Screen & App Library > App Icons (if available) or configure Home Screen icon appearance via the Customize menu and inspect Light, Dark and Tinted. Device OS and locale may vary.

Static checks performed: asset file dimensions, PNG format/RGB (opaque), JSON correctness, Xcode app-icon naming, original source files preserved. Actual `actool` or Simulator build must be performed on macOS with Xcode.
