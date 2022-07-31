# Geohash encoding/decoding and associated functions
#
# https://en.wikipedia.org/wiki/Geohash
#
# Based on https://github.com/chrisveness/latlon-geohash/blob/master/latlon-geohash.js
module Geohash
  extend self

  VERSION = "0.1.0"

  # Encodes latitude/longitude to geohash, either to specified precision or to automatically
  # evaluated precision.
  #
  # ```
  # Geohash.encode(52.205, 0.119, 7) # => "u120fxw"
  # ```
  def encode(latitude : Float64, longitude : Float64, precision = 12)
    latlng = [latitude, longitude]
    points = [[-90.0, 90.0], [-180.0, 180.0]]
    is_lng = 1

    (0...precision).map {
      ch = 0

      5.times do |bit|
        mid = (points[is_lng][0] + points[is_lng][1]) / 2
        points[is_lng][latlng[is_lng] > mid ? 0 : 1] = mid
        ch |= BITS[bit] if latlng[is_lng] > mid
        is_lng ^= 1
      end

      BASE32[ch, 1]
    }.join
  end

  # Decode geohash to latitude/longitude (location is approximate center of geohash cell,
  # to reasonable precision).
  #
  # ```
  # Geohash.decode('u120fxw') # => {lat: 52.205, lng: 0.1188}
  # ```
  def decode(geohash : String) : NamedTuple(lat: Float64, lng: Float64)
    bounds = Geohash.bounds(geohash)

    lat_min = bounds[:sw][:lat]
    lng_min = bounds[:sw][:lng]
    lat_max = bounds[:ne][:lat]
    lng_max = bounds[:ne][:lng]

    # cell center
    lat = (lat_min + lat_max) / 2
    lng = (lng_min + lng_max) / 2

    # round to close to center without excessive precision: ⌊2-log10(Δ°)⌋ decimal places
    lat = lat.round((2 - Math.log(lat_max - lat_min) / Math::LOG10).floor.to_i)
    lng = lng.round((2 - Math.log(lng_max - lng_min) / Math::LOG10).floor.to_i)

    {lat: lat, lng: lng}
  end

  # Returns SW/NE latitude/longitude bounds of specified geohash.
  def bounds(geohash) : NamedTuple(sw: NamedTuple(lat: Float64, lng: Float64), ne: NamedTuple(lat: Float64, lng: Float64))
    latlng = [[-90.0, 90.0], [-180.0, 180.0]]
    is_lng = 1

    geohash.downcase.each_char do |c|
      BITS.each do |mask|
        latlng[is_lng][(BASE32.index(c).to_s.to_i & mask) == 0 ? 1 : 0] = (latlng[is_lng][0] + latlng[is_lng][1]) / 2
        is_lng ^= 1
      end
    end

    lat_min, lat_max = latlng[0].minmax
    lng_min, lng_max = latlng[1].minmax

    {
      sw: {lat: lat_min, lng: lng_min},
      ne: {lat: lat_max, lng: lng_max},
    }
  end

  # Returns all 8 adjacent cells to specified geohash.
  def neighbors(geohash : String) : NamedTuple(n: String, ne: String, e: String, se: String, s: String, sw: String, w: String, nw: String)
    {
      n:  adjacent(geohash, :n),
      ne: adjacent(adjacent(geohash, :n), :e),
      e:  adjacent(geohash, :e),
      se: adjacent(adjacent(geohash, :s), :e),
      s:  adjacent(geohash, :s),
      sw: adjacent(adjacent(geohash, :s), :w),
      w:  adjacent(geohash, :w),
      nw: adjacent(adjacent(geohash, :n), :w),
    }
  end

  # Determines adjacent cell in given direction.
  #
  # `direction` - Direction from geohash (:n/:s/:e/:w).
  private def adjacent(geohash : String, direction : Symbol) : String
    last_ch = geohash[-1, 1] # last character of hash
    parent = geohash[0...-1] # hash without last character

    type = (geohash.size % 2) == 1 ? :odd : :even

    # check for edge-cases which don't share common prefix
    if BORDERS[direction][type].includes?(last_ch)
      parent = adjacent(parent, direction)
    end

    # append letter for direction to parent
    parent + BASE32.char_at(NEIGHBORS[direction][type].index(last_ch).not_nil!)
  end

  # (geohash-specific) Base32 map
  private BASE32 = "0123456789bcdefghjkmnpqrstuvwxyz"

  private BITS = [0x10, 0x08, 0x04, 0x02, 0x01]

  private NEIGHBORS = {
    n: {even: "p0r21436x8zb9dcf5h7kjnmqesgutwvy", odd: "bc01fg45238967deuvhjyznpkmstqrwx"},
    s: {even: "14365h7k9dcfesgujnmqp0r2twvyx8zb", odd: "238967debc01fg45kmstqrwxuvhjyznp"},
    e: {even: "bc01fg45238967deuvhjyznpkmstqrwx", odd: "p0r21436x8zb9dcf5h7kjnmqesgutwvy"},
    w: {even: "238967debc01fg45kmstqrwxuvhjyznp", odd: "14365h7k9dcfesgujnmqp0r2twvyx8zb"},
  }

  private BORDERS = {
    n: {even: "prxz", odd: "bcfguvyz"},
    s: {even: "028b", odd: "0145hjnp"},
    e: {even: "bcfguvyz", odd: "prxz"},
    w: {even: "0145hjnp", odd: "028b"},
  }
end
