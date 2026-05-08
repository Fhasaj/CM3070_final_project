#!/usr/bin/env bash
# =============================================================================
# download_model.sh
# Downloads the YOLOv8n ONNX model weights into data/models/
# Run from the project root: ./scripts/download_model.sh
# =============================================================================

set -euo pipefail

# --- Config ------------------------------------------------------------------
MODEL_NAME="yolov8n.onnx"
MODEL_DIR="data/models"
MODEL_PATH="${MODEL_DIR}/${MODEL_NAME}"

# Direct ONNX download — no Python required
DIRECT_ONNX_URL="https://github.com/ultralytics/assets/releases/download/v8.1.0/yolov8n.onnx"

# --- Helpers -----------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

# --- Preflight ---------------------------------------------------------------
# Must be run from project root
if [[ ! -f "CMakeLists.txt" ]]; then
    error "Run this script from the project root directory."
    error "Example: ./scripts/download_model.sh"
    exit 1
fi

# Create model directory
mkdir -p "${MODEL_DIR}"

# Already downloaded?
if [[ -f "${MODEL_PATH}" ]]; then
    info "Model already exists at ${MODEL_PATH} — nothing to do."
    info "Delete the file and re-run to force a fresh download."
    exit 0
fi

# --- Check downloader --------------------------------------------------------
if command -v curl &>/dev/null; then
    DOWNLOADER="curl"
elif command -v wget &>/dev/null; then
    DOWNLOADER="wget"
else
    error "Neither curl nor wget found. Install one and try again."
    error "  Ubuntu:  sudo apt install curl"
    error "  macOS:   brew install curl"
    exit 1
fi

# --- Attempt 1: direct ONNX download -----------------------------------------
info "Downloading YOLOv8n ONNX weights (~12 MB)..."
info "Source:      ${DIRECT_ONNX_URL}"
info "Destination: ${MODEL_PATH}"
echo ""

download_success=false

if [[ "${DOWNLOADER}" == "curl" ]]; then
    if curl -fL --progress-bar "${DIRECT_ONNX_URL}" -o "${MODEL_PATH}"; then
        download_success=true
    fi
else
    if wget --show-progress -q "${DIRECT_ONNX_URL}" -O "${MODEL_PATH}"; then
        download_success=true
    fi
fi

# --- Attempt 2: export via ultralytics Python package ------------------------
if [[ "${download_success}" == false ]]; then
    warn "Direct download failed. Falling back to ultralytics Python export..."
    echo ""

    if ! command -v python3 &>/dev/null; then
        error "python3 not found. Cannot use fallback export."
        error "Try downloading the model manually from:"
        error "  ${DIRECT_ONNX_URL}"
        error "and place it at: ${MODEL_PATH}"
        rm -f "${MODEL_PATH}"
        exit 1
    fi

    if ! python3 -c "import ultralytics" &>/dev/null; then
        info "Installing ultralytics Python package..."
        pip3 install ultralytics --quiet
    fi

    info "Exporting YOLOv8n → ONNX via ultralytics..."
    python3 - <<'PYEOF'
from ultralytics import YOLO
import shutil, os, sys

try:
    model = YOLO("yolov8n.pt")   # downloads .pt weights if not cached
    model.export(format="onnx")  # writes yolov8n.onnx in cwd

    src = "yolov8n.onnx"
    dst = "data/models/yolov8n.onnx"
    os.makedirs("data/models", exist_ok=True)
    shutil.move(src, dst)
    print(f"Moved {src} -> {dst}")

    # Clean up .pt — not needed at runtime
    for f in ["yolov8n.pt"]:
        if os.path.exists(f):
            os.remove(f)
except Exception as e:
    print(f"Export failed: {e}", file=sys.stderr)
    sys.exit(1)
PYEOF

    if [[ -f "${MODEL_PATH}" ]]; then
        download_success=true
    fi
fi

# --- Verify ------------------------------------------------------------------
if [[ "${download_success}" == false ]] || [[ ! -f "${MODEL_PATH}" ]]; then
    error "Download failed — model file was not created."
    error "Try manually downloading from:"
    error "  ${DIRECT_ONNX_URL}"
    error "and placing it at: ${MODEL_PATH}"
    exit 1
fi

# Basic size check — YOLOv8n ONNX should be at least 10 MB
FILE_BYTES=$(wc -c < "${MODEL_PATH}")
if [[ "${FILE_BYTES}" -lt 10000000 ]]; then
    warn "File size looks small (${FILE_BYTES} bytes). The file may be corrupt."
    warn "Delete ${MODEL_PATH} and run this script again."
fi

FILE_SIZE=$(du -sh "${MODEL_PATH}" | cut -f1)

echo ""
info "Download complete."
info "  File : ${MODEL_PATH}"
info "  Size : ${FILE_SIZE}"
echo ""
info "You can now run the tracker:"
info "  ./build/vehicle_tracker --input data/samples/highway.mp4 --display"