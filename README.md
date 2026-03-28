# Linux NitroSense — Pop!_OS / Ubuntu Install Guide

> A complete guide to install [Linux-NitroSense](https://github.com/Packss/Linux-NitroSense) on **Pop!_OS** (and Ubuntu-based distros), including fixes for common errors people run into.

---

## Supported Laptop Models

| Model | Status |
|---|---|
| Acer Nitro AN515-46 | ✅ Supported |
| Acer Nitro AN515-54 | ✅ Supported |
| Acer Nitro AN515-56 | ✅ Supported |
| Acer Nitro AN515-57 | ✅ Supported |
| Acer Nitro AN515-58 | ✅ Supported |
| Acer Nitro AN515-44 | ✅ Supported |
| Acer Nitro AN517-55 | ✅ Supported |

---

## Prerequisites

- Pop!_OS 22.04+ or Ubuntu 22.04+ (any Ubuntu-based distro)
- **Secure Boot must be OFF** (required for the kernel module)

To disable Secure Boot: reboot → enter BIOS/UEFI → find Secure Boot → set to Disabled.

---

## Step 1 — Install the acpi_ec Kernel Module

This gives NitroSense access to your laptop's Embedded Controller (EC).

```bash
sudo apt-get install git dkms
git clone https://github.com/musikid/acpi_ec/
cd acpi_ec
sudo ./install.sh
sudo modprobe acpi_ec
```

Verify EC access (should output binary-looking data, not an error):

```bash
sudo cat /dev/ec | head -c 20
```

---

## Step 2 — Install Python Dependencies

```bash
sudo apt-get install python3-pyqt6 python3-pyqt6.qtcharts python3-dmidecode
```

> ⚠️ **Do NOT install `dmidecode` via pip.** The pip package has a different API and will cause an `ImportError`. Always use the apt version (`python3-dmidecode`).

---

## Step 3 — Clone Linux-NitroSense

```bash
cd ~/acpi_ec   # or any directory you prefer
git clone https://github.com/Packss/Linux-NitroSense/
cd Linux-NitroSense
```

---

## Step 4 — Apply the dmidecode Patch (Required Fix)

The original code uses `DMIDecode().model()` and `DMIDecode().cpu_type()` from a Python library that is **not compatible** with the `python3-dmidecode` apt package. This patch replaces those calls with `subprocess` calls to the system `dmidecode` binary, which works perfectly.

Run this command from inside the `Linux-NitroSense` directory:

```bash
sudo bash fix_dmidecode.sh
```

Or apply it manually — see the [Manual Patch](#manual-patch) section below.

---

## Step 5 — Run NitroSense

```bash
cd ~/acpi_ec/Linux-NitroSense
sudo -E python3 main.py
```

`sudo` is required to access the EC registers. `-E` preserves your display environment so the GUI launches correctly.

---

## fix_dmidecode.sh (The Patch Script)

Save this as `fix_dmidecode.sh` inside your `Linux-NitroSense` directory and run it with `sudo bash fix_dmidecode.sh`.

```bash
#!/bin/bash
# fix_dmidecode.sh
# Fixes the ImportError: cannot import name 'DMIDecode' from 'dmidecode'
# by replacing the Python dmidecode library calls with subprocess calls
# to the system dmidecode binary.

TARGET="core/device_regs.py"

if [ ! -f "$TARGET" ]; then
    echo "Error: $TARGET not found. Run this script from inside the Linux-NitroSense directory."
    exit 1
fi

echo "Patching $TARGET ..."

cat > "$TARGET" << 'PYEOF'
import enum
import sys
import subprocess


def _dmi_get(dmi_type, field):
    """Read a field from dmidecode output using the system binary."""
    try:
        out = subprocess.check_output(["dmidecode", "-t", dmi_type], text=True)
        for line in out.splitlines():
            if field in line:
                return line.split(":", 1)[1].strip()
    except Exception:
        pass
    return ""


def _get_model():
    return _dmi_get("system", "Product Name")


def _get_cpu_type():
    return _dmi_get("processor", "Version")


## ------------------------------##
## --Nitro EC Register Class--   ##
## ------------------------------##
# This class contains the register addresses for the Nitro EC.
# The addresses are used for communication with the EC (Embedded Controller).
# CAUTION: Changing or using these values on different laptops may cause
# unexpected behavior or damage to the laptop.
# Use at your own risk.
## ------------------------------##

class ECS_AN515_46(enum.Enum):
    GPU_FAN_MODE_CONTROL = "0x21"
    GPU_AUTO_MODE = "0x10"
    GPU_TURBO_MODE = "0x20"
    GPU_MANUAL_MODE = "0x30"
    GPU_MANUAL_SPEED_CONTROL = "0x3A"
    CPU_FAN_MODE_CONTROL = "0x22"
    CPU_AUTO_MODE = "0x04"
    CPU_TURBO_MODE = "0x08"
    CPU_MANUAL_MODE = "0x0C"
    CPU_MANUAL_SPEED_CONTROL = "0x37"
    KB_30_SEC_AUTO = "0x06"
    KB_30_AUTO_OFF = "0x00"
    KB_30_AUTO_ON = "0x1E"
    CPUFANSPEEDHIGHBITS = "0x13"
    CPUFANSPEEDLOWBITS = "0x14"
    GPUFANSPEEDHIGHBITS = "0x15"
    GPUFANSPEEDLOWBITS = "0x16"
    CPUTEMP = "0xB0"
    GPUTEMP = "0xB6"
    SYSTEMP = "0xB3"
    POWERSTATUS = "0x00"
    POWERPLUGGEDIN = "0x01"
    POWERUNPLUGGED = "0x00"
    BATTERYCHARGELIMIT = "0x03"
    BATTERYLIMITON = "0x51"
    BATTERYLIMITOFF = "0x11"
    BATTERYSTATUS = "0xC1"
    BATTERYPLUGGEDINANDCHARGING = "0x02"
    BATTERYDRAINING = "0x01"
    BATTERYOFF = "0x00"
    POWEROFFUSBCHARGING = "0x08"
    USBCHARGINGON = "0x0F"
    USBCHARGINGOFF = "0x1F"
    NITROMODE = "0x2C"
    QUIETMODE = "0x00"
    DEFAULTMODE = "0x01"
    EXTREMEMODE = "0x04"


class ECS_AN515_44(enum.Enum):
    GPU_FAN_MODE_CONTROL = "0x21"
    GPU_AUTO_MODE = "0x10"
    GPU_TURBO_MODE = "0x20"
    GPU_MANUAL_MODE = "0x30"
    GPU_MANUAL_SPEED_CONTROL = "0x3A"
    CPU_FAN_MODE_CONTROL = "0x22"
    CPU_AUTO_MODE = "0x04"
    CPU_TURBO_MODE = "0x08"
    CPU_MANUAL_MODE = "0x0C"
    CPU_MANUAL_SPEED_CONTROL = "0x37"
    KB_30_SEC_AUTO = "0x06"
    KB_30_AUTO_OFF = "0x00"
    KB_30_AUTO_ON = "0x1E"
    CPUFANSPEEDHIGHBITS = "0x13"
    CPUFANSPEEDLOWBITS = "0x14"
    GPUFANSPEEDHIGHBITS = "0x15"
    GPUFANSPEEDLOWBITS = "0x16"
    CPUTEMP = "0xB0"
    GPUTEMP = "0xB4"
    SYSTEMP = "0xB0"
    POWERSTATUS = "0x00"
    POWERPLUGGEDIN = "0x01"
    POWERUNPLUGGED = "0x00"
    BATTERYCHARGELIMIT = "0x03"
    BATTERYLIMITON = "0x40"
    BATTERYLIMITOFF = "0x00"
    BATTERYSTATUS = "0xC1"
    BATTERYPLUGGEDINANDCHARGING = "0x02"
    BATTERYDRAINING = "0x01"
    BATTERYOFF = "0x00"
    POWEROFFUSBCHARGING = "0x08"
    USBCHARGINGON = "0x0F"
    USBCHARGINGOFF = "0x1F"
    NITROMODE = "0x2C"
    QUIETMODE = "0x00"
    DEFAULTMODE = "0x01"
    EXTREMEMODE = "0x04"


MODEL_TO_ECS = {
    "Nitro AN515-46": ECS_AN515_46,
    "Nitro AN515-54": ECS_AN515_46,
    "Nitro AN515-56": ECS_AN515_46,
    "Nitro AN515-44": ECS_AN515_44,
    "Nitro AN515-57": ECS_AN515_46,
    "Nitro AN515-58": ECS_AN515_46,
    "Nitro AN517-55": ECS_AN515_46,
}

model = _get_model()
print(f"Detected running on: {model}")

cpu = _get_cpu_type().lower()
if "amd" in cpu:
    CPU_TYPE = "AMD"
elif "intel" in cpu:
    CPU_TYPE = "Intel"
else:
    CPU_TYPE = "Unknown"

ECS = MODEL_TO_ECS.get(model)
if ECS:
    print(f"Using registers for {model}")
else:
    print(f"Device '{model}' not supported!")
    sys.exit(1)
PYEOF

echo "Patch applied successfully."
echo "Run the app with: sudo -E python3 main.py"
```

---

## Manual Patch

If you prefer not to use the script, replace the contents of `core/device_regs.py` manually. The key change is replacing:

```python
from dmidecode import DMIDecode
...
model = DMIDecode().model()
cpu = DMIDecode().cpu_type().lower()
```

With:

```python
import subprocess

def _dmi_get(dmi_type, field):
    try:
        out = subprocess.check_output(["dmidecode", "-t", dmi_type], text=True)
        for line in out.splitlines():
            if field in line:
                return line.split(":", 1)[1].strip()
    except Exception:
        pass
    return ""

model = _dmi_get("system", "Product Name")
cpu = _dmi_get("processor", "Version").lower()
```

---

## Common Errors & Fixes

### `ModuleNotFoundError: No module named 'dmidecode'`

```bash
sudo apt install python3-dmidecode
```

---

### `ImportError: cannot import name 'DMIDecode' from 'dmidecode'`

This happens when the pip version of `dmidecode` is installed instead of the apt version. Fix:

```bash
sudo pip3 uninstall dmidecode --break-system-packages
sudo apt install python3-dmidecode
# Then apply the patch (Step 4)
```

---

### `ModuleNotFoundError: No module named 'PyQt6'`

```bash
sudo apt install python3-pyqt6 python3-pyqt6.qtcharts
```

---

### App launches but GPU/CPU readings show 0 or errors

Make sure the `acpi_ec` module is loaded:

```bash
sudo modprobe acpi_ec
sudo cat /dev/ec | head -c 5
```

If you get "Permission denied" or "No such file", redo Step 1.

---

### After switching Nitro modes, GPU power doesn't change

Restart the NVIDIA power daemon:

```bash
sudo systemctl restart nvidia-powerd
```

---

## Launching NitroSense

Every time you want to use it:

```bash
cd ~/acpi_ec/Linux-NitroSense
sudo -E python3 main.py
```

---

## Credits

- Original app: [Packss/Linux-NitroSense](https://github.com/Packss/Linux-NitroSense)
- acpi_ec kernel module: [musikid/acpi_ec](https://github.com/musikid/acpi_ec)
- This guide tested on **Pop!_OS 22.04** with an **Acer Nitro AN515** series laptop
