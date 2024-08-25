# jekyll-apple-maps
Apple Maps plugin for Jekyll

This gem provides [Jekyll](https://jekyllrb.com) integrations for [Apple Maps server APIs](https://developer.apple.com/documentation/applemapsserverapi/). Currently it supports the following APIs:

+ [Snapshots](https://developer.apple.com/documentation/snapshots)
  + Supports both light and dark modes with dynamic `picture` tags
  + Caches images to avoid regenerating images with the same parameters, saving on API calls
  + Supports all parameters currently accepted by the Snapshots API
  + Cleans up asset images for maps that are no longer being used

## Installation

1. Install gem

This plugin is available as the [jekyll-apple-maps RubyGem](https://rubygems.org/gems/jekyll-apple-maps). You can add it to your project by adding this line to your `Gemfile`: `gem 'jekyll-apple-maps'`. Then run `bundle` to install the gem.

2. Add to configuration

After the gem has been installed, you need to add to your site's `_config.yml` to configure the plugin. 

```
plugins:
- jekyll-apple-maps
```

You can also optionally override the `referer` parameter in your `_config.yml`. This can be useful when serving locally, where your site's URL is `localhost` by default.

```
apple-maps:
  referer: https://example.com
```

3. Add API Key

To use this plugin, you'll need an Apple Developer account to generate an API key. This plugin uses a "Web Snapshots" Maps token, you can use the steps [listed here](https://developer.apple.com/documentation/mapkitjs/creating_a_maps_token) to generate one.

> [!NOTE]
> This plugin uses your Jekyll site's `site.url` as the `referer` header on requests to the Apple Maps API by default. As mentioned above, you can also override it in your `_config.yml` file. When creating an API key you should either specify your site's url as the domain restriction, or generate a key without a domain restriction. 

Once you have your API key, you should set the the `APPLE_MAPS_SNAPSHOT_API_KEY` environment variable.

`export APPLE_MAPS_SNAPSHOT_API_KEY=your_api_key_here`

## Usage

### Snapshots

The `apple_maps_snapshot_block` creates an Apple Maps image snapshot using the specified parameters. The [Apple Docs](https://developer.apple.com/documentation/snapshots/create_a_maps_web_snapshot) provide more details on each of the API parameters.

The following parameters are accepted by the block:
+ `center` - Coordinates of the center of the map. Can be set to `auto` if annotations and/or overlays are specified. Defaults to `auto`.
+ `map_type` - What type of map view to use. Options are: `standard`, `hybrid`, `satellite`, and `mutedStandard`. Defaults to `standard`.
+ `show_poi` - Whether to display places of interest on the map. Defaults to `true`.
+ `language` - Language to use for map labels. Defaults to `en-US`.
+ `span` - Coordinate span of how much to display around the map's center. Defaults to `nil`.
+ `zoom` - Zoom level with the range of `3` to `20`. Defaults to `12`.
+ `width` - Pixel width of the image. Defaults to `600`.
+ `height` -  Pixel height of the image. Defaults to `300`.
+ `color_schemes` - Array of which color schemes to generate for the map. Options are `light` and `dark`. Defaults to both (`['light', 'dark']`).
+ `overlays` - An array of [overlay objects](https://developer.apple.com/documentation/snapshots/overlay). Defaults to empty `[]`.
+ `annotations` - An array of [annotation objects](https://developer.apple.com/documentation/snapshots/annotation). Defaults to empty `[]`.
+ `overlays_styles` - An array of [overlay style objects](https://developer.apple.com/documentation/snapshots/overlaystyle). Defaults to empty `[]`.
+ `images` - An array of [image objects](https://developer.apple.com/documentation/snapshots/image) for annotations. Defaults to empty `[]`.

#### Examples
```
{% apple_maps_snapshot_block %}
  center: "33.24767,115.73192"
  show_poi: 1
  zoom: 14
  width: 600
  height: 150
  annotations: [
    {
      "point": "33.24767,115.73192",
      "color": "449944",
      "glyphText": "Salton Sea",
      "markerStyle": "large"
    }
  ]
{% endapple_maps_snapshot_block %}
```

## Rate limiting
Apple specifies the following limits on usage of the Apple Maps Server APIs. This plugin caches snapshot images for the same parameters to avoid regenerating images. But if you initially generate a large number of snapshots (>25,000), you may exceed this limit.

```
The service provides up to 25,000 service calls per day per team between Apple Maps Server API and MapKit JS. If your app exceeds this quota, the service returns an HTTP 429 error (Too Many Requests) and your app needs to retry later. If your app requires a larger daily quota, submit a quota increase request form.

MapKit JS provides a free daily limit of 250,000 map views and 25,000 service calls per Apple Developer Program membership. For additional capacity needs, contact us.
https://developer.apple.com/maps/web/
```

## Development

To execute the test suite locally:
```
bundle exec rspec
```

To build and use the gem locally:
```
gem build jekyll-apple-maps.gemspec
gem install ./jekyll-apple-maps-1.0.0.gem
```

```
gem 'jekyll-apple-maps', path: '/PathHere/jekyll-apple-maps'
```