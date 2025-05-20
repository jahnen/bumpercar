#!/bin/bash
set -e

echo "Running bumpercar to update DESCRIPTION..."
Rscript /usr/local/bin/bumpercar.R
