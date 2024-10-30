#!/bin/sh

clear () {
    rm log.log
    rm station_result.xml
}

DEVICE_NAME=$(xcrun simctl list devices | grep 'iPhone' | grep -v 'iPhone SE' | sed -E 's/^ *([^()]+) \(([A-F0-9-]+)\) \(.*$/\1 \2/' | sort -k2 -r | head -n 1 | awk '{print $NF}')

if [ -z "$DEVICE_NAME" ]; then
  echo "Error: No Booted iOS Simulator device found."
  exit 1
fi

set -o pipefail && xcodebuild -project ios-stations.xcodeproj -scheme ios-stations -sdk iphonesimulator -destination "platform=iOS Simulator,id=$DEVICE_NAME" "-only-testing:ios-stationsTests/ios_stationsTests/testStation$1" test &> log.log
buildStatus=${PIPESTATUS[0]}

cat log.log | xcpretty --report junit --output station_result.xml > /dev/null 2>&1

# xcprettyの出力ファイルの行数をカウント
reportRowCount=$(cat station_result.xml | wc -l)
if [ $reportRowCount -le 2 ]; then
    if [ $buildStatus -eq 0 ]; then
        # テスト通過
        cat station_result.xml
        clear
        exit 0
    else
        # コンパイルエラー
        cat ios-stationsTests/junit_compile_error.xml
        clear
        exit 1
    fi
else
    # テストエラー
    cat station_result.xml
    clear
    exit 1
fi
