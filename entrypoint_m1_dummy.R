#!/usr/bin/env Rscript

library(argparse)
library(jsonlite)

parser <- ArgumentParser(description = "m1_dummy: abs(cont - random[0.02,0.05]) per cell")

parser$add_argument("--output_dir", "-o", required = TRUE, help= "Output directory for results")
parser$add_argument("--name", "-n", required = TRUE, help= "Dataset id used in output filenames")
parser$add_argument("--soupx.percell", dest = "percell_rds", required = TRUE, help= "Path to SoupX per-cell contamination RDS (colums: cell, cont)")
parser$add_argument("--seed", type = "integer", default = 1, help = "Random seed for reproducibility (ensures same random colum each run)")
args <- parser$parse_args()

# Output paths -> ensures output directory exists, defines two output
dir.create(args$output_dir, recursive = TRUE, showWarnings = FALSE)
json_path <- file.path(args$output_dir, paste0(args$name, ".m1_dummy_summary.json"))

# Load and validate input
if (!file.exists(args$percell_rds)) stop("Input RDS not found ...")
df <- readRDS(args$percell_rds)

required_cols <- c("cell", "cont")
missing_cols <- setdiff(required_cols, colnames(df))
if (length(missing_cols) > 0) stop("Input table missing required column(s) ...")

# compute dummy metrics -> random reference between 0.02 and 0.05 and computes abs(cont-random) per cell
# Fix random seed so that random colums is reproducible across runs
set.seed(args$seed)
n <- nrow(df)
df$random   <- runif(n, min = 0.02, max = 0.05)
df$abs_diff <- abs(df$cont - df$random)

## Write outputs
# per-cell TSV (cell, cont, random, abs_diff)

summary_list <- list(
  n_cells         = nrow(df),
  mean_abs_diff   = mean(df$abs_diff),
  median_abs_diff = median(df$abs_diff),
  p95_abs_diff    = unname(quantile(df$abs_diff, 0.95)),
  seed            = args$seed
)
writeLines(jsonlite::toJSON(summary_list, auto_unbox = TRUE, digits = 6), json_path)

# Terminal message -> log line in job output
cat(sprintf("[m1_dummy] Done for %s\n - summary JSON: %s\n",
            args$name, json_path))


