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
    xorg.libSM
    xorg.libXxf86vm
    webkitgtk_4_0
  ];

  dontStrip = true;

  installPhase = ''
    runHook preInstall

    mkdir -p "$out"
    cp -r bin resources share "$out"

    mkdir -p "$doc/share/doc/${finalAttrs.pname}"
    cp -r *.html doc "$doc/share/doc/${finalAttrs.pname}"
    cp -r samples "$doc/share/doc/${finalAttrs.pname}/examples"

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
        --replace-fail '$( cd "$( dirname "$0" )" && pwd )' "$out"/bin
    done

    rm -f "$out"/share/monkeymotion/monkeybrains.jar
    rmdir --ignore-fail-on-non-empty "$out"/share/monkeymotion

    (
      cd "$TMPDIR"
      '${lib.getExe' jre "jar"}' xf \
        "$out"/bin/monkeybrains.jar \
        com/garmin/monkeybrains/devices/devices.xml
    )
    '${lib.getExe jre}' -classpath "$out"/bin/monkeybrains.jar \
      com.garmin.monkeybrains.jungle.DefaultJungleGenerator \
      -d "$TMPDIR"/com/garmin/monkeybrains/devices/devices.xml \
      -o "$out"/bin
    sed -i "s|^devicesPath = .*|devicesPath = \"$out/resources/device-reference\"|" \
      "$out"/bin/default.jungle
  '';

  dontWrapGApps = true;
  preFixup = ''
    wrapGApp "$out"/bin/monkeymotion
    wrapGApp "$out"/bin/simulator
    wrapProgramShell "$out"/bin/era "''${gappsWrapperArgs[@]}"

    for bin in connectiq monkeydo; do
      wrapProgramShell "$out"/bin/"$bin" \
        --prefix PATH : '${lib.makeBinPath [ coreutils ]}'
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
  };
})
