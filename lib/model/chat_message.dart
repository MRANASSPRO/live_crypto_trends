class ChatMessage {
  final String content;
  final DateTime dateTime;
  final bool isWriter;

  ChatMessage({
    this.content,
    this.dateTime,
    this.isWriter,
  });
}