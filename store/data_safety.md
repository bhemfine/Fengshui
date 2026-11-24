# Google Play Data safety form: answers

Effective: [date] · App: Inkstone · Publisher: [Publisher name]

These answers apply to v1.0 and to Phase 2 to 4 features, all of which use the stateless proxy. Revise them before the marketplace launches.

## Key concept: "collected" vs ephemeral processing

Google's definitions:

- **"Collected"** means data is transmitted off the device to you (the developer) or to a third party.
- **Processed only on the device** does not count as collected.
- **Ephemeral processing** also does not need to be declared as collected. Google treats processing as ephemeral when data is held only in memory, kept no longer than needed to serve the request in real time, and not used for any other purpose.

How this applies to Inkstone:

- All profile data, charts, floor plans, photos and journals stay on the device. They are **not collected**.
- The proxy forwards images, coordinates and text to Anthropic or Google Maps in memory. It returns the result, then stores and logs nothing. This meets the definition of **ephemeral processing**, so the answer is **not collected**.
- Google's guidance also says data sent to third-party services on your behalf counts as collection unless the processing is ephemeral, or another exemption applies. Before submitting, confirm in writing that each processor does not retain the data beyond the request, or that the retention fits Google's criteria. Anthropic API retention terms and Google Maps caching terms are both relevant. **If you cannot confirm this, declare the data type as Collected → "Processed ephemerally: Yes"**, with purpose "App functionality". This is the safer option, and the form supports it directly.

## Section-by-section answers

| Question | Answer |
| --- | --- |
| Does your app collect or share any of the required user data types? | **No.** This is the recommended answer if the checks below pass. If any processor keeps data, answer **Yes** and use the table with "ephemeral: yes". |
| Is all user data encrypted in transit? | **Yes** (HTTPS/TLS to the proxy, Maps, AI and Play) |
| Do you provide a way for users to request that their data be deleted? | **Yes.** Users delete in the app (Settings > Delete all data) and then uninstall. The developer holds no data. If Play asks for a deletion URL or method, point to the privacy policy, section 9. |
| Data shared with third parties | **None.** Transfers to service providers that process data on our behalf are not "sharing" under Google's definition. |
| Account creation | The app does not let users create an account. Answer accordingly in the account deletion section. |
| Independent security review | No (optional) |
| Families policy / target audience | 18+; not directed to children |

## Per data type

| Data type | Collected? | Shared? | Notes / what to declare |
| --- | --- | --- | --- |
| **Personal info** (name, email, address, other) | No | No | Names, birth details and home addresses stay on the device. Names are removed from prompts. In Phase 3, addresses go to Maps through the proxy and are processed ephemerally. **Marketplace:** contact email becomes collected (App functionality, not optional for booking) and must be declared then. |
| **Financial info** (purchase history) | No | No | Google Play handles payment and purchase history. Purchase token checks are not stored. Google's guidance says Play Billing data does not need declaring. |
| **Location**, approximate or precise | No | No | Used only during a Maps check and sent through the proxy ephemerally. No background location, nothing stored. If processor retention is uncertain, declare: Precise location, Collected, ephemeral: Yes, App functionality, Optional. |
| **Photos and videos** | No | No | Floor plan, palm and face photos are processed ephemerally by the AI processor through the proxy. Saved copies stay on the device only. If uncertain, declare: Photos, Collected, ephemeral: Yes, App functionality, Optional. |
| **Health and fitness** | No | No | No health data. |
| **Messages** | No | No | Ask the Master chats stay on the device. Questions are processed ephemerally by AI. |
| **App activity** (interactions, in-app search) | No | No | No analytics. If anonymous aggregate analytics are ever added, re-evaluate. |
| **App info and performance: Crash logs, Diagnostics** | See note | No | If a crash reporter is **enabled**, declare: **Crash logs** (and **Diagnostics** if performance data is sent), Collected, not shared, not ephemeral, purpose "App functionality / Analytics", optional or required as applicable. Keep the reports free of PII. Play Console Android vitals alone does not require a declaration. |
| **Device or other IDs** | No | No | No advertising ID and no installation ID. If the crash reporter creates an installation ID, declare **Device or other IDs**, Collected, purpose App functionality, or turn the ID off. |
| **Files and docs** | No | No | Floor plan PDFs stay on the device or go ephemerally to the AI processor. Backups go to the user's own storage or Drive, which the developer cannot access. |
| **Contacts, Calendar, Audio, Web browsing** | No | No | Not used |

## Double-check before submitting

- [ ] The proxy has no request body logging. Check Cloudflare Workers Logs, Logpush, Tail and the host's access logs. Turn off content logging and test it.
- [ ] Anthropic API data retention and training terms are confirmed in writing. Zero retention is preferred. Otherwise, use the ephemeral declaration.
- [ ] Google Maps caching terms are reviewed, and the proxy does not cache results.
- [ ] Scan every SDK in the merged manifest and dependency tree, including crash reporting, billing, Drive and fonts, for data it sends by default.
- [ ] Crash reporter: the user ID is off, breadcrumbs and logs are free of PII, and the screenshot feature is off. The form matches the crash reporter's actual behaviour.
- [ ] No `AD_ID` permission in the merged manifest. Remove it if a library adds it.
- [ ] Android Auto Backup is disabled or excluded for the raw database (`dataExtractionRules`, `fullBackupContent`).
- [ ] The location permission is foreground only and requested only during a Maps check.
- [ ] The privacy policy URL is live, public, not a PDF, and matches these answers.
- [ ] "Delete all data" works on a physical device, including files and photos saved by the app.
- [ ] The listing makes no medical, financial or guaranteed-outcome claims, and the disclaimer is present.
- [ ] Before the marketplace launches, update the form: email (Personal info), the booking note, Purchase history (Stripe), and Audio/Video if calls are recorded (they should not be).
