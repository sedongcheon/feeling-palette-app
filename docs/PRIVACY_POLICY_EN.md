# Feeling Palette Privacy Policy

**Effective date**: April 18, 2026
**Last updated**: April 18, 2026

This Privacy Policy ("Policy") explains how the Feeling Palette mobile application ("App") collects, uses, stores, and protects your personal information. Please read this Policy carefully before using the App.

---

## 1. Information we collect and how

### 1.1 Information you provide directly
- **Diary content**: the emotion-diary text you write inside the App
- **App-lock password (PIN)**: the 4-digit PIN you set (stored as a hash, never in plain text)

### 1.2 Information collected automatically
- **Device information**: OS version, device model, screen resolution, language settings
- **Advertising identifiers**: Android Advertising ID (ADID), iOS Advertising Identifier (IDFA) — you can opt out via your device settings
- **Usage statistics**: feature usage frequency (measured by the ad SDK)

### 1.3 Information collected only when you opt in
- **Google account info**: your Google account email and authentication tokens, used when you enable the Google Drive backup feature
- **Biometric authentication**: when you choose fingerprint/Face ID for unlocking, only the authentication result is returned to the App. The biometric data itself is managed by your operating system and is not accessible to the App.

---

## 2. How we use this information

| Information | Purpose |
|-----------|-----------|
| Diary content | To run AI emotion analysis and to display your own entries back to you |
| PIN hash | App access control (identity verification) |
| Device info & ad identifiers | Ad delivery and performance measurement; service quality improvement |
| Google account info | Backup and restore of your diary to **your own** Google Drive (optional) |

---

## 3. Where data is stored and how long we keep it

### 3.1 Local storage (on your device)
- **Diary content**: stored only in the SQLite database on your device. It is **not** transmitted to or stored on the developer's servers.
- **PIN hash / biometric settings**: stored encrypted in your device's secure storage (Android Keystore / iOS Keychain).
- **Retention**: kept until you delete the App or use the in-app "Reset all data" function.

### 3.2 Server-side processing (AI analysis)
- When you run "AI emotion analysis", the diary entry you analyze is sent to the developer's analysis server (`feeling-api-aws.sedoli.co.kr`).
- The server returns the analysis result immediately and **does not store** the request body. (Transient processing logs are auto-deleted after at most 30 days.)

### 3.3 Google Drive backup (optional)
- When you run a backup, your diary data is serialized into a JSON file and uploaded to **your own** Google Drive "App folder".
- Only you can access or delete this backup file. The developer has no access to it.

### 3.4 Advertising data
- Advertising identifiers and related data are retained per the policies of the ad network (Google AdMob).

---

## 4. Third-party services and information sharing

The App uses the following third-party services. Their privacy policies apply alongside this Policy.

### 4.1 Google AdMob (advertising)
- **Collected**: advertising identifiers, device info, approximate location (country level), ad interaction data
- **Purpose**: personalized ad delivery and ad performance measurement
- **Policy**: <https://policies.google.com/privacy>
- When you opt out via "Limit Ad Tracking" on Android or decline ATT on iOS, you will receive non-personalized ads only.

### 4.2 Google Drive API (optional feature)
- **Collected**: Google account email, authentication tokens, Drive file access scope
- **Purpose**: backing up and restoring diaries to your own Google Drive
- **Policy**: <https://policies.google.com/privacy>
- You can revoke the App's access at any time from your Google account settings.

### 4.3 AI analysis server (operated by the developer)
- **Operator**: Feeling Palette developer
- **Collected**: the diary text sent for AI analysis (not stored after analysis)
- **Purpose**: returning the emotion analysis result
- **Access**: HTTPS-only; access is restricted to the developer

Other than the cases above, the App does **not** sell, transfer, or share your personal information with any third party.

---

## 5. Your rights

You may exercise the following rights:

1. **Access and edit**: view or edit any entry from inside the App at any time
2. **Delete**: delete individual entries, or use "Reset all data" to remove everything
3. **Opt out of ad tracking**: reset your advertising identifier or limit tracking from your OS settings
4. **Revoke Google access**: remove Feeling Palette from your Google account's connected apps
5. **Uninstall**: deleting the App removes all data stored on your device

If you are located in the EU/EEA or the United Kingdom, you also have the rights granted by the GDPR/UK GDPR, including the right to rectification, erasure, restriction, portability, and to lodge a complaint with a supervisory authority. Contact information is in section 9 below.

---

## 6. Security measures

- App lock for access control (4-digit PIN + optional biometric authentication)
- PINs stored as SHA-256 hashes with salt and key stretching (original is not recoverable)
- Device secure storage (Android Keystore / iOS Keychain)
- TLS (HTTPS) encryption for all server communication
- Access to personal information is restricted to the developer

---

## 7. Children's privacy

The App is a general-audience service and is not directed at any specific age group. We do not knowingly collect personal information from children under **13 years of age** (under **16** where required by the GDPR, or under **14** where required by South Korea's PIPA). If we learn that a child below the applicable age has provided personal information without verifiable parental consent, we will delete that information promptly.

---

## 8. Changes to this Policy

This Policy may be updated to reflect changes in law or our service. Updates will be announced in-app or by updating this page. We will give at least 7 days' notice before significant changes take effect.

---

## 9. Contact

For questions about this Privacy Policy or your personal information, please contact:

- **Privacy officer**: Cheon Sedong
- **Email**: sedong1000@gmail.com

---

*This Policy reflects Feeling Palette v1.0.0.*
