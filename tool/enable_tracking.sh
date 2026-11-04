#!/usr/bin/env sh
# Debug helper: `flutter run` force-stops the app, and Android then removes
# ScrollBuddy from the enabled accessibility services. Run this after launching
# to turn tracking back on without going through system settings.
# Note: this replaces any other enabled accessibility services on the device.
set -e
SERVICE=com.example.scrollbuddy/com.example.scrollbuddy.service.ReelAccessibilityService
adb shell settings put secure enabled_accessibility_services "$SERVICE"
adb shell settings put secure accessibility_enabled 1
echo "Tracking enabled: $(adb shell settings get secure enabled_accessibility_services)"
