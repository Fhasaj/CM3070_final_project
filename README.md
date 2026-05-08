# Vehicle Detection, Tracking and Counting

A real-time C++ pipeline for detecting, tracking, and counting vehicles in
traffic camera footage. Built as a final-year project for **CM3065 Intelligent
Signal Processing** at the University of London (BSc Computer Science).

> **Status:** Work in progress. See [project roadmap](#roadmap) for current state.

---

## What it does

This system takes a traffic camera video (file or live stream) and produces,
in real time:

- Annotated video with bounding boxes and persistent ID numbers per vehicle
- Per-class vehicle counts (car / truck / bus / motorbike)
- Directional counts when vehicles cross a virtual line in the scene
- A structured CSV log of vehicles passing per minute

It is designed to run on a resource-constrained edge device — a standard
laptop CPU, Raspberry Pi 5, or Jetson Nano — without requiring a discrete GPU.

### Pipeline overview

```
┌──────────────┐   ┌──────────────────┐   ┌──────────────────┐   ┌─────────────┐
│  Video in    │ → │   Detection       │ → │    Tracking      │ → │  Counting   │
│ (file/cam)   │   │ YOLOv8 via       │   │ SORT (Kalman +   │   │ Virtual-    │
│              │   │ OpenCV DNN / C++ │   │ Hungarian algo)  │   │ line cross  │
└──────────────┘   └──────────────────┘   └──────────────────┘   └─────────────┘
                                                                         │
                                                                         ▼
                                                              ┌──────────────────┐
                                                              │ Annotated video  │
                                                              │ + CSV count log  │
                                                              │ + per-frame JSON │
                                                              └──────────────────┘
```

---

## Motivation

Cities have deployed CCTV traffic cameras at scale, but manual monitoring
does not scale. Existing automated solutions fall into two camps:

- **Closed-source commercial products** (e.g. VivaCity Labs, Siemens MAS) —
  accurate and deployed, but opaque and expensive for smaller authorities.
- **Python / GPU open-source stacks** (e.g. Ultralytics YOLOv8 + ByteTrack)
  — capable, but assume a beefy GPU and are not genuinely edge-deployable
  without significant re-engineering.

This project sits in the gap: an **open, transparent, C++ implementation**
evaluated on a public benchmark, with the algorithmic internals (Kalman
filter, Hungarian algorithm) fully documented rather than hidden behind a
library API.

For the full literature review, see the project report (submitted separately).

---

## Quick start

```bash
# 1. Clone the repository
git clone https://github.com/Fhasaj/CM3070_final_project.git
cd CM3070_final_project

# 2. Install prerequisites and build (full instructions in INSTALL.md)
cmake -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build -j

# 3. Download pre-trained YOLO weights (one-off, ~12 MB)
./scripts/download_model.sh

# 4. Run on a sample clip
./build/vehicle_tracker \
  --input data/samples/highway.mp4 \
  --output out.mp4 \
  --display
```

For full setup instructions including OpenCV + DNN dependencies, see
[INSTALL.md](INSTALL.md).

For reproducing the evaluation results from the project report, see
[EVALUATION.md](EVALUATION.md).

---

## Usage

```
vehicle_tracker [options]

  --input   <path>          Video file path, or 0 for default webcam
  --output  <path>          Annotated output video path (optional)
  --line    <x1,y1,x2,y2>  Virtual counting line in pixel coordinates
  --classes <ids>           Comma-separated COCO class IDs to track
                            Default: 2,3,5,7  (car, motorbike, bus, truck)
  --conf    <float>         Detection confidence threshold (default: 0.4)
  --iou     <float>         NMS IoU threshold (default: 0.45)
  --log     <path>          Write per-minute counts to CSV file
  --display                 Show live annotated preview window
  --help                    Print this message and exit
```

### Examples

Run on a recorded clip with a counting line and CSV output:

```bash
./build/vehicle_tracker \
  --input  data/samples/highway.mp4 \
  --output out.mp4 \
  --line   100,540,1820,540 \
  --log    counts.csv
```

Run live from a webcam with preview:

```bash
./build/vehicle_tracker --input 0 --display
```

---

## Repository layout

```
vehicle-tracker/
├── README.md              ← you are here
├── INSTALL.md             ← build prerequisites and step-by-step setup
├── EVALUATION.md          ← reproducing benchmark results
├── LICENSE                ← MIT
├── CMakeLists.txt
│
├── src/
│   ├── main.cpp           ← entry point and CLI argument parsing
│   ├── detector.cpp       ← YOLOv8 inference via OpenCV DNN
│   ├── tracker.cpp        ← SORT: Kalman filter + Hungarian algorithm
│   ├── counter.cpp        ← virtual-line crossing and per-class counts
│   └── io.cpp             ← video I/O, annotation drawing, CSV logging
│
├── include/               ← corresponding headers
│
├── tests/                 ← unit tests (Catch2)
│   ├── test_tracker.cpp   ← Kalman filter and assignment correctness
│   ├── test_counter.cpp   ← line-crossing geometry
│   └── test_detector.cpp  ← detection pipeline smoke tests
│
├── scripts/
│   ├── download_model.sh  ← fetches YOLOv8n ONNX weights
│   └── evaluate.py        ← evaluation harness for UA-DETRAC benchmark
│
├── data/
│   ├── samples/           ← small clips for quick testing (git-tracked)
│   └── README.md          ← instructions for placing benchmark datasets
│
└── docs/
    ├── report.pdf         ← full project report (submitted separately)
    └── images/            ← diagrams used in report and README
```

---

## Algorithms

### Detection

Pre-trained YOLOv8n model (COCO) loaded via **OpenCV's DNN module in C++**.
Detections are filtered to vehicle classes only (car=2, motorbike=3, bus=5,
truck=7) and passed through non-maximum suppression before being forwarded
to the tracker.

### Tracking — SORT

A custom C++ implementation of **SORT** (Bewley et al., ICIP 2016).
Each frame, three steps run in order:

1. **Predict** — a constant-velocity Kalman filter rolls each existing track
   forward to estimate its current position.
2. **Associate** — the Hungarian algorithm matches incoming YOLO detections
   to predicted tracks, using Intersection-over-Union as the assignment cost.
3. **Update / manage** — matched tracks update their Kalman state; unmatched
   detections spawn new tracks; tracks unmatched for 3 consecutive frames are
   deleted.

### Counting

Each track maintains a "last known side" relative to a user-defined virtual
line. When the centroid's side flips between consecutive frames, the counter
for the appropriate direction and vehicle class is incremented.

For full mathematical detail and design decisions, see the project report.

---

## Roadmap

- [x] Project scoping and concept pitch
- [x] Literature review
- [x] Repository and documentation structure
- [ ] OpenCV + DNN build verified end-to-end
- [ ] Detection layer: YOLO inference in C++ with class filtering
- [ ] Minimum viable tracker: IoU-only matching
- [ ] Full SORT: Kalman filter + Hungarian algorithm
- [ ] Virtual-line counting layer
- [ ] CSV logging and structured JSON output
- [ ] Unit tests for tracker and counter
- [ ] Evaluation harness against UA-DETRAC ground truth
- [ ] Optional: Flutter dashboard frontend

---

## Key references

- **SORT** — Bewley et al. (2016). *Simple Online and Realtime Tracking.* ICIP.
  [arXiv:1602.00763](https://arxiv.org/abs/1602.00763)
- **DeepSORT** — Wojke et al. (2017). *SORT with a Deep Association Metric.* ICIP.
  [arXiv:1703.07402](https://arxiv.org/abs/1703.07402)
- **UA-DETRAC** — Wen et al. (2020). *A new benchmark and protocol for
  multi-object detection and tracking.* CVIU.
- **CLEAR MOT metrics** — Bernardin & Stiefelhagen (2008). EURASIP JIVP.

Full bibliography in the project report.

---

## Licence

Source code: **MIT** — see [LICENSE](LICENSE).

Pre-trained YOLOv8 weights are distributed by Ultralytics under **AGPL-3.0**.
They are fetched at build time by `scripts/download_model.sh` and are not
redistributed in this repository.

---

## Author

Final-year project, BSc Computer Science — University of London.
For assessment queries please use the university submission system.