# Garmin Connect IQ SDK

## SDK Manager

To download the device library, you will need to use the SDK manager:

```
nix run .#connectiq-sdk-manager
```

When using Nvidia on Wayland, you may need to set `__NV_DISABLE_EXPLICIT_SYNC=1`.

## Developer Key

The compiler requires a developer key to sign apps, to generate one:

```
nix run .#gen-dev-key
```

## Documentation

Documentation and examples are available in the `doc` output:

```
nix build .#connectiq-sdk.doc
```

To compile and run the simulator on such an example:

```
nix run .#connectiq-sdk -- \
    -f ./result-doc/share/doc/connectiq-sdk/examples/Attention/monkey.jungle \
    -o Attention.prg \
    -y developer_key.der
nix shell .#connectiq-sdk -c simulator &
nix shell .#connectiq-sdk -c monkeydo Attention.prg fenix7pro
```
