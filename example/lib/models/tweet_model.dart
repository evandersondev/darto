class Tweet {
  final String id;
  final String text;
  final bool isLiked;

  const Tweet({required this.id, required this.text, this.isLiked = false});

  Map<String, dynamic> toMap() {
    final result = <String, dynamic>{};

    result.addAll({'id': id});
    result.addAll({'text': text});
    result.addAll({'isLiked': isLiked});

    return result;
  }

  factory Tweet.fromMap(Map<String, dynamic> map) {
    return Tweet(
      id: map['id'] ?? '',
      text: map['text'] ?? '',
      isLiked: map['isLiked'] ?? false,
    );
  }
}
