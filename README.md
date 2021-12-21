# mdpull

Command line app to pull Opensea style NFT metadata

```
OVERVIEW: Command line app to pull Opensea style NFT metadata

USAGE: mdpull <arg-id> [--num-tokens <num-tokens>] [--output-filename <output-filename>] [--use-dune-format]

ARGUMENTS:
  <arg-id>                IPFS Arg Id

OPTIONS:
  -n, --num-tokens <num-tokens>
                          Number of tokens (default: 10)
  -o, --output-filename <output-filename>
                          Output filename
  -u, --use-dune-format   Use Dune table format
  -h, --help              Show help information.
```

### Notes

* Mac only
* Command line only

### Developer Commands

`swift build` Builds app to the `.build` folder

`swift build -c release` Build a release version

`./.build/debug/mdpull` Runs app after building

`swift run mdpull` Runs app directly
