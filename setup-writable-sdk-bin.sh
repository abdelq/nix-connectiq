store_root='@storeRoot@'
store_bin="$store_root/bin"
store_name="${store_root##*/}"

for dir in "${XDG_RUNTIME_DIR:-}" "${TMPDIR:-/tmp}"; do
  [ -n "$dir" ] || continue
  cache_root="$dir/$store_name-$UID"
  cache_bin="$cache_root/bin"
  if mkdir -p "$cache_bin" 2>/dev/null; then
    break
  fi
done

for path in "$store_bin"/*; do
  [ -e "$path" ] || continue
  name="${path##*/}"
  if [ "$name" != monkeybrains.jar ]; then
    ln -sfn "$path" "$cache_bin/$name"
  fi
done

if [ ! -f "$cache_bin/monkeybrains.jar" ]; then
  cp "$store_bin/monkeybrains.jar" "$cache_bin/monkeybrains.jar"
  chmod u+w "$cache_bin/monkeybrains.jar"
fi

export MB_HOME="$cache_bin"
