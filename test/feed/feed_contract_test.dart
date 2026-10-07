import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import 'package:mjengo_hub_app/feed/controllers/feed_controller.dart';
import 'package:mjengo_hub_app/feed/models/feed_contract.dart';
import 'package:mjengo_hub_app/feed/models/feed_model.dart';
import 'package:mjengo_hub_app/feed/services/feed_api_service.dart';
import 'package:mjengo_hub_app/feed/screens/feed_screen.dart';
import 'package:mjengo_hub_app/feed/screens/feed_composer_screen.dart';
import 'package:mjengo_hub_app/services/base_service.dart';

class _FakeFeedService extends FeedApiService {
  final FeedPage page;
  final bool fail;
  final FeedPublishResult? publishResult;

  _FakeFeedService(this.page, {this.fail = false, this.publishResult});

  @override
  Future<FeedPage> getFeed({int page = 1, int perPage = 15}) async {
    if (fail) throw const FeedApiException('Feed is unavailable.');
    return this.page;
  }

  @override
  Future<FeedPublishResult> createPost({
    required String content,
    int? pageId,
    List<FeedUploadAttachment> attachments = const [],
  }) async {
    return publishResult ??
        FeedPublishResult(
          item: FeedItem(text: content, status: 'published'),
          status: 'published',
        );
  }
}

class _FakeBaseService extends BaseService {
  Map<String, String>? fields;
  List<http.MultipartFile>? files;

  @override
  Future<Response> postMultipart(
    String endpoint, {
    required List<http.MultipartFile> files,
    Map<String, String>? fields,
  }) async {
    this.files = files;
    this.fields = fields;
    return Response(
      statusCode: 201,
      body: {
        'success': true,
        'data': {
          'id': 20,
          'status': 'published',
          'post_type': 'community',
          'author': {'display_name': 'Member'},
        },
      },
    );
  }
}

void main() {
  test('exposes the website Feed tabs without claiming native support', () {
    expect(FeedTab.values.map((tab) => tab.label), [
      'For You',
      'Following',
      'Trending',
      'Topics',
      'Discussions',
      'Messages',
      'Calls',
    ]);
    expect(FeedTab.forYou.hasNativeApi, isTrue);
    expect(FeedTab.following.hasNativeApi, isFalse);
    expect(FeedContract.hasNativeReadApi, isTrue);
    expect(FeedContract.hasNativePublishApi, isTrue);
  });

  test('parses normalized Feed records and nullable pagination safely', () {
    final page = FeedPage.fromResponse({
      'success': true,
      'data': [
        {
          'id': 8,
          'feed_post_id': 8,
          'post_type': 'editorial',
          'author': {
            'id': 2,
            'display_name': 'Mjengo Hub',
            'is_editorial': true,
          },
          'published_at': '2026-10-07T09:30:00Z',
          'text': 'A verified Feed post.',
          'media': [
            {'media_type': 'image', 'url': 'https://media.example/image.jpg'},
          ],
          'source': {
            'type': 'article',
            'id': 4,
            'article_slug': 'verified-story',
          },
          'comment_count': 3,
        },
      ],
      'pagination': {
        'page': 2,
        'per_page': 15,
        'has_next': true,
        'next_page': 3,
      },
    });

    expect(page.items.single.source?.articleSlug, 'verified-story');
    expect(
      page.items.single.media.single.url,
      'https://media.example/image.jpg',
    );
    expect(page.items.single.commentCount, 3);
    expect(page.page, 2);
    expect(page.hasNext, isTrue);
    expect(page.nextPage, 3);
  });

  test('controller supports loading, pagination and error state', () async {
    final controller = FeedController(
      service: _FakeFeedService(
        const FeedPage(
          items: [FeedItem(id: 1, text: 'First')],
          page: 1,
          hasNext: true,
        ),
        fail: false,
      ),
      loadOnInit: false,
    );
    await controller.load();

    expect(controller.items.single.text, 'First');
    expect(controller.hasNext.value, isTrue);

    final failed = FeedController(
      service: _FakeFeedService(const FeedPage(), fail: true),
      loadOnInit: false,
    );
    await failed.load();
    expect(failed.items, isEmpty);
    expect(failed.errorMessage.value, 'Feed is unavailable.');
  });

  test('parses published and moderation publish responses', () {
    final published = FeedPublishResult.fromResponse({
      'success': true,
      'message': 'Post published.',
      'data': {
        'id': 10,
        'status': 'published',
        'post_type': 'community',
        'author': {'display_name': 'Member'},
      },
    });
    final pending = FeedPublishResult.fromResponse({
      'success': true,
      'message': 'Post submitted for moderation.',
      'data': {
        'id': 11,
        'status': 'moderation',
        'post_type': 'community',
        'author': {'display_name': 'Member'},
      },
    });

    expect(published.isPublished, isTrue);
    expect(pending.isPending, isTrue);
  });

  test('controller publishes and keeps server-returned status', () async {
    final controller = FeedController(
      service: _FakeFeedService(
        const FeedPage(),
        publishResult: const FeedPublishResult(
          item: FeedItem(id: 12, text: 'Awaiting review', status: 'moderation'),
          status: 'moderation',
        ),
      ),
      loadOnInit: false,
    );
    final result = await controller.publishPost('Awaiting review');

    expect(result.status, 'moderation');
    expect(result.item.id, 12);
    expect(controller.items, isEmpty);
  });

  test('multipart publish input preserves attachment bytes and filename', () {
    const attachment = FeedUploadAttachment(
      filename: 'site.jpg',
      bytes: [1, 2, 3],
    );
    expect(attachment.filename, 'site.jpg');
    expect(attachment.bytes, [1, 2, 3]);
  });

  test('Feed API builds multipart media requests', () async {
    final fake = _FakeBaseService();
    Get.put<BaseService>(fake);
    addTearDown(Get.delete<BaseService>);

    final result = await FeedApiService().createPost(
      content: 'Image update',
      attachments: const [
        FeedUploadAttachment(filename: 'site.jpg', bytes: [1, 2, 3]),
      ],
    );

    expect(result.isPublished, isTrue);
    expect(fake.fields?['content'], 'Image update');
    expect(fake.files?.single.field, 'media');
    expect(fake.files?.single.filename, 'site.jpg');
  });

  testWidgets('renders the native Feed composer at 360px', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final controller = FeedController(
      service: _FakeFeedService(const FeedPage(), fail: false),
      loadOnInit: false,
    );
    await controller.load();
    await tester.pumpWidget(
      GetMaterialApp(
        getPages: [
          GetPage(
            name: '/login',
            page: () => const Scaffold(body: Text('Sign In')),
          ),
        ],
        home: FeedScreen(controller: controller),
      ),
    );

    expect(find.text('Media & Feed'), findsOneWidget);
    expect(
      find.text("What's happening in the built environment?"),
      findsOneWidget,
    );
    expect(find.text('No Feed posts yet'), findsOneWidget);
    expect(find.text('Open Feed on website'), findsOneWidget);
    expect(find.text('Open Media Directory'), findsOneWidget);

    await tester.tap(find.text("What's happening in the built environment?"));
    await tester.pumpAndSettle();
    expect(find.text('Sign In'), findsOneWidget);
  });

  testWidgets('composer previews and removes selected media', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final controller = FeedController(
      service: _FakeFeedService(const FeedPage()),
      loadOnInit: false,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: FeedComposerScreen(
          controller: controller,
          initialAttachments: const [
            FeedUploadAttachment(filename: 'site.jpg', bytes: [1, 2, 3]),
          ],
        ),
      ),
    );

    expect(find.text('1/4 images'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();
    expect(find.text('0/4 images'), findsOneWidget);
  });
}
