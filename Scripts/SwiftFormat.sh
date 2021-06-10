# Type a script or drag a script file from your workspace to insert its path.
if which swiftformat >/dev/null; then
  swiftformat . --lint --lenient
else
  echo "warning: SwiftFormat not installed, download from https://github.com/nicklockwood/SwiftFormat"
fi