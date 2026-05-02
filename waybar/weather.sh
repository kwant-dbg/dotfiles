#!/bin/sh

curl_bin="$(command -v curl)"
jq_bin="$(command -v jq)"

if [ -z "$curl_bin" ] || [ -z "$jq_bin" ]; then
    printf '{"text":"󰖐 --","tooltip":"Install curl and jq for weather"}\n'
    exit 0
fi

latitude="${WAYBAR_WEATHER_LAT:-31.6138}"
longitude="${WAYBAR_WEATHER_LON:-76.3579}"
location="${WAYBAR_WEATHER_LABEL:-Bangana, Himachal Pradesh}"
url="https://api.open-meteo.com/v1/forecast?latitude=${latitude}&longitude=${longitude}&current=temperature_2m,apparent_temperature,relative_humidity_2m,weather_code,wind_speed_10m&timezone=auto"
response="$("$curl_bin" -s --max-time 10 -A 'waybar-weather' "$url")"

if [ -z "$response" ]; then
    printf '{"text":"󰖐 --","tooltip":"Weather unavailable"}\n'
    exit 0
fi

printf '%s' "$response" | "$jq_bin" -cer --arg location "$location" '
  def weather_desc($code):
    {
      "0": "Clear",
      "1": "Mainly clear",
      "2": "Partly cloudy",
      "3": "Overcast",
      "45": "Fog",
      "48": "Rime fog",
      "51": "Light drizzle",
      "53": "Drizzle",
      "55": "Dense drizzle",
      "56": "Freezing drizzle",
      "57": "Dense freezing drizzle",
      "61": "Light rain",
      "63": "Rain",
      "65": "Heavy rain",
      "66": "Freezing rain",
      "67": "Heavy freezing rain",
      "71": "Light snow",
      "73": "Snow",
      "75": "Heavy snow",
      "77": "Snow grains",
      "80": "Rain showers",
      "81": "Heavy showers",
      "82": "Violent showers",
      "85": "Snow showers",
      "86": "Heavy snow showers",
      "95": "Thunderstorm",
      "96": "Thunderstorm with hail",
      "99": "Severe thunderstorm with hail"
    }[($code | tostring)] // "Unknown";

  .current as $c
  | if ($c.temperature_2m == null or $c.weather_code == null) then
      {"text":"󰖐 --","tooltip":"Weather unavailable"}
    else
      {
        "text": ("󰖙 \($c.temperature_2m | round)°C"),
        "tooltip": (
          $location + "\n"
          + weather_desc($c.weather_code) + "\n"
          + "Feels like \($c.apparent_temperature | round)°C\n"
          + "Humidity \($c.relative_humidity_2m)%\n"
          + "Wind \($c.wind_speed_10m | round) km/h"
        )
      }
    end
' 2>/dev/null || printf '{"text":"󰖐 --","tooltip":"Weather unavailable"}\n'
