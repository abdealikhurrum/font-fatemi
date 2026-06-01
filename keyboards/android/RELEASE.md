# Releasing the LigaCheh Android keyboard to Google Play

The app (`:app`, package `com.exordiumnetworks.ligacheh`) targets **API 35
(Android 15)** — the minimum Google Play accepts for new apps and updates.

## One-time: create the upload keystore

```bash
cd keyboards/android
keytool -genkeypair -v -keystore ligacheh-upload.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias ligacheh
cp keystore.properties.template keystore.properties
# edit keystore.properties with the passwords/alias you just chose
```

`keystore.properties`, `*.jks`, and `*.keystore` are git-ignored — keep the
keystore file and passwords backed up safely and out of version control. With
Play App Signing, Google holds the real app-signing key; this `.jks` is only the
*upload* key, but losing it still requires a reset through Play support.

## Build the release bundle

```bash
cd keyboards/android
./gradlew bundleRelease     # -> app/build/outputs/bundle/release/app-release.aab
```

Upload the `.aab` (Play does not accept APKs for new apps). If
`keystore.properties` is present the bundle is signed automatically; otherwise it
is unsigned.

## Play Console checklist (outside this repo)

- [ ] **Privacy Policy URL** — required for keyboards. Reuse the iOS policy text.
- [ ] **Data Safety form** — this app has no `INTERNET` permission and no network
      code: it collects and transmits **no** user data. Declare accordingly.
- [ ] Store listing: 512×512 icon, 1024×500 feature graphic, phone screenshots,
      short + full description.
- [ ] Content rating questionnaire and target-audience declaration.
- [ ] Bump `versionCode`/`versionName` in `app/build.gradle` for each release.
