require "../spec_helper"

class User
  include LuckyCache::Cachable
  property email : String

  def initialize(@email : String)
  end
end

class Post
  include LuckyCache::Cachable
  property title : String

  def initialize(@title : String)
  end
end

describe LuckyCache::MemoryStore do
  describe "#fetch" do
    it "does both read and write" do
      cache = LuckyCache::MemoryStore.new
      counter = 0
      cache.fetch("fred", as: User) do
        counter += 1
        User.new("fred@email.net")
      end
      result = cache.fetch("fred", as: User) do
        counter += 1
        User.new("fred@email.net")
      end

      counter.should eq(1)
      result.should be_a(User)
      result.email.should eq("fred@email.net")
    end

    it "allows for array of the cache type" do
      cache = LuckyCache::MemoryStore.new
      counter = 0
      cache.fetch("friends", as: Array(User)) do
        counter += 1
        [User.new("fred@email.net"), User.new("chris@email.net")]
      end
      result = cache.fetch("friends", as: Array(User)) do
        counter += 1
        [User.new("fred@email.net"), User.new("chris@email.net")]
      end

      result.should be_a(Array(User))
      counter.should eq(1)
      friends = result.not_nil!
      friends.size.should eq(2)
      friends.map(&.email).should contain("chris@email.net")
    end

    it "can cache other complex types" do
      cache = LuckyCache::MemoryStore.new
      counter = 0
      cache.fetch("blogs", as: Array(Post)) do
        counter += 1
        [Post.new("learn how to cache"), Post.new("learn about cash")]
      end
      result = cache.fetch("blogs", as: Array(Post)) do
        counter += 1
        [Post.new("learn how to cache"), Post.new("learn about cash")]
      end

      result.should be_a(Array(Post))
      counter.should eq(1)
      friends = result.not_nil!
      friends.size.should eq(2)
      friends.map(&.title).should contain("learn about cash")
    end

    it "caches basic types" do
      cache = LuckyCache::MemoryStore.new
      str = cache.fetch("string:key", as: String) { "test" }
      int = cache.fetch("int:key", as: Int64) { 0_i64 }
      bul = cache.fetch("bool:key", as: Bool) { false }
      tym = cache.fetch("time:key", as: Time) { Time.local(1999, 10, 31, 18, 30) }

      str.should eq("test")
      int.should eq(0_i64)
      bul.should eq(false)
      tym.should eq(Time.local(1999, 10, 31, 18, 30))
    end

    it "expires at the specified time" do
      cache = LuckyCache::MemoryStore.new
      Timecop.freeze(Time.local(2042, 3, 17, 21, 49)) do
        cache.fetch("coupon", expires_in: 48.hours, as: UUID) do
          UUID.random
        end
        Timecop.travel(12.hours.from_now) do
          cache.read("coupon").not_nil!.expired?.should eq(false)
        end
        Timecop.travel(35.hours.from_now) do
          cache.read("coupon").not_nil!.expired?.should eq(false)
        end
        Timecop.travel(49.hours.from_now) do
          cache.read("coupon").should eq(nil)
        end
      end
    end
  end

  describe "#read" do
    it "returns nil when no key is found" do
      cache = LuckyCache::MemoryStore.new
      cache.read("key").should eq(nil)
    end

    it "returns nil when the item is expired" do
      cache = LuckyCache::MemoryStore.new
      cache.write("key", expires_in: 1.minute) { "some data" }
      Timecop.travel(90.seconds.from_now) do
        cache.read("key").should eq(nil)
      end
    end
  end

  describe "#delete" do
    it "returns nil when no item exists" do
      cache = LuckyCache::MemoryStore.new
      cache.delete("key").should eq(nil)
    end

    it "deletes the value from cache" do
      cache = LuckyCache::MemoryStore.new
      cache.write("key") { 123 }
      cache.read("key").should_not be_nil
      cache.delete("key")
      cache.read("key").should be_nil
    end
  end

  describe "#flush" do
    it "resets all of the cache" do
      cache = LuckyCache::MemoryStore.new
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
      cache = LuckyCache::MemoryStore.new
      cache.size.should eq(0)

      cache.write("numbers") { 123 }
      cache.write("letters") { "abc" }
      cache.size.should eq(2)

      cache.flush
      cache.size.should eq(0)
    end
  end
end
