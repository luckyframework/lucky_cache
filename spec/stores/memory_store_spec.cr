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
  describe "fetch" do
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

    it "can cache other types" do
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
  end
end
