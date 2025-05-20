FROM rocker/r-ver:latest

# Install R dependencies
RUN R -e "install.packages(c('desc', 'remotes'), repos='https://cloud.r-project.org')"

# Install system dependencies: git, gh CLI
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        git \
        curl \
        gnupg \
        ca-certificates \
        jq && \
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | \
        gpg --dearmor -o /usr/share/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | \
        tee /etc/apt/sources.list.d/github-cli.list > /dev/null && \
    apt-get update && \
    apt-get install -y --no-install-recommends gh && \
    apt-get clean && rm -rf /var/lib/apt/lists/*


# Copy bumpercar code into the container
COPY bumpercar.R /usr/local/bin/bumpercar.R
COPY entrypoint.sh /entrypoint.sh

# Make entrypoint executable
RUN chmod +x /entrypoint.sh

# Set entrypoint
ENTRYPOINT ["/entrypoint.sh"]
