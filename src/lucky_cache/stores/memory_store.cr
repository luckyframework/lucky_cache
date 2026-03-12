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

      # This is because types like `String`, `Int32`, etc... don't include `Cacheable` like a custom type would.
      # In order to support these, we have to account for them separately.
      if data.is_a?(Array(String)) || data.is_a?(Array(Int32)) || data.is_a?(Array(Int64)) || data.is_a?(Array(Float64)) || data.is_a?(Array(Bool))
        stored_data = data
      elsif data.is_a?(Array)
        stored_data = [] of Cacheable
        data.each { |datum| stored_data << datum }
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

    # If the `CacheItem` exists, it will map the `Array(Cacheable)`
    # in to `Array(T)`. If no item is found, write the block value
    # and return the block value
    def fetch(key : CacheKey, *, as : Array(T).class, expires_in : Time::Span = LuckyCache.settings.default_duration, &) forall T
      if cache_item = read(key)
        new_array = Array(T).new
        {% if T < LuckyCache::Cacheable %}
          cache_item.value.as(Array(LuckyCache::Cacheable)).each { |val| new_array << val.as(T) }
        {% else %}
          cache_item.value.as(Array(T)).each { |val| new_array << val }
        {% end %}
        new_array
      else
        write(key, expires_in: expires_in) { yield }
      end
    end

    # If the `CacheItem` exists, it will cast the `Cacheable`
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
