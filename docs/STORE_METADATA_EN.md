# Store metadata — English

App Store Connect / Google Play Console **English** metadata. Mirrors the structure of `STORE_METADATA.md` (Korean). Paste as-is or adjust tone.

---

## 🏷️ App name

| Location | Value | Notes |
|------|-----|-----|
| Play Store (en) | `Feeling Palette` | Brand-only |
| App Store (en) | `Feeling Palette` | Brand-only |
| Play Store (ko) | `Feeling Palette` | Brand unified |
| App Store (ko) | `Feeling Palette` | Brand unified |

> Brand kept consistent across all locales (see `STORE_METADATA.md` for Korean store name policy).

---

## 🏷️ Subtitle (App Store only, 30 chars)

**Recommended**: `Color-log your daily feelings` (29 chars)

Candidates:
- `Color-log your daily feelings` ⭐ emotive, fits
- `AI emotion diary, every day` (27 chars)
- `Paint your mood, day by day` (27 chars)
- `Track moods with AI insights` (28 chars)

---

## 📝 Short description (Play Store only, 80 chars)

**Recommended** (78 chars):
> Daily diary + AI emotion analysis. See your mood flow with calendar & stats.

---

## 📖 Full description (Play/App Store, 4000-char limit)

```
🎨 Feeling Palette — Color-log your feelings with AI

How did your day feel today?
Feeling Palette lets you freely record your daily emotions
and AI gently analyzes the colors of your mood.


✨ Key features

🖋️ Freely jot it down
• Multiple entries per day — morning excitement, evening tiredness
• Quick text entry with automatic timestamps
• Edit or delete anytime

🤖 AI emotion analysis
• Six emotions visualized as scores:
  Joy, Sadness, Anger, Anxiety, Calm, Excitement
• AI comment tuned to your entry
• Re-analyze up to 3 times per entry

📅 Emotion calendar
• See a month of moods at a glance, in color
• Days with multiple entries show the average emotion as the day's color
• Tap a date to see every entry and an emotion average chart

📊 Monthly stats
• Top 3 emotions you felt this month
• Emotion distribution donut chart
• Weekly emotion-trend line graph

📖 Timeline
• Browse every entry in one view
• Infinite scroll back through your history

🔐 Safe by default
• 4-digit PIN lock + fingerprint / Face ID
• Diaries stay on your device
• Optional backup & restore to your private Google Drive app folder

💝 Ad-free comfort (optional)
• A single one-time purchase removes banner and interstitial ads


💌 Privacy first

Feeling Palette treats your diary as yours.
• Diary content is stored only on your device
• Entries are sent to the AI server temporarily for analysis,
  never stored on the server
• App lock keeps prying eyes out

Read more: https://sedongcheon.github.io/feelingpalette-privacy/


📬 Contact: sedong1000@gmail.com
```

Length: ~1,200 characters (well within the 4,000-char limit).

---

## ✨ Promotional text (App Store only, 170 chars)

Editable anytime without review — use for marketing.

**Recommended** (160 chars):
> Color-log your daily feelings. AI breaks each entry into six emotions, monthly stats reveal your mood flow, and an app lock keeps everything safely yours.

---

## 🔑 Keywords (App Store only, 100 chars, comma-separated)

**Recommended** (95 chars):
```
emotion diary,mood diary,mood tracker,AI diary,journal,daily journal,feelings,mood log,wellbeing
```

> Play Store has no separate keyword field — keywords are woven into the description body (already done above).

---

## 📂 Category

| Platform | Primary | Secondary |
|--------|-----------|--------------|
| Play Store | **Lifestyle** | (none) |
| App Store | **Lifestyle** | Health & Fitness |

> "Health & Fitness" was considered (emotional care angle). Apple applies stricter review to medical/health apps, so **Lifestyle is recommended**.

---

## 🎂 Age rating

| Platform | Recommended |
|--------|-----------|
| Play Store (IARC questionnaire) | Everyone (3+) — no violence/sex/gambling. Check "Contains ads". |
| App Store | 4+ — suitable for all ages |

> Users may write sensitive content, but ratings are evaluated based on **what the app itself offers**.

---

## 📢 First-release notes (What's New)

```
🎨 Feeling Palette is here!

• AI emotion analysis — six emotions scored & visualized
• Emotion calendar & monthly stats
• PIN + biometric app lock
• Google Drive backup / restore
• Multiple entries per day
```

---

## 🌐 Privacy policy URL

```
https://sedongcheon.github.io/feelingpalette-privacy/
```

**Required** for both Play Console and App Store Connect.

> Consider adding an English-locale privacy policy page if the current page is Korean-only. Apple/Google may require the policy to be readable in the locale you're publishing to. Suggested URL: `https://sedongcheon.github.io/feelingpalette-privacy/en/` or `?lang=en`.

---

## 📧 Support info

| Field | Value |
|------|--------------------|
| Developer name | Sedori |
| Support email | sedong1000@gmail.com |
| Support URL | (optional) — leave blank if none |
| Marketing URL | (optional) — leave blank if none |

---

## ✅ Checklist (entry order)

**Play Console (English store listing)**:
- [ ] App name (English)
- [ ] Short description
- [ ] Full description
- [ ] Category: Lifestyle
- [ ] Tags: `emotion diary`, `AI`, `journal`, `mood`
- [ ] Privacy policy URL (English page if available)
- [ ] Contains ads: **Yes**
- [ ] App access (lock) explanation
- [ ] Content rating questionnaire
- [ ] Target audience: 13+
- [ ] Data safety (see `docs/RELEASE_PREP.md` §Data Safety)

**App Store Connect (English localization)**:
- [ ] App name
- [ ] Subtitle
- [ ] Promotional text
- [ ] Full description
- [ ] Keywords
- [ ] Category
- [ ] Age rating: 4+
- [ ] Support URL
- [ ] Marketing URL (optional)
- [ ] Privacy policy URL
- [ ] App Privacy (data collection disclosure)

---

## 💡 Iteration ideas

Post-launch A/B candidates:
- Two or three icon variants
- Vary subtitle and measure install-rate
- Promotional text is editable anytime without review — use freely

---

## 🌐 Localization parity

This file mirrors `STORE_METADATA.md` (Korean). When you update one, mirror the change in the other to keep both store listings consistent.

| Section | KO file | EN file |
|---------|---------|---------|
| App name | ✓ | ✓ |
| Subtitle | ✓ | ✓ |
| Short description | ✓ | ✓ |
| Full description | ✓ | ✓ |
| Promo text | ✓ | ✓ |
| Keywords | ✓ | ✓ |
| Category | ✓ | ✓ |
| Age rating | ✓ | ✓ |
| Release notes | ✓ | ✓ |
| Privacy URL | ✓ | ✓ (may need en page) |
| Support info | ✓ | ✓ |
