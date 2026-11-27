# Inkstone Privacy Policy

Effective: 27 November 2026 (draft, updated as this build stores more on the phone)
Operator: [Publisher name] ("we", "us")
Contact: [support email]

## 1. Summary (this build)

- There is no account and no company server that keeps your personal data.
- What you save stays **on this phone**, in the app's private folder. Android's automatic backup is switched **off**.
- This build does **not** use an encrypted database. Checklist answers, the current home (facing, address, floor, unit, property type, completion year), notification time, and floor-plan photos are stored in ordinary on-device files (SharedPreferences and the app documents folder). Example birth profiles are built into the app and are not user-editable storage yet.
- "Delete my data" on the Me screen clears those saved items, the floor-plan photo, notification settings and local crash reports, and resets the home to the example. Uninstalling the app also removes them.
- Optional permissions: **camera** (only if you photograph a floor plan), **notifications** (only if you turn on the daily reminder). There is no location permission.
- Listing import and maps use the internet. Crash reports stay on the phone until you choose **Send crash report**, which opens your share sheet; we do not receive them unless you send them to us.
- Sections from "Intended at launch" onwards describe features that are **not all in this build** (encrypted database, backups, bookings, a proxy). They will be rewritten before a Play Store release so they match the shipped app.

## 2. Data on your device (this build)

The app may store:

- the current home you set: label, facing, completion year, period, address, postal code, floor, unit, property type, and the rotation of a floor-plan photo
- your household birth profiles (name, date, gender, and birth time if you add one). These start as the example couple and are only on this phone
- home-checklist answers and the last property type you used
- a floor-plan image you took, picked from the gallery, or confirmed from a listing
- whether the daily reminder is on, and the time you chose
- local crash logs (time, app version, device and OS if available, error and stack). These do **not** include names, birth dates, addresses or photos

Birth details default to the example couple Chua Boon Eng (you) and Chou Jiahui Victoria (partner). You can edit and save your own birth profile on this phone. **Delete my data** clears the saved profile and restores those two defaults.

We cannot read any of this from our side. If you uninstall the app or use **Delete my data**, it is gone. We cannot recover it.

## 3. Optional backup

Encrypted backup and Google Drive backup are **not built**. Do not rely on a backup of this prototype. Intended launch behaviour, if it ships, will be described here before release.

## 3a. Permissions (this build)

- **Internet:** map tiles, address search, and listing import (when you paste a link or share one).
- **Camera:** optional, to photograph a floor plan. You can pick a photo from the gallery instead, or skip both.
- **Notifications:** optional daily reminder. The notification text is generic ("Today's card is ready") and does not include your name or address. Alarms are inexact; the app does not use exact-alarm permission.
- No location, contacts, microphone or storage-access permission is requested in this build.


## 4. Intended at launch (not all built yet)

The headings below may still describe planned launch features. Do not treat them as a description of this prototype.

## 4. The stateless proxy

Some features need online services, such as AI explanations, photo reading, address lookup and map imagery. For these, the app sends only the data needed for that request to our proxy. This may include an image, coordinates or an address, or already-calculated chart factors. Where a feature works without them, we remove names and raw birth details before sending.

The proxy forwards the request, returns the result and then discards it. It does not store request or response content and does not log content. It keeps no user accounts. Short-lived technical data, such as an IP address used to block abuse through rate limiting, is not linked to you and is not kept with any content.

## 5. Third-party processors

| Service | Used for | What it receives |
| --- | --- | --- |
| Anthropic API (AI model) | Written explanations; reading floor plans, palms and photos (as features are released) | The minimal prompt or image sent through our proxy. It does not receive your name or account details. Data is handled under Anthropic's commercial terms. |
| Google Maps Platform | Address lookup, map, satellite and Street View (house check, birthplace lookup) | Addresses or coordinates, sent through our proxy |
| Google Play Billing | Subscriptions and purchases | Google processes payment under its own privacy policy. We never see your card details. To confirm access, the app or proxy may check a purchase token, which is not stored. |
| Crash reporting (if enabled) | Fixing crashes | Technical crash data only: device model, OS version, app version and stack trace. No names, birth data, addresses, photos, prompts or user IDs. |

We do not sell data. We do not use advertising trackers. We do not send personal data to analytics.

## 6. Permissions

| Permission | Why | When it is requested |
| --- | --- | --- |
| Camera / photos | To photograph or choose a floor plan, palm or face | Only when you use that feature |
| Location | To check a property or your current position on the map | Only while you run a Maps check. Never in the background. |
| Notifications | Daily card, clash days and solar terms (scheduled on your phone) | When you turn reminders on |
| Motion and compass sensors | To read the facing direction of a door | During the compass step |

Every feature has a manual option if you decline a permission.

## 7. Children

Inkstone is not directed to children under 13, and we do not knowingly process their data. Information about family members, including children, that you enter stays on your phone. The future marketplace will be for users aged 18 and over only.

## 8. Your rights under the PDPA (Singapore)

Under the Personal Data Protection Act 2012, you may ask to access or correct your personal data and you may withdraw consent.

Because your data is held on your phone, you can view, correct and delete it directly in the app. We hold no copy of your app data, so we usually have nothing to provide or delete. You can still contact us with any request or complaint, and we will reply within a reasonable time.

## 9. Deleting your data

1. Open **Settings > Delete all data on this device**. This wipes the database and the files saved by the app.
2. Uninstall the app.
3. Delete any backup files you made, or remove the app's data from your Google Drive (Drive > Settings > Manage apps).

## 10. Future marketplace

**This section applies only when the marketplace launches.** It does not apply to the current app.

If you book a consultation with a master, our marketplace server will store only what the booking needs:

- the session time
- the master
- an anonymous user handle
- a contact email for confirmations and reminders
- a short note about your concern
- a payment reference (card data stays with Stripe)

Your charts or floor plan are shared with the master only if you tap "share" for that booking. They are deleted with the booking. Booking data will be deleted after a fixed retention period of [retention period], except for non-identifying totals needed for accounting. Video and voice providers process calls for us. Requests to "Delete all data" will also ask us to delete any outstanding booking contact data, subject to legal duties. This policy will be updated before launch with the providers and retention period.

## 11. Security

- Data is encrypted on your device.
- All network traffic uses encryption in transit (HTTPS/TLS).
- API keys are kept only on our proxy, never in the app.

## 12. Changes

We will post updates here and change the effective date. Significant changes will be shown in the app.

## 13. Contact

[Publisher name], [support email]
