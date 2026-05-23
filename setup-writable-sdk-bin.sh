store_root='@storeRoot@'
store_bin="$store_root/bin"
store_name="${store_root##*/}"

cache_root="${XDG_RUNTIME_DIR:-${TMPDIR:-/tmp}}/$store_name-$UID"
cache_bin="$cache_root/bin"
mkdir -p "$cache_bin"

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
