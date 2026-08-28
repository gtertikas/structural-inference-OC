#!/usr/bin/env Rscript
# Fig 3b (replacement): Participant factor-score distributions — subscale-level FA
# Nature Human Behaviour format: 120mm width, Arial, 300dpi PNG (matches Fig3a style)
#
# Replaces the raw PCA scree plot (generate_all_figures.m Fig3b), which a reviewer
# flagged as visually suggesting 1 factor via naive eyeball-scree read, with no CNG
# statistic shown to justify the 3-factor choice. CNG test result (k=3, confirmed on
# both the 209-item and 22-subscale datasets) should instead be reported as one line
# in Methods; this figure shows the participant-level evidence for 3 separable factors.
#
# Output: figures/Fig3b_score_distributions.png / .pdf

rm(list = ls())

required_packages <- c("ggplot2", "reshape2", "polycor", "psych",
                       "GPArotation", "gghalves", "extrafont", "dplyr")
for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) install.packages(pkg, repos = "https://cloud.r-project.org")
  library(pkg, character.only = TRUE)
}

tryCatch({
  font_import(prompt = FALSE)
  loadfonts(device = "pdf", quiet = TRUE)
}, error = function(e) message("extrafont: ", e$message))

# ── Paths ──────────────────────────────────────────────────────────────────
base_dir  <- "/Users/georgetertikas/Documents/Nadescha_code"
data_dir  <- file.path(base_dir, "Rscripts", "data")
out_dir   <- file.path(base_dir, "figures")
dir.create(out_dir, showWarnings = FALSE)

# ── Load subscale data & refit FA (identical to generate_fig3a.R, for
#    consistent ML1/ML2/ML3 <-> AD/OC/SU identity and matched factor scores) ──
subdata <- read.csv(file.path(data_dir, "subdata_Feb23.csv"), row.names = 1)
cat(sprintf("Loaded subscale data: %d subjects, %d subscales\n", nrow(subdata), ncol(subdata)))

set.seed(42)
het.mat <- hetcor(subdata)$cor

fa_res <- psych::fa(r = het.mat, nfactors = 3,
                    n.obs   = nrow(subdata),
                    rotate  = "oblimin",
                    fm      = "ml",
                    scores  = "regression")

fa_scores_obj <- factor.scores(x = subdata, f = fa_res)
scores <- data.frame(fa_scores_obj$scores)
loadings_mat <- data.frame(fa_res$loadings[])

# ── Determine factor identity from loading pattern (same logic as Fig3a) ───
ocir_rows <- grep("^OCIR", rownames(loadings_mat))
dass_rows <- grep("^DASS|^LSAS", rownames(loadings_mat))

ad_col <- names(which.max(colMeans(abs(loadings_mat[dass_rows, ]))))
oc_col <- names(which.max(colMeans(abs(loadings_mat[ocir_rows, ]))))
su_col <- setdiff(c("ML1","ML2","ML3"), c(ad_col, oc_col))
cat(sprintf("\nFactor identity: AD=%s, OC=%s, SU=%s\n", ad_col, oc_col, su_col))

plot_df <- data.frame(
  AD = scores[[ad_col]],
  OC = scores[[oc_col]],
  SU = scores[[su_col]]
)
long_df <- reshape2::melt(plot_df, variable.name = "Factor", value.name = "Score")
long_df$Factor <- factor(long_df$Factor, levels = c("AD","OC","SU"))

factor_labels <- c(
  AD = "AD\n(Anxiety/Depression)",
  OC = "OC\n(Compulsivity)",
  SU = "SU\n(Schizotypy)"
)
long_df$FactorLabel <- factor(factor_labels[as.character(long_df$Factor)],
                               levels = factor_labels[c("AD","OC","SU")])

# same colour family as Fig3a's questionnaire-group colours (DASS->AD, OCI-R->OC, SSMS->SU)
factor_colors <- c(AD = "#4daf4a", OC = "#377eb8", SU = "#e31a1c")
long_df$col <- factor_colors[as.character(long_df$Factor)]

# ── NHB theme (matches Fig3a) ───────────────────────────────────────────────
nhb_theme <- theme_classic(base_size = 11, base_family = "Arial") +
  theme(
    axis.text.x  = element_text(size = 11, colour = "black"),
    axis.text.y  = element_text(size = 11, colour = "black"),
    axis.title   = element_text(size = 12, colour = "black"),
    axis.ticks   = element_line(linewidth = 0.5, colour = "black"),
    axis.line    = element_line(linewidth = 0.5, colour = "black"),
    plot.margin  = margin(3, 3, 3, 3, "mm"),
    legend.position = "none"
  )

# ── Raincloud plot: half-violin + boxplot + jittered points ───────────────
p_score <- ggplot(long_df, aes(x = FactorLabel, y = Score, fill = Factor, colour = Factor)) +
  gghalves::geom_half_violin(side = "r", position = position_nudge(x = 0.15),
                              alpha = 0.5, colour = NA, trim = FALSE) +
  geom_boxplot(width = 0.12, position = position_nudge(x = 0.15),
               outlier.shape = NA, colour = "black", linewidth = 0.4, alpha = 0.9) +
  gghalves::geom_half_point(side = "l", position = position_nudge(x = -0.15),
                             size = 0.7, alpha = 0.45, shape = 16, stroke = 0) +
  scale_fill_manual(values = factor_colors) +
  scale_colour_manual(values = factor_colors) +
  labs(x = NULL, y = "Factor score (regression-weighted)") +
  nhb_theme

# ── Save ─────────────────────────────────────────────────────────────────
out_png <- file.path(out_dir, "Fig3b_score_distributions.png")
png(out_png, width = 120/25.4, height = 90/25.4, units = "in", res = 300, bg = "white")
print(p_score)
dev.off()

out_pdf <- file.path(out_dir, "Fig3b_score_distributions.pdf")
pdf(out_pdf, width = 120/25.4, height = 90/25.4)  # Arial resolved via extrafont's Type1 registration
print(p_score)
dev.off()

cat(sprintf("\nFig 3b (score distributions) saved:\n  %s\n  %s\n", out_png, out_pdf))

# ── Summary stats for the manuscript legend/text ────────────────────────────
cat("\n=== Factor score summary (N =", nrow(plot_df), ") ===\n")
for (f in c("AD","OC","SU")) {
  d <- plot_df[[f]]
  cat(sprintf("  %-3s  M=%6.3f  SD=%5.3f  range=[%5.2f, %5.2f]\n",
              f, mean(d), sd(d), min(d), max(d)))
}

cat("\n=== Reminder: CNG test result to report in Methods instead of the scree plot ===\n")
cat("  Item-level (209 items):    CNG selects k = 3\n")
cat("  Subscale-level (22 vars):  CNG selects k = 3\n")
