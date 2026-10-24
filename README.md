# 16KB Page Size Compatibility Test (Android)

This project provides a **Bash automation script** to test Android apps for compatibility with devices that use a **16 KB memory page size**, as described in Google’s official [Android Page Size Compatibility Guide](https://developer.android.com/guide/practices/page-sizes).  
It installs an APK, checks page-size configuration, enables compatibility mode if required, launches the app, collects logs and memory stats, and generates a report.

> 🧩 This script was developed with help from the official Android documentation and collaboration with colleagues.

---

## 🎯 Purpose

Android 15 introduces support for **16 KB page sizes** on newer ARM devices.  
Apps that rely on native code (C/C++) or memory-intensive workloads may fail to run unless verified.  
This script helps developers **quickly validate** whether their existing APKs can execute safely in such environments.

---

## 🧰 Features

- ✅ Detects the device page size (`getconf PAGE_SIZE`)
- ✅ Enables 16 KB app-compatibility mode on 4 KB systems
- ✅ Installs and launches the specified APK automatically
- ✅ Verifies that the app process is running
- ✅ Checks for logcat warnings or linker issues
- ✅ Dumps memory summary (`dumpsys meminfo`)
- ✅ Generates a concise text report and log file

---

## 🧩 Requirements

- macOS / Linux environment with **bash**
- **ADB** installed and accessible in `$PATH`
- A connected Android 15+ device or 16 KB-capable emulator
- Your target APK file built with compatible NDK or Flutter

---

## ⚙️ Quick Start

```bash
# 1️⃣  Make the script executable
chmod +x test_16kb_compatibility_simple.sh

# 2️⃣  (Optional) Update configuration inside the script
#      APP_PACKAGE="your.app.package"
#      APK_PATH="path/to/your.apk"

# 3️⃣  Run the test
./test_16kb_compatibility_simple.sh
or
sh test_16kb_compatibility_simple.sh
```

The script will:
1. Verify ADB and connected device  
2. Install your APK (uninstalling previous instance if present)  
3. Detect or enable 16 KB compatibility mode  
4. Launch the app and monitor logs  
5. Generate:
   - `16kb_compatibility_test.log`
   - `16kb_compatibility_report.txt`

---

## 📄 Output Example

```
==========================================
16KB Page Size Compatibility Test Report
==========================================
Date: Fri Oct 24 11:21:09 +06 2025
App Package: com.polydrive
Device Page Size: 16384 bytes
App Status: RUNNING
Compatibility Warnings: None found
Memory Usage: Stable (~20 MB)
==========================================
```

---

## 🧠 How It Works

- **Page Size Detection:**  
  Uses `adb shell getconf PAGE_SIZE` to determine device memory page size.

- **Compatibility Mode:**  
  If running on a 4 KB device, the script temporarily enables:
  ```bash
  adb shell setprop bionic.linker.16kb.app_compat.enabled true
  adb shell setprop pm.16kb.app_compat.disabled false
  ```

- **Verification:**  
  Launches the app, inspects running processes, filters logcat output for `"16kb"`, `"page size"`, or `"compat mode"` references, and reports findings.

---

## 🧾 Notes & Best Practices

- Use the **Android 15 system image (16 KB ARM64 emulator)** for best results.  
- Always review logcat for any warnings related to `bionic`, `linker`, or native libraries.  
- Some warnings may originate from system services, not the tested app.  
- The script automatically resets system properties during cleanup.

# Android 16KB Compatibility Test Flow

```mermaid
flowchart TD
    subgraph group_control["Test Control"]
        node_script["Test Workflow"]
    end

    subgraph group_validation["Device Validation"]
        node_page_check["Page Size Check"]
        node_compat_mode["Compatibility Mode"]
        node_app_run["App Launch Check"]
        node_log_check["Log Inspection"]
        node_memory_check["Memory Inspection"]
    end

    subgraph group_outputs["Test Outputs"]
        node_log_file["Test Log"]
        node_report["Compatibility Report"]
    end

    node_developer(("Developer"))
    node_apk["Target APK"]
    node_adb["ADB Tool"]
    node_device["Android Device"]

    node_developer -->|"runs"| node_script
    node_apk -->|"supplies APK"| node_script
    node_script -->|"runs"| node_page_check
    node_script -->|"runs"| node_compat_mode
    node_script -->|"runs"| node_app_run
    node_script -->|"runs"| node_log_check
    node_script -->|"runs"| node_memory_check
    node_page_check -->|"reads page size"| node_adb
    node_compat_mode -->|"sets properties"| node_adb
    node_app_run -->|"installs and launches"| node_adb
    node_adb -->|"executes commands"| node_device
    node_log_check -->|"reads logcat"| node_adb
    node_memory_check -->|"dumps meminfo"| node_adb
    node_script -->|"resets properties"| node_adb
    node_script -->|"writes log"| node_log_file
    node_script -->|"writes report"| node_report

    click node_script "https://github.com/shazzadur007/16kb-page-size-compatibility-test-script-android-/blob/main/test_16kb_compatibility_simple.sh"
    click node_page_check "https://github.com/shazzadur007/16kb-page-size-compatibility-test-script-android-/blob/main/test_16kb_compatibility_simple.sh"
    click node_compat_mode "https://github.com/shazzadur007/16kb-page-size-compatibility-test-script-android-/blob/main/test_16kb_compatibility_simple.sh"
    click node_app_run "https://github.com/shazzadur007/16kb-page-size-compatibility-test-script-android-/blob/main/test_16kb_compatibility_simple.sh"
    click node_log_check "https://github.com/shazzadur007/16kb-page-size-compatibility-test-script-android-/blob/main/test_16kb_compatibility_simple.sh"
    click node_memory_check "https://github.com/shazzadur007/16kb-page-size-compatibility-test-script-android-/blob/main/test_16kb_compatibility_simple.sh"

    classDef toneNeutral fill:#f8fafc,stroke:#334155,stroke-width:1.5px,color:#0f172a
    classDef toneBlue fill:#dbeafe,stroke:#2563eb,stroke-width:1.5px,color:#172554
    classDef toneAmber fill:#fef3c7,stroke:#d97706,stroke-width:1.5px,color:#78350f
    classDef toneMint fill:#dcfce7,stroke:#16a34a,stroke-width:1.5px,color:#14532d
    classDef toneRose fill:#ffe4e6,stroke:#e11d48,stroke-width:1.5px,color:#881337
    classDef toneIndigo fill:#e0e7ff,stroke:#4f46e5,stroke-width:1.5px,color:#312e81
    classDef toneTeal fill:#ccfbf1,stroke:#0f766e,stroke-width:1.5px,color:#134e4a
    class node_script toneBlue
    class node_page_check,node_compat_mode,node_app_run,node_log_check,node_memory_check toneAmber
    class node_log_file,node_report toneMint
    class node_developer,node_apk,node_adb,node_device toneIndigo
```

## 📜 License

This project is licensed under the **MIT License** — see [LICENSE](LICENSE).

---

## 🙌 Acknowledgements

- Based on Google’s [Page Size Compatibility Guide](https://developer.android.com/guide/practices/page-sizes)  
- Contributions and validation from internal QA and engineering colleagues
