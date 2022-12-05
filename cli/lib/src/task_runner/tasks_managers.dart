import 'package:monarch_cli/src/task_runner/task.dart';
import 'package:monarch_utils/log.dart';

import 'preview_api.dart';
import 'reloaders.dart';
import 'process_task.dart';
import '../utils/standard_output.dart' show StandardOutput;
import 'task_count_heartbeat.dart';

abstract class TasksManager with Log {
  void manage();
  bool get isRunning;
}

class RegenAndHotReload extends TasksManager {
  final StandardOutput stdout_;
  final ProcessParentReadyTask regenTask;
  final PreviewApi previewApi;

  RegenAndHotReload({
    required this.stdout_,
    required this.regenTask,
    required this.previewApi,
  });

  bool _isReloading = false;
  bool _needsReload = false;

  @override
  bool get isRunning =>
      regenTask.childTaskStatus == ChildTaskStatus.running || _isReloading;

  final heartbeat = SimpleHeartbeat(kReloadingStories);

  @override
  void manage() {
    regenTask.childTaskStatusStream.listen((childTaskStatus) {
      switch (childTaskStatus) {
        case ChildTaskStatus.running:
          if (!heartbeat.isActive) {
            heartbeat.start();
          }
          break;

        case ChildTaskStatus.done:
          _needsReload = true;
          if (!_isReloading) {
            reload();
          }
          break;

        case ChildTaskStatus.failed:
          if (heartbeat.isActive) {
            heartbeat.completeError();
          }
          break;

        default:
      }
    });
  }

  void reload() async {
    _needsReload = false;

    _isReloading = true;
    var reloader = HotReloader(previewApi, stdout_);
    await reloader.reload(heartbeat);
    _isReloading = false;

    if (_needsReload) {
      if (!heartbeat.isActive) {
        heartbeat.start();
      }
      reload();
    }
  }
}

class RegenRebundleAndHotRestart extends TasksManager {
  final ProcessParentReadyTask regenTask;
  final ProcessTask buildPreviewBundleTask;
  final PreviewApi previewApi;

  RegenRebundleAndHotRestart({
    required this.regenTask,
    required this.buildPreviewBundleTask,
    required this.previewApi,
  });

  @override
  bool get isRunning =>
      regenTask.childTaskStatus == ChildTaskStatus.running ||
      buildPreviewBundleTask.status == TaskStatus.running;

  final heartbeat =
      TaskCountHeartbeat(kReloadingStoriesHotRestart, taskCount: 2);

  @override
  void manage() {
    regenTask.childTaskStatusStream.listen((childTaskStatus) {
      switch (childTaskStatus) {
        case ChildTaskStatus.running:
          if (!heartbeat.isActive) {
            heartbeat.completedTaskCount = 0;
            heartbeat.start();
          }
          break;

        case ChildTaskStatus.done:
          heartbeat.completedTaskCount = 1;
          reload();
          break;

        case ChildTaskStatus.failed:
          if (heartbeat.isActive) {
            heartbeat.completeError();
          }
          break;

        default:
      }
    });
  }

  void reload() async {
    var reloader = HotRestarter(buildPreviewBundleTask, previewApi);
    reloader.reload(heartbeat);
  }
}