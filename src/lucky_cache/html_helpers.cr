module LuckyCache::HtmlHelpers
  # Use this in your Lucky Page class.
  #
  # ```
  # cache("some_key", expires_in: 5.minutes) do
  #   div do
  #     text "Data"
  #   end
  # end
  # ```
  def cache(key, *, expires_in : Time::Span?)
    cache = LuckyCache.settings.storage
    expires = expires_in || LuckyCache.settings.default_duration

    cached_html = cache.read(key)
    if cached_html
      raw(cached_html.value.as(String))
    else
      original_view = @view
      # Temporarily override the view
      @view = IO::Memory.new

      check_tag_content! yield # This will write to our temporary @view object

      html_fragment = @view.to_s

      cache.write(key, expires_in: expires) { html_fragment }
      # Set instance var back to original view
      @view = original_view
      # Write fragment to original view
      raw(html_fragment)
    end
  end
end
