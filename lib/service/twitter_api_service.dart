import 'dart:convert';

import 'package:fimber/fimber.dart';

import '../config.dart';
import 'package:http/http.dart';
import 'package:twitter_api/twitter_api.dart';

class TwitterAPIService {
  TwitterAPIService({this.queryTag}) {
    _twitterApi = twitterApi(
      consumerKey: OAuthConsumerKey,
      consumerSecret: OAuthConsumerSecret,
      token: OAuthToken,
      tokenSecret: OAuthTokenSecret,
    );
  }

  twitterApi _twitterApi;
  final String queryTag;

  static const String path = "search/tweets.json";

  Future<List> getTweetsQuery() async {
    try {
      // Make the request to twitter
      Response response = await _twitterApi.getTwitterRequest(
        // Http Method
        "GET",
        // Endpoint you are trying to reach
        path,
        // The options for the request
        options: {
          "q": queryTag,
          "count": "50",
        },
      );

      Fimber.d("Twitter request: $path");
      Fimber.d("Twitter response status: ${response.statusCode}");

      final decodedResponse = json.decode(response.body);

      return decodedResponse['statuses'] as List;
    } catch (error) {
      rethrow;
    }
  }
}
