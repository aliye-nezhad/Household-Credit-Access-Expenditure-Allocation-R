# Reproduce the 1393 HEIS household-finance study in a locked R environment.
# Source archives are read-only; working microdata are never committed.
main <- function() {
  options(warn = 1)
  arguments <- commandArgs(trailingOnly = FALSE)
  script_arg <- grep("^--file=", arguments, value = TRUE)
  if (length(script_arg) != 1L) {
    stop("Launch this file with Rscript scripts/reproduce.R", call. = FALSE)
  }
  script_path <- sub("^--file=", "", script_arg)
  root <- normalizePath(file.path(dirname(script_path), ".."), mustWork = TRUE)
  old_directory <- getwd()
  setwd(root)
  on.exit(setwd(old_directory), add = TRUE)
  old_umask <- Sys.umask("077")
  on.exit(Sys.umask(old_umask), add = TRUE)

  fail <- function(message) stop(message, call. = FALSE)
  assert <- function(condition, message) if (!isTRUE(condition)) fail(message)
  binary <- function(names) {
    for (name in names) {
      found <- Sys.which(name)
      if (nzchar(found)) return(unname(found))
    }
    fail(paste("Required executable not found:", paste(names, collapse = " or ")))
  }
  run <- function(executable, arguments = character(), output = TRUE,
                  error_file = NULL) {
    if (isTRUE(output)) {
      log <- suppressWarnings(system2(
        executable, args = arguments, stdout = TRUE, stderr = TRUE))
      status <- attr(log, "status")
      if (is.null(status)) status <- 0L
      if (status != 0L) fail(paste0(
        "Command failed (", status, "): ", executable, "\n",
        paste(tail(log, 25L), collapse = "\n")))
      return(log)
    }
    # When stdout is a file path, system2 returns a status integer.
    if (is.character(output) && length(output) == 1L) {
      status <- suppressWarnings(system2(
        executable, args = arguments, stdout = output,
        stderr = if (is.null(error_file)) "" else error_file))
    } else {
      status <- suppressWarnings(system2(
        executable, args = arguments, stdout = "", stderr = ""))
    }
    if (!identical(as.integer(status), 0L)) {
      details <- if (!is.null(error_file) && file.exists(error_file))
        tail(readLines(error_file, warn = FALSE), 25L) else character()
      fail(paste0("Command failed (", status, "): ", executable,
                  "\n", paste(details, collapse = "\n")))
    }
    invisible(status)
  }
  require_nonempty <- function(paths) {
    missing <- paths[!file.exists(paths)]
    if (length(missing)) fail(paste(
      "Missing required input files:", paste(missing, collapse = ", ")))
    empty <- paths[file.info(paths)$size <= 0 | is.na(file.info(paths)$size)]
    if (length(empty)) fail(paste("Empty files:", paste(empty, collapse = ", ")))
    invisible(TRUE)
  }

  sevenzip <- binary(c("7zz", "7z"))
  exporter <- binary("mdb-export")
  downloader <- binary("curl")
  sha256 <- binary("sha256sum")
  rscript <- binary("Rscript")
  source_sha <- "92c5f6162323eb08cee9d51463814542f9a12367"
  source_url <- paste0(
    "https://raw.githubusercontent.com/aliye-nezhad/",
    "household-catastrophic-health-expenditure-R/",
    source_sha, "/data/raw")

  dir.create("reproduced", showWarnings = FALSE)
  work <- tempfile(".work-", tmpdir = normalizePath("reproduced"))
  dir.create(work, mode = "0700")
  on.exit(unlink(work, recursive = TRUE, force = TRUE), add = TRUE)
  raw_dir <- file.path(work, "raw")
  input_dir <- file.path(work, "inputs")
  result_dir <- file.path(work, "results")
  for (path in c(raw_dir, input_dir, result_dir)) dir.create(path)
  archives <- c("93.rar", "R93.rar", "U93.rar")

  for (name in archives) {
    destination <- file.path(raw_dir, name)
    cat("Downloading verified source:", name, "\n")
    run(downloader, c(
      "--fail", "--location", "--silent", "--show-error", "--retry", "3",
      shQuote(paste0(source_url, "/", name)), "--output", shQuote(destination)))
  }
  require_nonempty(file.path(raw_dir, archives))
  checksum_lines <- readLines("data/source_sha256.txt", warn = FALSE)
  checksum_parts <- strsplit(trimws(checksum_lines), "[[:space:]]+")
  expected <- setNames(
    vapply(checksum_parts, function(x) x[[1L]], character(1L)),
    basename(vapply(checksum_parts, function(x) x[[2L]], character(1L))))
  assert(all(archives %in% names(expected)),
         "Incomplete source checksum manifest")
  for (name in archives) {
    actual <- substr(run(sha256, shQuote(file.path(raw_dir, name)))[[1L]],
                     1L, 64L)
    assert(identical(tolower(actual), tolower(expected[[name]])),
           paste("SHA-256 mismatch:", name))
    cat("SHA-256 verified:", name, "\n")
  }

  for (name in archives) {
    run(sevenzip, c("e", shQuote(file.path(raw_dir, name)),
                    paste0("-o", shQuote(input_dir)), "-y"))
  }
  database <- file.path(input_dir, "93.mdb")
  require_nonempty(c(database, file.path(input_dir, "R93.xls"),
                     file.path(input_dir, "U93.xls")))

  tables <- c(
    "R93Data", "U93Data", "R93P3S13", "U93P3S13",
    "R93P3S03", "U93P3S03", "R93P3S05", "U93P3S05",
    "R93P3S07", "U93P3S07", "R93P3S08", "U93P3S08",
    "R93P3S09", "U93P3S09", "R93P3S11", "U93P3S11")
  for (table in tables) {
    csv <- file.path(input_dir, paste0(table, ".csv"))
    err <- file.path(work, "mdb-export.stderr.txt")
    run(exporter, c(shQuote(database), shQuote(table)),
        output = csv, error_file = err)
    require_nonempty(csv)
  }
  scripts <- c(
    "code/analysis.R", "code/extended_analysis.R",
    "code/measurement_sensitivity.R", "code/write_research_note.R",
    "code/validate.R")
  for (script in scripts) {
    cat("Running:", script, "\n")
    arguments <- c("--vanilla", shQuote(script),
                   shQuote(input_dir), shQuote(result_dir))
    if (identical(script, "code/write_research_note.R") ||
        identical(script, "code/validate.R")) {
      arguments <- c("--vanilla", shQuote(script), shQuote(result_dir))
    }
    run(rscript, arguments, output = FALSE)
  }

  code_files <- c("pixi.lock", scripts, "scripts/reproduce.R")
  hashes <- run(sha256, vapply(c(file.path(raw_dir, archives), code_files),
                               shQuote, character(1L)))
  dir.create(file.path(result_dir, "diagnostics"), showWarnings = FALSE)
  writeLines(c(paste("Source Git commit:", source_sha), hashes),
             file.path(result_dir, "diagnostics", "input_hashes.txt"))
  run_directory <- file.path(
    root, "reproduced",
    sprintf("run-%s-%d", format(Sys.time(), "%Y%m%dT%H%M%SZ",
                               tz = "UTC"), Sys.getpid()))
  assert(file.rename(result_dir, run_directory),
         "Could not preserve validated analysis outputs")

  show_csv <- function(label, path, max_lines = Inf) {
    cat("--- ", label, " ---\n", sep = "")
    lines <- readLines(file.path(run_directory, path), warn = FALSE)
    if (is.finite(max_lines)) lines <- head(lines, max_lines)
    cat(paste(lines, collapse = "\n"), "\n", sep = "")
  }
  cat("Validated results:", run_directory, "\n")
  show_csv("Matched analytical sample", "diagnostics/sample_linkage.csv")
  show_csv("Weighted loan-reporting rates",
           "tables/reported_loan_entries_by_residence.csv")
  show_csv("Annual durable-purchase associations",
           "tables/annual_durable_purchase_associations.csv")
  show_csv("Leave-out expenditure sensitivity",
           "tables/leaveout_primary_robustness.csv")
  show_csv("Loan reporting groups",
           "tables/exclusive_loan_reporting_groups.csv")
  show_csv("Selected model coefficients",
           "tables/regression_coefficients.csv", 15L)
  invisible(run_directory)
}

main()
