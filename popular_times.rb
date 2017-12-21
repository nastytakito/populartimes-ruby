require 'json'
require 'certified' #quitar después
require 'net/http'
require 'logger'
class PopularTimes
  $logger = Logger.new(STDOUT)
  $api_key = nil
  $radius_search = "https://maps.googleapis.com/maps/api/place/nearbysearch/json?"

  def initialize (api_key)
    $api_key = api_key
  end

  def get_details(place_id)
    detail_url = 'https://maps.googleapis.com/maps/api/place/details/json?placeid=%{place_id}&key=%{api_key}' %
        {
            place_id: place_id,
            api_key: $api_key
        }
    uri = URI(detail_url)
    response = JSON.parse(Net::HTTP.get(uri))
    check_response_code(response)
    details = response['result']
    search_term = "%{name} %{formatted_address}" %
        {
            name: details['name'],
            formatted_address: details['formatted_address']
        }
    popularity, rating, rating_n, current_popularity = get_current_popularity(search_term)
    details_json = {
        id: details["place_id"],
        name: details['name'],
        address: details['formatted_address'],
        search_term: search_term,
        types: details["types"],
        coordinates: details["geometry"]["location"]
    }
    if rating != nil
      details_json["rating"] = rating
    elsif details["rating"] != nil
      details_json["rating"] = details["rating"]
    end

    if rating_n != nil
      details_json["rating_n"] = rating_n
    else
      details_json["rating_n"] = 0
    end

    if current_popularity != nil
      details_json["current_popularity"] = current_popularity
    end

    if popularity != nil
      details_json["popular_times"] = get_popularity_for_day(popularity)
    else
      details_json["popular_times"] = []
    end

    JSON.unparse(details_json)
  end

  def get_popularity_for_day(popularity)
    popular_times_json, days_json = [], Array.new(7) {Array.new(24) {0}}
    day_name = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
    if popularity != ""
      for day in popularity
        day_no, pop_time = day[0..2]
        if pop_time != nil
          for el in pop_time
            hour, pop = el[0..2]
            days_json[day_no - 1][hour] = pop
            if hour == 23
              day_no = day_no % 7 + 1
            end
          end
        end
      end
      for d in (0..6)
        popular_times_json.push({:name => day_name[d], :data => days_json[d]})
      end
      popular_times_json
    end
  end

  def check_response_code(resp)

    # check if query quota has been surpassed or other errors occured
    # :param resp: json response
    # :return:

    if resp["status"] == "OK" or resp["status"] == "ZERO_RESULTS"
      return
    end
    if resp["status"] == "REQUEST_DENIED"
      $logger.error("Your request was denied, the API key is invalid.")
    end
    if resp["status"] == "OVER_QUERY_LIMIT"
      $logger.error("You exceeded your Query Limit for Google Places API Web Service, " +
                        "check https://developers.google.com/places/web-service/usage to upgrade your quota.")
    end
    if resp["status"] == "INVALID_REQUEST"
      $logger.error("The query string is malformed, " +
                        "check params.json if your formatting for lat/lng and radius is correct.")
    end
    # TODO: preguntar si esto está gud
    # $logger.error("Exiting application ...")
    # exit(1)
  end

  def get_current_popularity (place_identifier)
    params_url = {
        tbm: "map",
        tch: 1,
        q: place_identifier,
        pb: "!4m12!1m3!1d4005.9771522653964!2d-122.42072974863942!3d37.8077459796541!2m3!1f0!2f0!3f0!3m2!1i1125!2i976" +
            "!4f13.1!7i20!10b1!12m6!2m3!5m1!6e2!20e3!10b1!16b1!19m3!2m2!1i392!2i106!20m61!2m2!1i203!2i100!3m2!2i4!5b1" +
            "!6m6!1m2!1i86!2i86!1m2!1i408!2i200!7m46!1m3!1e1!2b0!3e3!1m3!1e2!2b1!3e2!1m3!1e2!2b0!3e3!1m3!1e3!2b0!3e3!" +
            "1m3!1e4!2b0!3e3!1m3!1e8!2b0!3e3!1m3!1e3!2b1!3e2!1m3!1e9!2b1!3e2!1m3!1e10!2b0!3e3!1m3!1e10!2b1!3e2!1m3!1e" +
            "10!2b0!3e4!2b1!4b1!9b0!22m6!1sa9fVWea_MsX8adX8j8AE%3A1!2zMWk6Mix0OjExODg3LGU6MSxwOmE5ZlZXZWFfTXNYOGFkWDh" +
            "qOEFFOjE!7e81!12e3!17sa9fVWea_MsX8adX8j8AE%3A564!18e15!24m15!2b1!5m4!2b1!3b1!5b1!6b1!10m1!8e3!17b1!24b1!" +
            "25b1!26b1!30m1!2b1!36b1!26m3!2m2!1i80!2i92!30m28!1m6!1m2!1i0!2i0!2m2!1i458!2i976!1m6!1m2!1i1075!2i0!2m2!" +
            "1i1125!2i976!1m6!1m2!1i0!2i0!2m2!1i1125!2i20!1m6!1m2!1i0!2i956!2m2!1i1125!2i976!37m1!1e81!42b1!47m0!49m1" +
            "!3b1"
    }
    search_url = "https://www.google.com/search?&" + URI.encode_www_form(params_url)
    uri = URI(search_url)
    response = Net::HTTP.get_response(uri)
    data = response.body
    jend = data.rindex('}')
    if jend > 0
      data = data[0..jend]
    end
    jdata = JSON.load(data)["d"]
    jdata = JSON.load(jdata[4..jdata.length])

    popular_times, rating, rating_n, current_popularity = nil, nil, nil, nil
    begin
      info = jdata[0][1][0][14]
      rating = info[4][7]
      rating_n = info[4][8]
      popular_times = info[84][0]
      current_popularity = info[84][7][1]
    ensure
      return popular_times, rating, rating_n, current_popularity
    end
  end

  def get_nearby_search(parameters)
    nearby_search = $radius_search + URI.encode_www_form(parameters)
    uri = URI(nearby_search)
    response = JSON.load(Net::HTTP.get(uri))
    check_response_code(response)
    response
  end

  def filter_popular_times(data)
    search_term = "%{name} %{formatted_address}" %
        {
            name: data['name'],
            formatted_address: data['vicinity']
        }
    popularity, rating, rating_n, current_popularity = get_current_popularity(search_term)

    nearby_json = {
        name: data['name'],
        address: data['vicinity'],
        coordinates: data["geometry"]["location"],
        id: data["place_id"]
    }

    if current_popularity != nil
      nearby_json["current_popularity"] = current_popularity
    end

    if popularity != nil
      nearby_json["popular_times"] = get_popularity_for_day(popularity)
    else
      nearby_json["popular_times"] = []
    end
    nearby_json
  end

  def get_nearby_places(lat, lng, radius)
    nearby_json = []
    threads = []
    results_limit = 40
    params_url = {
        location: "%{lat},%{lng}" % {lat: lat, lng: lng},
        radius: radius,
        type: "restaurant",
        key: $api_key
    }
    response = get_nearby_search(params_url)
    data_list = response["results"]
    while nearby_json.length < results_limit
      data_list.each do |data|
        threads << Thread.new {
          if nearby_json.length < results_limit
            temp_result = filter_popular_times(data)
            if temp_result["popular_times"].length != 0
              duplicated_entry = false
              if nearby_json.length == 0
                nearby_json << temp_result
              end
              nearby_json.each do |restaurant|
                if restaurant.has_value?(temp_result[:id])
                  duplicated_entry = true
                  break
                end
              end
              if duplicated_entry === false
                nearby_json << temp_result
              end
            end
          else
            break
          end
        }
      end
      threads.each do |th|
        th.join
      end
      p "nearbyjson = " + nearby_json.length.to_s
      threads = []
      sleep (0.8)
      if nearby_json.length < results_limit
        if response["next_page_token"] != nil
          page_params_url = {
              pagetoken: response["next_page_token"],
              key: $api_key
          }
          response = get_nearby_search(page_params_url)
          data_list = response["results"]
        else
          if params_url[:type] != "bar"
            params_url = {
                location: "%{lat},%{lng}" % {lat: lat, lng: lng},
                radius: radius,
                type: "bar",
                key: $api_key
            }
            response = get_nearby_search(params_url)
            data_list = response["results"]
          else
            break
          end
        end
      end
    end
    puts JSON.unparse nearby_json
  end
end