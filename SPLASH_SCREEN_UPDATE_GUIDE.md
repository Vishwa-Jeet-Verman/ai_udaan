# AI UDAAN Splash Screen Update Guide

## 🎯 Objective
Replace the current splash screen with the new AI UDAAN bootcamp image featuring the cosmic design with rocket, AI head, and globe.

## 📋 Steps to Update

### Step 1: Save the New Image

1. **Save the AI UDAAN image** you provided to your computer
2. **Rename it** to `splash_bg.png`
3. **Replace** the existing file at: `frontend/assets/splash_bg.png`

#### Using Finder (Mac):
```
1. Open Finder
2. Navigate to: [Your Project]/frontend/assets/
3. You'll see the old splash_bg.png
4. Drag and drop your new AI UDAAN image here
5. When prompted, choose "Replace"
```

#### Using Terminal:
```bash
# Navigate to your project
cd [your-project-path]/frontend/assets/

# Remove old splash (optional - already backed up as splash_bg_old.png)
# rm splash_bg.png

# Copy your new image here and rename it to splash_bg.png
cp ~/Downloads/your-ai-udaan-image.png splash_bg.png
```

### Step 2: Verify the Image

Make sure the image:
- ✅ Is named exactly: `splash_bg.png`
- ✅ Is located in: `frontend/assets/`
- ✅ Is in PNG format
- ✅ Has good resolution (recommended: 1080x1920 or higher)

### Step 3: Test the App

```bash
cd frontend
flutter run
```

## 🎨 What's Been Updated

### Code Changes Made:

1. **Background Color**: Changed to dark blue-black (`#0A1628`) to match the cosmic theme
2. **Loading Spinner**: Changed to bright green (`#00FFB3`) to match the image's green accents
3. **Error Fallback**: Added a beautiful gradient fallback if image fails to load
4. **Removed Overlay**: Removed the dark overlay so the full image is visible

### Splash Screen Features:

- ✅ Full-screen image display
- ✅ Covers all screen sizes (mobile, tablet, desktop)
- ✅ Bright green loading spinner at bottom
- ✅ 800ms display duration
- ✅ Smooth transition to language selection or home
- ✅ Fallback design if image not found

## 🎨 Image Specifications

### Your New Splash Image Shows:
- 🌌 Cosmic background with stars and nebula
- 🚀 Rocket launching upward
- 🧠 AI head made of particles
- 🌍 Globe with network connections
- 📊 "AI UDAAN" logo with glowing effect
- 📚 "BOOTCAMP" subtitle
- 🎓 Hindi text: "सीखो AI | बनाओ भविष्य | कमाओ बिना सीमा"

### Color Palette:
- Deep blue/black background
- Bright cyan/green accents
- Orange/red highlights
- White text with glow effects

## 🔧 Technical Details

### File Location:
```
frontend/
  └── assets/
      ├── splash_bg.png          ← Your new image goes here
      ├── splash_bg_old.png      ← Backup of old image
      └── .env
```

### Pubspec.yaml (Already Configured):
```yaml
flutter:
  assets:
    - .env
    - assets/splash_bg.png
```

### Splash Screen Code:
- Location: `frontend/lib/screens/splash/splash_screen.dart`
- Background: Dark blue-black (`#0A1628`)
- Spinner: Bright green (`#00FFB3`)
- Duration: 800ms
- Fit: `BoxFit.cover` (fills entire screen)

## 🎯 Expected Result

When you run the app:

1. **Splash Screen Appears** (800ms)
   - Shows your cosmic AI UDAAN image
   - Bright green loading spinner at bottom
   - Full-screen, no borders

2. **Checks Language Preference**
   - First time: Goes to language selection
   - Returning user: Goes to home screen

3. **Smooth Transition**
   - Fades to next screen

## ✅ Verification Checklist

After updating the image, verify:

- [ ] Image displays full-screen
- [ ] No white borders or gaps
- [ ] Loading spinner is visible (bright green)
- [ ] Image is clear and not pixelated
- [ ] Transition to next screen is smooth
- [ ] Works on different screen sizes

## 🐛 Troubleshooting

### Issue: Image not showing
**Solution**: 
```bash
cd frontend
flutter clean
flutter pub get
flutter run
```

### Issue: Image is stretched or distorted
**Solution**: The image uses `BoxFit.cover` which maintains aspect ratio. If it looks wrong, check your image dimensions.

### Issue: "Asset not found" error
**Solution**: 
1. Verify file name is exactly `splash_bg.png`
2. Verify it's in `frontend/assets/` folder
3. Run `flutter pub get`

### Issue: Image is too dark
**Solution**: The overlay has been removed. If still too dark, you can adjust the image brightness before saving it.

## 🎨 Optional: Adjust Loading Spinner

If you want to change the spinner color to match your preference:

Edit `frontend/lib/screens/splash/splash_screen.dart`:

```dart
CircularProgressIndicator(
  color: Color(0xFF00FFB3), // Change this color
  strokeWidth: 3,
),
```

Color suggestions:
- Bright Green: `0xFF00FFB3` (current)
- Cyan: `0xFF00D9FF`
- White: `0xFFFFFFFF`
- Your app green: `0xFF1F7A63`

## 📱 Preview

Your splash screen will show:
```
┌─────────────────────────────────┐
│                                  │
│     [Cosmic Background]          │
│                                  │
│         🚀 Rocket                │
│                                  │
│      AI UDAAN Logo               │
│       (Glowing)                  │
│                                  │
│      BOOTCAMP                    │
│                                  │
│   सीखो AI | बनाओ भविष्य         │
│                                  │
│         🌍 Globe                 │
│                                  │
│          ⭕ Loading...           │ ← Green spinner
│                                  │
└─────────────────────────────────┘
```

## 🚀 Ready to Go!

Once you've replaced the image file:

```bash
cd frontend
flutter run
```

Your beautiful AI UDAAN cosmic splash screen will appear! 🎉

---

**Need Help?** 
- Check that the file is named exactly `splash_bg.png`
- Make sure it's in the `frontend/assets/` folder
- Run `flutter clean` and `flutter pub get` if issues persist
