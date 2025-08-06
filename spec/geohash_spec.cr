require "./spec_helper"

describe Geohash do
  it "#encode" do
    Geohash.encode(52.205, 0.119, 7).should eq("u120fxw")
    Geohash.encode(48.669, -4.329).should eq("gbsuv")
    Geohash.encode(40.7178486, -74.0002041).should eq("dr5rsh6wwm0")
  end

  it "#decode" do
    Geohash.decode("gbsuv").should eq({lat: 48.669, lng: -4.329})
    Geohash.decode("u120fxw").should eq({lat: 52.205, lng: 0.1188})
    Geohash.decode("dr5rsh6wwm0").should eq({lat: 40.7178486, lng: -74.0002041})

    # Edge cases
    Geohash.decode("0").should eq({lat: -67.5, lng: -157.5})
    Geohash.decode("z").should eq({lat: 67.5, lng: 157.5})
    Geohash.decode("").should eq({lat: 0.0, lng: 0.0})
  end

  it "#bounds" do
    Geohash.bounds("gbsuv").should eq(
      {sw: {lat: 48.6474609375, lng: -4.3505859375}, ne: {lat: 48.69140625, lng: -4.306640625}}
    )
  end

  it "#neighbors" do
    # gbsvh	gbsvj gbsvn
    # gbsuu	gbsuv gbsuy
    # gbsus	gbsut gbsuw
    Geohash.neighbors("gbsuv").should eq(
      {n: "gbsvj", ne: "gbsvn", e: "gbsuy", se: "gbsuw", s: "gbsut", sw: "gbsus", w: "gbsuu", nw: "gbsvh"}
    )
  end
end
