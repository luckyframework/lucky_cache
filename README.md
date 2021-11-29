# LuckyCache

Cache content within your Lucky application.

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     lucky_cache:
       github: luckyframework/lucky_cache
   ```

2. Run `shards install`

## Usage

```crystal
require "lucky_cache"

LuckyCache.configure do |settings|
  settings.storage = LuckyCache::MemoryStore.new
  settings.default_duration = 5.minutes
end

class SomeObject
  include LuckyCache::Cachable
end

cache = LuckyCache.settings.storage
some_object = cache.fetch("some_key", as: SomeObject) do
  SomeObject.new
end
```

### Page fragment cache

You can cache portions of your page by including the `LuckyCache::HtmlHelpers` module
in your Page class, and use the `cache()` helper method.

```crystal
class Posts::ShowPage < MainLayout
  include LuckyCache::HtmlHelpers
  needs post : Post

  def content
    cache("post:#{post.id}:comments", expires_in: 1.hour) do
      post.comments.each do |comment|
        div comment.text
      end
    end
  end
end
```

## Development



## Contributing

1. Fork it (<https://github.com/luckyframework/lucky_cache/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Jeremy Woertink](https://github.com/jwoertink) - maintainer

## Thanks & attributions

* Initial structure and some code was pulled from the original LuckyCache by [@matthewmcgarvey](https://github.com/matthewmcgarvey/lucky_cache).
* Lots of inspiration on Cache store was from [@mamantoha](https://github.com/crystal-cache/cache)
