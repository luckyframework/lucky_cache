require "splay_tree_map"
require "habitat"
require "uuid"
require "json"
require "./lucky_cache/cachable"
require "./lucky_cache/cache_item"
require "./lucky_cache/stores/*"
require "./lucky_cache/*"

module LuckyCache
  VERSION = "0.1.1"

  Habitat.create do
    setting storage : LuckyCache::BaseStore = LuckyCache::NullStore.new
    setting default_duration : Time::Span = 1.minute
  end

  alias CachableTypes = Cachable | Array(Cachable) | String | Array(String) | Int32 | Array(Int32) | Int64 | Array(Int64) | Float64 | Array(Float64) | Bool | Array(Bool) | Time | UUID | JSON::Any
end
