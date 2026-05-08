# Data Directory

This directory holds video data used for development, testing, and evaluation.
It is **not fully tracked by git** — large dataset files are excluded via
`.gitignore`. Only the small sample clips in `samples/` are committed.

---

## Directory structure

```
data/
├── README.md             ← this file
├── models/               ← YOLO model weights (downloaded by script, not git-tracked)
│   └── yolov8n.onnx
├── samples/              ← small clips for quick testing (git-tracked)
│   ├── highway.mp4       ← 30s highway clip, 1080p
│   └── junction.mp4      ← 30s urban junction clip, 720p
└── ua-detrac/            ← UA-DETRAC benchmark (download separately, not git-tracked)
    ├── Insight-MVT_Annotation_Train/
    └── DETRAC-Train-Annotations-XML/
```

---

## Downloading the YOLO model weights

Run the download script from the project root:

```bash
./scripts/download_model.sh
```

This fetches `yolov8n.onnx` (~12 MB) from the official Ultralytics release
and places it at `data/models/yolov8n.onnx`.

YOLOv8n is the nano variant — smallest and fastest, suitable for edge-device
deployment. For higher accuracy at the cost of speed, edit `download_model.sh`
to fetch `yolov8s.onnx` (small) instead.

---

## Downloading UA-DETRAC (for evaluation only)

UA-DETRAC is only required to reproduce the evaluation results from the
project report. It is not needed to run the tracker on your own footage.

1. Register at [https://detrac-db.rit.albany.edu/](https://detrac-db.rit.albany.edu/)
2. Download `DETRAC-train-data.zip` and `DETRAC-Train-Annotations-XML.zip`
3. Unzip both into `data/ua-detrac/`

See [EVALUATION.md](../EVALUATION.md) for the full evaluation walkthrough.

---

## Using your own video

The tracker accepts any video file OpenCV can open (MP4, AVI, MKV, etc.)
or a directory of JPEG frames sorted alphanumerically:

```bash
./build/vehicle_tracker \
  --input /path/to/your/video.mp4 \
  --display
```

For best results, use footage from a static camera with a clear view of the
road. Very wide-angle lenses, heavily compressed streams, or footage where
vehicles are small relative to the frame will reduce detection accuracy.

---

## Licence note

Sample clips in `samples/` were recorded by the project author and are
released under the same MIT licence as the project code.

UA-DETRAC is a publicly available research dataset subject to its own terms.
If you use it in any publication, cite:

> Wen, L., Du, D., Cai, Z., Lei, Z., Chang, M-C., Qi, H., Lim, J.,
> Yang, M-H., & Lyu, S. (2020). UA-DETRAC: A new benchmark and protocol
> for multi-object detection and tracking. *Computer Vision and Image
> Understanding*, 193, 102907.