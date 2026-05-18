{
  lib,
  stdenvNoCC,
  fetchzip,

  autoPatchelfHook,
  makeWrapper,
  wrapGAppsHook3,
  dos2unix,

  bashNonInteractive,
  coreutils,
  ffmpeg,
  jre,
  libjpeg8,
  python2,
  xorg,
  webkitgtk_4_0,
}:

let
  buildId = "2026-03-09-6a872a80b";
in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "connectiq-sdk";
  version = "9.1.0";

  outputs = [
    "out"
    "doc"
  ];

  src = fetchzip {
    url = "https://developer.garmin.com/downloads/connect-iq/sdks/connectiq-sdk-lin-${finalAttrs.version}-${buildId}.zip";
    hash = "sha256-YIQJ8TFlOwYotsY8JD/UrJjG3z9dZhn0eD80V4K+/XE=";
  };

  strictDeps = true;
  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
    wrapGAppsHook3
    dos2unix
  ];
  buildInputs = [
    bashNonInteractive
    libjpeg8
    xorg.libXxf86vm
    webkitgtk_4_0
  ];

  dontStrip = true;

  installPhase = ''
    runHook preInstall

    mkdir -p "$out"
    cp -r bin share "$out"

    mkdir -p "$doc/share/doc/${finalAttrs.pname}"
    cp -r *.html doc "$doc/share/doc/${finalAttrs.pname}"
    cp -r samples "$doc/share/doc/${finalAttrs.pname}/examples"
    cp -rn resources/. "$doc/share/doc/${finalAttrs.pname}/doc/resources"

    runHook postInstall
  '';

  postInstall = ''
    rm -f "$out"/bin/*.bat
    chmod +x "$out"/bin/monkeym
    dos2unix -e "$out"/bin/monkeygraph

    for file in "$out"/bin/*; do
      [ -f "$file" ] && isScript "$file" || continue
      substituteInPlace "$file" \
        --replace-warn 'java ' '${lib.getExe jre} ' \
        --replace-fail '$( cd "$( dirname "$0" )" && pwd )' "\''${MB_HOME:-$out/bin}"
    done

    rm -f "$out"/share/monkeymotion/monkeybrains.jar
    rmdir --ignore-fail-on-non-empty "$out"/share/monkeymotion

    install -D ${./setup-writable-sdk-bin.sh} "$out"/libexec/setup-writable-sdk-bin
    substituteInPlace "$out"/libexec/setup-writable-sdk-bin \
      --subst-var-by storeRoot "$out"
  '';

  dontWrapGApps = true;
  preFixup = ''
    wrapGApp "$out"/bin/monkeymotion
    wrapGApp "$out"/bin/simulator

    wrapProgramShell "$out"/bin/era \
      "''${gappsWrapperArgs[@]}" \
      --prefix PATH : '${lib.makeBinPath [ coreutils ]}' \
      --run ". $out/libexec/setup-writable-sdk-bin"

    for file in "$out"/bin/*; do
      [ -f "$file" ] && isScript "$file" || continue
      [ "''${file##*/}" = era ] && continue
      wrapProgramShell "$file" \
        --prefix PATH : '${lib.makeBinPath [ coreutils ]}' \
        --run ". $out/libexec/setup-writable-sdk-bin"
    done

    mv "$out"/bin/generateOptimizedYUV.py "$out"/bin/.generateOptimizedYUV.py-wrapped
    makeShellWrapper '${lib.getExe' python2 "python2"}' "$out"/bin/generateOptimizedYUV.py \
      --add-flag "$out"/bin/.generateOptimizedYUV.py-wrapped \
      --prefix PATH : '${lib.makeBinPath [ ffmpeg ]}'
  '';

  meta = {
    description = "Garmin Connect IQ SDK";
    homepage = "https://developer.garmin.com/connect-iq";
    license = lib.licenses.unfree;
    sourceProvenance = with lib.sourceTypes; [
      binaryBytecode
      binaryNativeCode
    ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "monkeyc";
  };
})
