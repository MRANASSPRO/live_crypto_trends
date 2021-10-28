import 'dart:async';

import 'package:live_crypto_trends/model/chat_message.dart';
import 'package:live_crypto_trends/model/coin.dart';

import '../config.dart';
import 'package:ably_flutter_plugin/ably_flutter_plugin.dart' as ably;
import 'package:flutter/foundation.dart';

/// store the currently available currencies on the Hub.
/// If any new currency is added to the source,
/// we can append it here
const List<Map> _coinTypes = [
  {
    "name": "Bitcoin",
    "code": "btc",
  },
  {
    "name": "Ethereum",
    "code": "eth",
  },
];

//UI change notifier when we receive new data
class CoinUpdates extends ChangeNotifier {
  CoinUpdates({this.name});

  final String name;

  Coin _coin;

  Coin get coin => _coin;

  updateCoin(value) {
    this._coin = value;
    notifyListeners();
  }
}

class ChatUpdates extends ChangeNotifier {
  ChatMessage _message;

  ChatMessage get message => _message;

  updateChat(value) {
    this._message = value;
    notifyListeners();
  }
}

/// The service is registered using `get_it`, to make sure we get the same
/// instance through out the life of the app, but can be done using other
/// solutions such as provider.
/// we want this service to be a Singleton i.e. initialized only once at the time of launching the app.
class AblyService {
  final ably.Realtime _realtime;

  ably.RealtimeChannel _chatChannel;

  AblyService._(this._realtime);

  Stream<ably.ConnectionStateChange> get connection =>
      _realtime.connection.on();

  static Future<AblyService> init() async {
    /// initialize client options for your Ably account using your private API
    /// key
    final ably.ClientOptions _clientOptions =
        ably.ClientOptions.fromKey(AblyAPIKey);

    /// initialize real-time object with the client options
    final _realtime = ably.Realtime(options: _clientOptions);

    /// connect the app to Ably's Realtime services supported by this SDK
    await _realtime.connect();

    /// return the single instance of AblyService with the local _realtime property
    return AblyService._(_realtime);
  }

  List<CoinUpdates> _coinUpdates = [];

  List<CoinUpdates> getCoinUpdates() {
    if (_coinUpdates.isEmpty) {
      for (int i = 0; i < _coinTypes.length; i++) {
        String coinName = _coinTypes[i]['name'];
        String coinCode = _coinTypes[i]['code'];

        _coinUpdates.add(CoinUpdates(name: coinName));

        //launch a realtime channel for each coin type
        ably.RealtimeChannel channel = _realtime.channels
            .get('[product:ably-coindesk/crypto-pricing]$coinCode:usd');

        //subscribe to receive a Dart Stream that emits the channel messages
        final Stream<ably.Message> messageStream = channel.subscribe();

        //listener to map each stream event to a Coin and listen to updates
        //important to filter out null values
        messageStream.where((event) => event.data != null).listen((message) {
          //here we call updateCoin to assign new coin data
          _coinUpdates[i].updateCoin(
            Coin(
              code: coinCode,
              price: double.parse('${message.data}'),
              dateTime: message.timestamp,
            ),
          );
        });
      }
    }
    return _coinUpdates;
  }

  /// This method is called one time when the chat page is opened, it doesn't
  /// read history (messages sent previously) so each time you leave and get
  /// back to chat page past messages will be lost.
  ChatUpdates getChatUpdates() {
    ChatUpdates _chatUpdates = ChatUpdates();

    _chatChannel = _realtime.channels.get('public-chat');

    var messageStream = _chatChannel.subscribe();

    messageStream.listen((message) {
      _chatUpdates.updateChat(
        ChatMessage(
          content: message.data,
          dateTime: message.timestamp,
          isWriter: message.name == "${_realtime.clientId}",
        ),
      );
    });

    return _chatUpdates;
  }

  /// connect to the same chat channel to publish new messages.
  /// The name of the channel is important, if it wasn't the same one subscribed
  /// to in [getChatUpdates] we won't get the published messages.
  Future sendMessage(String content) async {
    _realtime.channels.get('public-chat');

    await _chatChannel
        .publish(data: content, name: "${_realtime.clientId}");
  }
}
