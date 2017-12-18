require_relative 'popular_times.rb'
place_id = "ChIJFXcRgSGFzoYR_mCDWHjoiCk"
api_key = "AIzaSyD0cH3NTJKmr5CgNIBANj_kSzfS91Ltgo0"
a = PopularTimes.new(api_key)
# puts( a.get_details(place_id))
puts(a.get_nearby_places(29.0809604, -110.9414922,3000))