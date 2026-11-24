# Google Play listing

Text and answers for the Play Console. Nothing here is used by the app itself.

## Store listing

**App name** (30 characters or fewer)
From Gravel Hill Bible

**Short description** (80 characters or fewer)
Read the Bible, keep notes and a prayer list, with a new verse every day.

**Full description**
From Gravel Hill Bible is a free Bible reader for everyday reading and study, with notes, highlights, a prayer list and a new verse every day.

WHAT YOU CAN DO
• Read the King James Version, included in the app with no download, and add other translations from within the app
• Search the Bible and open two passages side by side with split view
• Highlight verses and keep notes, with labels to find them again
• Keep a prayer list of the people, events and requests you want to remember, and add or remove names whenever you like
• See a new verse of the day, chosen with Gospel hall assemblies in mind, changing at midnight in Halifax, Nova Scotia
• Choose a light or dark theme, a text size and several reading layouts
• Optionally sync your notes, prayer list, settings and reading position through your own Google Drive, so your devices stay together

PRIVATE AND SIMPLE
No ads, no tracking, and no account with us. Everything stays on your device unless you choose to sync with your own Google Drive. The app can only see its own hidden app folder there, never your other files.

ABOUT
From Gravel Hill Bible is built and maintained by From Gravel Hill Enterprises (fromgravelhill.ca). It is built on Basic Bible, created by PopGTN, and the source code is open under the Apache License 2.0. The King James Version text is in the public domain; each translation shows its own rights notice.

**Category:** Books & Reference
**Contact website:** https://fromgravelhill.ca/
**Contact email:** the address you want shown publicly (required)
**Privacy policy URL:** you must publish one before the first release (see "Privacy policy" at the end). Suggested address: https://fromgravelhill.ca/from-gravel-hill-bible/privacy/

## Graphics

- App icon, 512 x 512 PNG: `play-store/icon-512.png`
- Feature graphic, 1024 x 500: `play-store/feature-graphic-1024x500.png`
- Phone screenshots (at least 2, up to 8): take them on your phone. Suggested: Bible reading, the book picker, Verse of the Day, Prayer List, Notes, Settings, and split view.
- Regenerate every icon and graphic with `python tools/generate_icons.py` (needs `pip install pillow`).

## App content answers

- **App access:** all functionality is available without logging in; signing in with Google is optional and only turns on sync
- **Ads:** no ads
- **Target audience:** 13 and over (or 18 and over). Avoid choosing under 13, which triggers the Families policy.
- **Content rating questionnaire:** religious content; no violence, no user-generated content shared with others, no purchases
- **News app / government app / financial features / health features:** none
- **Data safety:** the developer collects no data and shares none. Optional Google Drive sync stores the user's notes, prayer list, settings and reading position in the user's own Google Drive app-data folder, which the developer cannot read. The app uses HTTPS only, so data is encrypted in transit. Users can delete their synced data by removing the app's data in their Google Account settings.
- **Permissions:** internet; notifications (used for translation download progress; asked inside the app)
- **Google sign-in:** requires the OAuth consent screen to be published and the Android OAuth client to list this app's package name (`ca.fromgravelhill.bible`) and the SHA-1 of the Play signing key. Add Play's app-signing SHA-1 (Play Console, App integrity) as a second Android client, or sign-in fails for people who install from Play.

## Release steps

1. Download the `.aab` file from the private draft release named `play-v` plus the version (Releases page; only people with write access can see drafts). Delete the draft after uploading and never click Publish on it.
2. Play Console, Testing, Internal testing, Create new release. On first upload, accept Play App Signing.
3. Upload the `.aab`, add testers by email, and roll out.
4. Test the Play version. Then use Closed testing and Production when ready.
5. Personal developer accounts created recently must run a closed test with at least 12 testers for 14 days before applying for production. Organization accounts do not.
6. Every upload needs a higher version number than the last. The release number counts up with every release, so this is automatic.
7. A bundle is only built when the release signing secrets are set. The key that signs it is your upload key: keep it safe, because Play needs it for every update.

## Privacy policy (draft to publish)

**From Gravel Hill Bible privacy policy**

From Gravel Hill Bible does not collect, store or share your personal information on any server run by From Gravel Hill Enterprises, and it contains no ads or analytics.

Your notes, highlights, prayer list, settings and reading position are stored on your device. If you choose to sign in with Google, the app copies those items to a hidden app-data folder in your own Google Drive so your devices can stay in step. The app can access only that folder, not your other Drive files, and From Gravel Hill Enterprises cannot see it. You can sign out in Settings at any time, and you can remove the synced data from your Google Account settings (Security, Third-party access).

The app connects to the internet to download Bible translations from a public GitHub repository and, if you sign in, to Google. Those services have their own privacy policies.

Contact: the email address shown on the Play listing. Last updated: the date you publish it.
