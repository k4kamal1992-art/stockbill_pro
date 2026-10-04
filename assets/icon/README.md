# App Icon Assets

## Required Files

1. **app_icon.png** (1024x1024px)
   - Main app icon for Android & iOS
   - Transparent background recommended
   - Center the logo with safe margins

2. **app_icon_foreground.png** (1024x1024px)
   - Android adaptive icon foreground
   - Transparent background required
   - Logo should fit within center 66% safe area

3. **brand.png** (600x200px)
   - Splash screen branding image
   - Transparent background
   - White or light colored logo

## How to Generate Icons

After placing the above files, run:

```bash
# Generate launcher icons
flutter pub run flutter_launcher_icons:main

# Generate native splash
flutter pub run flutter_native_splash:create
```

## For Dark Mode Splash

The splash screen will automatically use:
- `color: "#5856D6"` for light mode
- `color_dark: "#1C1C1E"` for dark mode

## Design Guidelines

- Use the business primary color (#5856D6) as base
- Keep design simple and recognizable at small sizes
- Avoid text in the icon (use logo/symbol only)
- Ensure good contrast on both light and dark backgrounds
