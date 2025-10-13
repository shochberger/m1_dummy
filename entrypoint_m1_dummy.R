#!/usr/bin/env Rscript

# Dummy metric:: per cell compute abs(cont - random[0.02, 0.05]).Summarizes mean/median/p95.
# Uses --method.meta to record the method ID. Output: {name}.m1_dummy.json.

library(argparse)
library(jsonlite)

p <- ArgumentParser(description = "m1_dummy: abs(cont - random[0.02,0.05]) per cell")
p$add_argument("--output_dir", "-o", required = TRUE, help= "Output directory for results")
p$add_argument("--name", "-n", required = TRUE, help= "Dataset id used in output filenames")
p$add_argument("--method.percell", dest = "percell_rds", required = TRUE, help= "RDS with colums:cell, cont)")
p$add_argument("--seed", type = "integer", default = 1, help = "Random seed for reproducibility (ensures same random colum each run)")
p$add_argument("--method.meta", dest= "method_meta", required=TRUE, help= "Sidecar JSON with method info")
args <- p$parse_args()

# Output paths
dir.create(args$output_dir, recursive = TRUE, showWarnings = FALSE)
json_path <- file.path(args$output_dir, paste0(args$name, ".m1_dummy.json"))

# Load and validate input
if (!file.exists(args$percell_rds)) stop("Input RDS not found ...")
df <- readRDS(args$percell_rds)

required_cols <- c("cell", "cont")
missing_cols <- setdiff(required_cols, colnames(df))
if (length(missing_cols) > 0) stop("Input table missing required column(s) ...")

# Method ID from sidecar
meta <- jsonlite::read_json(args$method_meta, simplifyVector = TRUE)
method_id <- if(!is.null(meta$method)) meta$method else "unknown"

# Compute dummy metrics -> random reference between 0.02 and 0.05.Computes abs(cont-random) per cell
# Fix random seed so that random colum is reproducible across runs
set.seed(args$seed)
n <- nrow(df)
df$random   <- runif(n, min = 0.02, max = 0.05)
df$abs_diff <- abs(df$cont - df$random)

# Write summary output
summary_list <- list(
  dataset = args$name,
  method = method_id,
  n_cells         = nrow(df),
  mean_abs_diff   = mean(df$abs_diff),
  median_abs_diff = median(df$abs_diff),
  p95_abs_diff    = unname(quantile(df$abs_diff, 0.95)),
  seed            = args$seed
)
writeLines(jsonlite::toJSON(summary_list, auto_unbox = TRUE, digits = 6), json_path)

# Terminal message
cat(sprintf("[m1_dummy] Done for %s\n - summary JSON: %s\n",
            args$name, json_path))


