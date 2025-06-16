# SGCRUN - GitHub Self-Hosted Containerized Runner Script

This script launches a temporary self-hosted GitHub Actions runner inside a Docker container using [`summerwind/actions-runner-dind`](https://hub.docker.com/r/summerwind/actions-runner-dind). It is useful for CI/CD workflows that require ephemeral, containerized runners for GitHub organizations.

## Requirements

- Bash
- Docker
- GitHub personal access token for registering runners
- The following CLI tools installed and in your `$PATH`:  
  `basename`, `realpath`, `date`, `echo`, `whoami`, `openssl`, `curl`, `jq`

## Usage

```bash
export SGCRUN_GITHUB_TOKEN="ghp_..."

/bin/bash sgcrun.sh my-org-name
```

## 🧩 Arguments

- `<github-organization>`  
  Required. The GitHub organization where the runner will be registered.

## 📦 Environment Variables

**Required:**

- `SGCRUN_GITHUB_TOKEN`  
  GitHub personal access token with permission to register runners for the organization.

**Optional:**

- `SGCRUN_LOG`  
  Absolute or relative path to a writable log file. If set and the file exists, script output will be appended to it.


## 📝 Logging

You may enable logging by creating a log file and exporting the `SGCRUN_LOG` environment variable:

```bash
touch /tmp/sgcrun.log

export SGCRUN_LOG="/tmp/sgcrun.log"

/bin/bash sgcrun.sh my-org-name
```

All output, including errors, will be written to this file as well as shown in the terminal.

## 🧪 Troubleshooting

- Make sure Docker is running and you have permissions to run `docker` commands.
- The script will exit early if required tools are not available.
- If the GitHub token is invalid or lacks permission, the registration will fail.

## ⚠️ **Warning:**  
The container will be executed with the `--privileged` flag to support Docker-in-Docker (DinD) functionality.   This grants the container extended permissions, which may pose a security risk if used in untrusted environments.  
**Use with caution.**

## License

MIT License © 2025
