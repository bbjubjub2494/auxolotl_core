{ lib, fetchFromGitForge }:

lib.makeOverridable (
{ owner, repo, rev
, name ? null # Override with null to use the default value
, pname ? "source-${githubBase}-${owner}-${repo}"
, fetchSubmodules ? false, leaveDotGit ? null
, deepClone ? false, private ? false, forceFetchGit ? false
, sparseCheckout ? []
, githubBase ? "github.com"
, passthru ? { }
, meta ? { }
, ... # For hash agility
}@args:

let
  baseUrl = "https://${githubBase}/${owner}/${repo}";
  gitRepoUrl = "${baseUrl}.git";
  url = "${baseUrl}/archive/${rev}.tar.gz";
  passthruAttrs = removeAttrs args [ "owner" "repo" "rev" "fetchSubmodules" "forceFetchGit" "githubBase" "varPrefix" ];
in
fetchFromGitForge {
  inherit owner repo rev name pname baseUrl gitRepoUrl url fetchSubmodules leaveDotGit deepClone forceFetchGit sparseCheckout passthruAttrs passthru meta;
})
