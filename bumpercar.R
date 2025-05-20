# tools/bumpercar.R

library(desc)
library(remotes)

# --- 1. Get DESCRIPTION path from argument or env ---
args <- commandArgs(trailingOnly = TRUE)
desc_path <- if (length(args) > 0) args[1] else
    Sys.getenv("INPUT_PATH", unset = "DESCRIPTION")

message(sprintf("[bumpercar] Using DESCRIPTION file at: %s", desc_path))

# --- FileFetcher: Fetch available CRAN packages ---
FileFetcher <- function() {
    available.packages()
}

# --- FileParser: Read and parse DESCRIPTION file ---
FileParser <- function(path) {
    desc::desc(file = path)
}

# --- UpdateChecker: Check and determine updated dependencies ---
UpdateChecker <- function(deps, ap) {
    updates <- list()
    for (i in seq_len(nrow(deps))) {
        pkg <- deps$package[i]
        type <- deps$type[i]
        current_version_spec <- deps$version[i]

        if (pkg == "R" || !pkg %in% rownames(ap)) next

        try(
            {
                latest_version <- ap[pkg, "Version"]

                # If there is no version specification, set to the latest version
                if (current_version_spec == "*" || current_version_spec == "") {
                    updates[[length(updates) + 1]] <- list(
                        pkg = pkg,
                        type = type,
                        version = paste0(">= ", latest_version),
                        msg = sprintf(
                            "%s: set version to >= %s",
                            pkg,
                            latest_version
                        )
                    )
                    next
                }

                # Extract version number from spec (e.g., ">= 1.1.0")
                version_match <- regmatches(
                    current_version_spec,
                    regexpr("[0-9]+(\\.[0-9]+)*", current_version_spec)
                )
                if (length(version_match) == 0) next

                current_version <- package_version(version_match)
                latest_version_parsed <- package_version(latest_version)

                if (
                    current_version[[1]][1] == latest_version_parsed[[1]][1] &&
                        latest_version_parsed > current_version
                ) {
                    updates[[length(updates) + 1]] <- list(
                        pkg = pkg,
                        type = type,
                        version = paste0(">= ", latest_version),
                        msg = sprintf(
                            "%s: upgraded from >= %s to >= %s",
                            pkg,
                            as.character(current_version),
                            latest_version
                        )
                    )
                }
            },
            silent = TRUE
        )
    }
    updates
}

# --- FileUpdater: Apply updates to DESCRIPTION file ---
FileUpdater <- function(d, updates) {
    for (u in updates) {
        d$set_dep(u$pkg, type = u$type, version = u$version)
        message(u$msg)
    }
    d
}

# --- Main flow ---
ap <- FileFetcher()
d <- FileParser(desc_path)
deps <- d$get_deps()
updates <- UpdateChecker(deps, ap)
d <- FileUpdater(d, updates)
d$write(file = desc_path)
