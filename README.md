# health-checker

TODO: Write a description here

## Installation

TODO: Write installation instructions here

## Usage

TODO: Write usage instructions here

## Development

```bash
sentry -b "crystal build ./src/health_checker.cr -o ./bin/health-checker" \
       -r "./bin/health-checker" \
       --run-args "-c conf/dev.yml"
```

```bash
docker run --rm -it -v $(pwd):/workspace -w /workspace \
    crystallang/crystal:latest-alpine \
    shards build --production --static

mv bin/health-checker bin/health-checker-linux
```

## Contributing

1. Fork it (<https://github.com/martinmares/health-checker/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Martin Mareš](https://github.com/martinmares) - creator and maintainer
