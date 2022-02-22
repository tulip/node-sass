{ fetchFromGitHub }:
fetchFromGitHub {
  owner = "sass";
  repo = "libsass";
  rev = "3.6.5";
  sha256 = "1cxj6r85d5f3qxdwzxrmkx8z875hig4cr8zsi30w6vj23cyds3l2";
  # Remove unicode file names which leads to different checksums on HFS+
  # vs. other filesystems because of unicode normalisation.
  extraPostFetch = ''
    rm -r $out/test/e2e/unicode-pwd
  '';
}
