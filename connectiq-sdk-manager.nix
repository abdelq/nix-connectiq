{
  lib,
  stdenvNoCC,
  fetchzip,

  autoPatchelfHook,
  wrapGAppsHook3,

  libjpeg8,
  xorg,
  webkitgtk_4_0,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "connectiq-sdk-manager";
  version = "1.0.16";

  src = fetchzip {
    url = "https://developer.garmin.com/downloads/connect-iq/sdk-manager/connectiq-sdk-manager-linux.zip";
    hash = "sha256-YVDYRRlBAyogZEs7Rhw1IUZfvhFYnkCIOPVYG8it8Xk=";
  };

  strictDeps = true;
  nativeBuildInputs = [
    autoPatchelfHook
    wrapGAppsHook3
  ];
  buildInputs = [
    libjpeg8
    xorg.libXxf86vm
    webkitgtk_4_0
  ];

  dontStrip = true;

  installPhase = ''
    runHook preInstall

    mkdir -p "$out"
    cp -r bin share "$out"

    runHook postInstall
  '';

  meta = {
    description = "Garmin Connect IQ SDK Manager";
    homepage = "https://developer.garmin.com/connect-iq";
    license = lib.licenses.unfree;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "sdkmanager";
  };
})
