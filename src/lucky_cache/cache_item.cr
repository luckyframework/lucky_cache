module LuckyCache
  struct CacheItem
    getter value : CachableTypes
    getter expires_in : Time::Span
    private getter expiration : Time

    def initialize(@value : CachableTypes, @expires_in : Time::Span)
      @expiration = @expires_in.from_now
    end

    def expired?
      expiration < Time.utc
    end
  end
end
