#!/usr/bin/env python3
"""
resize_figures_300dpi.py
Resample all figure PNGs to exact 300 DPI at their intended NHB panel dimensions.

Run after generate_all_figures.m:
    python3 resize_figures_300dpi.py

MATLAB's exportgraphics produces the correct DPI metadata (300 dpi) but the
physical size is slightly off (~79mm instead of 88mm) because plotting functions
resize the figure window in headless mode. This script corrects that by resampling
each panel to the exact pixel count implied by 300 DPI × the target NHB width.
"""

from PIL import Image
import os, sys

DPI = 300
MM_TO_PX = DPI / 25.4  # pixels per mm at 300 DPI

# Target dimensions (mm): {filename_stem: (width_mm, height_mm)}
TARGET_MM = {
    "Fig2a_performance_boxplot":      (88,  90),
    "Fig2b_switch_histogram":         (88,  80),
    "Fig2c_FB_by_switch":             (120, 90),
    "Fig2d_noFB_by_switch":           (120, 90),
    "Fig2e_LME_noFB_bar":             (88,  95),
    "Fig3b_scree_plot":               (88,  80),
    "Fig3c_factor_correlations":      (88,  80),
    "Fig4a_OC_vs_initial_perf":       (88,  88),
    "Fig4b_OC_vs_MC_reps":            (88,  88),
    "Fig5a_OC_vs_switches":           (88,  88),
    "Fig5b_FB_prepost_MB":            (88,  88),
    "Fig5c_OC_vs_FB_MBt1":           (88,  88),
    "Fig5de_GLMM_abPE_bar":           (88,  95),
    "Fig6a_interaction_noFB_MBsinceSW": (120, 90),
    "Fig6b_noFB_prepost_MB":          (88,  88),
    "Fig6c_OC_vs_noFB_MBt1":         (88,  88),
    "Fig6e_GLMM_sPE_bar":             (88,  95),
    "Fig6f_GLMM_sPE_change_bar":      (88,  95),
    "SuppFig1b_GLMM_abPE_allMBs":    (88,  95),
    "SuppFig1c_switch_win_loss":      (88, 160),
    "Fig3a_factor_loadings_heatmap":  (120, 130),
}

figures_dir = os.path.join(os.path.dirname(__file__), "figures")

print(f"Resampling figures to 300 DPI in: {figures_dir}\n")
any_error = False

for stem, (w_mm, h_mm) in sorted(TARGET_MM.items()):
    path = os.path.join(figures_dir, f"{stem}.png")
    if not os.path.exists(path):
        print(f"  SKIP (not found): {stem}.png")
        continue

    target_w = round(w_mm * MM_TO_PX)
    target_h = round(h_mm * MM_TO_PX)

    img = Image.open(path)
    orig_w, orig_h = img.size
    orig_dpi_x = img.info.get("dpi", (DPI, DPI))[0]

    if orig_w == target_w and orig_h == target_h:
        print(f"  OK   {stem}.png  {orig_w}x{orig_h}px  ({w_mm}x{h_mm}mm @ {DPI}dpi)")
        continue

    # Resample with LANCZOS (best quality for downscale; fine for <15% upscale)
    img_rgb = img.convert("RGBA") if img.mode == "RGBA" else img.convert("RGB")
    img_resized = img_rgb.resize((target_w, target_h), Image.LANCZOS)

    # Save with correct DPI metadata
    img_resized.save(path, dpi=(DPI, DPI))
    print(f"  FIX  {stem}.png  {orig_w}x{orig_h} → {target_w}x{target_h}px  "
          f"({w_mm}x{h_mm}mm @ {DPI}dpi)")

if not any_error:
    print(f"\nDone. All figures at 300 DPI in {figures_dir}/")
