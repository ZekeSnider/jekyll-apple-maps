# jekyll-apple-maps
[![CircleCI](https://dl.circleci.com/status-badge/img/circleci/aW12qZgMpxbXNYTbdzFe5/FS3eDPqnpMpZJ2cKYi2aN9/tree/main.svg?style=svg)](https://dl.circleci.com/status-badge/redirect/circleci/aW12qZgMpxbXNYTbdzFe5/FS3eDPqnpMpZJ2cKYi2aN9/tree/main) [![codecov](https://codecov.io/gh/ZekeSnider/jekyll-apple-maps/graph/badge.svg?token=2V7NFD77OL)](https://codecov.io/gh/ZekeSnider/jekyll-apple-maps)

![Hero image for jekyll-apple-maps](/assets/hero_image.png)

This gem provides [Jekyll](https://jekyllrb.com) integrations for the [Apple Maps server APIs](https://developer.apple.com/documentation/applemapsserverapi/). It allows you to include Apple Maps content in your site using Jekyll Liquid tags. Currently it supports the following APIs:

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
+ `scale` - The pixel density of the image. Valid values are `1`, `2`, `3`. Defaults to `2`.
+ `color_schemes` - Array of which color schemes to generate for the map. Options are `light` and `dark`. Defaults to both (`['light', 'dark']`).
+ `overlays` - An array of [overlay objects](https://developer.apple.com/documentation/snapshots/overlay). Defaults to empty `[]`.
+ `annotations` - An array of [annotation objects](https://developer.apple.com/documentation/snapshots/annotation). Defaults to empty `[]`.
+ `overlays_styles` - An array of [overlay style objects](https://developer.apple.com/documentation/snapshots/overlaystyle). Defaults to empty `[]`.
+ `images` - An array of [image objects](https://developer.apple.com/documentation/snapshots/image) for annotations. Defaults to empty `[]`.

#### Examples
A map with a single annotation
```
{% apple_maps_snapshot_block %}
  center: "33.24767,-115.73192"
  show_poi: true
  zoom: 6
  width: 600
  height: 400
  annotations: [
    {
      "point": "33.24767,-115.73192",
      "color":"449944",
      "glyphText": "S",
      "markerStyle": "large"
    }
  ]
{% endapple_maps_snapshot_block %}
```
![Example map using a single annotation](/assets/single_annotation.png)

Using an image annotation
```
{% apple_maps_snapshot_block %}
  center: "33.24767,-115.73192"
  show_poi: false
  zoom: 8
  width: 600
  height: 400
  color_schemes: ["dark"]
  annotations: [
    {
      "markerStyle": "img", 
      "imgIdx": 0, 
      "point":"33.24767,-115.73192", 
      "color":"449944", 
      "offset": "0,15"
    }
  ]
  images: [
    {
      "url": "https://www.iconfinder.com/icons/2376758/download/png/48",
      "height": 48,
      "width": 48
    }
  ]
{% endapple_maps_snapshot_block %}
```
![Example map using an image annotation](/assets/image_annotation.png)

A map with multiple annotations
```
{% apple_maps_snapshot_block %}
  center: "37.772318, -122.447326"
  zoom: 11.5
  width: 600
  height: 400
  annotations: [
    {
      "point": "37.819724, -122.478557",
      "color":"red",
      "glyphText": "G",
      "markerStyle": "large"
    },
    {
      "point": "37.750472,-122.484132",
      "color": "blue",
      "glyphText": "S",
      "markerStyle": "large"
    },
    {
      "point": "37.755217, -122.452776",
      "color": "red",
      "markerStyle": "balloon"
    },
    {
      "point": "37.778457, -122.389238",
      "color": "orange",
      "markerStyle": "dot"
    }
  ]
{% endapple_maps_snapshot_block %}
```
![Example map using multiple annotations](/assets/multiple_annotations.png)

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

To publish a new version of the gem:

1. Merge changes to `main` branch with updated version in `lib/jekyll/apple_maps/version.rb` and `jekyll-apple-maps.gemspec`
2. `gem build jekyll-apple-maps.gemspec`
3. `gem push jekyll-apple-maps-<version here>.gem`

You can also use the local version of this gem from your gemfile:
```
gem 'jekyll-apple-maps', path: '/PathHere/jekyll-apple-maps'
```

There's also a CLI utility for testing templates. 
+ `-s` Is the source directory where the maps assets should be written to
+ `-r` Is the referer header to use for the request
+ `-h` prints help options

When you execute the script you'll paste in the full template text (as seen above in examples).
```
./script/render.rb -s /YourUser/Developer/jekyll-test -r https://example.com
```