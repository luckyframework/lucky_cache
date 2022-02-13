module LuckyCache
  abstract struct BaseStore
    alias CacheKey = String

    abstract def read(key : CacheKey) : CacheItem?

    abstract def write(key : CacheKey, *, expires_in : Time::Span = LuckyCache.settings.default_duration, &)

    abstract def delete(key : CacheKey)

    abstract def flush : Nil

    abstract def fetch(key : CacheKey, *, as : Array(T).class, expires_in : Time::Span = LuckyCache.settings.default_duration, &) forall T

    abstract def fetch(key : CacheKey, *, as : T.class, expires_in : Time::Span = LuckyCache.settings.default_duration, &) forall T

    abstract def size : Int32
  end
end
