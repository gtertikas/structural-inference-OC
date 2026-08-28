#!/usr/bin/env Rscript
# Fig 3a: Factor loadings heatmap — subscale-level FA
# Nature Human Behaviour format: 88mm single column, Arial 7pt
#
# Replicates subscale FA from factorana.R with local paths
# Output: figures/Fig3a_factor_loadings_heatmap.pdf

rm(list = ls())

required_packages <- c("ggplot2", "reshape2", "polycor", "psych",
                       "GPArotation", "gridExtra", "extrafont", "dplyr")
for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) install.packages(pkg, repos = "https://cloud.r-project.org")
  library(pkg, character.only = TRUE)
}

# Load Arial font if available (for NHB)
tryCatch({
  font_import(prompt = FALSE)
  loadfonts(device = "pdf", quiet = TRUE)
}, error = function(e) message("extrafont: ", e$message))

# ── Paths ──────────────────────────────────────────────────────────────────
base_dir  <- "/Users/georgetertikas/Documents/Nadescha_code"
data_dir  <- file.path(base_dir, "Rscripts", "data")
out_dir   <- file.path(base_dir, "figures")
dir.create(out_dir, showWarnings = FALSE)

# ── Load subscale data ─────────────────────────────────────────────────────
subdata <- read.csv(file.path(data_dir, "subdata_Feb23.csv"), row.names = 1)

cat(sprintf("Loaded subscale data: %d subjects, %d subscales\n",
            nrow(subdata), ncol(subdata)))

# ── Factor analysis (replicates factorana.R subscale section) ──────────────
set.seed(42)
het.mat <- hetcor(subdata)$cor

fa_res <- psych::fa(r = het.mat, nfactors = 3,
                    n.obs   = nrow(subdata),
                    rotate  = "oblimin",
                    fm      = "ml",
                    scores  = "regression")

loadings_mat <- data.frame(fa_res$loadings[])
cat("\nFactor loadings (subscale level):\n")
print(round(loadings_mat, 3))

# ── Readable row labels ────────────────────────────────────────────────────
subscale_labels <- c(
  "DASSdep"    = "DASS: Depression",
  "DASSanx"    = "DASS: Anxiety",
  "DASSstress" = "DASS: Stress",
  "LSASfear"   = "LSAS: Fear",
  "LSASavoid"  = "LSAS: Avoidance",
  "OCIRwash"   = "OCI-R: Washing",
  "OCIRobs"    = "OCI-R: Obsessing",
  "OCIRhoar"   = "OCI-R: Hoarding",
  "OCIRord"    = "OCI-R: Ordering",
  "OCIRcmp"    = "OCI-R: Checking",
  "OCIRneut"   = "OCI-R: Neutralising",
  "SSMSunuExp" = "SSMS: Unusual Exp.",
  "SSMScogDis" = "SSMS: Cog. Disorg.",
  "SSMSinAnh"  = "SSMS: Introv. Anhed.",
  "SSMSimNC"   = "SSMS: Impulsive Nonconf.",
  "BISatt"     = "BIS: Attentional",
  "BISmot"     = "BIS: Motor",
  "BISnonpl"   = "BIS: Non-planning",
  "AMIbeh"     = "AMI: Behavioural",
  "AMIsoc"     = "AMI: Social",
  "AMIemot"    = "AMI: Emotional",
  "RSSmean"    = "RSS: Total"
)

# ── Questionnaire grouping for row colours ─────────────────────────────────
qgroup_map <- c(
  "DASSdep"    = "DASS",  "DASSanx"    = "DASS",  "DASSstress" = "DASS",
  "LSASfear"   = "LSAS",  "LSASavoid"  = "LSAS",
  "OCIRwash"   = "OCI-R", "OCIRobs"    = "OCI-R", "OCIRhoar"   = "OCI-R",
  "OCIRord"    = "OCI-R", "OCIRcmp"    = "OCI-R", "OCIRneut"   = "OCI-R",
  "SSMSunuExp" = "SSMS",  "SSMScogDis" = "SSMS",  "SSMSinAnh"  = "SSMS",
  "SSMSimNC"   = "SSMS",
  "BISatt"     = "BIS",   "BISmot"     = "BIS",   "BISnonpl"   = "BIS",
  "AMIbeh"     = "AMI",   "AMIsoc"     = "AMI",   "AMIemot"    = "AMI",
  "RSSmean"    = "RSS"
)

qgroup_colors <- c(
  "DASS"  = "#4daf4a",
  "LSAS"  = "#984ea3",
  "OCI-R" = "#377eb8",
  "SSMS"  = "#e31a1c",
  "BIS"   = "#ff7f00",
  "AMI"   = "#ffff33",
  "RSS"   = "#B4D4DA"
)

# ── Determine factor identity from loading patterns ────────────────────────
# Factor with highest avg OCIR loading = OC
# Factor with highest avg DASS/LSAS loading = AD
ocir_rows <- grep("^OCIR", rownames(loadings_mat))
dass_rows  <- grep("^DASS|^LSAS", rownames(loadings_mat))
ami_rows   <- grep("^AMI|^SSMS", rownames(loadings_mat))

factor_order <- order(-c(
  mean(abs(loadings_mat[dass_rows,  "ML1"])),
  mean(abs(loadings_mat[dass_rows,  "ML2"])),
  mean(abs(loadings_mat[dass_rows,  "ML3"]))
))
# Use canonical order: AD (high DASS), OC (high OCIR), SU (high SSMS)
ad_col <- names(which.max(colMeans(abs(loadings_mat[dass_rows,  ]))))
oc_col <- names(which.max(colMeans(abs(loadings_mat[ocir_rows,  ]))))
su_col <- setdiff(c("ML1","ML2","ML3"), c(ad_col, oc_col))

cat(sprintf("\nFactor identity: AD=%s, OC=%s, SU=%s\n", ad_col, oc_col, su_col))

col_rename <- c()
col_rename[ad_col] <- "AD\n(Anxiety/Depression)"
col_rename[oc_col] <- "OC\n(Compulsivity)"
col_rename[su_col] <- "SU\n(Schizotypy)"

# ── Build long-format data frame ───────────────────────────────────────────
loadings_mat$subscale <- rownames(loadings_mat)
loadings_mat$label    <- subscale_labels[loadings_mat$subscale]
loadings_mat$qgroup   <- qgroup_map[loadings_mat$subscale]

# Keep display order: DASS, LSAS, OCIR, SSMS, BIS, AMI, RSS (top to bottom)
row_order <- rev(names(subscale_labels))   # bottom of heatmap = first in list
loadings_mat$label <- factor(loadings_mat$label,
                              levels = subscale_labels[row_order])

long_df <- reshape2::melt(loadings_mat,
                           id.vars      = c("subscale", "label", "qgroup"),
                           variable.name = "Factor",
                           value.name    = "Loading")

long_df$FactorName <- col_rename[as.character(long_df$Factor)]
long_df$FactorName <- factor(long_df$FactorName,
                              levels = col_rename[c(ad_col, oc_col, su_col)])

# ── NHB theme ──────────────────────────────────────────────────────────────
# Font sizes: rendered at 120mm, will be scaled to ~53mm in 3-col 159mm figure.
# Scale factor = 53/120 = 0.44. To get ≥7pt at final: render at 7/0.44 = 15.9pt.
# Use base_size=11, axis labels=12pt — gives ~5-5.5pt at final, above NHB min 5pt.
# For 2-col (79mm): 12 * (79/120) = 7.9pt — comfortably above 7pt.
nhb_theme <- theme_classic(base_size = 11, base_family = "Arial") +
  theme(
    axis.text.x      = element_text(size = 11, colour = "black"),
    axis.text.y      = element_text(size = 10, colour = "black"),
    axis.title       = element_text(size = 12, colour = "black"),
    axis.ticks       = element_line(linewidth = 0.5, colour = "black"),
    axis.line        = element_line(linewidth = 0.5, colour = "black"),
    legend.text      = element_text(size = 10),
    legend.title     = element_text(size = 11),
    legend.key.width = unit(3, "mm"),
    legend.key.height= unit(8, "mm"),
    panel.border     = element_rect(colour = "black", fill = NA, linewidth = 0.5),
    axis.line.x      = element_blank(),
    axis.line.y      = element_blank(),
    plot.margin      = margin(2, 2, 2, 2, "mm")
  )

# ── Main heatmap ───────────────────────────────────────────────────────────
p_heat <- ggplot(long_df, aes(x = FactorName, y = label, fill = Loading)) +
  geom_tile(colour = "white", linewidth = 0.2) +
  scale_fill_gradient2(
    low      = "#2166ac",
    mid      = "white",
    high     = "#d6604d",
    midpoint = 0,
    limits   = c(-1, 1),
    name     = "Loading",
    guide    = guide_colourbar(barwidth = unit(2.5, "mm"), barheight = unit(18, "mm"),
                               ticks.linewidth = 0.3)
  ) +
  labs(x = NULL, y = NULL) +
  nhb_theme +
  theme(
    axis.text.x = element_text(size = 7, colour = "black", hjust = 0.5)
  )

# ── Add questionnaire group labels on right side ───────────────────────────
# Build annotation layer: coloured rectangles on the right
qgroup_order <- c("DASS","LSAS","OCI-R","SSMS","BIS","AMI","RSS")
label_to_qgroup <- setNames(loadings_mat$qgroup, loadings_mat$label)

long_df$qgroup_f <- factor(label_to_qgroup[as.character(long_df$label)],
                            levels = qgroup_order)

# Create a side strip plot
strip_df <- unique(long_df[, c("label", "qgroup_f")])
strip_df$x <- 1

p_strip <- ggplot(strip_df, aes(x = x, y = label, fill = qgroup_f)) +
  geom_tile(colour = "white", linewidth = 0.3) +
  scale_fill_manual(values = qgroup_colors, name = "Scale",
                    guide = guide_legend(keywidth = unit(3,"mm"),
                                        keyheight = unit(3,"mm"))) +
  labs(x = NULL, y = NULL) +
  theme_void(base_size = 11, base_family = "Arial") +
  theme(
    legend.text  = element_text(size = 10),
    legend.title = element_text(size = 11, face = "bold"),
    axis.text.y  = element_text(size = 10, hjust = 0, colour = "black"),
    plot.margin  = margin(2, 1, 2, 0, "mm")
  )

# ── Combine and save ───────────────────────────────────────────────────────
# NHB 1.5-col width: 120mm; height ~140mm for 22 rows
# PNG at 300 DPI — 120mm wide = 120/25.4*300 = 1417 px, 130mm tall = 1535 px
# Font sizes scaled up so labels are ≥7pt at final panel size (~53mm, 3-col layout):
#   ggplot base_size=11 → 11 * (53/120) ≈ 4.9pt minimum (strip), labels at base_size are 11pt
#   Axis labels set to 12pt → 12 * (53/120) ≈ 5.3pt — above NHB min 5pt
# For 2-column (79mm) layout: 11 * (79/120) ≈ 7.2pt — above recommended 7pt
out_file <- file.path(out_dir, "Fig3a_factor_loadings_heatmap.png")
png(out_file, width = 120/25.4, height = 130/25.4, units = "in",
    res = 300, bg = "white")
grid.arrange(p_heat, p_strip, ncol = 2, widths = c(6, 0.6))
dev.off()

cat(sprintf("\nFig 3a saved: %s\n", out_file))

# ── Also print loading values for manuscript ───────────────────────────────
cat("\n=== Factor loadings table (subscale level) ===\n")
tbl <- loadings_mat[, c("label", ad_col, oc_col, su_col)]
colnames(tbl)[2:4] <- c("AD", "OC", "SU")
tbl <- tbl[order(tbl$label), ]
for (i in seq_len(nrow(tbl))) {
  cat(sprintf("  %-35s  AD=%6.3f  OC=%6.3f  SU=%6.3f\n",
              as.character(tbl$label[i]),
              tbl$AD[i], tbl$OC[i], tbl$SU[i]))
}

# ── Print FA fit statistics ────────────────────────────────────────────────
cat("\n=== FA fit statistics ===\n")
cat(sprintf("  RMSEA: %.4f\n", fa_res$RMSEA[1]))
cat(sprintf("  TLI:   %.4f\n", fa_res$TLI))
cat(sprintf("  BIC:   %.4f\n", fa_res$BIC))
cat(sprintf("  Chi-sq: %.2f, df=%d\n", fa_res$chi, fa_res$dof))

cat("\n=== Factor intercorrelations ===\n")
print(round(fa_res$Phi, 3))
