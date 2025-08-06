# Geohash encoding/decoding and associated functions
#
# https://en.wikipedia.org/wiki/Geohash
#
# Based on https://github.com/davetroy/geohash-js/blob/master/geohash.js
module Geohash
  extend self

  VERSION = {{ `shards version #{__DIR__}`.chomp.stringify }}

  # Encodes latitude/longitude to geohash, either to specified precision or to automatically
  # evaluated precision.
  #
  # ```
  # Geohash.encode(48.669, -4.329) # => "gbsuv"
  # ```
  def encode(latitude : Float64, longitude : Float64) : String
    # Calculate precision to use
    lat_decimals = count_significant_decimals(latitude)
    lon_decimals = count_significant_decimals(longitude)
    max_decimals = {lat_decimals, lon_decimals}.max

    # Map decimal places to geohash precision
    # This mapping is based on the relationship between coordinate precision and geohash length
    precision = case max_decimals
                when 0..3 then 5  # ~2.4km precision
                when 4    then 7  # ~76m precision
                when 5    then 9  # ~2.4m precision
                when 6    then 10 # ~60cm precision
                when 7    then 11 # ~15cm precision
                else           12 # ~37mm precision
                end

    encode latitude, longitude, precision
  end

  # Encodes latitude/longitude to geohash, either to specified precision or to automatically
  # evaluated precision.
  #
  # ```
  # Geohash.encode(52.205, 0.119, 7) # => "u120fxw"
  # ```
  def encode(latitude : Float64, longitude : Float64, precision : Int32) : String
    raise ArgumentError.new("Invalid latitude: #{latitude}") unless -90.0 <= latitude <= 90.0
    raise ArgumentError.new("Invalid longitude: #{longitude}") unless -180.0 <= longitude <= 180.0
    raise ArgumentError.new("Precision must be positive") unless precision > 0

    lat_min, lat_max = -90.0, 90.0
    lon_min, lon_max = -180.0, 180.0

    String.build(precision) do |str|
      bits = 0_u8
      bit = 0
      is_even = true

      while str.bytesize < precision
        if is_even # longitude
          mid = (lon_min + lon_max) / 2.0
          if longitude >= mid
            bits |= (1_u8 << (4 - bit))
            lon_min = mid
          else
            lon_max = mid
          end
        else # latitude
          mid = (lat_min + lat_max) / 2.0
          if latitude >= mid
            bits |= (1_u8 << (4 - bit))
            lat_min = mid
          else
            lat_max = mid
          end
        end

        is_even = !is_even
        bit += 1

        if bit == 5
          str << BASE32[bits]
          bits = 0_u8
          bit = 0
        end
      end
    end
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

  @[AlwaysInline]
  private def count_significant_decimals(value : Float64) : Int32
    abs_value = value.abs

    return 0 if (abs_value - abs_value.round).abs < 1e-10

    scaled = abs_value
    epsilon = 1e-9

    # Check up to 10 decimal places
    10.times do |i|
      scaled *= 10.0
      if (scaled - scaled.round).abs < epsilon
        return i + 1
      end
    end

    7
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

  private MAX_PRECISION = 12

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
