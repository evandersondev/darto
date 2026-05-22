void log(String message, [List<String>? rest]) {
  // ignore: avoid_print
  if (rest != null && rest.isNotEmpty) {
    print('$message ${rest.join(' ')}');
  } else {
    print(message);
  }
}
