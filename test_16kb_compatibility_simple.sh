#!/bin/bash

# Simplified 16KB Page Size Compatibility Test Script 
# Tests existing APK without rebuilding

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
APP_PACKAGE="com.yourpackage"
APK_PATH="test_apk/your_apk_name.apk"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/16kb_compatibility_test.log"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if ADB is available
    if ! command -v adb &> /dev/null; then
        print_error "ADB is not installed or not in PATH"
        exit 1
    fi
    
    # Check if device/emulator is connected
    if ! adb devices | grep -q "device$"; then
        print_error "No Android device or emulator connected"
        print_status "Please connect a device or start an emulator"
        exit 1
    fi
    
    # Check if APK exists
    if [ ! -f "$APK_PATH" ]; then
        print_error "APK not found at: $APK_PATH"
        print_status "Please build the APK first using: fvm flutter build apk --debug"
        exit 1
    fi
    
    print_success "Prerequisites check passed"
}

# Function to install APK
install_apk() {
    print_status "Installing APK on device..."
    
    # Uninstall existing app if present
    adb uninstall "$APP_PACKAGE" 2>/dev/null || true
    
    # Install new APK
    adb install "$APK_PATH"
    
    if adb shell pm list packages | grep -q "$APP_PACKAGE"; then
        print_success "APK installed successfully"
    else
        print_error "Failed to install APK"
        exit 1
    fi
}

# Function to check device page size
check_device_page_size() {
    print_status "Checking device page size..."
    
    PAGE_SIZE=$(adb shell getconf PAGE_SIZE)
    print_status "Device page size: $PAGE_SIZE bytes"
    
    if [ "$PAGE_SIZE" = "16384" ]; then
        print_success "Device is running with 16KB page size"
        return 0
    elif [ "$PAGE_SIZE" = "4096" ]; then
        print_warning "Device is running with 4KB page size (standard)"
        print_status "Testing compatibility mode..."
        return 1
    else
        print_warning "Unknown page size: $PAGE_SIZE"
        return 1
    fi
}

# Function to enable 16KB compatibility mode
enable_16kb_compatibility() {
    print_status "Enabling 16KB compatibility mode..."
    
    # Enable 16KB backcompat mode
    adb shell setprop bionic.linker.16kb.app_compat.enabled true
    adb shell setprop pm.16kb.app_compat.disabled false
    
    print_success "16KB compatibility mode enabled"
}

# Function to test app launch
test_app_launch() {
    print_status "Testing app launch..."
    
    # Launch the app
    adb shell am start -n "$APP_PACKAGE/.MainActivity"
    
    # Wait for app to start
    sleep 5
    
    # Check if app is running
    if adb shell ps | grep -q "$APP_PACKAGE"; then
        print_success "App launched successfully"
        
        # Check for compatibility warnings in logcat
        print_status "Checking for compatibility warnings..."
        sleep 3
        
        # Look for 16KB compatibility warnings
        COMPAT_WARNINGS=$(adb logcat -d | grep -i "16kb\|page.*size\|compat.*mode" | wc -l)
        if [ "$COMPAT_WARNINGS" -gt 0 ]; then
            print_warning "Found $COMPAT_WARNINGS compatibility warnings in logs"
            adb logcat -d | grep -i "16kb\|page.*size\|compat.*mode" | head -5
        else
            print_success "No compatibility warnings found"
        fi
        
        return 0
    else
        print_error "App failed to launch"
        return 1
    fi
}

# Function to test app functionality
test_app_functionality() {
    print_status "Testing basic app functionality..."
    
    # Test if app is responsive
    adb shell input keyevent KEYCODE_HOME
    sleep 2
    adb shell am start -n "$APP_PACKAGE/.MainActivity"
    sleep 3
    
    if adb shell ps | grep -q "$APP_PACKAGE"; then
        print_success "App is responsive to navigation"
    else
        print_error "App is not responsive"
        return 1
    fi
    
    # Test memory usage
    print_status "Checking memory usage..."
    MEMORY_INFO=$(adb shell dumpsys meminfo "$APP_PACKAGE" | head -20)
    echo "$MEMORY_INFO"
    
    return 0
}

# Function to generate compatibility report
generate_report() {
    print_status "Generating compatibility report..."
    
    REPORT_FILE="$SCRIPT_DIR/16kb_compatibility_report.txt"
    
    {
        echo "=========================================="
        echo "16KB Page Size Compatibility Test Report"
        echo "=========================================="
        echo "Date: $(date)"
        echo "App Package: $APP_PACKAGE"
        echo "APK Path: $APK_PATH"
        echo ""
        
        echo "Device Information:"
        echo "-------------------"
        adb shell getprop ro.build.version.release
        adb shell getprop ro.build.version.sdk
        adb shell getprop ro.product.model
        adb shell getprop ro.product.manufacturer
        echo ""
        
        echo "Page Size Information:"
        echo "---------------------"
        echo "Device Page Size: $(adb shell getconf PAGE_SIZE) bytes"
        echo ""
        
        echo "App Status:"
        echo "-----------"
        if adb shell ps | grep -q "$APP_PACKAGE"; then
            echo "App Status: RUNNING"
        else
            echo "App Status: NOT RUNNING"
        fi
        echo ""
        
        echo "Compatibility Warnings:"
        echo "----------------------"
        adb logcat -d | grep -i "16kb\|page.*size\|compat.*mode" || echo "No warnings found"
        echo ""
        
        echo "Memory Usage:"
        echo "------------"
        adb shell dumpsys meminfo "$APP_PACKAGE" | head -10
        echo ""
        
    } > "$REPORT_FILE"
    
    print_success "Compatibility report generated: $REPORT_FILE"
}

# Function to cleanup
cleanup() {
    print_status "Cleaning up..."
    
    # Stop the app
    adb shell am force-stop "$APP_PACKAGE"
    
    # Reset compatibility mode
    adb shell setprop bionic.linker.16kb.app_compat.enabled false
    adb shell setprop pm.16kb.app_compat.disabled true
    
    print_success "Cleanup completed"
}

# Main execution
main() {
    echo "=========================================="
    echo "16KB Page Size Compatibility Test"
    echo "FindIt Mobile App"
    echo "=========================================="
    echo ""
    
    log_message "Starting 16KB compatibility test"
    
    # Initialize log file
    echo "16KB Page Size Compatibility Test Log" > "$LOG_FILE"
    echo "Started at: $(date)" >> "$LOG_FILE"
    echo "==========================================" >> "$LOG_FILE"
    
    # Run tests
    check_prerequisites
    install_apk
    
    # Check device page size
    if check_device_page_size; then
        print_status "Testing on native 16KB device"
    else
        print_status "Testing with 16KB compatibility mode"
        enable_16kb_compatibility
    fi
    
    # Test app functionality
    if test_app_launch; then
        test_app_functionality
        print_success "App is compatible with 16KB page sizes"
    else
        print_error "App failed compatibility test"
    fi
    
    # Generate report
    generate_report
    
    # Cleanup
    cleanup
    
    echo ""
    echo "=========================================="
    print_success "16KB compatibility test completed!"
    echo "Check the report file for detailed results"
    echo "=========================================="
    
    log_message "16KB compatibility test completed"
}

# Run main function
main "$@"
