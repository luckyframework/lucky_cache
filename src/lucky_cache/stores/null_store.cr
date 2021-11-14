module LuckyCache
  struct NullStore < BaseStore
    def read(key : CacheKey) : CacheItem?
      nil
    end

    def write(key : CacheKey, *, expires_in : Time::Span = 1.second, &)
      yield
    end

    def delete(key : CacheKey)
      nil
    end

    def fetch(key : CacheKey, *, as : Array(T).class, expires_in : Time::Span = 1.second, &) forall T
      yield
    end

    def fetch(key : CacheKey, *, as : T.class, expires_in : Time::Span = 1.second, &) forall T
      yield
    end
  end
end
