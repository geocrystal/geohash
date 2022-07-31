require "./spec_helper"

describe Geohash do
  it "#decode" do
    Geohash.decode("gbsuv").should eq({lat: 48.669, lng: -4.329})
  end

  it "#encode" do
    Geohash.encode(48.669, -4.329, 5).should eq("gbsuv")
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
