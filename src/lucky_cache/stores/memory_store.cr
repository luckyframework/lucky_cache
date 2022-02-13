module LuckyCache
  struct MemoryStore < BaseStore
    private getter cache : SplayTreeMap(CacheKey, CacheItem)

    def initialize
      @cache = SplayTreeMap(CacheKey, CacheItem).new
    end

    # Returns the `CacheItem` or nil if the `key` is not found.
    # If the key is found, but the item is expired, it returns nil.
    def read(key : CacheKey) : CacheItem?
      if item = cache[key]?
        item.expired? ? nil : item
      end
    end

    # Adds the block value to the `cache`. Returns the block value
    def write(key : CacheKey, *, expires_in : Time::Span = LuckyCache.settings.default_duration, &)
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

    # Deletes `key` from the cache
    def delete(key : CacheKey)
      cache.delete(key)
    end

    # Completely clears all cache keys
    def flush : Nil
      cache.clear
    end

    # If the `CacheItem` exists, it will map the `Array(Cachable)`
    # in to `Array(T)`. If no item is found, write the block value
    # and return the block value
    def fetch(key : CacheKey, *, as : Array(T).class, expires_in : Time::Span = LuckyCache.settings.default_duration, &) forall T
      if cache_item = read(key)
        new_array = Array(T).new
        cache_item.value.as(Array(LuckyCache::Cachable)).each { |v| new_array << v.as(T) }
        new_array
      else
        write(key, expires_in: expires_in) { yield }
      end
    end

    # If the `CacheItem` exists, it will cast the `Cachable`
    # in to `T`. If no item is found, write the block value
    # and return the block value
    def fetch(key : CacheKey, *, as : T.class, expires_in : Time::Span = LuckyCache.settings.default_duration, &) forall T
      if cache_item = read(key)
        cache_item.value.as(T)
      else
        write(key, expires_in: expires_in) { yield }
      end
    end

    def size : Int32
      @cache.size
    end
  end
end
