import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';

void main() => runApp(WeatherApp());

class WeatherApp extends StatefulWidget {
  @override
  _WeatherAppState createState() => _WeatherAppState();
}

class _WeatherAppState extends State<WeatherApp> {
  int temperature;
  var minTemperatureForeCast = List(7);
  var maxTemperatureForeCast = List(7);

  String location = 'Istanbul';
  String weather = 'clear';
  String abbreviation = '';
  var abbreviationForeCast = List(7);
  String errorMessage = '';
  Color textcolor = Colors.black; //Default Color of temp
  int woeid = 2487956;

  String searchApiUrl =
      'https://www.metaweather.com/api/location/search/?query=';
  String locationApiUrl = 'https://www.metaweather.com/api/location/';
  @override
  void initState() {
    super.initState();
    fetchLocation();
    fetchLocationDay();
  }

  void fetchSearch(String input) async {
    try {
      var searchResult = await http.get(searchApiUrl + input);
      var result = json.decode(searchResult.body)[0];

      setState(() {
        location = result["title"];
        woeid = result["woeid"];
        errorMessage = '';
      });
    } catch (error) {
      setState(() {
        errorMessage = "Sorry city not found.. Check your typing and try again";
      });
    }
  }

  void fetchLocation() async {
    var locationResult = await http.get(locationApiUrl + woeid.toString());
    var result = json.decode(locationResult.body);
    var consolidated_weather = result["consolidated_weather"];
    var data = consolidated_weather[0];

    setState(() {
      temperature = data["the_temp"].round();
      weather = data["weather_state_name"].replaceAll(' ', '').toLowerCase();
      abbreviation = data["weather_state_abbr"];
    });
  }

  void fetchLocationDay() async {
    var today = DateTime.now();
    for (var i = 0; i < 7; i++) {
      var locationDayResult = await http.get(locationApiUrl +
          woeid.toString() +
          '/' +
          DateFormat('y/M/d')
              .format(today.add(Duration(days: i + 1)))
              .toString());
      var result = json.decode(locationDayResult.body);
      var data = result[0];
      setState(() {
        minTemperatureForeCast[i] = data["min_temp"].round();
        maxTemperatureForeCast[i] = data["max_temp"].round();

        abbreviationForeCast[i] = data["weather_state_abbr"];
      });
    }
  }

  void onTextFieldSubmitted(String input) async {
    await fetchSearch(input);
    await fetchLocation();
    await fetchLocationDay();
  }

  Color tempColor(temperature) {
    if (temperature > -60 && temperature < 23) {
      return Colors.blue[900];
    }
    if (temperature >= 29 && temperature < 60) {
      return Colors.red[900];
    } else {
      return Colors.yellow[900];
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Container(
        decoration: BoxDecoration(
            image: DecorationImage(
                image: AssetImage('images/$weather.png'),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(0.6), BlendMode.dstATop))),
        child: temperature == null
            ? Center(
                child: CircularProgressIndicator(),
              )
            : Scaffold(
                backgroundColor: Colors.transparent,
                body: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    Column(
                      children: <Widget>[
                        Column(
                          children: <Widget>[
                            Center(
                              child: Image.network(
                                'https://www.metaweather.com/static/img/weather/png/' +
                                    abbreviation +
                                    '.png',
                                width: 60,
                              ),
                            )
                          ],
                        ),
                        Center(
                            child: Text(
                          temperature.toString() + ' °C',
                          style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 22,
                              color: tempColor(temperature),
                              backgroundColor: Colors.black26),
                        )),
                        Center(
                            child: Text(
                          location,
                          style: TextStyle(color: Colors.white, fontSize: 23),
                        ))
                      ],
                    ),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Flexible(
                                              child: Row(
                          children: <Widget>[
                            for (var i = 0; i < 7; i++)
                              forecastElement(
                                  i + 1,
                                  abbreviationForeCast[i],
                                  minTemperatureForeCast[i],
                                  maxTemperatureForeCast[i])
                          ],
                        ),
                      ),
                    ),
                    Column(
                      children: <Widget>[
                        Container(
                          width: 300,
                          child: TextField(
                            onSubmitted: (String input) {
                              onTextFieldSubmitted(input);
                            },
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Please type location...',
                              hintStyle: TextStyle(
                                  color: Colors.white, fontSize: 20.0),
                              prefixIcon:
                                  Icon(Icons.search, color: Colors.white),
                            ),
                          ),
                        ),
                        Padding(
                          padding:
                              const EdgeInsets.only(right: 32.0, left: 32.0),
                          child: Text(
                            errorMessage,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.redAccent,
                                fontSize: Platform.isAndroid ? 15.0 : 20.0),
                          ),
                        )
                      ],
                    )
                  ],
                ),
              ),
      ),
    );
  }
}

Widget forecastElement(
    daysFromNow, abbreviation, minTemperature, maxTemperature) {
  var now = DateTime.now();
  var oneDayFromNow = now.add(Duration(days: daysFromNow));

  return Padding(
    padding: const EdgeInsets.only(left: 16.0),
    child: Flexible(
          child: Container(
        decoration: BoxDecoration(
          color: Color.fromRGBO(205, 212, 228, 0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                Text(
                  DateFormat.E().format(oneDayFromNow),
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
                Text(
                  DateFormat.MMMd().format(oneDayFromNow),
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 16.0, bottom: 16.0),
                  child: Image.network(
                    'https://www.metaweather.com/static/img/weather/png/' +
                        abbreviation +
                        '.png',
                    width: 50,
                  ),
                ),
                Text('Low: ' + minTemperature.toString() + ' °C',
                    style: TextStyle(color: Colors.blue[900], fontSize: 20.0)),
                Text('High: ' + maxTemperature.toString() + ' °C',
                    style: TextStyle(color: Colors.red[900], fontSize: 20.0))
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
