module LuckyCache
  abstract struct BaseStore
    alias CacheKey = String

    abstract def read(key : CacheKey) : CacheItem?

    abstract def write(key : CacheKey, *, expires_in : Time::Span = 1.second, &)

    abstract def delete(key : CacheKey)

    abstract def fetch(key : CacheKey, *, as : Array(T).class, expires_in : Time::Span = 1.second, &) forall T

    abstract def fetch(key : CacheKey, *, as : T.class, expires_in : Time::Span = 1.second, &) forall T
  end
end
