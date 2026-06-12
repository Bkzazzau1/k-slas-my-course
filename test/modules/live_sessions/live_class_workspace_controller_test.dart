import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_courses/modules/live_sessions/controller/live_class_workspace_controller.dart';

void main() {
  group('LiveClassBoardController', () {
    test('stores annotations per page and restores them on page switch', () {
      final controller = LiveClassBoardController(
        sessionId: 'session-1',
        userId: 'lecturer-1',
      )..setPageCount(3);

      const canvasSize = Size(1000, 700);

      controller.beginStroke(const Offset(100, 120), canvasSize);
      controller.appendPoint(const Offset(280, 260), canvasSize);
      controller.endStroke();

      controller.setPage(2);
      controller.beginStroke(const Offset(140, 200), canvasSize);
      controller.appendPoint(const Offset(320, 340), canvasSize);
      controller.endStroke();

      expect(controller.annotationCountForPage(1), 1);
      expect(controller.annotationCountForPage(2), 1);
      expect(controller.currentPage, 2);

      controller.setPage(1);

      expect(controller.currentPageStrokes, hasLength(1));
      expect(controller.currentPageStrokes.first.sessionId, 'session-1');
      expect(controller.currentPageStrokes.first.userId, 'lecturer-1');
    });

    test('undo and redo stay page-scoped', () {
      final controller = LiveClassBoardController(
        sessionId: 'session-2',
        userId: 'lecturer-2',
      )..setPageCount(2);

      const canvasSize = Size(800, 600);

      controller.beginStroke(const Offset(80, 120), canvasSize);
      controller.appendPoint(const Offset(240, 260), canvasSize);
      controller.endStroke();

      controller.setPage(2);
      controller.beginStroke(const Offset(90, 140), canvasSize);
      controller.appendPoint(const Offset(260, 300), canvasSize);
      controller.endStroke();

      controller.undo();
      expect(controller.currentPageStrokes, isEmpty);

      controller.redo();
      expect(controller.currentPageStrokes, hasLength(1));

      controller.setPage(1);
      expect(controller.currentPageStrokes, hasLength(1));
    });
  });

  group('LiveClassGestureController', () {
    test(
      'reports blocked camera when gesture mode starts without camera',
      () async {
        final controller = LiveClassGestureController();

        await controller.setGestureEnabled(true, cameraReady: false);

        expect(controller.isGestureEnabled, isTrue);
        expect(
          controller.trackingState,
          LiveClassGestureTrackingState.blockedCamera,
        );
        expect(controller.isUnavailable, isTrue);
      },
    );

    test('moves to active when camera is ready', () async {
      final controller = LiveClassGestureController();

      await controller.setGestureEnabled(true, cameraReady: true);

      expect(controller.trackingState, LiveClassGestureTrackingState.active);
      expect(controller.currentGesture, LiveClassGestureAction.ready);
      expect(controller.gesturePreviewVisible, isTrue);
    });
  });
}
