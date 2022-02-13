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

describe LuckyCache::NullStore do
  describe "#fetch" do
    it "does nothing" do
      cache = LuckyCache::NullStore.new
      counter = 0
      cache.fetch("fred", as: User) do
        counter += 1
        User.new("fred@email.net")
      end
      result = cache.fetch("fred", as: User) do
        counter += 1
        User.new("fred@email.net")
      end

      counter.should eq(2)
      result.should be_a(User)
      result.email.should eq("fred@email.net")
    end

    it "still does nothing" do
      cache = LuckyCache::NullStore.new
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
      counter.should eq(2)
      friends = result.not_nil!
      friends.size.should eq(2)
      friends.map(&.email).should contain("chris@email.net")
    end

    it "can do nothing with other complex types" do
      cache = LuckyCache::NullStore.new
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
      counter.should eq(2)
      friends = result.not_nil!
      friends.size.should eq(2)
      friends.map(&.title).should contain("learn about cash")
    end

    it "does nothing with basic types" do
      cache = LuckyCache::NullStore.new
      str = cache.fetch("string:key", as: String) { "test" }
      int = cache.fetch("int:key", as: Int64) { 0_i64 }
      bul = cache.fetch("bool:key", as: Bool) { false }
      tym = cache.fetch("time:key", as: Time) { Time.local(1999, 10, 31, 18, 30) }

      str.should eq("test")
      int.should eq(0_i64)
      bul.should eq(false)
      tym.should eq(Time.local(1999, 10, 31, 18, 30))
    end
  end

  describe "#read" do
    it "always returns nil because it doesn't cache" do
      cache = LuckyCache::NullStore.new
      cache.read("key").should eq(nil)
      cache.write("key", expires_in: 1.minute) { "some data" }
      cache.read("key").should eq(nil)
    end
  end

  describe "#delete" do
    it "always returns nil because there's nothing to delete" do
      cache = LuckyCache::NullStore.new
      cache.delete("key").should eq(nil)
      cache.write("key", expires_in: 1.minute) { "some data" }
      cache.delete("key").should eq(nil)
    end
  end

  describe "#flush" do
    it "does nothing" do
      cache = LuckyCache::NullStore.new
      cache.responds_to?(:flush).should eq(true)
    end
  end

  describe "#size" do
    it "returns 0 because it doesn't really cache anything" do
      cache = LuckyCache::NullStore.new
      cache.size.should eq(0)

      cache.write("numbers") { 123 }
      cache.write("letters") { "abc" }
      cache.size.should eq(0)

      cache.flush
      cache.size.should eq(0)
    end
  end
end
