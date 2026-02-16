# App Icon Template for Icon Composer

Use this template to design the Checkpoint app icon and then bring it into **Icon Composer** (Apple’s icon design app from [developer.apple.com/icon-composer](https://developer.apple.com/icon-composer)).

## Files

- **AppIcon-Template.svg** – 1024×1024 canvas with:
  - Dark background (#1a1a1c)
  - Safe zone circle (keep important content inside ~81% so it isn’t cropped by the iOS squircle)
  - Placeholder checkmark in a circle (amber #e8bc44) – replace with your own artwork

## Workflow with Icon Composer

1. **Edit the template**  
   Open `AppIcon-Template.svg` in:
   - **Figma** (File → Open)
   - **Sketch**
   - **Adobe Illustrator**
   - **Affinity Designer**  
   Replace the placeholder with your icon design. Use layers so you can assign Liquid Glass and modes in Icon Composer.

2. **Export for Icon Composer**  
   From your design tool, export **layered artwork** in a format Icon Composer supports (e.g. PDF with layers, or whatever Icon Composer’s File → Import expects). Check Icon Composer’s help or WWDC session for the recommended format.

3. **Import into Icon Composer**  
   - Open **Icon Composer** (macOS Sequoia 15.3+, from Apple Developer Downloads).
   - Import your exported file.
   - Organize layers, set Liquid Glass properties, and adjust Default / Dark / Mono if needed.
   - Add the icon to your Xcode project or export a flattened PNG for the asset catalog.

## If you’re not using Icon Composer

- Edit the SVG in any vector editor.
- Export a **1024×1024 PNG** (no transparency for the final app icon).
- Replace `AppIcon.appiconset/AppIcon.png` with your export.

## Canvas and safe zone

- **Canvas:** 1024×1024 pt (required for iOS).
- **Safe zone:** Keep important shapes and text inside the inner dashed circle (~832px diameter) so they’re not clipped by the system icon mask.
