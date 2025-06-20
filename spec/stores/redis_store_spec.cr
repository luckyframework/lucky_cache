require "../spec_helper"
require "redis"

describe LuckyCache::RedisStore do
  describe "#fetch" do
    it "raises error for custom cachable objects" do
      redis_client = Redis::Client.new
      cache = LuckyCache::RedisStore.new(redis_client)
      cache.flush

      expect_raises(ArgumentError, "RedisStore cannot serialize custom Cachable objects") do
        cache.write("user") { User.new("test@example.com") }
      end

      cache.flush
    end

    it "caches basic types" do
      redis_client = Redis::Client.new
      cache = LuckyCache::RedisStore.new(redis_client)
      cache.flush

      str = cache.fetch("string:key", as: String) { "test" }
      int = cache.fetch("int:key", as: Int64) { 0_i64 }
      bul = cache.fetch("bool:key", as: Bool) { false }
      tym = cache.fetch("time:key", as: Time) { Time.local(1999, 10, 31, 18, 30) }

      str.should eq("test")
      int.should eq(0_i64)
      bul.should eq(false)
      tym.should eq(Time.local(1999, 10, 31, 18, 30))

      cache.flush
    end

    it "caches arrays of basic types" do
      redis_client = Redis::Client.new
      cache = LuckyCache::RedisStore.new(redis_client)
      cache.flush

      str_array = cache.fetch("strings", as: Array(String)) { ["hello", "world"] }
      int_array = cache.fetch("ints", as: Array(Int32)) { [1, 2, 3] }
      bool_array = cache.fetch("bools", as: Array(Bool)) { [true, false, true] }

      str_array.should eq(["hello", "world"])
      int_array.should eq([1, 2, 3])
      bool_array.should eq([true, false, true])

      cache.flush
    end

    it "expires at the specified time" do
      redis_client = Redis::Client.new
      cache = LuckyCache::RedisStore.new(redis_client)
      cache.flush

      Timecop.freeze(Time.local(2042, 3, 17, 21, 49)) do
        cache.fetch("coupon", expires_in: 2.seconds, as: UUID) do
          UUID.random
        end
        cache.read("coupon").not_nil!.expired?.should eq(false)

        sleep 3.seconds
        cache.read("coupon").should eq(nil)
      end

      cache.flush
    end
  end

  describe "#read" do
    it "returns nil when no key is found" do
      redis_client = Redis::Client.new
      cache = LuckyCache::RedisStore.new(redis_client)
      cache.flush

      cache.read("key").should eq(nil)

      cache.flush
    end

    it "returns nil when the item is expired" do
      redis_client = Redis::Client.new
      cache = LuckyCache::RedisStore.new(redis_client)
      cache.flush

      cache.write("key", expires_in: 1.second) { "some data" }
      sleep 2.seconds
      cache.read("key").should eq(nil)

      cache.flush
    end
  end

  describe "#delete" do
    it "returns nil when no item exists" do
      redis_client = Redis::Client.new
      cache = LuckyCache::RedisStore.new(redis_client)
      cache.flush

      cache.delete("key").should eq(nil)

      cache.flush
    end

    it "deletes the value from cache" do
      redis_client = Redis::Client.new
      cache = LuckyCache::RedisStore.new(redis_client)
      cache.flush

      cache.write("key") { 123 }
      cache.read("key").should_not be_nil
      cache.delete("key")
      cache.read("key").should be_nil

      cache.flush
    end
  end

  describe "#flush" do
    it "resets all of the cache" do
      redis_client = Redis::Client.new
      cache = LuckyCache::RedisStore.new(redis_client)
      cache.flush

      cache.write("numbers") { 123 }
      cache.write("letters") { "abc" }
      cache.write("false") { true }
      cache.read("numbers").should_not be_nil
      cache.read("letters").should_not be_nil
      cache.read("false").should_not be_nil

      cache.flush

      cache.read("numbers").should be_nil
      cache.read("letters").should be_nil
      cache.read("false").should be_nil
    end
  end

  describe "#size" do
    it "returns the total number of items in the cache" do
      redis_client = Redis::Client.new
      cache = LuckyCache::RedisStore.new(redis_client)
      cache.flush

      cache.size.should eq(0)

      cache.write("numbers") { 123 }
      cache.write("letters") { "abc" }
      cache.size.should eq(2)

      cache.flush
      cache.size.should eq(0)
    end
  end

  describe "with custom prefix" do
    it "uses the custom prefix for keys" do
      redis_client = Redis::Client.new
      cache = LuckyCache::RedisStore.new(redis_client, prefix: "myapp:")
      cache.flush

      cache.write("test") { "value" }

      redis_client.keys("myapp:*").size.should eq(1)
      redis_client.get("myapp:test").should_not be_nil

      cache.flush
    end
  end

  describe "#write" do
    it "supports JSON::Any values" do
      redis_client = Redis::Client.new
      cache = LuckyCache::RedisStore.new(redis_client)
      cache.flush

      json = JSON.parse(%({"name": "test", "count": 42}))
      cache.write("json_data") { json }

      result = cache.read("json_data")
      result.should_not be_nil
      result.not_nil!.value.as(JSON::Any)["name"].as_s.should eq("test")
      result.not_nil!.value.as(JSON::Any)["count"].as_i.should eq(42)

      cache.flush
    end

    it "stores UUID values" do
      redis_client = Redis::Client.new
      cache = LuckyCache::RedisStore.new(redis_client)
      cache.flush

      uuid = UUID.random
      cache.write("uuid_key") { uuid }

      result = cache.read("uuid_key")
      result.should_not be_nil
      result.not_nil!.value.as(UUID).should eq(uuid)

      cache.flush
    end
  end
end

# Define User class only for error testing
class User
  include LuckyCache::Cachable
  property email : String

  def initialize(@email : String)
  end
end
