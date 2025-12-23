#!/bin/bash

# Screenshot capture script for CleanSnap app
SCREENSHOTS_DIR="/Users/sebastiandoyle/Documents/Local Programming/Claude Code Goes Wild/Duplicate Photos/CleanSnap/Screenshots"
DEVICE="iPhone 17 Pro"
APP_ID="com.cleansnap.app"

mkdir -p "$SCREENSHOTS_DIR"
cd "$SCREENSHOTS_DIR"

take_screenshot() {
    local name=$1
    sleep 1
    xcrun simctl io "$DEVICE" screenshot "${name}.png"
    echo "Captured: ${name}.png"
}

tap_at() {
    local x=$1
    local y=$2
    xcrun simctl io "$DEVICE" tap "$x" "$y"
    sleep 0.5
}

# Kill and relaunch app fresh
xcrun simctl terminate "$DEVICE" "$APP_ID" 2>/dev/null
sleep 1
xcrun simctl launch "$DEVICE" "$APP_ID"
sleep 2

# Screenshot 1: Onboarding Welcome
take_screenshot "01_onboarding_welcome"

# Tap Next button (center bottom area)
tap_at 207 750
sleep 1
take_screenshot "02_onboarding_duplicates"

# Tap Next again
tap_at 207 750
sleep 1
take_screenshot "03_onboarding_vault"

# Tap Next again
tap_at 207 750
sleep 1
take_screenshot "04_onboarding_cleanup"

# Tap "Continue with Limited Access" (below main button)
tap_at 207 810
sleep 2
take_screenshot "05_home_screen"

# Tap Duplicates tab (second tab)
tap_at 155 890
sleep 1
take_screenshot "06_duplicates_screen"

# Tap Vault tab (third tab)
tap_at 280 890
sleep 1
take_screenshot "07_vault_locked"

# Tap Settings tab (fourth tab)
tap_at 360 890
sleep 1
take_screenshot "08_settings_screen"

# Tap Home tab
tap_at 55 890
sleep 1

echo "Screenshots captured in $SCREENSHOTS_DIR"
ls -la "$SCREENSHOTS_DIR"
