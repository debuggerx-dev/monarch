import 'dart:io';
import 'package:monarch_io_utils/utils.dart';
import 'package:path/path.dart' as p;

import 'paths.dart' as paths;
import 'utils.dart' as utils;

void main() {
  print('''

### build_controller.dart
''');

  utils.createDirectoryIfNeeded(paths.out_ui);

  for (final flutter_sdk in utils.read_flutter_sdks()) {
    print('''
===============================================================================
Using flutter sdk at:
  $flutter_sdk
  Flutter version ${paths.get_flutter_version(flutter_sdk)}, ${paths.get_flutter_channel(flutter_sdk)} channel.
''');

    var out_ui_flutter_id = paths.out_ui_flutter_id(flutter_sdk);
    utils.createDirectoryIfNeeded(out_ui_flutter_id);

    var out_ui_flutter_id_controller =
        paths.out_ui_flutter_id_controller(out_ui_flutter_id);
    var out_controller_dir = Directory(out_ui_flutter_id_controller);
    if (out_controller_dir.existsSync())
      out_controller_dir.deleteSync(recursive: true);
    out_controller_dir.createSync(recursive: true);

    {
      print('''
Running `flutter pub get` in:
  ${paths.controller}
''');
      var result = Process.runSync(
          paths.flutter_exe(flutter_sdk), ['pub', 'get'],
          workingDirectory: paths.controller, runInShell: Platform.isWindows);
      utils.exitIfNeeded(result, 'Error running `flutter pub get`');
    }

    {
      print('''
Building monarch controller flutter bundle. Will output to:
  $out_ui_flutter_id_controller
''');

      var result = Process.runSync(
          paths.flutter_exe(flutter_sdk),
          [
            'build',
            'bundle',
            '-t',
            'lib/main.dart',
            '--debug',
            '--target-platform',
            valueForPlatform(macos: 'darwin', windows: 'windows-x64'),
            '--asset-dir',
            p.join(out_ui_flutter_id_controller, 'flutter_assets'),
            '--verbose'
          ],
          workingDirectory: paths.controller,
          runInShell: Platform.isWindows);

      utils.exitIfNeeded(
          result, 'Error building monarch controller flutter bundle');
    }

    {
      if (Platform.isWindows) {
        var result = Process.runSync(
            'copy',
            [
              p.join(flutter_sdk, 'bin', 'cache', 'artifacts', 'engine',
                  'windows-x64', 'icudtl.dat'),
              out_ui_flutter_id_controller
            ],
            runInShell: true);
        utils.exitIfNeeded(result, 'Error copying icudtl.dat to monarch_controller directory');
      }
    }

    print('''
===============================================================================
''');
  }

  var version =
      utils.readPubspecVersion(p.join(paths.controller, 'pubspec.yaml'));
  version = utils.getVersionSuffix(version);

  utils.writeInternalFile('controller_version.txt', version);

  print('Monarch controller build finished. Version $version');
}
