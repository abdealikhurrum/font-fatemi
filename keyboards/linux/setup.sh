#!/usr/bin/env bash
# Install the LSD IBus engine system-wide.
# Requires: sudo, python3, python3-gi, gir1.2-ibus-1.0

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

INSTALL_DIR=/usr/lib/ibus-lsd
COMPONENT_DIR=/usr/share/ibus/component
ICON_DIR=/usr/share/ibus-lsd

echo "Installing LSD IBus engine..."

# Install the Python package and launcher
sudo install -d "$INSTALL_DIR"
sudo cp -r "$SCRIPT_DIR/lsd_ibus" "$INSTALL_DIR/"
sudo install -m 755 "$SCRIPT_DIR/ibus-engine-lsd" "$INSTALL_DIR/ibus-engine-lsd"

# Register the IBus component
sudo install -d "$COMPONENT_DIR"
sudo install -m 644 "$SCRIPT_DIR/lsd.xml" "$COMPONENT_DIR/lsd.xml"

# Install icon from branding directory
sudo install -d "$ICON_DIR"
ICON="$SCRIPT_DIR/../../branding/lsd-icon.svg"
if [ -f "$ICON" ]; then
    sudo install -m 644 "$ICON" "$ICON_DIR/lsd-icon.svg"
fi

# Restart IBus to pick up the new component
ibus restart 2>/dev/null || true

echo ""
echo "Done. Next steps:"
echo "  1. Log out and back in, or run:  ibus restart"
echo "  2. Open IBus Preferences → Input Method → Add"
echo "  3. Search for 'Lisan ud Dawat' and add it."
