# Building and Running Swiftfin in the iOS Simulator

This guide explains how to build and run the Swiftfin app in the iOS Simulator from the command line.

## Prerequisites
- Xcode and Xcode command line tools installed
- Carthage installed (for VLCKit dependencies)
- Bundler and Ruby (for Fastlane, optional)

## Steps

### 1. Install Ruby Gems (Fastlane, optional)
If you want to use Fastlane or other Ruby tools:
```sh
bundle install --path vendor/bundle
```

### 2. Ensure Carthage Dependencies Are Present
VLCKit frameworks should be in `Carthage/Build/`. If not, run:
```sh
carthage bootstrap --use-xcframeworks
```

### 3. Build the App for the Simulator
List available schemes and simulators (optional):
```sh
xcodebuild -list
```

Build the app for an available simulator (e.g., iPhone 16, OS 18.5):
```sh
xcodebuild -scheme "Swiftfin" -destination "platform=iOS Simulator,name=iPhone 16,OS=18.5" build
```

### 4. Boot the Simulator
Find available devices:
```sh
xcrun simctl list devices available | grep iPhone
```

Boot the desired simulator (replace the name as needed):
```sh
xcrun simctl boot "iPhone 16"
open -a Simulator
```

### 5. Install the App in the Simulator
```sh
xcrun simctl install booted "/Users/andrejvysny/Library/Developer/Xcode/DerivedData/Swiftfin-fgghtvigwpcaqzejbcbexicnucjq/Build/Products/Debug-iphonesimulator/Swiftfin iOS.app"
```

### 6. Launch the App in the Simulator
```sh
xcrun simctl launch booted org.jellyfin.swiftfin
```

---

You should now see the Swiftfin app running in the iOS Simulator. Adjust device names and paths as needed for your environment. 

## Quick Rebuild & Relaunch (Already Set Up)

If you have already set up the environment and just want to rebuild and relaunch the app in the simulator:

1. **Rebuild the app:**
   ```sh
   xcodebuild -scheme "Swiftfin" -destination "platform=iOS Simulator,name=iPhone 16,OS=18.5" build
   ```
2. **Reinstall the app in the booted simulator:**
   ```sh
   xcrun simctl install booted "/Users/andrejvysny/Library/Developer/Xcode/DerivedData/Swiftfin-fgghtvigwpcaqzejbcbexicnucjq/Build/Products/Debug-iphonesimulator/Swiftfin iOS.app"
   ```
3. **Relaunch the app:**
   ```sh
   xcrun simctl launch booted org.jellyfin.swiftfin
   ```

This is useful for rapid development and testing after code changes. 