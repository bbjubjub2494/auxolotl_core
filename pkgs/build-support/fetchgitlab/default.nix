{ lib, fetchgit, fetchzip }:

lib.makeOverridable (
{ owner, repo, rev
, name ? null # Override with null to use the default value
, pname ? lib.concatStringsSep "-" ([ "source" domain ] ++ (lib.optional (group != null) group) ++ [ owner repo ])
, fetchSubmodules ? false, leaveDotGit ? null
, deepClone ? false, forceFetchGit ? false
, sparseCheckout ? []
, protocol ? "https", domain ? "gitlab.com", group ? null
, passthru ? { }
, meta ? { }
, ... # For hash agility
}@args:

let
  name = if args.name or null != null then args.name
  else "${pname}-${rev}";

  position = (if args.meta.description or null != null
    then builtins.unsafeGetAttrPos "description" args.meta
    else builtins.unsafeGetAttrPos "rev" args
  );
  baseUrl = "${protocol}://${domain}/${slug}";
  newPassthru = passthru // {
    inherit rev owner repo;
  };
  newMeta = meta // {
    homepage = meta.homepage or baseUrl;
  } // lib.optionalAttrs (position != null) {
    # to indicate where derivation originates, similar to make-derivation.nix's mkDerivation
    position = "${position.file}:${toString position.line}";
  };
  passthruAttrs = removeAttrs args [ "protocol" "domain" "owner" "group" "repo" "rev" "fetchSubmodules" "forceFetchGit" "leaveDotGit" "deepClone" ];
  slug = lib.concatStringsSep "/" ((lib.optional (group != null) group) ++ [ owner repo ]);
  escapedSlug = lib.replaceStrings [ "." "/" ] [ "%2E" "%2F" ] slug;
  escapedRev = lib.replaceStrings [ "+" "%" "/" ] [ "%2B" "%25" "%2F" ] rev;
  useFetchGit = fetchSubmodules || (leaveDotGit == true) || deepClone || forceFetchGit || (sparseCheckout != []);
  # We prefer fetchzip in cases we don't need submodules as the hash
  # is more stable in that case.
  fetcher =
    if useFetchGit then fetchgit
    # fetchzip may not be overridable when using external tools, for example nix-prefetch
    else if fetchzip ? override then fetchzip.override { withUnzip = false; }
    else fetchzip;

  gitRepoUrl = "${baseUrl}.git";

  fetcherArgs = (if useFetchGit
    then {
      inherit rev deepClone fetchSubmodules sparseCheckout; url = gitRepoUrl;
      passthru = newPassthru;
    } // lib.optionalAttrs (leaveDotGit != null) { inherit leaveDotGit; }
    else {
      url = "${protocol}://${domain}/api/v4/projects/${escapedSlug}/repository/archive.tar.gz?sha=${escapedRev}";

      passthru = newPassthru // {
        inherit gitRepoUrl;
      };
    }
  ) // passthruAttrs // { inherit name; };
in

(fetcher fetcherArgs).overrideAttrs (finalAttrs: previousAttrs: {
  meta = newMeta;
})
)
