require "redis"
require "json"

module LuckyCache
  struct RedisStore < BaseStore
    private getter redis : Redis::Client
    private getter prefix : String

    def initialize(@redis : Redis::Client = Redis::Client.new, @prefix : String = "lucky_cache:")
    end

    def read(key : CacheKey) : CacheItem?
      prefixed_key = "#{prefix}#{key}"

      if data = redis.get(prefixed_key)
        if cache_item = deserialize_cache_item(data)
          cache_item.expired? ? nil : cache_item
        end
      end
    end

    def write(key : CacheKey, *, expires_in : Time::Span = LuckyCache.settings.default_duration, &)
      data = yield

      # For Redis storage, we need to check if the data is serializable
      # Custom Cachable objects cannot be serialized to JSON without custom serialization logic
      unless serializable?(data)
        raise ArgumentError.new("RedisStore cannot serialize custom Cachable objects. Use MemoryStore for custom objects or store serializable representations (Hash, NamedTuple, JSON::Any).")
      end

      cache_item = CacheItem.new(
        value: data,
        expires_in: expires_in
      )

      prefixed_key = "#{prefix}#{key}"
      serialized = serialize_cache_item(cache_item)

      redis.set(prefixed_key, serialized, ex: expires_in.total_seconds.to_i)

      data
    end

    def delete(key : CacheKey)
      prefixed_key = "#{prefix}#{key}"
      result = redis.del(prefixed_key)
      result > 0 ? result : nil
    end

    def flush : Nil
      keys = redis.keys("#{prefix}*").map(&.to_s)
      redis.del(keys) unless keys.empty?
    end

    def fetch(key : CacheKey, *, as : Array(T).class, expires_in : Time::Span = LuckyCache.settings.default_duration, &) forall T
      if cache_item = read(key)
        case value = cache_item.value
        when Array
          value.map { |v| v.as(T) }
        else
          raise TypeCastError.new("Expected Array but got #{value.class}")
        end
      else
        write(key, expires_in: expires_in) { yield }
      end
    end

    def fetch(key : CacheKey, *, as : T.class, expires_in : Time::Span = LuckyCache.settings.default_duration, &) forall T
      if cache_item = read(key)
        cache_item.value.as(T)
      else
        write(key, expires_in: expires_in) { yield }
      end
    end

    def size : Int32
      redis.keys("#{prefix}*").size
    end

    private def serializable?(value) : Bool
      case value
      when String, Int32, Int64, Float64, Bool, Time, UUID, JSON::Any
        true
      when Array
        value.all? { |v| serializable?(v) }
      else
        false
      end
    end

    private def serialize_cache_item(item : CacheItem) : String
      value_json = serialize_value(item.value)
      created_at = Time.utc

      {
        "value"      => value_json,
        "expires_in" => item.expires_in.total_seconds,
        "created_at" => created_at.to_rfc3339,
        "type"       => determine_type(item.value),
      }.to_json
    end

    private def deserialize_cache_item(data : String) : CacheItem?
      parsed = JSON.parse(data)

      type_name = parsed["type"].as_s
      value_json = parsed["value"]
      expires_in = Time::Span.new(seconds: parsed["expires_in"].as_f.to_i)
      created_at = Time.parse_rfc3339(parsed["created_at"].as_s)

      # Check if expired based on created_at + expires_in
      if created_at + expires_in < Time.utc
        return nil
      end

      value = deserialize_value(value_json, type_name)

      CacheItem.new(value: value, expires_in: expires_in)
    rescue
      nil
    end

    private def serialize_value(value : CachableTypes) : JSON::Any
      case value
      when String
        JSON::Any.new(value)
      when Int32
        JSON::Any.new(value.to_i64)
      when Int64
        JSON::Any.new(value)
      when Float64
        JSON::Any.new(value)
      when Bool
        JSON::Any.new(value)
      when Time
        JSON::Any.new(value.to_rfc3339)
      when UUID
        JSON::Any.new(value.to_s)
      when JSON::Any
        value
      when Array(String)
        JSON::Any.new(value.map { |v| JSON::Any.new(v) })
      when Array(Int32)
        JSON::Any.new(value.map { |v| JSON::Any.new(v.to_i64) })
      when Array(Int64)
        JSON::Any.new(value.map { |v| JSON::Any.new(v) })
      when Array(Float64)
        JSON::Any.new(value.map { |v| JSON::Any.new(v) })
      when Array(Bool)
        JSON::Any.new(value.map { |v| JSON::Any.new(v) })
      else
        raise ArgumentError.new("Cannot serialize value of type #{value.class}")
      end
    end

    private def deserialize_value(json : JSON::Any, type_name : String) : CachableTypes
      case type_name
      when "String"
        json.as_s
      when "Int32"
        json.as_i
      when "Int64"
        json.as_i64
      when "Float64"
        json.as_f
      when "Bool"
        json.as_bool
      when "Time"
        Time.parse_rfc3339(json.as_s)
      when "UUID"
        UUID.new(json.as_s)
      when "JSON::Any"
        json
      when "Array(String)"
        json.as_a.map(&.as_s)
      when "Array(Int32)"
        json.as_a.map(&.as_i)
      when "Array(Int64)"
        json.as_a.map(&.as_i64)
      when "Array(Float64)"
        json.as_a.map(&.as_f)
      when "Array(Bool)"
        json.as_a.map(&.as_bool)
      else
        raise ArgumentError.new("Cannot deserialize type #{type_name}")
      end
    end

    private def determine_type(value : CachableTypes) : String
      case value
      when String
        "String"
      when Int32
        "Int32"
      when Int64
        "Int64"
      when Float64
        "Float64"
      when Bool
        "Bool"
      when Time
        "Time"
      when UUID
        "UUID"
      when JSON::Any
        "JSON::Any"
      when Array(String)
        "Array(String)"
      when Array(Int32)
        "Array(Int32)"
      when Array(Int64)
        "Array(Int64)"
      when Array(Float64)
        "Array(Float64)"
      when Array(Bool)
        "Array(Bool)"
      else
        "Unknown"
      end
    end
  end
end
