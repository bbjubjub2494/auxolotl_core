{ lib, fetchgit, fetchzip }:

{ owner, repo, rev
, baseUrl, gitRepoUrl, url
, pname
, passthruAttrs
, name
, fetchSubmodules, leaveDotGit
, deepClone, forceFetchGit
, sparseCheckout
, passthru
, meta
}@args:

let
  name = if args.name or null != null then args.name
  else "${pname}-${rev}";

  position = (if args.meta.description or null != null
    then builtins.unsafeGetAttrPos "description" args.meta
    else builtins.unsafeGetAttrPos "rev" args
  );
  newPassthru = passthru // {
    inherit rev owner repo;
  };
  newMeta = meta // {
    homepage = meta.homepage or baseUrl;
  } // lib.optionalAttrs (position != null) {
    # to indicate where derivation originates, similar to make-derivation.nix's mkDerivation
    position = "${position.file}:${toString position.line}";
  };
  useFetchGit = fetchSubmodules || (leaveDotGit == true) || deepClone || forceFetchGit || (sparseCheckout != []);


  # We prefer fetchzip in cases we don't need submodules as the hash
  # is more stable in that case.
  fetcher =
    if useFetchGit then fetchgit
    # fetchzip may not be overridable when using external tools, for example nix-prefetch
    else if fetchzip ? override then fetchzip.override { withUnzip = false; }
    else fetchzip;

  fetcherArgs = (if useFetchGit
    then {
      inherit rev deepClone fetchSubmodules sparseCheckout;
      url = gitRepoUrl;
      passthru = newPassthru;
    } // lib.optionalAttrs (leaveDotGit != null) { inherit leaveDotGit; }
    else {
      passthru = newPassthru // {
        inherit gitRepoUrl;
      };
    }
  ) // passthruAttrs // { inherit name; };
in

(fetcher fetcherArgs).overrideAttrs (finalAttrs: previousAttrs: {
  meta = newMeta;
})
