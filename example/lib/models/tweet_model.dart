class Tweet {
  final String id;
  final String text;
  final bool isLiked;

  const Tweet({required this.id, required this.text, this.isLiked = false});
}
