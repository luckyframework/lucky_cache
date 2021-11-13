require "splay_tree_map"
require "habitat"
require "./lucky_cache/cachable"
require "./lucky_cache/cache_item"
require "./lucky_cache/stores/*"
require "./lucky_cache/*"

module LuckyCache
  VERSION = "0.1.0"

  Habitat.create do
    setting storage : LuckyCache::BaseStore = LuckyCache::NullStore.new
    setting default_duration : Time::Span = 1.minute
  end

  alias CachableTypes = Array(Cachable) | Cachable | String | Int32 | Int64
end
