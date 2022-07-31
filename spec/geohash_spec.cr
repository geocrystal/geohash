require "./spec_helper"

describe Geohash do
  it "#decode" do
    Geohash.decode("u120fxw").should eq({lat: 52.205, lng: 0.1188})
  end

  it "#encode" do
    Geohash.encode(52.205, 0.119, 7).should eq("u120fxw")
  end

  it "#bounds" do
    Geohash.bounds("u120fxw").should eq(
      {sw: {lat: 52.20428466796875, lng: 0.11810302734375}, ne: {lat: 52.205657958984375, lng: 0.119476318359375}}
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
