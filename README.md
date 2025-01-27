# Sorugami App

This is very short guide and insufficient, for more detailed information,
please be sure to check the [documentation](https://wrteamdev.github.io/Elite_Quiz_Doc) or Offline Doc provided in with the code.

#### IGNORE THE .githooks folder and setup-hooks.sh file, it is only for our development process.

#### it doesn't affect the app code in any way.

## How to run the app in Android (real or emulator)

### Android

1. Get the packages

```shell Get the packages
flutter pub get
```

2. Run the app

```shell
flutter run
```

### IOS (Simulator)

1. Get the packages

```shell Get the packages
flutter pub get
```

2. Get the Pods

```shell
cd ios
pod install
cd ..
```

3. Run the app

```shell
flutter run
```

## How to get your DEBUG SHA keys

- prerequisite: ensure that you are able to use the `keytool` command in your terminal.
  If not, please check your Java installation. Only continue after you are able to use the `keytool` command.

- debug keystore is automatically created when you install the Android Studio for the first time.
- and when you sign the app with in debug mode, it will use that debug keystore.

If you are using Mac or Linux, you can use the following command to get the SHA keys:

```shell
keytool -list -v -alias androiddebugkey -keystore ~/.android/debug.keystore -keypass android -storepass android
```

and if you are using Windows, you can use the following command to get the SHA keys:

```shell
keytool -list -v -alias androiddebugkey -keystore %USERPROFILE%\.android\debug.keystore -keypass android -storepass android
```

- You can find more about this in app [documentation](https://wrteamdev.github.io/Elite_Quiz_Doc/#:~:text=SHA%20keys%20and%20Keystore%20Basics).

## How to build the release version of the app (for Play Store)

prerequisite:

- make sure you are using correct app version (you can change it from pubspec.yaml then run `flutter pub get`)
- you will need to first create a new release keystore for the app.
- And sign the app with it, also add the SHA keys (of keystore) in firebase, re-download the google-services.json file.
- Run the app with release keystore make sure to check if login works fine.

```shell Build App Bundle
flutter build appbundle --release
open build/app/outputs/bundle/release/
```
# sorugamiapp
# sorugamiapp
