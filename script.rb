require_relative 'popular_times.rb'
place_id = "ChIJe7_cq2qEzoYRryNztqnVxqc"
api_key = "AIzaSyD0cH3NTJKmr5CgNIBANj_kSzfS91Ltgo0"

a = PopularTimes.new(api_key)
nearby_details = a.get_nearby_places(29.082464, -110.9745661,3000)

# details = a.get_details("ChIJe7_cq2qEzoYRryNztqnVxqc")



# puts( details )
puts( nearby_details )