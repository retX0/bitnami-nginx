# Docker Image DIY repo
use this repo to DIY docker image and track upstream to keep itself update.
put the upstream file into upstream directory, and edit sync-and-update.yml

FAQ:
1. `buildx failed with: ERROR: failed to solve: failed to push xx unexpected status from HEAD request to xx: 403 Forbidden`
  chekcout `Package Settings` URL should be `https://github.com/[username]?tab=packages`, make sure you have permission to upload it.
2. `remote: Permission to xxx.git denied to github-actions[bot].`
  go to repo `Settings`, select `Actions`, and make sure your `Workflow permissions` HAVE `Read and write permissions` 