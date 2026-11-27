# Phone test checklist (Android)

Run this on a real phone before a release build. Confirm with the owner before any APK is built. Times below are in Asia/Singapore.

## Compass and direction

- [ ] Open the direction calculator. The heading updates when you turn the phone.
- [ ] A phone without a working compass still lets you type a bearing or use the map.
- [ ] The 24 Mountains label matches the degree shown, including line-facing within 3°.

## Map bearing

- [ ] The map loads (tiles appear) on Wi-Fi and on mobile data.
- [ ] Address search finds a Singapore block or street.
- [ ] Dragging or rotating the facing line updates the degree and the mountain name.
- [ ] The chosen degree is passed back into the quick check and saved as the current home.

## Listing import

- [ ] Pasting a 99.co link fills address, postal code and floor (if the listing has them) and does **not** pick a facing.
- [ ] A PropertyGuru link opens the in-app browser, then fills what it can. After import, cookies and cache are cleared.
- [ ] An HDB Flat Portal link works in the in-app browser.
- [ ] A floor-plan image, if the listing has one, can be saved and confirmed. Many listings have no plan.
- [ ] You still have to set the facing yourself.

## Floor plan and home

- [ ] Choose a plan from the gallery and photograph one with the camera (decline the camera once to confirm the app still works).
- [ ] The facing stepper saves; after you leave the screen and reopen the app, the same facing is there.
- [ ] Rotating the plan puts the front door at the bottom of the 3×3 grid. The facing palace is the bottom centre.
- [ ] Tapping a square shows the mountain/water tip for that palace.
- [ ] The floor-element note appears when a floor number is set, and is labelled as popular belief, not Flying Stars.
- [ ] Me → Delete my data removes the saved home, plan photo, checklist answers, reminder settings and crash logs, and restores the example home.

## Notifications

- [ ] Turn the daily card on from Me. Android 13+ shows the notification permission prompt.
- [ ] Set a time a few minutes ahead, wait, and confirm a generic "Today's card is ready" notification (no name or address).
- [ ] Turn it off; no further notifications arrive.
- [ ] After a reboot, an enabled reminder still fires around the chosen time (inexact).

## Your Year and tarot

- [ ] Your Year can step to years other than 2026 and 2027 and still shows a full guide (written or rule-based).
- [ ] Tarot: type a question, draw one card and a three-card spread, including a reversed card, and check the reading matches the topic.

## Crash report

- [ ] Me → Send crash report: if no crashes, you see a message. After a test crash (if one is recorded), the share sheet opens with a report that has no birth data or address.

## General

- [ ] The entertainment disclaimer is visible on reading screens.
- [ ] The app works offline for Kua, Flying Stars, BaZi, Your Year and tarot (maps and listing import need the network).
