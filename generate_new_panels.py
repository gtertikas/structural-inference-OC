"""
generate_new_panels.py – v2
Generates revised panels and reassembles all 5 compound figures.

Changes from v1:
  - Fig 1: symmetric layout, panel e larger, uniform 8 pt font
  - Fig 3: schematics (3a performance curve, 3b comprehension Qs) from original draft
  - Fig 4b: boxplot + histogram style with structural-change marker
  - Fig 4d: GLMM bar chart + associative-belief schematic (cropped from draft)
  - Fig 5a: interaction plot (already present, confirmed)
  - Fig 5d: sPE trial-structure schematic (cropped from draft)
  - Fig 5e: significance stars on correct bars
  - Fig 5f: 2-bar version (s-PE_changed, OC×s-PE_changed)
  - All bar colours: warm tan for PE/intercept, green for OC terms (match MATLAB)
"""

import os, warnings, pickle
import numpy as np
import pandas as pd
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import matplotlib.gridspec as gridspec
import matplotlib.patches as mpatches
import matplotlib.image as mpimg
from matplotlib.patches import FancyArrowPatch, FancyBboxPatch
from scipy.stats import ttest_1samp
from factor_analyzer import FactorAnalyzer
import scipy.io
import statsmodels.formula.api as smf

warnings.filterwarnings('ignore')

# ── paths ────────────────────────────────────────────────────────────────────
BASE_DIR = '/Users/georgetertikas/Documents/Nadescha_code'
FIG_DIR  = os.path.join(BASE_DIR, 'figures')
OUT_DIR  = os.path.join(FIG_DIR,  'compound')
PAN_DIR  = os.path.join(OUT_DIR,  'panels')
os.makedirs(PAN_DIR, exist_ok=True)

MM2IN = 1 / 25.4
FS    = 8          # uniform font size throughout

# ── colours (match MATLAB originals) ─────────────────────────────────────────
COL_FB   = np.array([0.20, 0.60, 0.80])   # blue
COL_NOFB = np.array([0.85, 0.40, 0.15])   # orange
COL_GEN  = np.array([0.70, 0.52, 0.26])   # warm tan  (PE / intercept bars)
COL_OC   = np.array([0.05, 0.55, 0.18])   # green     (OC-related bars)

plt.rcParams.update({
    'font.family'       : 'Arial',
    'font.size'         : FS,
    'axes.linewidth'    : 0.75,
    'xtick.major.width' : 0.75,
    'ytick.major.width' : 0.75,
    'xtick.major.size'  : 3,
    'ytick.major.size'  : 3,
})

# ── helpers ───────────────────────────────────────────────────────────────────
def nhb(ax, fs=FS):
    ax.spines['top'].set_visible(False)
    ax.spines['right'].set_visible(False)
    for sp in ['left', 'bottom']:
        ax.spines[sp].set_linewidth(0.75)
    ax.tick_params(direction='out', labelsize=fs, width=0.75, length=3)
    ax.xaxis.label.set_fontsize(fs)
    ax.yaxis.label.set_fontsize(fs)

def plabel(ax, letter, x=-0.14, y=1.10):
    ax.text(x, y, letter, transform=ax.transAxes,
            fontsize=11, fontweight='bold', va='top', ha='left',
            fontfamily='Arial')

def nanSE(x):
    x = np.asarray(x, float)
    return np.nanstd(x, ddof=1) / np.sqrt(np.sum(~np.isnan(x)))

def savepanel(name):
    path = os.path.join(PAN_DIR, f'{name}.png')
    plt.savefig(path, dpi=300, bbox_inches='tight', facecolor='white')
    plt.close()
    print(f'  panel: {name}.png')
    return path

def savecompound(name):
    for ext in ('png', 'pdf'):
        path = os.path.join(OUT_DIR, f'{name}.{ext}')
        plt.savefig(path, dpi=300, bbox_inches='tight', facecolor='white')
    plt.close()
    print(f'  compound: {name}.png / .pdf')

def load_img(fname, crop_cols=None):
    data = mpimg.imread(os.path.join(FIG_DIR, fname))
    if crop_cols is not None:
        data = data[:, crop_cols[0]:crop_cols[1], :]
    return data

def pimg(fname):
    return mpimg.imread(os.path.join(PAN_DIR, f'{fname}.png'))

def oimg(fname, crop_cols=None):
    data = mpimg.imread(os.path.join(FIG_DIR, f'{fname}.png'))
    if crop_cols:
        data = data[:, crop_cols[0]:crop_cols[1], :]
    return data

def show(ax, image):
    ax.imshow(image, interpolation='lanczos')
    ax.axis('off')


# ── load behavioural data (N=313, exported from MATLAB) ──────────────────────
print('Loading behavioural data (N=313)...')

all_perf_sub  = np.loadtxt(os.path.join(BASE_DIR, 'FBsub_export.csv'),    delimiter=',')
fb3_all       = np.loadtxt(os.path.join(BASE_DIR, 'FB_sub_export.csv'),   delimiter=',')
nofb3_all     = np.loadtxt(os.path.join(BASE_DIR, 'noFB_sub_export.csv'), delimiter=',')
swNr_all      = np.loadtxt(os.path.join(BASE_DIR, 'swNr_export.csv'),     delimiter=',')
FBperf_only   = np.loadtxt(os.path.join(BASE_DIR, 'FBperf_export.csv'),   delimiter=',')
noFBperf_only = np.loadtxt(os.path.join(BASE_DIR, 'noFBperf_export.csv'), delimiter=',')

# N=111 used only for by-switch breakdown (Fig1c/1d Python panels);
# compound figure uses MATLAB originals for those panels anyway.
d   = scipy.io.loadmat(os.path.join(BASE_DIR, 'dataN111.mat'),
                        squeeze_me=True, struct_as_record=False)
s   = d['s']
fb_by_sw   = {i: [] for i in range(1, 7)}
nofb_by_sw = {i: [] for i in range(1, 7)}

for isub in range(len(s.sub)):
    ph6  = s.sub[isub].phase[5]
    pmat = ph6.opt.pmat
    df   = pd.DataFrame(pmat.mat, columns=list(pmat.names))
    perf = df['FB_optchoice'].values.copy(); perf[perf == -1] = 0
    sidx = df['stimidx'].values
    sw   = df['trueSwitch'].values

    sw_positions = np.where(sw == 1)[0]
    for sw_i, sw_pos in enumerate(sw_positions):
        sw_num = sw_i + 1
        if sw_num > 6: continue
        end = sw_positions[sw_i+1] if sw_i+1 < len(sw_positions) else len(perf)
        sp, si = perf[sw_pos:end], sidx[sw_pos:end]
        if (si==1).any(): fb_by_sw[sw_num].append(sp[si==1].mean())
        if (si==0).any(): nofb_by_sw[sw_num].append(sp[si==0].mean())

print(f'  N={len(all_perf_sub)} subjects loaded (from MATLAB export)')


# ════════════════════════════════════════════════════════════════════════════════
# FIG 1a – Single "all trials" performance boxplot
# ════════════════════════════════════════════════════════════════════════════════
print('\nGenerating Fig1a...')
FS_A = 11  # match apparent MATLAB font size in compound
fig, ax = plt.subplots(figsize=(45*MM2IN, 72*MM2IN))
bp = ax.boxplot([all_perf_sub], patch_artist=True, widths=0.5,
                medianprops=dict(color='red', linewidth=1.5),
                whiskerprops=dict(linewidth=0.75),
                capprops=dict(linewidth=0.75),
                flierprops=dict(marker='o', markersize=2.5,
                                markerfacecolor='none', markeredgewidth=0.5))
bp['boxes'][0].set_facecolor('white'); bp['boxes'][0].set_linewidth(0.75)
ax.axhline(0.5, color='k', linestyle='--', linewidth=0.75)
ax.set_xticks([1]); ax.set_xticklabels(['all trials'], fontsize=FS_A)
ax.set_ylabel('Performance (prop. correct)', fontsize=FS_A)
ax.set_ylim(0.3, 1.05)
ax.text(0.05, 0.97, f'N = {len(all_perf_sub)}', transform=ax.transAxes,
        fontsize=FS_A-1, va='top')
ax.tick_params(labelsize=FS_A)
nhb(ax)
savepanel('Fig1a_alltrials')


# ════════════════════════════════════════════════════════════════════════════════
# FIG 1c/1d – FB / noFB performance by structural-change number (N=313, #1–#6)
# ════════════════════════════════════════════════════════════════════════════════
print('Generating Fig1c/1d...')
FS_CD = 12  # larger font for c/d (native 100mm displayed at ~87mm → apparent ~10.4pt)

COL_BOX  = np.array([0.00, 0.447, 0.741])   # MATLAB default blue
COL_HIST = np.array([0.30, 0.780, 0.920])   # cyan, matching MATLAB boxhist

def sw_boxplot_N313(perf_sub, swNr_sub, ylabel, fname, exclude_sw1=False):
    groups = []
    for i in range(1, 7):
        g = perf_sub[swNr_sub == i]
        g = g[~np.isnan(g)]
        if exclude_sw1 and i == 1:
            groups.append(np.array([]))
        else:
            groups.append(g)
    labels = [f'#{i}' for i in range(1, 7)]
    fig, ax = plt.subplots(figsize=(100*MM2IN, 75*MM2IN))
    bp = ax.boxplot(groups, patch_artist=True, widths=0.28,
                    medianprops=dict(color='red', linewidth=1.2),
                    whiskerprops=dict(color='k', linewidth=0.75),
                    capprops=dict(color='k', linewidth=0.75),
                    flierprops=dict(marker='+', markersize=4,
                                   markeredgecolor='red', markeredgewidth=0.75))
    for box in bp['boxes']:
        box.set_facecolor('white'); box.set_edgecolor('k'); box.set_linewidth(0.75)
    # Histogram to the right of each boxplot — cyan bars, 10 bins
    # Normalise ALL groups to the global max count so bar widths reflect N
    all_counts = []
    all_bins_list = []
    for g in groups:
        if len(g) < 2:
            all_counts.append(np.zeros(10)); all_bins_list.append(np.linspace(0,1,11))
            continue
        c, b = np.histogram(g, bins=10, range=(0, 1))
        all_counts.append(c); all_bins_list.append(b)
    global_max = max(c.max() for c in all_counts if c.max() > 0)
    scale = 0.38 / global_max
    for i, (counts, bins) in enumerate(zip(all_counts, all_bins_list)):
        pos = i + 1
        for j in range(len(counts)):
            bar_w = counts[j] * scale
            if bar_w > 0:
                y_ctr = (bins[j] + bins[j+1]) / 2
                ax.barh(y_ctr, bar_w, left=pos + 0.20,
                        height=(bins[1] - bins[0]) * 0.92,
                        color=COL_HIST, linewidth=0)
    ax.axhline(0.5, color='gray', linestyle='--', linewidth=0.6)
    ax.set_xticks(range(1, 7))
    ax.set_xticklabels(labels, fontsize=FS_CD)
    ax.set_xlabel('Number of structural changes', fontsize=FS_CD)
    ax.set_ylabel(ylabel, fontsize=FS_CD)
    ax.set_ylim(0, 1.02)
    ax.set_xlim(0.5, 6.8)
    ax.tick_params(labelsize=FS_CD)
    nhb(ax, fs=FS_CD)
    savepanel(fname)

sw_boxplot_N313(FBperf_only,   swNr_all, 'FB trials: performance (prop. correct)',    'Fig1c_FB_byswitch')
sw_boxplot_N313(noFBperf_only, swNr_all, 'no-FB trials: performance (prop. correct)', 'Fig1d_noFB_byswitch', exclude_sw1=True)


# ════════════════════════════════════════════════════════════════════════════════
# FIG 1e – LME bar: no-FB performance ~ FB performance (intercept + slope)
#   Replicates basicBehaviour.m Fig2e but computed in Python from N=313 exports.
#   Model: noFBperf_pct ~ FBperf_cent + (1|subID), subset swNr > 2
# ════════════════════════════════════════════════════════════════════════════════
print('Generating Fig1e...')
subidx_e      = swNr_all > 2
FBperf_e      = FBperf_only[subidx_e] * 100          # FB-only perf in %
noFBperf_e    = noFBperf_only[subidx_e] * 100        # noFB-only perf in %
FBperf_cent_e = FBperf_e - np.nanmean(FBperf_e)
# Z-score predictor → slope = change in noFB% per 1 SD change in FB%  (~10%)
FBperf_std_e  = FBperf_cent_e / np.nanstd(FBperf_e, ddof=1)
n_e           = int(subidx_e.sum())
df_e = pd.DataFrame({'noFB': noFBperf_e, 'FBstd': FBperf_std_e,
                     'subID': np.arange(n_e)})
md  = smf.mixedlm('noFB ~ FBstd', df_e, groups=df_e['subID'])
mdf = md.fit(reml=False)
coefs_e = np.array([mdf.fe_params['Intercept'], mdf.fe_params['FBstd']])
ses_e   = np.array([mdf.bse_fe['Intercept'],    mdf.bse_fe['FBstd']])
print(f'  LME (z-scored): Intercept={coefs_e[0]:.2f}±{ses_e[0]:.2f}, FB/SD={coefs_e[1]:.2f}±{ses_e[1]:.2f}, N={n_e}')

FS_E = 10  # match apparent MATLAB font size in compound
fig, ax = plt.subplots(figsize=(64*MM2IN, 72*MM2IN))
ax.bar([1, 2], coefs_e, color=[COL_GEN, COL_FB], edgecolor='none', width=0.65)
ax.errorbar([1, 2], coefs_e, yerr=ses_e,
            fmt='none', color='k', linewidth=0.75, capsize=3, capthick=0.75)
ax.axhline(0, color='k', linewidth=0.5)
ax.set_xticks([1, 2])
ax.set_xticklabels(['Intercept', 'FB trials:\n% correct'], fontsize=FS_E,
                    rotation=30, ha='right', rotation_mode='anchor')
ax.set_ylabel('no-FB performance effect size (%)', fontsize=FS_E)
y_max = max(coefs_e + ses_e) * 1.15
ax.set_ylim(0, max(y_max, 5))
ax.tick_params(labelsize=FS_E)
nhb(ax)
savepanel('Fig1e_LME_bar')


# ════════════════════════════════════════════════════════════════════════════════
# FIG 2a – Factor loading bar charts (colored by questionnaire)
# ════════════════════════════════════════════════════════════════════════════════
print('Generating Fig2a...')
subdata = pd.read_csv(os.path.join(BASE_DIR, 'Rscripts', 'data', 'subdata_Feb23.csv'), index_col=0)
fa = FactorAnalyzer(n_factors=3, rotation='oblimin', method='ml')
fa.fit(subdata)
loadings = pd.DataFrame(fa.loadings_, index=subdata.columns, columns=['ML1','ML2','ML3'])

factor_order = [
    ('ML1', 'Factor 1: Anxiety-Depression (AD)'),
    ('ML2', 'Factor 2: Social Unease (SU)'),
    ('ML3', 'Factor 3: Obsessive-Compulsive (OC)'),
]

QUEST_COL = {
    'DASSdep':    '#4d9e4d', 'DASSanx':    '#4d9e4d', 'DASSstress':  '#4d9e4d',
    'LSASfear':   '#7b52a8', 'LSASavoid':  '#7b52a8',
    'OCIRwash':   '#4a7ab5', 'OCIRobs':    '#4a7ab5', 'OCIRhoar':    '#4a7ab5',
    'OCIRord':    '#4a7ab5', 'OCIRcmp':    '#4a7ab5', 'OCIRneut':    '#4a7ab5',
    'SSMSunuExp': '#d94f8a', 'SSMScogDis': '#d94f8a',
    'SSMSinAnh':  '#d94f8a', 'SSMSimNC':   '#d94f8a',
    'BISatt':     '#e07c2a', 'BISmot':     '#e07c2a', 'BISnonpl':    '#e07c2a',
    'AMIbeh':     '#cfc020', 'AMIsoc':     '#cfc020', 'AMIemot':     '#cfc020',
    'RSSmean':    '#afc8d4',
}
BAR_COLS = [QUEST_COL[c] for c in subdata.columns]
XLABELS  = ['Depression','Anxiety','Stress','Fear','Avoidance',
             'Washing','Obsessing','Hoarding','Ordering','Compulsion','Neutralising',
             'Unu. experience','Cog. disturbances','Intr. anhedonia','Impulsive noncon.',
             'Attention','Motor','Non-planning','Behaviour','Social','Emotional','RSS']
x = np.arange(len(subdata.columns))

fig = plt.figure(figsize=(120*MM2IN, 130*MM2IN))
gs  = gridspec.GridSpec(3, 1, figure=fig, hspace=0.22)

for row, (fac, title) in enumerate(factor_order):
    ax = fig.add_subplot(gs[row])
    vals = loadings[fac].values
    ax.bar(x, vals, color=BAR_COLS, edgecolor='none', width=0.8)
    ax.axhline(0, color='k', linewidth=0.6)
    ax.set_xlim(-0.6, len(x) - 0.4)
    ax.set_ylim(-1.1, 1.15)
    ax.set_yticks([-1, 0, 1])
    ax.set_ylabel('Loading', fontsize=FS)
    ax.set_title(title, fontsize=FS, pad=2, loc='left')
    nhb(ax, fs=FS)
    if row < 2:
        ax.set_xticks([])
    else:
        ax.set_xticks(x)
        ax.set_xticklabels(XLABELS, rotation=45, ha='right',
                            fontsize=FS-2, rotation_mode='anchor')

patches = [mpatches.Patch(fc=c, ec='none', label=l) for c, l in [
    ('#4d9e4d','DASS'), ('#7b52a8','LSAS'), ('#4a7ab5','OCI-R'),
    ('#d94f8a','SSMS'), ('#e07c2a','BIS'),  ('#cfc020','AMI'), ('#afc8d4','RSS')]]
fig.legend(handles=patches, ncol=7, loc='lower center',
           bbox_to_anchor=(0.5, -0.04), fontsize=FS-1.5,
           frameon=False, handlelength=1.2, columnspacing=0.8)
savepanel('Fig2a_FA_barcharts')


# ════════════════════════════════════════════════════════════════════════════════
# FIG 5a – LME bar: noFB perf ~ OC * MBsinceSW  (3 bars, no intercept)
#   Model: MBperf6 ~ FA6*MBsw6 + (1|subID6)
# ════════════════════════════════════════════════════════════════════════════════
print('Generating Fig5a...')
coefs_5a = np.array([ 0.02160, -0.01436, -0.01547])
ses_5a   = np.array([ 0.00515,  0.01212,  0.00522])
names_5a = ['#MB since change\n(MBchange)', 'OC', 'OC ×\n#MBchange']
bar_cols_5a = [COL_GEN, COL_OC, COL_OC]

fig, ax = plt.subplots(figsize=(75*MM2IN, 72*MM2IN))
ax.bar(range(1, 4), coefs_5a, color=bar_cols_5a, edgecolor='none', width=0.65)
ax.errorbar(range(1, 4), coefs_5a, yerr=ses_5a,
            fmt='none', color='k', linewidth=0.75, capsize=3, capthick=0.75)
ax.axhline(0, color='k', linewidth=0.5)
ax.set_xticks(range(1, 4))
ax.set_xticklabels(names_5a, rotation=45, ha='right', fontsize=FS, rotation_mode='anchor')
ax.tick_params(axis='x', pad=1)
ax.set_ylabel('no-FB performance', fontsize=FS)
ylim5a = ax.get_ylim()
# *** on MBchange bar (positive: above error cap)
ax.text(1, coefs_5a[0] + ses_5a[0] + 0.04*(ylim5a[1]-ylim5a[0]),
        '***', ha='center', va='bottom', fontsize=10)
# OC bar: n.s. – no star
# *** on OC × MBchange bar (negative: just above zero line)
ax.text(3, 0 + 0.015*(ylim5a[1]-ylim5a[0]),
        '***', ha='center', va='bottom', fontsize=10)
nhb(ax)
savepanel('Fig5a_interaction_noFB_MBsinceSW')


# ════════════════════════════════════════════════════════════════════════════════
# FIG 2c – Factor correlation matrix (oblimin phi) with values on cells
# ════════════════════════════════════════════════════════════════════════════════
print('Generating Fig2c...')
phi = fa.phi_   # 3×3 inter-factor correlation matrix from oblimin
flabels = ['AD', 'SU', 'OC']

fig, ax = plt.subplots(figsize=(55*MM2IN, 55*MM2IN))
im = ax.imshow(phi, cmap='RdBu_r', vmin=-1, vmax=1, aspect='equal')

# Add correlation values only for the 3 unique off-diagonal pairs
for i in range(3):
    for j in range(3):
        if i == j:
            continue
        r = phi[i, j]
        # White text on dark cells, black on light cells
        txt_col = 'white' if abs(r) > 0.45 else 'black'
        ax.text(j, i, f'{r:.2f}', ha='center', va='center',
                fontsize=FS, color=txt_col, fontweight='normal')

ax.set_xticks(range(3)); ax.set_xticklabels(flabels, fontsize=FS)
ax.set_yticks(range(3)); ax.set_yticklabels(flabels, fontsize=FS)
plt.colorbar(im, ax=ax, fraction=0.046, pad=0.04).ax.tick_params(labelsize=FS-1)
ax.tick_params(length=0)
for sp in ax.spines.values():
    sp.set_visible(False)
savepanel('Fig2c_factor_correlations')


# ════════════════════════════════════════════════════════════════════════════════
# FIG 4b – FB performance pre/during/post switch: boxplot + histogram
# ════════════════════════════════════════════════════════════════════════════════
print('Generating Fig4b...')
valid_fb = fb3_all[~np.isnan(fb3_all).any(axis=1)]

fig, ax = plt.subplots(figsize=(65*MM2IN, 80*MM2IN))

labels4b = ['prior\nMB t−1', 'post\nMB t', 'post\nMB t+1']
positions = [1, 2, 3]
cols_data4b = [valid_fb[:,0], valid_fb[:,1], valid_fb[:,2]]

# Pre-compute histograms; normalise across whole sample (global max, matching Fig1c)
all_counts4b, all_bins4b = [], []
for col_data in cols_data4b:
    c, b = np.histogram(col_data, bins=10, range=(0, 1))
    all_counts4b.append(c); all_bins4b.append(b)
global_max4b = max(c.max() for c in all_counts4b if c.max() > 0)
scale4b = 0.38 / global_max4b

for pos, col_data, counts, bins in zip(positions, cols_data4b, all_counts4b, all_bins4b):
    bp = ax.boxplot(col_data, positions=[pos], widths=[0.28],
                    patch_artist=True,
                    medianprops=dict(color='red', linewidth=1.2),
                    whiskerprops=dict(color='k', linewidth=0.75),
                    capprops=dict(color='k', linewidth=0.75),
                    flierprops=dict(marker='+', markersize=4,
                                   markeredgecolor='red', markeredgewidth=0.75))
    bp['boxes'][0].set_facecolor('white')
    bp['boxes'][0].set_edgecolor('k')
    bp['boxes'][0].set_linewidth(0.75)
    for j in range(len(counts)):
        bar_w = counts[j] * scale4b
        if bar_w > 0:
            y_ctr = (bins[j] + bins[j+1]) / 2
            ax.barh(y_ctr, bar_w, left=pos + 0.20,
                    height=(bins[1] - bins[0]) * 0.92,
                    color=COL_HIST, linewidth=0)

ax.axvline(1.68, color='red', linestyle='--', linewidth=1.1)
ax.text(1.68, 1.03, 'structural\nchange', ha='center', va='bottom',
        fontsize=FS-1, color='red', transform=ax.get_xaxis_transform())
ax.axhline(0.5, color='gray', linestyle='--', linewidth=0.6)
ax.set_xticks(positions)
ax.set_xticklabels(labels4b, fontsize=FS)
ax.set_ylabel('FB trials: average performance', fontsize=FS)
ax.set_ylim(0, 1.05)
ax.set_xlim(0.5, 3.9)
nhb(ax)
savepanel('Fig4b_FB_prepost_boxhist')


# ════════════════════════════════════════════════════════════════════════════════
# FIG 5b – no-FB performance pre/during/post switch: boxplot + histogram
#           (same style as Fig4b / Fig1c but for noFB data)
# ════════════════════════════════════════════════════════════════════════════════
print('Generating Fig5b...')
valid_nofb = nofb3_all[~np.isnan(nofb3_all).any(axis=1)]

fig, ax = plt.subplots(figsize=(65*MM2IN, 80*MM2IN))

labels5b = ['prior\nMB t−1', 'post\nMB t', 'post\nMB t+1']
cols_data5b = [valid_nofb[:,0], valid_nofb[:,1], valid_nofb[:,2]]

all_counts5b, all_bins5b = [], []
for col_data in cols_data5b:
    c, b = np.histogram(col_data, bins=10, range=(0, 1))
    all_counts5b.append(c); all_bins5b.append(b)
global_max5b = max(c.max() for c in all_counts5b if c.max() > 0)
scale5b = 0.38 / global_max5b

for pos, col_data, counts, bins in zip(positions, cols_data5b, all_counts5b, all_bins5b):
    bp = ax.boxplot(col_data, positions=[pos], widths=[0.28],
                    patch_artist=True,
                    medianprops=dict(color='red', linewidth=1.2),
                    whiskerprops=dict(color='k', linewidth=0.75),
                    capprops=dict(color='k', linewidth=0.75),
                    flierprops=dict(marker='+', markersize=4,
                                   markeredgecolor='red', markeredgewidth=0.75))
    bp['boxes'][0].set_facecolor('white')
    bp['boxes'][0].set_edgecolor('k')
    bp['boxes'][0].set_linewidth(0.75)
    for j in range(len(counts)):
        bar_w = counts[j] * scale5b
        if bar_w > 0:
            y_ctr = (bins[j] + bins[j+1]) / 2
            ax.barh(y_ctr, bar_w, left=pos + 0.20,
                    height=(bins[1] - bins[0]) * 0.92,
                    color=COL_HIST, linewidth=0)

ax.axvline(1.68, color='red', linestyle='--', linewidth=1.1)
ax.text(1.68, 1.03, 'structural\nchange', ha='center', va='bottom',
        fontsize=FS-1, color='red', transform=ax.get_xaxis_transform())
ax.axhline(0.5, color='gray', linestyle='--', linewidth=0.6)
ax.set_xticks(positions)
ax.set_xticklabels(labels5b, fontsize=FS)
ax.set_ylabel('no-FB trials: average performance', fontsize=FS)
ax.set_ylim(0, 1.05)
ax.set_xlim(0.5, 3.9)
nhb(ax)
savepanel('Fig5b_noFB_prepost_boxhist')


# ════════════════════════════════════════════════════════════════════════════════
# FIG 4d – GLMM abPE bar chart (left) + schematic (right, from draft)
# ════════════════════════════════════════════════════════════════════════════════
print('Generating Fig4d...')
coefs_abpe = np.array([1.30,  0.01, -0.13])
ses_abpe   = np.array([0.04,  0.04,  0.02])
names_abpe = ['ab-PE', 'OC', 'ab-PE\n× OC']
bar_cols_4d = [COL_GEN, COL_OC, COL_OC]

fig = plt.figure(figsize=(120*MM2IN, 72*MM2IN))
gs  = gridspec.GridSpec(1, 2, figure=fig, width_ratios=[1, 1.5], wspace=0.06)

# Left: GLMM bar chart
ax_bar = fig.add_subplot(gs[0])
ax_bar.bar(range(1,4), coefs_abpe, color=bar_cols_4d, edgecolor='none', width=0.65)
ax_bar.errorbar(range(1,4), coefs_abpe, yerr=ses_abpe,
                fmt='none', color='k', linewidth=0.75, capsize=3, capthick=0.75)
ax_bar.axhline(0, color='k', linewidth=0.5)
ax_bar.set_xticks(range(1,4))
ax_bar.set_xticklabels(names_abpe, rotation=45, ha='right',
                        fontsize=FS, rotation_mode='anchor')
ax_bar.tick_params(axis='x', pad=1)
ax_bar.set_ylabel('log(switch)', fontsize=FS)
ylim4d = ax_bar.get_ylim()
# Significance star on ab-PE bar (positive: place above error cap)
ax_bar.text(1, coefs_abpe[0] + ses_abpe[0] + 0.04*(ylim4d[1]-ylim4d[0]),
            '***', ha='center', va='bottom', fontsize=10)
# Significance star on interaction bar (negative: place just above zero line to avoid tick-label overlap)
ax_bar.text(3, 0 + 0.015*(ylim4d[1]-ylim4d[0]),
            '***', ha='center', va='bottom', fontsize=10)
nhb(ax_bar)

# Right: associative belief PE schematic (cropped from original draft)
ax_sc = fig.add_subplot(gs[1])
sc_img = pimg('Schematic_4d')
show(ax_sc, sc_img)

savepanel('Fig4d_abPE_bar_schematic')


# ════════════════════════════════════════════════════════════════════════════════
# FIG 5e – GLMM sPE bar with significance stars
# ════════════════════════════════════════════════════════════════════════════════
print('Generating Fig5e...')
coefs_spe = np.array([0.43,  0.07, -0.027])
ses_spe   = np.array([0.01,  0.04,  0.007])
names_spe = ['FB s-PE', 'OC', 'OC ×\nFB s-PE']
bar_cols_5e = [COL_GEN, COL_OC, COL_OC]

fig, ax = plt.subplots(figsize=(60*MM2IN, 70*MM2IN))
ax.bar(range(1,4), coefs_spe, color=bar_cols_5e, edgecolor='none', width=0.65)
ax.errorbar(range(1,4), coefs_spe, yerr=ses_spe,
            fmt='none', color='k', linewidth=0.75, capsize=3, capthick=0.75)
ax.axhline(0, color='k', linewidth=0.5)
ax.set_xticks(range(1,4))
ax.set_xticklabels(names_spe, rotation=45, ha='right',
                    fontsize=FS, rotation_mode='anchor')
ax.tick_params(axis='x', pad=1)
ax.set_ylabel('log(switch)', fontsize=FS)
ylim5e = ax.get_ylim()
# Stars on FB s-PE (bar 1, positive: place above error cap)
ax.text(1, coefs_spe[0] + ses_spe[0] + 0.04*(ylim5e[1]-ylim5e[0]),
        '***', ha='center', va='bottom', fontsize=10)
# Stars on OC × FB s-PE (bar 3, negative: place just above zero line to avoid tick-label overlap)
ax.text(3, 0 + 0.015*(ylim5e[1]-ylim5e[0]),
        '***', ha='center', va='bottom', fontsize=10)
nhb(ax)
savepanel('Fig5e_GLMM_sPE_stars')


# ════════════════════════════════════════════════════════════════════════════════
# FIG 5f – 2-bar sPE-change model (s-PE_changed, OC × s-PE_changed)
# ════════════════════════════════════════════════════════════════════════════════
print('Generating Fig5f...')
coefs_5f = np.array([0.4418, -0.0443])
ses_5f   = np.array([0.0129,  0.0130])
names_5f = ['FB s-PE\nchanged', 'OC ×\nFB s-PE\nchanged']
bar_cols_5f = [COL_GEN, COL_OC]

fig, ax = plt.subplots(figsize=(48*MM2IN, 70*MM2IN))
ax.bar([1, 2], coefs_5f, color=bar_cols_5f, edgecolor='none', width=0.6)
ax.errorbar([1, 2], coefs_5f, yerr=ses_5f,
            fmt='none', color='k', linewidth=0.75, capsize=3, capthick=0.75)
ax.axhline(0, color='k', linewidth=0.5)
ax.set_xticks([1, 2])
ax.set_xticklabels(names_5f, rotation=45, ha='right',
                    fontsize=FS, rotation_mode='anchor')
ax.tick_params(axis='x', pad=1)
ax.set_ylabel('log(switch)', fontsize=FS)
ylim5f = ax.get_ylim()
# *** on FB s-PE changed (positive bar: above error cap)
ax.text(1, coefs_5f[0] + ses_5f[0] + 0.04*(ylim5f[1]-ylim5f[0]),
        '***', ha='center', va='bottom', fontsize=10)
# *** on OC × FB s-PE changed (negative bar: just above zero line)
ax.text(2, 0 + 0.015*(ylim5f[1]-ylim5f[0]),
        '***', ha='center', va='bottom', fontsize=10)
ax.text(0.97, 0.97, 'p = 0.0028\n(switchNr > 3)', ha='right', va='top',
        transform=ax.transAxes, fontsize=FS, color='k')
nhb(ax)
savepanel('Fig5f_GLMM_sPEchange_2bars')


# ════════════════════════════════════════════════════════════════════════════════
# FIG 3a – OC score vs initial performance (practice phases + pre-first-switch)
# ════════════════════════════════════════════════════════════════════════════════
print('Generating Fig3a...')
fa_df    = pd.read_csv(os.path.join(BASE_DIR, 'Rscripts', 'data', 'fa_subs_scores_Feb23.csv'))
oc_all   = fa_df['ML3'].values          # OC factor score, N=313
pre_perf = np.loadtxt(os.path.join(BASE_DIR, 'initPerf_export.csv'), delimiter=',')

valid3a = ~np.isnan(oc_all) & ~np.isnan(pre_perf)
x3a, y3a = oc_all[valid3a], pre_perf[valid3a]
from scipy.stats import spearmanr
from scipy.integrate import quad
from scipy.special import gammaln

def bf10_corr(r, n):
    """
    BF10 for correlation with uniform prior on rho in (-1, 1).
    Numerically integrates the Pearson sampling likelihood (Fisher 1915)
    and treats Spearman rho as an approximation to Pearson r for the BF.
    BF10 < 1  →  evidence for H0 (no correlation).
    """
    # Log-integrand for numerical stability
    def log_integrand(rho):
        if abs(rho) >= 1 or abs(r * rho) >= 1:
            return -np.inf
        return (0.5 * (n - 1) * np.log(1 - rho**2)
                - (n - 1.5) * np.log(1 - r * rho))
    integrand = lambda rho: np.exp(log_integrand(rho))
    integral, _ = quad(integrand, -1, 1, limit=500, epsabs=1e-12, epsrel=1e-10)
    # Divide by 2: prior is uniform(1/2) on [-1,1]; denominator (H0) = 1
    return float(integral / 2)

r3a, p3a = spearmanr(x3a, y3a)
bf3a = bf10_corr(r3a, len(x3a))
bf01_3a = 1 / bf3a
print(f'  Fig3a: rho={r3a:.3f}, p={p3a:.3f}, BF10={bf3a:.3f}, BF01={bf01_3a:.1f}')

fig = plt.figure(figsize=(88*MM2IN, 95*MM2IN))
left, width, bottom, height, sp = 0.20, 0.56, 0.18, 0.56, 0.015
ax_s  = fig.add_axes([left,            bottom,           width,  height])
ax_hx = fig.add_axes([left,            bottom+height+sp, width,  0.13  ], sharex=ax_s)
ax_hy = fig.add_axes([left+width+sp,   bottom,           0.13,   height], sharey=ax_s)

ax_s.scatter(x3a, y3a, s=8, color='k', alpha=0.5, linewidths=0)
p_fit = np.polyfit(x3a, y3a, 1)
xfit  = np.linspace(x3a.min(), x3a.max(), 100)
ax_s.plot(xfit, np.polyval(p_fit, xfit), 'k-', linewidth=0.75)
ax_s.axhline(0.5, color='gray', linestyle='--', linewidth=0.5)
ax_s.set_xlabel('OC score', fontsize=FS)
ax_s.set_ylabel('Initial performance\n(prop. correct)', fontsize=FS)
ax_s.text(0.97, 0.08,
          f'rho={r3a:.3f}, p={p3a:.3f}\nBF01={bf01_3a:.1f}',
          transform=ax_s.transAxes, ha='right', va='bottom',
          fontsize=FS-1, fontweight='normal')
nhb(ax_s)

ax_hx.hist(x3a, bins=20, color='gray', edgecolor='none', linewidth=0)
ax_hx.axis('off')

ax_hy.hist(y3a, bins=20, color='gray', edgecolor='none', linewidth=0, orientation='horizontal')
ax_hy.axis('off')

savepanel('Fig3a_OC_vs_preswitch_perf')


# ════════════════════════════════════════════════════════════════════════════════
# FIG 3b – OC score vs comprehension question repetitions
# ════════════════════════════════════════════════════════════════════════════════
print('Generating Fig3b...')
mcreps_path = os.path.join(BASE_DIR, 'mcreps_export.csv')
if os.path.exists(mcreps_path):
    mc_reps = np.loadtxt(mcreps_path, delimiter=',')
    valid3b = ~np.isnan(oc_all) & ~np.isnan(mc_reps)
    x3b, y3b = oc_all[valid3b], mc_reps[valid3b]
    r3b, p3b = spearmanr(x3b, y3b)
    bf3b = bf10_corr(r3b, len(x3b))
    bf01_3b = 1 / bf3b
    print(f'  Fig3b: rho={r3b:.3f}, p={p3b:.3f}, BF10={bf3b:.3f}, BF01={bf01_3b:.1f}')

    fig = plt.figure(figsize=(88*MM2IN, 95*MM2IN))
    left, width, bottom, height, sp = 0.20, 0.56, 0.18, 0.56, 0.015
    ax_s  = fig.add_axes([left,            bottom,           width,  height])
    ax_hx = fig.add_axes([left,            bottom+height+sp, width,  0.13  ], sharex=ax_s)
    ax_hy = fig.add_axes([left+width+sp,   bottom,           0.13,   height], sharey=ax_s)

    ax_s.scatter(x3b, y3b, s=8, color='k', alpha=0.5, linewidths=0)
    p_fit = np.polyfit(x3b, y3b, 1)
    xfit  = np.linspace(x3b.min(), x3b.max(), 100)
    ax_s.plot(xfit, np.polyval(p_fit, xfit), 'k-', linewidth=0.75)
    ax_s.set_xlabel('OC score', fontsize=FS)
    ax_s.set_ylabel('# comprehension repetitions', fontsize=FS)
    # Stats placed upper-left where comprehension reps data is sparse
    ax_s.text(0.45, 0.97,
              f'rho={r3b:.3f}, p={p3b:.3f}\nBF01={bf01_3b:.1f}',
              transform=ax_s.transAxes, ha='left', va='top',
              fontsize=FS-1, fontweight='normal')
    nhb(ax_s)

    ax_hx.hist(x3b, bins=20, color='gray', edgecolor='none', linewidth=0)
    ax_hx.axis('off')

    ax_hy.hist(y3b, bins=20, color='gray', edgecolor='none', linewidth=0, orientation='horizontal')
    ax_hy.axis('off')

    savepanel('Fig3b_OC_vs_mcreps')
    USE_PYTHON_3B = True
else:
    print('  mcreps_export.csv not yet available; using MATLAB panel for 3b')
    USE_PYTHON_3B = False


# ════════════════════════════════════════════════════════════════════════════════
# FIG 4a / 4c / 5c – OC scatter plots with marginal histograms
#   Two versions saved for each: plain (rho + p) and with BF01
# ════════════════════════════════════════════════════════════════════════════════

def scatter_marginals(x, y, xlabel, ylabel, fname_base,
                      stats_xy=(0.97, 0.08), stats_ha='right', stats_va='bottom',
                      chance_line=None, integer_y=False, two_row_stats=False):
    """Scatter + marginal histograms; saves <fname_base>.png (rho + p, no BF)."""
    from scipy.stats import spearmanr
    r, p = spearmanr(x, y)
    print(f'  {fname_base}: rho={r:.3f}, p={p:.3f}')

    fig = plt.figure(figsize=(88*MM2IN, 95*MM2IN))
    left, width, bottom, height, sp = 0.20, 0.56, 0.18, 0.56, 0.015
    ax_s  = fig.add_axes([left,          bottom,           width, height])
    ax_hx = fig.add_axes([left,          bottom+height+sp, width, 0.13], sharex=ax_s)
    ax_hy = fig.add_axes([left+width+sp, bottom,           0.13,  height], sharey=ax_s)

    y_plot = y + np.random.RandomState(42).uniform(-0.18, 0.18, len(y)) if integer_y else y

    ax_s.scatter(x, y_plot, s=8, color='k', alpha=0.5, linewidths=0)
    p_fit = np.polyfit(x, y, 1)
    xfit  = np.linspace(x.min(), x.max(), 100)
    ax_s.plot(xfit, np.polyval(p_fit, xfit), 'k-', linewidth=0.75)
    if chance_line is not None:
        ax_s.axhline(chance_line, color='gray', linestyle='--', linewidth=0.5)
    ax_s.set_xlabel(xlabel, fontsize=FS)
    ax_s.set_ylabel(ylabel, fontsize=FS)
    if integer_y:
        ax_s.set_yticks(sorted(np.unique(y).astype(int)))
    nhb(ax_s)

    stats_str = f'rho={r:.3f}\np={p:.3f}' if two_row_stats else f'rho={r:.3f}, p={p:.3f}'
    ax_s.text(stats_xy[0], stats_xy[1], stats_str,
              transform=ax_s.transAxes, ha=stats_ha, va=stats_va, fontsize=FS-1)

    ax_hx.hist(x, bins=20, color='gray', edgecolor='none', linewidth=0)
    ax_hx.axis('off')
    ax_hy.hist(y, bins=20, color='gray', edgecolor='none', linewidth=0,
               orientation='horizontal')
    ax_hy.axis('off')

    savepanel(fname_base)


print('Generating Fig4a...')
valid4a = ~np.isnan(oc_all) & ~np.isnan(swNr_all)
scatter_marginals(oc_all[valid4a], swNr_all[valid4a],
                  xlabel='OC score', ylabel='# structural changes',
                  fname_base='Fig4a_OC_vs_switches',
                  stats_xy=(0.97, 0.06), stats_ha='right', stats_va='bottom',
                  integer_y=True, two_row_stats=True)

print('Generating Fig4c...')
valid4c = ~np.isnan(oc_all) & ~np.isnan(fb3_all[:, 2])
scatter_marginals(oc_all[valid4c], fb3_all[valid4c, 2],
                  xlabel='OC score',
                  ylabel='FB trials: performance MB t+1\n(prop. correct)',
                  fname_base='Fig4c_OC_vs_FB_MBt1',
                  stats_xy=(0.97, 0.06), stats_ha='right', stats_va='bottom',
                  chance_line=0.5)

print('Generating Fig5c...')
valid5c = ~np.isnan(oc_all) & ~np.isnan(nofb3_all[:, 2])
scatter_marginals(oc_all[valid5c], nofb3_all[valid5c, 2],
                  xlabel='OC score',
                  ylabel='no-FB trials: performance MB t+1\n(prop. correct)',
                  fname_base='Fig5c_OC_vs_noFB_MBt1',
                  stats_xy=(0.97, 0.06), stats_ha='right', stats_va='bottom',
                  chance_line=0.5)



# ════════════════════════════════════════════════════════════════════════════════
# SUPP FIG 1b – GLMM: switch ~ prevPE * OC  (3-bar, no intercept)
# ════════════════════════════════════════════════════════════════════════════════
print('\nGenerating SuppFig1b...')
coefs_S1b = np.array([ 1.15532,  0.09595, -0.07504])
ses_S1b   = np.array([ 0.02009,  0.04217,  0.01988])
names_S1b = ['ab-PE', 'OC', 'ab-PE ×\nOC']
bar_cols_S1b = [COL_GEN, COL_OC, COL_OC]

fig, ax = plt.subplots(figsize=(72*MM2IN, 72*MM2IN))
ax.bar(range(1, 4), coefs_S1b, color=bar_cols_S1b, edgecolor='none', width=0.65)
ax.errorbar(range(1, 4), coefs_S1b, yerr=ses_S1b,
            fmt='none', color='k', linewidth=0.75, capsize=3, capthick=0.75)
ax.axhline(0, color='k', linewidth=0.5)
ax.set_xticks(range(1, 4))
ax.set_xticklabels(names_S1b, rotation=45, ha='right', fontsize=FS,
                   rotation_mode='anchor')
ax.tick_params(axis='x', pad=1)
ax.set_ylabel('GLMM coefficient (log-odds)', fontsize=FS)
ylim_S1b = ax.get_ylim()
# bar 1: ab-PE positive (***) – above error cap
ax.text(1, coefs_S1b[0] + ses_S1b[0] + 0.04*(ylim_S1b[1]-ylim_S1b[0]),
        '***', ha='center', va='bottom', fontsize=10)
# bar 2: OC positive (*) – above error cap
ax.text(2, coefs_S1b[1] + ses_S1b[1] + 0.04*(ylim_S1b[1]-ylim_S1b[0]),
        '*', ha='center', va='bottom', fontsize=10)
# bar 3: ab-PE×OC negative (***) – just above zero line
ax.text(3, 0 + 0.015*(ylim_S1b[1]-ylim_S1b[0]),
        '***', ha='center', va='bottom', fontsize=10)
nhb(ax)
savepanel('SuppFig1b_GLMM_switch_prevPE_OC')


# ════════════════════════════════════════════════════════════════════════════════
# SUPP FIG 1c – % switch on win/loss trials vs OC score (scatter + marginals)
#   Win:  rho=0.101, p=0.1
#   Loss: rho=-0.057, p=0.3
#   Two versions: plain and with BF01
# ════════════════════════════════════════════════════════════════════════════════
print('Generating SuppFig1c...')
from scipy.integrate import quad as _quad

s1c_data  = np.loadtxt(os.path.join(BASE_DIR, 'suppfig1c_data.csv'), delimiter=',')
oc_s1c    = s1c_data[:, 0]
sw_win    = s1c_data[:, 1]
sw_loss   = s1c_data[:, 2]

# Drop rows where either win or loss is NaN
valid_win  = ~np.isnan(oc_s1c) & ~np.isnan(sw_win)
valid_loss = ~np.isnan(oc_s1c) & ~np.isnan(sw_loss)

from scipy.stats import spearmanr as _spearmanr
r_win,  p_win  = _spearmanr(oc_s1c[valid_win],  sw_win[valid_win])
r_loss, p_loss = _spearmanr(oc_s1c[valid_loss], sw_loss[valid_loss])
print(f'  S1c Win:  rho={r_win:.3f}, p={p_win:.4f}')
print(f'  S1c Loss: rho={r_loss:.3f}, p={p_loss:.4f}')

bf10_win  = bf10_corr(r_win,  int(valid_win.sum()))
bf01_win  = 1 / bf10_win
bf10_loss = bf10_corr(r_loss, int(valid_loss.sum()))
bf01_loss = 1 / bf10_loss
print(f'  S1c Win:  BF01={bf01_win:.2f}')
print(f'  S1c Loss: BF01={bf01_loss:.2f}')


def _s1c_fig(with_bf):
    fig = plt.figure(figsize=(88*MM2IN, 170*MM2IN))
    left, width, bottom_lo, bottom_hi = 0.20, 0.56, 0.08, 0.57
    height, sp = 0.34, 0.015

    ax_s_win  = fig.add_axes([left,          bottom_hi,          width,  height])
    ax_hx_win = fig.add_axes([left,          bottom_hi+height+sp, width,  0.09], sharex=ax_s_win)
    ax_hy_win = fig.add_axes([left+width+sp, bottom_hi,           0.10,   height], sharey=ax_s_win)

    ax_s_los  = fig.add_axes([left,          bottom_lo,           width,  height])
    ax_hx_los = fig.add_axes([left,          bottom_lo+height+sp, width,  0.09], sharex=ax_s_los)
    ax_hy_los = fig.add_axes([left+width+sp, bottom_lo,           0.10,   height], sharey=ax_s_los)

    # win: slightly below top-right; loss: bottom-right (avoids dense data at top)
    stats_pos = {'win': (0.97, 0.82, 'top'), 'loss': (0.97, 0.06, 'bottom')}
    for ax_s, xd, yd, rv, pv, bfv, lbl in [
        (ax_s_win,  oc_s1c[valid_win],  sw_win[valid_win],   r_win,  p_win,  bf01_win,  'win'),
        (ax_s_los,  oc_s1c[valid_loss], sw_loss[valid_loss], r_loss, p_loss, bf01_loss, 'loss'),
    ]:
        ax_s.scatter(xd, yd, s=8, color='k', alpha=0.5, linewidths=0)
        p_fit = np.polyfit(xd, yd, 1)
        xfit  = np.linspace(xd.min(), xd.max(), 100)
        ax_s.plot(xfit, np.polyval(p_fit, xfit), 'k-', linewidth=0.75)
        ax_s.set_xlabel('OC score', fontsize=FS)
        ax_s.set_ylabel(f'% switch after {lbl}', fontsize=FS)
        nhb(ax_s)
        p_str  = f'{round(pv, 1):.1f}'
        if with_bf:
            stats_str = f'rho={rv:.3f}, p={p_str}\nBF01={bfv:.1f}'
        else:
            stats_str = f'rho={rv:.3f}, p={p_str}'
        sx, sy, sva = stats_pos[lbl]
        ax_s.text(sx, sy, stats_str,
                  transform=ax_s.transAxes, ha='right', va=sva, fontsize=FS-1)

    ax_hx_win.hist(oc_s1c[valid_win],  bins=20, color='gray', edgecolor='none', linewidth=0)
    ax_hx_win.axis('off')
    ax_hy_win.hist(sw_win[valid_win],  bins=20, color='gray', edgecolor='none',
                   linewidth=0, orientation='horizontal')
    ax_hy_win.axis('off')

    ax_hx_los.hist(oc_s1c[valid_loss], bins=20, color='gray', edgecolor='none', linewidth=0)
    ax_hx_los.axis('off')
    ax_hy_los.hist(sw_loss[valid_loss], bins=20, color='gray', edgecolor='none',
                   linewidth=0, orientation='horizontal')
    ax_hy_los.axis('off')

    suffix = '_BF' if with_bf else ''
    savepanel(f'SuppFig1c_switch_winloss{suffix}')

_s1c_fig(with_bf=False)
_s1c_fig(with_bf=True)


print('\nAll panels generated.')


# ════════════════════════════════════════════════════════════════════════════════
# ASSEMBLE COMPOUND FIGURES
# ════════════════════════════════════════════════════════════════════════════════
print('\nAssembling compound figures...')


# ── Figure 1: Basic Behaviour ─────────────────────────────────────────────────
# Layout per user request:
#   Row 1: a (boxplot) | b (histogram) | e (LME bar)  — all same line
#   Row 2: c (FB by switch) | d (noFB by switch)       — wider, font matches row 1
#
# Font calibration (MATLAB panels use 14 pt at native size):
#   panel b native=88mm, displayed≈65mm  → apparent ≈10.4 pt
#   panel c/d native=120mm, displayed≈85mm → apparent ≈ 9.9 pt   (close match)
#   Python panels a,e generated at 10 pt, displayed near-native   → ≈10 pt
print('  Fig1...')
fig = plt.figure(figsize=(180*MM2IN, 165*MM2IN))

# Row 1 (top 45% of figure): a is narrow; b and e share remaining space equally
gs1 = gridspec.GridSpec(1, 3, figure=fig,
                         left=0.0, right=1.0, top=1.0, bottom=0.53,
                         width_ratios=[1.0, 1.7, 1.5], wspace=0.10)

# Row 2 (bottom 48%): c and d, equal width, each ~85 mm displayed
gs2 = gridspec.GridSpec(1, 2, figure=fig,
                         left=0.0, right=1.0, top=0.48, bottom=0.0,
                         wspace=0.07)

ax_a = fig.add_subplot(gs1[0, 0])
ax_b = fig.add_subplot(gs1[0, 1])
ax_e = fig.add_subplot(gs1[0, 2])
ax_c = fig.add_subplot(gs2[0, 0])
ax_d = fig.add_subplot(gs2[0, 1])

LBL_Y = 1.06
# Row 1: consistent x-offset relative to each panel's width
ROW1_X = -0.09
# Row 2: c and d are wider so a smaller fraction offset keeps labels tidy
ROW2_X = -0.05

show(ax_a, pimg('Fig1a_alltrials'));        plabel(ax_a, 'a', x=ROW1_X, y=LBL_Y)
show(ax_b, oimg('Fig2b_switch_histogram')); plabel(ax_b, 'b', x=ROW1_X, y=LBL_Y)
show(ax_e, pimg('Fig1e_LME_bar'));          plabel(ax_e, 'e', x=ROW1_X, y=LBL_Y)
show(ax_c, pimg('Fig1c_FB_byswitch'));      plabel(ax_c, 'c', x=ROW2_X, y=LBL_Y)
show(ax_d, pimg('Fig1d_noFB_byswitch'));    plabel(ax_d, 'd', x=ROW2_X, y=LBL_Y)

savecompound('Fig1_basic_behaviour')


# ── Figure 2: Factor Analysis ──────────────────────────────────────────────────
print('  Fig2...')
fig = plt.figure(figsize=(180*MM2IN, 155*MM2IN))
gs  = gridspec.GridSpec(2, 5, figure=fig, hspace=0.14, wspace=0.10)

ax_a = fig.add_subplot(gs[0:2, 0:3])
ax_b = fig.add_subplot(gs[0,   3:5])
ax_c = fig.add_subplot(gs[1,   3:5])

show(ax_a, pimg('Fig2a_FA_barcharts'));              plabel(ax_a, 'a', x=-0.06, y=1.04)
show(ax_b, oimg('Fig3b_scree_plot'));                plabel(ax_b, 'b', x=-0.18, y=1.10)
show(ax_c, pimg('Fig2c_factor_correlations'));        plabel(ax_c, 'c', x=-0.18, y=1.10)

savecompound('Fig2_factor_analysis')


# ── Figure 3: OC vs pre-switch performance & comprehension ───────────────────
print('  Fig3...')
SCHEM_DIR = os.path.join(FIG_DIR, 'compound')
schem_3a = mpimg.imread(os.path.join(SCHEM_DIR, 'Figure_2_side_panel_a_new.png'))
schem_3b = mpimg.imread(os.path.join(SCHEM_DIR, 'Figure_2_side_panel_b_new.png'))

fig = plt.figure(figsize=(180*MM2IN, 120*MM2IN))
gs  = gridspec.GridSpec(2, 2, figure=fig,
                         height_ratios=[0.40, 1],
                         hspace=0.06, wspace=0.10)

ax_sa = fig.add_subplot(gs[0, 0])
ax_sb = fig.add_subplot(gs[0, 1])
ax_a  = fig.add_subplot(gs[1, 0])
ax_b  = fig.add_subplot(gs[1, 1])

show(ax_sa, schem_3a);                              plabel(ax_sa, 'a', x=-0.08, y=1.10)
show(ax_sb, schem_3b);                              plabel(ax_sb, 'b', x=-0.08, y=1.10)
show(ax_a,  pimg('Fig3a_OC_vs_preswitch_perf'))
if USE_PYTHON_3B:
    show(ax_b, pimg('Fig3b_OC_vs_mcreps'))
else:
    show(ax_b, oimg('Fig4b_OC_vs_MC_reps'))

savecompound('Fig3_OC_initial_performance')


# ── Figure 4: abPE × OC ──────────────────────────────────────────────────────
# Two versions: plain (no BF) and with BF
def _assemble_fig4(bf_suffix=''):
    fig = plt.figure(figsize=(180*MM2IN, 155*MM2IN))
    gs  = gridspec.GridSpec(2, 2, figure=fig, hspace=0.12, wspace=0.08)
    ax_a = fig.add_subplot(gs[0, 0])
    ax_b = fig.add_subplot(gs[0, 1])
    ax_c = fig.add_subplot(gs[1, 0])
    ax_d = fig.add_subplot(gs[1, 1])
    show(ax_a, pimg('Fig4a_OC_vs_switches'));               plabel(ax_a, 'a', x=-0.08, y=1.10)
    show(ax_b, pimg('Fig4b_FB_prepost_boxhist'));           plabel(ax_b, 'b', x=-0.14, y=1.10)
    show(ax_c, pimg('Fig4c_OC_vs_FB_MBt1'));               plabel(ax_c, 'c', x=-0.08, y=1.10)
    show(ax_d, pimg('Fig4d_abPE_bar_schematic'));           plabel(ax_d, 'd', x=-0.08, y=1.10)
    savecompound('Fig4_abPE_OC')

print('  Fig4...')
_assemble_fig4()


# ── Figure 5: sPE × OC ────────────────────────────────────────────────────────
print('  Fig5...')
fig = plt.figure(figsize=(180*MM2IN, 155*MM2IN))
gs  = gridspec.GridSpec(2, 12, figure=fig,
                         height_ratios=[1, 1],
                         hspace=0.16, wspace=0.08)
ax_a = fig.add_subplot(gs[0, 0:7])
ax_b = fig.add_subplot(gs[0, 7:12])
ax_c = fig.add_subplot(gs[1, 0:4])
ax_d = fig.add_subplot(gs[1, 4:8])
ax_e = fig.add_subplot(gs[1, 8:10])
ax_f = fig.add_subplot(gs[1, 10:12])
show(ax_a, pimg('Fig5a_interaction_noFB_MBsinceSW')); plabel(ax_a, 'a', x=-0.06, y=1.10)
show(ax_b, pimg('Fig5b_noFB_prepost_boxhist'));        plabel(ax_b, 'b', x=-0.14, y=1.10)
show(ax_c, pimg('Fig5c_OC_vs_noFB_MBt1'));            plabel(ax_c, 'c', x=-0.08, y=1.10)
show(ax_d, pimg('Schematic_5d'));                      plabel(ax_d, 'd', x=-0.08, y=1.10)
show(ax_e, pimg('Fig5e_GLMM_sPE_stars'));             plabel(ax_e, 'e', x=-0.22, y=1.10)
show(ax_f, pimg('Fig5f_GLMM_sPEchange_2bars'));       plabel(ax_f, 'f', x=-0.22, y=1.10)
savecompound('Fig5_sPE_OC')


# ── Supplementary Figure 1: S1b + S1c ────────────────────────────────────────
# Two versions: plain (no BF) and with BF
def _assemble_suppfig1(bf_suffix=''):
    print(f'  SuppFig1{bf_suffix}...')
    fig = plt.figure(figsize=(180*MM2IN, 100*MM2IN))
    gs  = gridspec.GridSpec(1, 2, figure=fig, hspace=0.10, wspace=0.12)
    ax_b = fig.add_subplot(gs[0, 0])
    ax_c = fig.add_subplot(gs[0, 1])
    show(ax_b, pimg('SuppFig1b_GLMM_switch_prevPE_OC'));           plabel(ax_b, 'b', x=-0.12, y=1.10)
    show(ax_c, pimg(f'SuppFig1c_switch_winloss{bf_suffix}'));      plabel(ax_c, 'c', x=-0.08, y=1.10)
    savecompound(f'SuppFig1{bf_suffix}')

_assemble_suppfig1('')
_assemble_suppfig1('_BF')


print('\nDone. All figures saved to:', OUT_DIR)
