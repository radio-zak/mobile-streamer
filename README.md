# mobile-streamer

Simple multi-platform radio streaming app. Uses Flutter with just_audio and just_audio_background libraries.  
Created for Studenckie Radio ŻAK Politechniki Łódzkiej, therefore appropriate branding is applied. Make sure to remove all associated branding if you wish to use this app as scaffolding for your own projects

## License disclaimer

The code of this project is licensed under AGPLv3, all provisions of this license apply.

Assets like the "88,8MHz" logo and all it's variants are the sole propriety of Technical University of Lodz Student Radio ŻAK and, by extension, of the Technical University of Lodz. Use of this assets in forks or other, here not specified works requires specific permission from the maintainer of this project and from the radio station.

## Developing

To start contributing to this project:

1. Install git
2. [Install Flutter SDK according to docs](https://docs.flutter.dev/install/manual)
3. Clone this repository: `git clone https://github.com/radio-zak/mobile-streamer`
4. Run `flutter pub get` in the repository root

Next steps are very platform-specific.

For Android app development:

1. [Install Android Studio and appropriate SDKs (link to docs)](https://developer.android.com/studio/install)
2. [Create an Android Virtual Device (link to docs)](https://developer.android.com/studio/run/managing-avds)
3. In your IDE select the virtual device of your choice for debugging purposes.
   If you're using VSCode, this should be in the right hand corner.

As far as CLI use is concerned, to debug your app on the emulated Android device:

- run `flutter devices list` and get your device name
- start the emulator `flutter emulators --lanuch <device name>`
- then run `flutter run -d <device name> --debug`

## Contact

Primary developer: Kacper Zieliński (<kacper.zielinski@zak.lodz.pl>)
