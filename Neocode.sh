#!/bin/zsh

set -e
set -o pipefail

# --- 🎯 Configuration (Modify for your project) ---

# Path to your .xcworkspace or .xcodeproj file
PROJECT_FILE="App.xcworkspace"

# The name of your Xcode Scheme to build
SCHEME_NAME="App"

# The name of the .app file generated after build (from Xcode Build Settings > Product Name)
# e.g., Scheme might be "App-Dev" but the app name is "App.app"
PRODUCT_NAME="App"

# Default simulator target name
DEFAULT_SIMULATOR_NAME="iPhone 16e"

# --- End Configuration ---

# --- Internal Script Settings ---
BUILD_DIR="./build"
C_GREEN="\033[0;32m"
C_YELLOW="\033[0;33m"
C_RED="\033[0;31m"
C_CYAN="\033[0;36m"
C_NONE="\033[0m"

# --- Function Definitions ---

function print_usage() {
  echo "Usage: $0 ${C_CYAN}[build|run|list|clean]${C_NONE} ${C_YELLOW}[simulator|device]${C_NONE} [TARGET_ID]" >&2
  echo "\n${C_CYAN}Actions:${C_NONE}" >&2
  echo "  ${C_CYAN}build${C_NONE}    : Build the app (incrementally)." >&2
  echo "  ${C_CYAN}run${C_NONE}      : Build (incrementally) and run the app." >&2
  echo "  ${C_CYAN}list${C_NONE}     : List available devices and simulators." >&2
  echo "  ${C_CYAN}clean${C_NONE}    : Clean the build directory ($BUILD_DIR)." >&2
  echo "\n${C_YELLOW}Targets (for build/run):${C_NONE}" >&2
  echo "  ${C_YELLOW}simulator${C_NONE} [TARGET_ID]: (Optional) Simulator name. Defaults to '${DEFAULT_SIMULATOR_NAME}'." >&2
  echo "  ${C_YELLOW}device${C_NONE}    [TARGET_ID]: (Optional for 'build', Required for 'run') Device UDID." >&2
}

function clean_build_dir() {
  echo "${C_YELLOW}🧹 Cleaning build directory: ${BUILD_DIR}...${C_NONE}" >&2
  rm -rf $BUILD_DIR
  echo "${C_GREEN}✅ Build directory cleaned.${C_NONE}" >&2
}

##
# (Modified) Lists available devices and simulators.
# Updated to provide the *correct* IDs needed for 'build' and 'run'.
##
function list_targets() {
  echo "${C_CYAN}🔎 Listing available Devices (Hardware UDIDs)...${C_NONE}" >&2
  echo "${C_YELLOW}   (Use these UDIDs for 'run [device|simulator] [UDID]')${C_NONE}" >&2
  xcrun xctrace list devices
}

##
# Builds the project (Core Logic).
# (Modified: Uses PRODUCT_NAME instead of SCHEME_NAME to return the .app path)
##
function build_project() {
  local platform=$1
  local destination=$2
  local sdk=$3

  echo "${C_CYAN}🚀 1. Building Scheme '${SCHEME_NAME}' for ${platform} (Incremental)...${C_NONE}" >&2

  local project_type_flag
  if [[ "$PROJECT_FILE" == *.xcworkspace ]]; then
    project_type_flag="-workspace"
  else
    project_type_flag="-project"
  fi

  # Redirect xcodebuild's stdout (build log) to stderr (&2).
  xcodebuild build \
    $project_type_flag "$PROJECT_FILE" \
    -scheme "$SCHEME_NAME" \
    -destination "$destination" \
    -configuration Debug \
    -derivedDataPath "$BUILD_DIR" \
    >&2 
  
  if [[ $? -ne 0 ]]; then
    echo "${C_RED}❌ Build Failed.${C_NONE}" >&2
    exit 1
  fi
  
  # (Core Fix)
  # The returned path uses $PRODUCT_NAME, not $SCHEME_NAME.
  echo "$BUILD_DIR/Build/Products/Debug-$sdk/$PRODUCT_NAME.app"
}

##
# Extracts the Bundle Identifier from the .app path.
##
function get_bundle_id() {
  local app_path=$1
  local plist_path="$app_path/Info.plist"
  
  if [[ ! -f "$plist_path" ]]; then
    echo "${C_RED}❌ Info.plist not found at $plist_path${C_NONE}" >&2
    echo "" # Return an empty string to let the calling function handle the error
    return
  fi
  
  /usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$plist_path"
}

# --- 'build' Action Functions ---

function build_for_simulator() {
  local sim_name=${1:-$DEFAULT_SIMULATOR_NAME}
  local destination="platform=iOS Simulator,name=$sim_name"
  local app_path=$(build_project "iOS Simulator" "$destination" "iphonesimulator")
  
  if [[ -n "$app_path" ]]; then
    echo "${C_GREEN}✅ Build Succeeded (Simulator). Output: ${app_path}${C_NONE}" >&2
  fi
}

function build_for_device() {
  local device_udid=$1
  local destination
  
  if [[ -z "$device_udid" ]]; then
    destination="generic/platform=iOS"
    echo "${C_YELLOW}Note: No UDID specified. Building for 'generic/platform=iOS'.${C_NONE}" >&2
  else
    destination="platform=iOS,id=$device_udid"
  fi
  
  local app_path=$(build_project "iOS" "$destination" "iphoneos")

  if [[ -n "$app_path" ]]; then
    echo "${C_GREEN}✅ Build Succeeded (Device). Output: ${app_path}${C_NONE}" >&2
  fi
}

# --- 'run' Action Functions ---

function run_on_simulator() {
  local sim_name=${1:-$DEFAULT_SIMULATOR_NAME}
  local destination="platform=iOS Simulator,name=$sim_name"

  local app_path=$(build_project "iOS Simulator" "$destination" "iphonesimulator")
  echo "${C_GREEN}✅ Build Succeeded: ${app_path}${C_NONE}" >&2

  local bundle_id=$(get_bundle_id "$app_path")
  
  if [[ -z "$bundle_id" ]]; then
      echo "${C_RED}❌ Failed to extract Bundle ID from $app_path.${C_NONE}" >&2
      exit 1
  fi
  echo "${C_GREEN}✅ Bundle ID Found: ${bundle_id}${C_NONE}" >&2

  echo "${C_CYAN}🚀 2. Finding and booting simulator...${C_NONE}" >&2
  local sim_udid=$(xcrun simctl list devices | grep "$sim_name" | grep "Booted" | head -n 1 | awk -F'[()]' '{print $2}')
  
  if [[ -z "$sim_udid" ]]; then
    sim_udid=$(xcrun simctl list devices | grep "$sim_name" | head -n 1 | awk -F'[()]' '{print $2}')
    if [[ -z "$sim_udid" ]]; then
        echo "${C_RED}❌ Simulator named \"$sim_name\" not found.${C_NONE}" >&2
        exit 1
    fi
    echo "Booting $sim_name ($sim_udid)..." >&2
  fi
  echo "${C_GREEN}✅ Simulator Ready: ${sim_udid}${C_NONE}" >&2
  
  echo "${C_CYAN}🚀 3. Installing app on simulator...${C_NONE}" >&2
  xcrun simctl install "$sim_udid" "$app_path"
  
  echo "${C_CYAN}🚀 4. Launching app (PID attaching)...${C_NONE}" >&2
  echo "--- (App logs will stream below) ---" >&2
  xcrun simctl launch --console "$sim_udid" "$bundle_id"
}

function run_on_device() {
  local device_udid=$1
  if [[ -z "$device_udid" ]]; then
    echo "${C_RED}❌ Error: Device UDID is required for 'run' action.${C_NONE}" >&2
    print_usage
    exit 1
  fi
  
  local destination="platform=iOS,id=$device_udid"
  
  local app_path=$(build_project "iOS" "$destination" "iphoneos")
  echo "${C_GREEN}✅ Build Succeeded: ${app_path}${C_NONE}" >&2
  
  local bundle_id=$(get_bundle_id "$app_path")

  if [[ -z "$bundle_id" ]]; then
      echo "${C_RED}❌ Failed to extract Bundle ID from $app_path.${C_NONE}" >&2
      exit 1
  fi
  echo "${C_GREEN}✅ Bundle ID Found: ${bundle_id}${C_NONE}" >&2
  
  echo "${C_CYAN}🚀 2. Installing app on device ${device_udid}...${C_NONE}" >&2
  xcrun devicectl device install app --device "$device_udid" "$app_path"
  
  echo "${C_CYAN}🚀 3. Launching app (PID attaching)...${C_NONE}" >&2
  echo "--- (App logs will stream below) ---" >&2
  xcrun devicectl device process launch --console --device "$device_udid" "$bundle_id"
}


# --- 🚀 Main Script Execution ---

if [[ $# -eq 0 ]]; then
  print_usage
  exit 1
fi

ACTION=$1
TARGET_ENV=$2
TARGET_ID=$3

case $ACTION in
  "list")
    list_targets
    exit 0
    ;;
  "clean")
    clean_build_dir
    exit 0
    ;;
esac

if [[ $# -lt 2 ]]; then
  echo "${C_RED}❌ Error: 'build' and 'run' actions require a target (simulator|device).${C_NONE}" >&2
  print_usage
  exit 1
fi

case $ACTION in
  "build")
    echo "${C_CYAN}===== Executing BUILD ONLY =====${C_NONE}" >&2
    case $TARGET_ENV in
      "simulator")
        build_for_simulator "$TARGET_ID"
        ;;
      "device")
        build_for_device "$TARGET_ID"
        ;;
      *)
        echo "${C_RED}❌ Invalid target: $TARGET_ENV${C_NONE}" >&2
        print_usage
        exit 1
        ;;
    esac
    ;;
  
  "run")
    echo "${C_CYAN}===== Executing BUILD and RUN =====${C_NONE}" >&2
    case $TARGET_ENV in
      "simulator")
        run_on_simulator "$TARGET_ID"
        ;;
      "device")
        run_on_device "$TARGET_ID"
        ;;
      *)
        echo "${C_RED}❌ Invalid target: $TARGET_ENV${C_NONE}" >&2
        print_usage
        exit 1
        ;;
    esac
    ;;
    
  *)
    echo "${C_RED}❌ Invalid action: $ACTION${C_NONE}" >&2
    print_usage
    exit 1
    ;;
esac

echo "\n${C_GREEN}🎉 Workflow finished successfully.${C_NONE}" >&2
