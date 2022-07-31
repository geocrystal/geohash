# geohash

[![Crystal CI](https://github.com/geocrystal/geohash/actions/workflows/crystal.yml/badge.svg)](https://github.com/geocrystal/geohash/actions/workflows/crystal.yml)
[![License](https://img.shields.io/github/license/geocrystal/geohash.svg)](https://github.com/geocrystal/geohash/blob/master/LICENSE)
[![GitHub release](https://img.shields.io/github/release/geocrystal/geohash.svg)](https://github.com/geocrystal/geohash/releases)

GeoHash encode/decode library for pure Crystal.

A [geohash](https://en.wikipedia.org/wiki/Geohash) is a convenient way of expressing a location (anywhere in the world)
using a short alphanumeric string, with greater precision obtained with longer strings.

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     geohash:
       github: geocrystal/geohash
   ```

2. Run `shards install`

## Usage

```crystal
require "geohash"

Geohash.encode(48.669, -4.329, 5) # => "gbsuv"
Geohash.decode("gbsuv") # => {lat: 48.669, lng: -4.329}

Geohash.neighbors("gbsuv")
# =>{n: "gbsvj", ne: "gbsvn", e: "gbsuy", se: "gbsuw", s: "gbsut", sw: "gbsus", w: "gbsuu", nw: "gbsvh"}
#
# Neighbors:
# gbsvh	gbsvj gbsvn
# gbsuu	gbsuv gbsuy
# gbsus	gbsut gbsuw

Geohash.bounds("gbsuv")
# => {sw: {lat: 48.6474609375, lng: -4.3505859375}, ne: {lat: 48.69140625, lng: -4.306640625}}
```

![alt text](/assets/screenshot.png)

<https://www.movable-type.co.uk/scripts/geohash.html>

## Contributing

1. Fork it (<https://github.com/geocrystal/geohash/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Anton Maminov](https://github.com/mamantoha) - creator and maintainer
