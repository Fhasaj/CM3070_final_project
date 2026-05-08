# Installation and Build Guide

This guide walks through installing all prerequisites and building the
`vehicle_tracker` binary from source. It covers **Linux (Ubuntu 22.04+)**
and **macOS (Homebrew)**. Windows is not officially supported but works
with minor adjustments under WSL2.

---

## Prerequisites overview

| Dependency | Version | Notes |
|------------|---------|-------|
| C++ compiler | GCC 11+ or Clang 14+ | Must support C++17 |
| CMake | 3.20+ | Build system |
| OpenCV | 4.8+ | **Must include the DNN module** |
| Eigen3 | 3.4+ | Used by the Kalman filter |
| yaml-cpp | 0.7+ | Configuration file parsing |
| Catch2 | 3.x | Unit tests only (optional) |

> **Important:** OpenCV must be compiled with the DNN module enabled.
> The package-manager versions (`apt install libopencv-dev`) usually include
> it, but verify before proceeding — see Step 2.

---

## Linux (Ubuntu 22.04 / 24.04)

### Step 1 — Install system dependencies

```bash
sudo apt update
sudo apt install -y \
    build-essential \
    cmake \
    git \
    pkg-config \
    libeigen3-dev \
    libyaml-cpp-dev \
    libcatch2-dev
```

### Step 2 — Install OpenCV with DNN support

```bash
sudo apt install -y libopencv-dev python3-opencv
```

Verify the DNN module is present:

```bash
python3 -c "import cv2; print(cv2.getBuildInformation())" | grep -A3 "DNN"
```

You should see `DNN: YES`. If not, follow the
[Building OpenCV from source](#building-opencv-from-source) section below.

### Step 3 — Clone and build

```bash
git clone https://github.com/<your-username>/vehicle-tracker.git
cd vehicle-tracker

cmake -B build \
  -DCMAKE_BUILD_TYPE=Release \
  -DBUILD_TESTS=ON

cmake --build build -j$(nproc)
```

### Step 4 — Download the YOLO model weights

```bash
./scripts/download_model.sh
```

This downloads `yolov8n.onnx` (~12 MB) into `data/models/`.

### Step 5 — Verify the build

```bash
# Run unit tests
cd build && ctest --output-on-failure && cd ..

# Smoke test on the included sample clip
./build/vehicle_tracker \
  --input data/samples/highway.mp4 \
  --display
```

A preview window should open showing detected and tracked vehicles.

---

## macOS (Homebrew)

```bash
# Install dependencies
brew install cmake eigen yaml-cpp catch2 opencv

# Clone and build
git clone https://github.com/<your-username>/vehicle-tracker.git
cd vehicle-tracker

cmake -B build \
  -DCMAKE_BUILD_TYPE=Release \
  -DOpenCV_DIR=$(brew --prefix opencv)/lib/cmake/opencv4

cmake --build build -j$(sysctl -n hw.logicalcpu)

# Download weights and verify
./scripts/download_model.sh
./build/vehicle_tracker --input data/samples/highway.mp4 --display
```

---

## Building OpenCV from source

Only needed if your system OpenCV does not include the DNN module.

```bash
# Install build dependencies
sudo apt install -y \
    libgtk-3-dev libpng-dev libjpeg-dev libtiff-dev \
    libavcodec-dev libavformat-dev libswscale-dev

# Clone OpenCV source
git clone --depth 1 --branch 4.9.0 \
    https://github.com/opencv/opencv.git

# Configure
cmake -B opencv/build opencv \
  -DCMAKE_BUILD_TYPE=Release \
  -DBUILD_opencv_dnn=ON \
  -DBUILD_TESTS=OFF \
  -DBUILD_EXAMPLES=OFF \
  -DWITH_CUDA=OFF

# Build and install
cmake --build opencv/build -j$(nproc)
sudo cmake --install opencv/build
```

Then rebuild this project pointing at your custom install:

```bash
cmake -B build \
  -DOpenCV_DIR=/usr/local/lib/cmake/opencv4 \
  -DCMAKE_BUILD_TYPE=Release
cmake --build build -j$(nproc)
```

---

## CMake options

| Option | Default | Description |
|--------|---------|-------------|
| `BUILD_TESTS` | `ON` | Build Catch2 unit tests |
| `ENABLE_DISPLAY` | `ON` | Enable OpenCV highgui window |
| `CMAKE_BUILD_TYPE` | `Release` | Use `Debug` for development |

---

## Common problems

**"Could not find OpenCV" during CMake**

Pass the path explicitly:

```bash
cmake -B build -DOpenCV_DIR=/path/to/opencv4/cmake
```

**"DNN module not available" at runtime**

Your OpenCV was compiled without DNN support. Follow the
[Building OpenCV from source](#building-opencv-from-source) section.

**Video opens but no detections appear**

1. Check `--conf 0.4` is not too high for your footage.
2. Confirm `data/models/yolov8n.onnx` exists.
3. Run `./scripts/download_model.sh` again if the file is missing or corrupt.

**Build fails on Eigen headers**

Install Eigen3: `sudo apt install libeigen3-dev` (Ubuntu) or
`brew install eigen` (macOS). Then delete the build directory and
re-run CMake from scratch.

---

## Next steps

- [README.md](README.md) — overview and usage
- [EVALUATION.md](EVALUATION.md) — reproducing benchmark results