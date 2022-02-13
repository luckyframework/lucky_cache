module LuckyCache
  struct NullStore < BaseStore
    def read(key : CacheKey) : CacheItem?
      nil
    end

    def write(key : CacheKey, *, expires_in : Time::Span = LuckyCache.settings.default_duration, &)
      yield
    end

    def delete(key : CacheKey)
      nil
    end

    def flush : Nil
      nil
    end

    def fetch(key : CacheKey, *, as : Array(T).class, expires_in : Time::Span = LuckyCache.settings.default_duration, &) forall T
      yield
    end

    def fetch(key : CacheKey, *, as : T.class, expires_in : Time::Span = LuckyCache.settings.default_duration, &) forall T
      yield
    end

    def size : Int32
      0
    end
  end
end
