.PHONY: release
release: release-android

.PHONY: release-android
release-android:
	flutter build apk --release --target-platform android-arm,android-arm64
