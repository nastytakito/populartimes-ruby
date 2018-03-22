require_relative 'popular_times.rb'
place_id = "ChIJ4680OBO-YoYRyqsBZxHn4rU"
api_key = "AIzaSyD0cH3NTJKmr5CgNIBANj_kSzfS91Ltgo0"

a = PopularTimes.new(api_key)
# nearby_details = a.get_nearby_places(29.082464, -110.9745661,3000)

details = a.get_details(place_id)



puts( details )
# puts( nearby_details )