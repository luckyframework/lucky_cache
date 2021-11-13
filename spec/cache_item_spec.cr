require "./spec_helper"

describe LuckyCache::CacheItem do
  context "when it expires in the future" do
    it "is not expired" do
      item = LuckyCache::CacheItem.new(value: "cheese", expires_in: 1.day)
      item.expired?.should be_false
    end
  end

  context "when it's already past the expiration date" do
    it "is expired" do
      cached_item = Timecop.freeze(Time.local(2021, 1, 1, 1, 1, 1)) do
        item = LuckyCache::CacheItem.new(value: "milk", expires_in: 1.hour)
        item.expired?.should be_false
        item
      end
      # 1 hour later
      Timecop.travel(Time.local(2021, 1, 1, 2, 2, 2)) do
        cached_item.expired?.should be_true
      end
    end
  end
end
