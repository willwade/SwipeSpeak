# SwipeSpeak Localization Guide

## Overview

SwipeSpeak now uses modern iOS localization with **String Catalogs** (.xcstrings files) instead of traditional Localizable.strings files. This provides better tooling, automatic string extraction, and improved management of translations.

## Architecture

### 1. String Catalog (`Localizable.xcstrings`)
- Central repository for all localizable strings
- Visual editor in Xcode for managing translations
- Automatic validation and pluralization support
- Located at: `SwipeSpeak/SwipeSpeak/Localizable.xcstrings`

### 2. LocalizedStrings.swift
- Type-safe Swift interface for accessing localized strings
- Organized into logical categories (Keyboard, Settings, Tutorial, etc.)
- Replaces direct `NSLocalizedString` calls
- Located at: `SwipeSpeak/SwipeSpeak/LocalizedStrings.swift`

## String Organization

Strings are organized hierarchically using dot notation:

```
keyboard.layout.4keys = "4 Keys"
keyboard.layout.6keys = "6 Keys"
settings.title = "Settings"
settings.cloud.sync = "Cloud Sync"
accessibility.sentence.empty = "Sentence area. Currently empty."
```

### Categories:

- **keyboard.*** - Keyboard layout names and labels
- **direction.*** - Directional indicators (Up, Down, Left, Right, etc.)
- **placeholder.*** - UI placeholder text
- **button.*** - Common button labels (Add, Cancel, Done, OK)
- **settings.*** - Settings screen strings
- **tutorial.*** - Tutorial dialog strings
- **about.*** - About screen content
- **words.*** - Word management dialogs
- **error.*** - Error messages
- **accessibility.*** - Accessibility labels and hints

## Usage Examples

### Basic Usage
```swift
// Old way (deprecated)
NSLocalizedString("Settings", comment: "")

// New way
LocalizedStrings.Settings.title
```

### Parameterized Strings
```swift
// Version string with parameters
LocalizedStrings.About.version("2.1", "16")

// Accessibility labels with dynamic content
LocalizedStrings.Accessibility.Sentence.label(sentenceText)
```

### SwiftUI Integration
```swift
// Direct usage in SwiftUI
Text(LocalizedStrings.Settings.title)
Button(LocalizedStrings.Button.done) { /* action */ }

// Navigation titles
.navigationTitle(LocalizedStrings.About.title)
```

## Supported Languages

Currently configured languages:
- **English (en)** - Source language
- **Spanish (es)** - Partial translations added
- **French (fr)** - Ready for translation
- **German (de)** - Ready for translation (word frequency data already available)

## Adding New Languages

1. **In Xcode:**
   - Open `Localizable.xcstrings`
   - Click the "+" button to add a new language
   - Select the target language from the list

2. **In Project Settings:**
   - Add the language code to `knownRegions` in project.pbxproj
   - Ensure `LOCALIZATION_PREFERS_STRING_CATALOGS = YES` is set

3. **Translation:**
   - Use Xcode's String Catalog editor to add translations
   - Export for professional translation if needed
   - Import completed translations back into the catalog

## Translation Guidelines

### For Accessibility Apps:
1. **Keep accessibility strings descriptive** - Users rely on VoiceOver
2. **Maintain consistent terminology** - Use the same terms across languages
3. **Consider cultural context** - Gesture patterns may vary by culture
4. **Test with native speakers** - Especially for accessibility features

### Key Considerations:
- **Keyboard layouts** - Some languages may need different key groupings
- **Direction indicators** - Consider RTL languages (Arabic, Hebrew)
- **Voice synthesis** - Ensure target language has good TTS support
- **Cultural gestures** - Swipe patterns may have different meanings

## Testing Localization

### In Simulator:
1. Go to Settings > General > Language & Region
2. Change iPhone Language to target language
3. Launch SwipeSpeak to test translations

### Xcode Testing:
1. Edit scheme > Run > Options
2. Set "Application Language" to target language
3. Run the app to test specific language

## Migration Notes

### Completed:
- ✅ Replaced all `NSLocalizedString` calls with `LocalizedStrings` enum
- ✅ Created comprehensive String Catalog with organized keys
- ✅ Updated all SwiftUI views to use localized strings
- ✅ Added Spanish translations for key strings as example
- ✅ Configured project for multi-language support

### Future Enhancements:
- Add complete translations for Spanish, French, German
- Consider RTL language support (Arabic, Hebrew)
- Add localized word frequency data for other languages
- Implement language-specific keyboard layouts
- Add localized speech synthesis voice selection

## Maintenance

### Adding New Strings:
1. Add the key to `Localizable.xcstrings` with English value
2. Add corresponding property to `LocalizedStrings.swift`
3. Use the new property in your code
4. Add translations for all supported languages

### Best Practices:
- Use descriptive key names that indicate context
- Group related strings under common prefixes
- Include meaningful comments for translators
- Test all languages before release
- Keep accessibility in mind for all translations

## File Locations

- **String Catalog**: `SwipeSpeak/SwipeSpeak/Localizable.xcstrings`
- **Swift Interface**: `SwipeSpeak/SwipeSpeak/LocalizedStrings.swift`
- **Project Config**: `SwipeSpeak/SwipeSpeak.xcodeproj/project.pbxproj`
- **This Guide**: `SwipeSpeak/LOCALIZATION.md`
