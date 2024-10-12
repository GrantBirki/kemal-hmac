require "octokit"
require "json"

def github_version_check
  # auth via octokit.cr
  github = Octokit.client

  # fetch info about the crystal-base-template repo
  repo_data = github.get("/repos/GrantBirki/crystal-base-template/commits/main")

  # convert the json string to a hash
  repo_data = JSON.parse(repo_data)

  # print the latest sha of this template repo
  puts "current sha of crystal-base-template: #{repo_data["sha"]}"
end
