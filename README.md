# Garmin Connect IQ SDK

## Platform support

The SDK is available on both `x86_64-linux` and `aarch64-linux`.
Garmin ships some programs as x86-64 executables like `simulator`,
so the ARM package omits those. The rest of the core tools in Java
such as `monkeyc` remain available.

## SDK Manager

To download the device library, you will need to use the SDK manager:

```
nix run .#connectiq-sdk-manager
```

> [!NOTE]
> The SDK manager is only available on `x86_64-linux`. \
> When using Nvidia on Wayland, you may need to set `__NV_DISABLE_EXPLICIT_SYNC=1`.

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
