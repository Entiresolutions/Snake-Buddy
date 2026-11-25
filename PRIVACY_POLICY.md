# Privacy Policy
Snake Buddy | Effective November 6, 2026 | Last updated November 26, 2026

## 01 Overview
Entire Solutions develops and publishes Snake Buddy, a 2D casual arcade action game designed for mobile devices running Android and iOS. This Privacy Policy explains how Snake Buddy handles information when you install, play, and interact with the game.

Player privacy is a foundational priority for Entire Solutions. Snake Buddy is built with a privacy-first architecture:
- You do not need to create an account, log in, or register to play.
- Entire Solutions does not operate private backend servers, customer databases, or custom telemetry servers for Snake Buddy.
- Entire Solutions does not directly collect, request, or store your personal identity information, such as your real name, email address, postal address, phone number, or government-issued identification.
- Core gameplay, including all 30 campaign levels, level progression, canvas theme customizations, high score tracking, and game settings, operates completely offline without requiring an active internet connection.

## 02 Information stored on your device
Snake Buddy stores game-related data locally on your device using native sandboxed storage (SharedPreferences on Android and UserDefaults on iOS). This data never leaves your device unless backed up by your operating system backup provider (such as Google Drive or Apple iCloud):

- Settings preferences: Your choices for sound effects (on/off), haptic vibration feedback (on/off), grid lines visibility (on/off), game difficulty (easy, normal, hard), and control scheme (swipe controls or on-screen directional buttons).
- Gameplay progression and high scores: Your highest unlocked campaign level (levels 1 through 30), the star ratings earned on each level (0 to 3 stars per level), current run scores, and personal best high scores.
- Canvas theme unlocks and ad progress: Your active canvas background theme selection, the list of unlocked canvas themes (unlocked via gameplay score milestones or optional rewarded ad watches), per-theme ad watch progress counters, and viewed theme status indicators.
- Ad pacing flag: A local boolean flag (`ads.hasPlayedFirstGame`) indicating whether you have started your first game, used solely to skip the App Open Ad on your very first play.
- In-memory gameplay buffer: Temporary game coordinates and positions retained in volatile device memory during an active game attempt to enable the Second Chance rewind mechanism. This transient buffer is cleared when the level ends or restarts.

This information is kept entirely within the application sandbox on your device. Entire Solutions has no access to this local data.

## 03 Advertising and information processed by third parties
To keep Snake Buddy free to download and play, the game integrates Google AdMob third-party advertising services.

### Third-party SDKs
- Google AdMob and Google Play Services (operated by Google LLC and Google Ireland Limited): Serves in-game advertisements, handles consent collection, and provides ad delivery analytics.

### Ad formats supported
- Rewarded ads: Optional video advertisements that players may voluntarily choose to watch after Game Over to earn a Second Chance continue (limited to 1 per level attempt).
- Rewarded interstitial ads: Optional advertisements that players may voluntarily choose to watch in the Theme gallery to unlock locked canvas themes early (requiring 1 to 5 ads depending on the theme).
- App-open ads: Full-screen advertisements displayed when selecting a level to start gameplay (skipped on the player's very first game play and not shown on the splash screen).

### Data categories processed by advertising providers
When connected to the internet, advertising SDKs may automatically collect and process certain technical data from your device to deliver, personalize, and measure advertisements:
- Unique Advertising Identifiers: Google Advertising ID (GAID) on Android devices, and Identifier for Advertisers (IDFA) on iOS devices (only if tracking authorization is granted by the user; otherwise Identifier for Vendor [IDFV] or contextual signals).
- Approximate location data: Coarse location derived from your IP address (such as country or city level) used to serve geographically relevant advertisements and respect local legal standards.
- Device and technical information: Device model, hardware manufacturer, operating system version, screen resolution, system language, mobile network carrier, and internet connection type (Wi-Fi, 4G, 5G).
- Ad interaction metrics: Information regarding which advertisements were displayed, duration of view, video completion rates, clicks, impressions, and engagement diagnostics.
- Crash and diagnostic logs: Technical reports generated when an ad fails to load or causes an unexpected application fault.
- User consent signals: Transparency and Consent Framework (TCF) consent strings collected through the User Messaging Platform (UMP) or Google consent management tools.

Entire Solutions does not own, store, or directly receive this third-party advertising data.

## 04 How information is used and shared
### How information is used
- Local gameplay data: Used solely on your device to remember your campaign level progress, save your best scores, preserve custom board themes, and apply your audio and control preferences.
- Third-party advertising data: Used by Google AdMob to deliver advertisements, optimize ad inventory, prevent invalid traffic and ad fraud, enforce frequency capping (preventing repetitive ads), and calculate developer revenue.

### How information is shared
- Entire Solutions does not sell, rent, monetize, or trade any player personal data to third parties.
- Information processed by Google AdMob is shared with authorized ad exchange partners, demand partners, and mediation networks strictly to fill ad requests according to Google policies.
- Legal obligations: We may disclose information only if required to do so by applicable law, search warrant, subpoena, court order, or official regulatory mandate.

## 05 Advertising choices and consent
You have full control over how advertising identifiers and personalization are used on your device:

- Opt out on Android:
  - Open device Settings > Google > Ads (or Settings > Privacy > Ads).
  - Tap "Reset advertising ID" to generate a new anonymous identifier, or tap "Delete advertising ID" to disable ad tracking across apps.
- Opt out on iOS:
  - Open device Settings > Privacy & Security > Tracking, and disable "Allow Apps to Request to Track".
  - Open device Settings > Privacy & Security > Apple Advertising, and toggle off "Personalized Ads".
- Regional consent management (EEA, UK, and Switzerland):
  - In eligible jurisdictions subject to the General Data Protection Regulation (GDPR/UK GDPR), an initial User Messaging Platform (UMP) consent dialogue is presented to allow you to accept, decline, or configure personalized ad consent and vendor permissions.
- Offline play:
  - You can play Snake Buddy completely offline by turning off mobile data and Wi-Fi or enabling Airplane Mode. When offline, no network requests are sent and no advertising data is transmitted.

## 06 Device permissions
Snake Buddy requests and uses only the minimum permissions necessary to function properly:

- `android.permission.INTERNET`: Required to connect to the internet to load online advertisements and deliver ad impressions.
- `android.permission.ACCESS_NETWORK_STATE`: Required to verify whether an active internet connection is available before initiating network requests, conserving battery and data.
- `android.permission.VIBRATE`: Required exclusively to trigger tactile haptic vibration when your snake eats fruits, collects banana boosters, crashes into obstacles, or clears a level. This permission accesses only the vibration actuator and does not access personal data.
- `com.google.android.gms.permission.AD_ID`: Required by Google Play Services / Google AdMob on Android 13+ to access the Google Advertising ID (GAID) for ad delivery and frequency capping, unless reset or deleted by the user in device settings.

### Hardware features
- `android.hardware.touchscreen` (marked `android:required="false"`): Declares that a physical touchscreen is not strictly mandatory, enabling compatibility with non-touch systems such as Android TV, foldables, and Chromebooks using keyboard or mouse input.
- `android.hardware.screen.portrait` (marked `android:required="false"`): Informs the platform of the game's responsive portrait layout orientation while preserving adaptable screen scaling.

Snake Buddy does not request access to sensitive hardware or data permissions, including Camera, Microphone, Precise GPS Location, Contacts, SMS, Storage files, or Phone State.

## 07 Children's privacy
Snake Buddy is an all-ages family-friendly arcade game designed for broad audiences.

- Entire Solutions does not knowingly collect, store, or solicit personal information from children under the age of 13 (or under 16 in the European Economic Area and United Kingdom) <!-- TODO: confirm Google Play Console Target Age tier selection: whether the app participates in the Designed for Families program or mixed-audience category -->.
- In compliance with the Children's Online Privacy Protection Act (COPPA), the General Data Protection Regulation (GDPR), and Google Play Families Policy:
  - If the game is designated for children or a mixed audience, third-party advertising requests are configured using child-directed tags (such as Google AdMob's `tagForChildDirectedTreatment` and `tagForUnderAgeOfConsent`).
  - Child-directed ad requests disable behavioral targeting, interest-based tracking, and remarketing, ensuring that only contextual, child-safe advertisements are displayed.
- If a parent, legal guardian, or caregiver believes that their child has provided personal information through our game, please contact us immediately at support@entiresol.com so we can investigate and promptly delete any such data.

## 08 Data retention and deletion
### Local device data
All gameplay statistics, level stars, unlocked themes, and settings are saved on your local device. You have direct control over this data at all times:
- To reset or delete all game progress on Android: Open Settings > Apps > Snake Buddy > Storage & Cache > tap "Clear Storage" or "Clear Data".
- To delete all game progress on iOS: Delete or uninstall Snake Buddy from your device.
- Uninstalling the application removes all local game progress and configuration files permanently.

### Third-party advertising data
Advertising telemetry, impression logs, and pseudonymous identifiers collected by Google AdMob are retained in accordance with Google's public retention policies, typically anonymized or purged within standard operational retention schedules.

## 09 Security and international processing
- Local data security: Your local game saves reside within the secure, private application sandbox managed by the Android and iOS operating systems, preventing unauthorized access by other third-party applications installed on your device.
- Network transmission: All network communications initiated by third-party advertising SDKs are encrypted in transit using industry-standard Transport Layer Security (TLS / HTTPS) protocols.
- International data transfers: Third-party advertising providers like Google operate global server networks. Data processed by these services may be transferred to, stored, and processed in the United States or other countries where Google and its partners operate facilities, subject to legally recognized data protection safeguards such as standard contractual clauses.

## 10 Your privacy rights
Depending on your geographic location and country of residence, you may have specific statutory privacy rights:

- Access and information: The right to understand what personal information is collected, used, and shared.
- Deletion: The right to request the deletion of personal data. You can exercise this directly by clearing app data or uninstalling the game.
- Opt out of sale or sharing: Under laws like the California Consumer Privacy Act as amended by the CPRA, residents have the right to opt out of the "sale" or "sharing" of personal data for cross-context behavioral advertising. You can exercise this right using your device's ad ID opt-out settings and through in-app consent preferences.
- European privacy rights (GDPR / UK GDPR): If you reside in the EEA or UK, you have the right to access, rectify, or erase your data, restrict or object to certain processing activities, withdraw your consent at any time without affecting the lawfulness of prior processing, and lodge a complaint with your local Data Protection Authority.

To inquire about or exercise any applicable rights, please contact Entire Solutions at support@entiresol.com.

## 11 Changes to this policy
Entire Solutions may update this Privacy Policy from time to time to reflect game updates, changes in legal obligations, or modifications to our third-party advertising integrations.

When changes are made, the revised policy will be posted with an updated "Last updated" date at the top of the document. We recommend reviewing this Privacy Policy periodically. Your continued use of Snake Buddy following the publication of changes signifies your acknowledgment and acceptance of the revised terms.

## 12 Contact and third-party privacy links
If you have questions, feedback, or concerns regarding this Privacy Policy or our privacy practices, please contact us:

- Developer / Publisher: Entire Solutions
- Privacy Contact Email: support@entiresol.com
- Mailing / Website: support@entiresol.com <!-- TODO: confirm official website URL if published -->

### Third-party privacy links
For detailed information regarding how our third-party advertising and platform service partners process data, please consult their official privacy policies:

- Google Privacy Policy: https://policies.google.com/privacy
- Google AdMob and Ads Technologies: https://policies.google.com/technologies/ads
- How Google Uses Information from Sites or Apps that Use Its Services: https://policies.google.com/technologies/partner-sites
- Google Play Services: https://policies.google.com/privacy
- Apple Privacy Policy (for iOS users): https://www.apple.com/legal/privacy/

