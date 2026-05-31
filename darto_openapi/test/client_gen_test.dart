import 'package:darto/darto.dart';
import 'package:darto_openapi/darto_openapi.dart';
import 'package:test/test.dart';

OpenApi buildApi() {
  final app = Darto();
  final api = OpenApi(app, info: Info(title: 'API', version: '1.0.0'));

  api.post(
    '/posts',
    request: Req(
      json: Schema.object({
        'title': Schema.string(),
        'tags': Schema.array(Schema.string()),
      }, required: ['title']),
    ),
    responses: {
      201: Res('Created', body: Schema.object({'id': Schema.integer()})),
    },
    handler: (c) => c.created({}),
  );

  api.get(
    '/posts/:id',
    request: Req(params: {'id': Schema.integer()}),
    responses: {
      200: Res('A post', body: Schema.object({
        'id': Schema.integer(),
        'title': Schema.string(),
      }, required: ['id', 'title'])),
    },
    handler: (c) => c.ok({}),
  );

  return api;
}

void main() {
  group('generateDartClient', () {
    late String src;
    setUp(() => src = generateDartClient(buildApi().toJson(), baseUrl: 'https://api.example.com'));

    test('emits request/response model classes with typed fields', () {
      expect(src, contains('class PostPostsRequest {'));
      expect(src, contains('final String title;')); // required → non-null
      expect(src, contains('final List<String>? tags;')); // optional → nullable
      expect(src, contains('class GetPostsByIdResponse {'));
      expect(src, contains('final int id;'));
    });

    test('models have fromJson and toJson', () {
      expect(src, contains('factory PostPostsRequest.fromJson('));
      expect(src, contains('Map<String, dynamic> toJson()'));
      expect(src, contains("(json['tags'] as List?)?.cast<String>()"));
    });

    test('client class with typed methods and base url', () {
      expect(src, contains('class ApiClient {'));
      expect(src, contains("baseUrl = 'https://api.example.com'"));
      // POST /posts → typed body + typed response
      expect(src, contains('Future<PostPostsResponse> postPosts(PostPostsRequest body) async'));
      // GET /posts/:id → typed path param + typed response
      expect(src, contains('Future<GetPostsByIdResponse> getPostsById(int id) async'));
      expect(src, contains("'/posts/\${id}'"));
    });

    test('is dependency-free (only dart:io + dart:convert)', () {
      expect(src, contains("import 'dart:io';"));
      expect(src, contains("import 'dart:convert';"));
      expect(src, isNot(contains("package:http")));
      expect(src, contains('class ApiException implements Exception'));
    });
  });
}
