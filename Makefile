.PHONY: release
release: release-android

.PHONY: release-android
release-android:
	flutter build apk --release --target-platform android-arm,android-arm64

.PHONY: android-install
android-install:
	~/Library/Android/sdk/platform-tools/adb install build/app/outputs/flutter-apk/app-release.apk