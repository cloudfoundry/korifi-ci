retry() {
  until $@; do
    echo -n .
    sleep 1
  done
  echo
}
