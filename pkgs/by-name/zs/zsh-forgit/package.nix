{
  stdenvNoCC,
  lib,
  bash,
  coreutils,
  findutils,
  fetchFromGitHub,
  fzf,
  gawk,
  git,
  gnugrep,
  gnused,
  makeWrapper,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "zsh-forgit";
  version = "25.03.0";

  src = fetchFromGitHub {
    owner = "wfxr";
    repo = "forgit";
    tag = finalAttrs.version;
    hash = "sha256-wYCuCxPv3HGEGaze/+an6ZprCtXu5ThsTCwaIquEy3Y=";
  };

  strictDeps = true;

  postPatch = ''
    substituteInPlace forgit.plugin.zsh \
      --replace-fail "\$FORGIT_INSTALL_DIR/bin/git-forgit" "$out/bin/git-forgit"
  '';

  dontBuild = true;

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    install -D bin/git-forgit $out/bin/git-forgit
    install -D completions/_git-forgit $out/share/zsh/site-functions/_git-forgit
    install -D forgit.plugin.zsh $out/share/zsh/${finalAttrs.pname}/forgit.plugin.zsh
    wrapProgram $out/bin/git-forgit \
      --prefix PATH : ${
        lib.makeBinPath [
          bash
          coreutils
          findutils
          fzf
          gawk
          git
          gnugrep
          gnused
        ]
      }

    runHook postInstall
  '';

  meta = with lib; {
    homepage = "https://github.com/wfxr/forgit";
    description = "Utility tool powered by fzf for using git interactively";
    mainProgram = "git-forgit";
    license = licenses.mit;
    maintainers = with maintainers; [ deejayem ];
    platforms = platforms.all;
  };
})
