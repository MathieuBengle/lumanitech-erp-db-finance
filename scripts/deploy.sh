#!/bin/bash
# =============================================================================
# Script: deploy.sh
# Description: Deploy Finance database - wrapper around setup.sh
# Usage: ./deploy.sh [OPTIONS]
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Call setup.sh with all arguments
exec "$SCRIPT_DIR/setup.sh" "$@"
