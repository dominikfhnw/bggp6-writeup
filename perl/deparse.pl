sub DESTROY {
    bless([]);
}
die($=, bless([]));
