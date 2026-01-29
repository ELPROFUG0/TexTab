# TexTab

A macOS menu bar app for quick AI-powered text actions and utility plugins.

Select any text, hit a shortcut, and get instant grammar fixes, rephrasing, translations, and more — without leaving your current app.

<!-- VIDEO: drag your paso2.2 video here using GitHub's web editor and it will embed automatically -->

<p align="center">
  <img src="screenshots/screenshot1.png" width="600" alt="TexTab main popup">
</p>

<p align="center">
  <img src="screenshots/screenshot2.png" width="600" alt="TexTab settings">
</p>

## What it does

TexTab sits in your menu bar and gives you fast access to AI text transformations through a popup. You select text anywhere on your Mac, trigger it with a hotkey (default `Cmd+Shift+T`), and pick an action.

**Built-in actions:**
- Fix grammar and spelling
- Rephrase for clarity
- Shorten text
- Formalize tone
- Translate to Spanish
- ...or create your own custom actions with any prompt you want

**Supports multiple AI providers:**
- OpenAI
- Anthropic (Claude)
- OpenRouter
- Perplexity (with web search)
- Groq

You bring your own API key.

## Plugins

TexTab also has a small plugin marketplace built in:

- **Chat** — talk directly to the AI from the popup
- **QR Code Generator** — turn text or URLs into QR codes
- **Image Converter** — convert between PNG, JPEG, WEBP, TIFF
- **Color Picker** — pick any color from your screen

Plugins can be installed and removed from the settings.

## Getting started

### Requirements

- macOS 13+
- Xcode 15+
- A free [Supabase](https://supabase.com) project (for auth and subscriptions)
- At least one AI provider API key

### Setup

1. Clone the repo:
   ```
   git clone https://github.com/ELPROFUG0/TexTab.git
   ```

2. Open `typo/typo.xcodeproj` in Xcode.

3. Create your secrets file. Copy the template:
   ```
   cp Secrets.example.swift typo/typo/Secrets.swift
   ```
   Then fill in your real values (Supabase URL, anon key, etc). This file is gitignored.

4. Make sure `Secrets.swift` is added to the Xcode target:
   - In Xcode, right-click the `typo` folder → **Add Files to "typo"**
   - Select `Secrets.swift`
   - Make sure **"Add to targets: typo"** is checked

5. Build and run (`Cmd+R`).

6. The app will appear in your menu bar. Go to settings to add your API key.

### Supabase (optional)

If you want auth and subscription features to work, you'll need to set up:

- A Supabase project with a `profiles` table
- Edge Functions for Stripe checkout (`create-checkout`) and webhook handling (`stripe-webhook`)
- The corresponding environment variables in your Supabase dashboard

If you just want to use the text actions locally, you can skip this.

## Project structure

```
typo/
├── typo/                    # Main app source
│   ├── typoApp.swift        # App entry point
│   ├── AuthManager.swift    # Auth & subscription logic
│   ├── ContentView.swift    # Main popup view
│   ├── SettingsView.swift   # Settings window
│   ├── Plugins/             # Built-in plugins
│   └── Secrets.swift        # Your credentials (gitignored)
├── supabase/
│   └── functions/           # Edge Functions (Deno/TypeScript)
├── provider_icons/          # AI provider logos
├── Secrets.example.swift    # Template for Secrets.swift
└── LICENSE                  # GPL v3
```

## License

GPL v3 — see [LICENSE](LICENSE).
