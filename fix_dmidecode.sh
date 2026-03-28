#!/bin/bash
# fix_dmidecode.sh
# Fixes the ImportError: cannot import name 'DMIDecode' from 'dmidecode'
# by replacing the Python dmidecode library calls with subprocess calls
# to the system dmidecode binary.
#
# Usage: sudo bash fix_dmidecode.sh
# Run from inside the Linux-NitroSense directory.

TARGET="core/device_regs.py"

if [ ! -f "$TARGET" ]; then
    echo "Error: $TARGET not found."
    echo "Please run this script from inside the Linux-NitroSense directory."
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

echo ""
echo "✅ Patch applied successfully to $TARGET"
echo ""
echo "Now run the app with:"
echo "  sudo -E python3 main.py"
