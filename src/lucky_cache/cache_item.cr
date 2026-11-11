module LuckyCache
  struct CacheItem
    getter value : CacheableTypes
    getter expires_in : Time::Span
    private getter expiration : Time

    def initialize(@value : CacheableTypes, @expires_in : Time::Span)
      @expiration = @expires_in.from_now
    end

    def initialize(@value : CacheableTypes, @expires_in : Time::Span, @expiration : Time)
    end

    protected def with_value(value : CacheableTypes) : CacheItem
      CacheItem.new(value, expires_in, expiration)
    end

    def expired?
      expiration < Time.utc
    end
  end
end
