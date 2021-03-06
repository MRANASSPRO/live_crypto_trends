import 'package:flutter/material.dart';
import 'package:live_crypto_trends/service/twitter_api_service.dart';
import 'package:tweet_ui/models/api/tweet.dart';
import 'package:tweet_ui/tweet_ui.dart';

class TwitterFeedView extends StatefulWidget {
  const TwitterFeedView({Key key, @required this.hashtag}) : super(key: key);
  final String hashtag;

  @override
  _TwitterFeedViewState createState() => _TwitterFeedViewState();
}

class _TwitterFeedViewState extends State<TwitterFeedView> {
  List tweetsJson = [];
  String errorMessage = '';

  @override
  void initState() {
    getTweets();
    super.initState();
  }

  // Get tweets from Twitter Service
  Future getTweets() async {
    final twitterService = TwitterAPIService(queryTag: widget.hashtag);

    try {
      final List response = await twitterService
          .getTweetsQuery();

      setState(() {
        tweetsJson = response;
      });
    } catch (error) {
      setState(() {
        errorMessage = 'Error retrieving tweets, please try again later.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("#${widget.hashtag}"),
      ),
      body: RefreshIndicator(
        onRefresh: () => getTweets(),
        child: tweetsJson.isEmpty
            ? errorMessage.isEmpty
            ? Center(
          child: CircularProgressIndicator(),
        )
            : Center(
          child: Text(errorMessage),
        )
            : ListView.builder(
          padding: EdgeInsets.symmetric(vertical: 15),
          itemCount: tweetsJson.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: EmbeddedTweetView.fromTweet(
                Tweet.fromJson(tweetsJson[index]),
                darkMode: true,
                backgroundColor: Colors.transparent,
                useVideoPlayer: false,
              ),
            );
          },
        ),
      ),
    );
  }
}
