module LuckyCache
  struct MemoryStore < BaseStore
    alias CacheKey = String
    private getter cache : SplayTreeMap(CacheKey, CacheItem)

    def initialize
      @cache = SplayTreeMap(CacheKey, CacheItem).new
    end

    # Returns the `CacheItem` or nil if the `key` is not found
    def read(key : CacheKey) : CacheItem?
      cache[key]?
    end

    # Adds the block value to the `cache`. Returns the block value
    def write(key : CacheKey, expires_in : Time::Span = LuckyCache.settings.default_duration, &)
      data = yield

      if data.is_a?(Array)
        stored_data = [] of Cachable
        data.each { |d| stored_data << d }
      else
        stored_data = data
      end

      cache[key] = CacheItem.new(
        value: stored_data,
        expires_in: expires_in
      )

      data
    end

    # If the `CacheItem` exists, it will map the `Array(Cachable)`
    # in to `Array(T)`. If no item is found, write the block value
    # and return the block value
    def fetch(key : CacheKey, as : Array(T).class, &) forall T
      if cache_item = read(key)
        new_array = Array(T).new
        cache_item.value.as(Array(LuckyCache::Cachable)).each { |v| new_array << v.as(T) }
        new_array
      else
        write(key) { yield }
      end
    end

    # If the `CacheItem` exists, it will cast the `Cachable`
    # in to `T`. If no item is found, write the block value
    # and return the block value
    def fetch(key : CacheKey, as : T.class, &) forall T
      if cache_item = read(key)
        cache_item.value.as(T)
      else
        write(key) { yield }
      end
    end
  end
end
