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
  # https://developer.garmin.com/downloads/connect-iq/sdks/sdks.json
  buildId = "2026-06-09-92a1605b2";
  withNativeTools = stdenvNoCC.hostPlatform.isx86_64;
in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "connectiq-sdk";
  version = "9.2.0";

  outputs = [
    "out"
    "doc"
  ];

  src = fetchzip {
    url = "https://developer.garmin.com/downloads/connect-iq/sdks/connectiq-sdk-lin-${finalAttrs.version}-${buildId}.zip";
    hash = "sha256-SIiEE71WhEcg67JmT4iuKYfe/gbBVi35I1XPd/3xKlo=";
    stripRoot = false;
  };

  strictDeps = true;
  nativeBuildInputs = [
    makeWrapper
    dos2unix
  ]
  ++ lib.optionals withNativeTools [
    autoPatchelfHook
    wrapGAppsHook3
  ];
  buildInputs = [
    bashNonInteractive
  ] ++ lib.optionals withNativeTools [
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
  ''
  + lib.optionalString (!withNativeTools) ''
    # Garmin only ships these tools as x86-64 ELF executables
    rm -f \
      "$out"/bin/connectiq \
      "$out"/bin/monkeymotion \
      "$out"/bin/shell \
      "$out"/bin/simulator
  ''
  + ''
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
  preFixup =
    lib.optionalString withNativeTools ''
      wrapGApp "$out"/bin/monkeymotion
      wrapGApp "$out"/bin/simulator
    ''
    + ''
      for file in "$out"/bin/*; do
        [ -f "$file" ] && isScript "$file" || continue

        wrapperArgs=()
        ${lib.optionalString withNativeTools ''
          if [ "''${file##*/}" = era ]; then
            wrapperArgs+=("''${gappsWrapperArgs[@]}")
          fi
        ''}
        wrapProgramShell "$file" \
          "''${wrapperArgs[@]}" \
          --prefix PATH : '${lib.makeBinPath [ coreutils ]}' \
          --run ". $out/libexec/setup-writable-sdk-bin"
      done

      mv "$out"/bin/generateOptimizedYUV.py "$out"/libexec/generateOptimizedYUV.py
      makeShellWrapper '${lib.getExe' python2 "python2"}' "$out"/bin/generateOptimizedYUV.py \
        --add-flag "$out"/libexec/generateOptimizedYUV.py \
        --prefix PATH : '${lib.makeBinPath [ ffmpeg ]}'
    '';

  meta = {
    description = "Garmin Connect IQ SDK";
    homepage = "https://developer.garmin.com/connect-iq";
    license = lib.licenses.unfree;
    sourceProvenance =
      with lib.sourceTypes;
      [
        binaryBytecode
      ]
      ++ lib.optionals withNativeTools [
        binaryNativeCode
      ];
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
    mainProgram = "monkeyc";
  };
})
