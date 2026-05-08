# Evaluation Guide

This document explains how to reproduce the evaluation results reported in
the project report. It covers dataset download, directory setup, running the
evaluation harness, and interpreting the output metrics.

---

## Metrics reported

| Metric | Description |
|--------|-------------|
| **Count accuracy (%)** | `1 - |predicted - ground_truth| / ground_truth` |
| **MOTA** | Multiple Object Tracking Accuracy — accounts for false positives, false negatives, and ID switches |
| **MOTP** | Multiple Object Tracking Precision — mean localisation accuracy of matched tracks |
| **IDF1** | ID F1 score — measures track identity consistency over time |
| **ID switches / min** | Average rate of tracker assigning a new ID to an already-tracked vehicle |

Count accuracy is the headline figure for the project's core goal.
MOTA / MOTP / IDF1 provide standard MOT context for examiners familiar
with the field.

---

## Step 1 — Download UA-DETRAC

1. Register at [https://detrac-db.rit.albany.edu/](https://detrac-db.rit.albany.edu/)
   (free; download link arrives by email, usually within 24 hours — **do this
   in week 1 of the project, not week 10**).

2. Download:
    - `DETRAC-train-data.zip` (~1.5 GB) — video frames as JPEG sequences
    - `DETRAC-Train-Annotations-XML.zip` — ground-truth bounding boxes

3. Unzip into `data/ua-detrac/`:

```
data/ua-detrac/
├── Insight-MVT_Annotation_Train/
│   ├── MVI_20011/
│   │   ├── img00001.jpg
│   │   ├── img00002.jpg
│   │   └── ...
│   └── MVI_20012/ ...
└── DETRAC-Train-Annotations-XML/
    ├── MVI_20011.xml
    ├── MVI_20012.xml
    └── ...
```

---

## Step 2 — Evaluation sequences

The project report evaluates on **6 sequences** chosen to cover
a range of conditions present in the dataset:

| Sequence | Scene | Weather | Vehicle density |
|----------|-------|---------|-----------------|
| MVI_20011 | Intersection | Cloudy | Medium |
| MVI_20032 | Highway | Sunny | High |
| MVI_20034 | Highway | Sunny | High |
| MVI_39031 | Urban junction | Night | Low |
| MVI_39051 | Urban junction | Rainy | Medium |
| MVI_63562 | Overpass | Cloudy | High |

These same sequences must be used to reproduce the reported figures.

---

## Step 3 — Run the evaluation harness

```bash
python3 scripts/evaluate.py \
  --sequences MVI_20011 MVI_20032 MVI_20034 MVI_39031 MVI_39051 MVI_63562 \
  --data-dir  data/ua-detrac \
  --tracker   ./build/vehicle_tracker \
  --output    results/
```

Options:

```
  --sequences <list>    Space-separated sequence names
  --data-dir  <path>    Root of the ua-detrac directory
  --tracker   <path>    Path to the compiled vehicle_tracker binary
  --conf      <float>   Detection confidence threshold (default: 0.4)
  --output    <path>    Directory for per-sequence results and summary
  --no-display          Suppress preview windows during evaluation
```

The script produces:

```
results/
├── MVI_20011/
│   ├── tracked_output.avi   ← annotated video
│   ├── counts.csv           ← per-minute vehicle counts
│   └── metrics.json         ← MOTA, MOTP, IDF1 for this sequence
├── MVI_20032/ ...
└── summary.csv              ← all metrics averaged across sequences
```

---

## Step 4 — Interpreting the output

`summary.csv` has one row per sequence and a final average row.
The figures in the project report correspond to the **AVERAGE** row:

```
sequence,   count_acc,  mota,   motp,   idf1,   id_sw_pm
MVI_20011,  94.2,       0.612,  0.731,  0.681,  2.1
MVI_20032,  91.7,       0.589,  0.718,  0.654,  3.4
...
AVERAGE,    92.8,       0.601,  0.725,  0.668,  2.8
```

---

## Metric definitions

**Count accuracy**

```
accuracy = 1 - ( |predicted_count - ground_truth_count| / ground_truth_count )
```

Ground-truth count = number of unique vehicle IDs in the annotation XML.
The evaluation script computes this automatically.

**MOTA and MOTP**

Defined in Bernardin & Stiefelhagen (2008), EURASIP JIVP. Computed from
per-frame bounding-box output vs annotation XML using the CLEAR MOT equations.

**IDF1**

Defined in Ristani et al. (2016), ECCV Workshop on Benchmarking Multi-Target
Tracking. Measures how consistently each ground-truth identity is covered by
a single predicted track over time.

---

## Baseline comparison

The project report compares results against the open-source SORT reference
implementation (`github.com/abewley/sort`) run on the same sequences under
identical conditions — same YOLOv8n detections, only the tracking algorithm
differs.

To run the baseline:

```bash
pip install filterpy scipy numpy
python3 scripts/run_sort_baseline.py \
  --sequences MVI_20011 MVI_20032 MVI_20034 MVI_39031 MVI_39051 MVI_63562 \
  --data-dir  data/ua-detrac \
  --output    results/baseline/
```

---

## Hardware used

All results in the project report were produced on:

- **CPU:** Intel Core i7, 11th gen (no discrete GPU)
- **RAM:** 16 GB
- **OS:** Ubuntu 22.04
- **OpenCV:** 4.9.0
- **Compiler:** GCC 11.4

Throughput (frames per second) will vary on different hardware.
All accuracy metrics are hardware-independent.

---

## Running a single sequence manually

```bash
./build/vehicle_tracker \
  --input  data/ua-detrac/Insight-MVT_Annotation_Train/MVI_20011/ \
  --output results/MVI_20011/tracked_output.avi \
  --log    results/MVI_20011/counts.csv \
  --display
```

`--input` accepts a directory of JPEG frames (sorted alphanumerically)
as well as video files.

---

## Troubleshooting

**"Tracker binary not found"**
Build the project first — see [INSTALL.md](INSTALL.md).

**All counts are 0**
The default counting line sits at the horizontal midpoint of the frame.
For some sequences vehicles may not cross this line. Pass `--line` with
coordinates appropriate to the scene, or let the evaluation script choose
automatically (default behaviour when `--line` is omitted).

**MOTA is negative**
Negative MOTA is valid — it means false positives and ID switches outweigh
true positives. This typically happens at low confidence thresholds.
Try `--conf 0.5` to reduce false detections.