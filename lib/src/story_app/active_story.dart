import 'dart:async';

import '../log/dropsource_log.dart';

class StoryId {
  final String package;
  final String path; // this path is the generated stories path
  final String name;

  StoryId(this.package, this.path, this.name);

  factory StoryId.fromNodeKey(String key) {
    ArgumentError.checkNotNull(key, 'key');
    final segments = key.split('|');
    if (segments.length != 3) {
      throw ArgumentError('story id key must have 3 piped segments');
    }

    return StoryId(segments[0], segments[1], segments[2]);
  }

  String get pathKey => '$package|$path';
}

class ActiveStory with Log {
  StoryId _activeStoryId;

  StoryId get activeStoryId => _activeStoryId;

  final _activeStoryChangeStreamController =
      StreamController<void>.broadcast();
  Stream<void> get activeStoryChangeStream =>
      _activeStoryChangeStreamController.stream;

  void setActiveStory(String key) {
    _activeStoryId = StoryId.fromNodeKey(key);
    _activeStoryChangeStreamController.add(null);
    log.info('active story id set: $key');
  }

  void resetActiveStory() {
    _activeStoryId = null;
    _activeStoryChangeStreamController.add(null);
    log.info('active story id reset');
  }

  void close() {
    _activeStoryChangeStreamController.close();
  }
}

final activeStory = ActiveStory();
