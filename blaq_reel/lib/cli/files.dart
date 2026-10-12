import 'dart:io';

import 'project.dart';

/// Opens [path] in its app: a video in the player, a folder in Finder.
Future<void> openFile(String path) async {
  if (Platform.isMacOS) {
    await Process.run('open', [path]);
  } else if (Platform.isWindows) {
    await Process.run('cmd', ['/c', 'start', '', path]);
  } else {
    await Process.run('xdg-open', [path]);
  }
}

/// Shows [path] in Finder (or Explorer, or the file manager), selected.
Future<void> revealFile(String path) async {
  if (Platform.isMacOS) {
    await Process.run('open', ['-R', path]);
  } else if (Platform.isWindows) {
    await Process.run('explorer', ['/select,', path]);
  } else {
    await Process.run('xdg-open', [File(path).parent.path]);
  }
}

/// A `file://` link to [path], which most terminals make clickable.
String fileLink(String path) => Uri.file(File(path).absolute.path).toString();

/// One thing a cleanup would remove: a file or folder in the output folder,
/// its size, and why it can go.
class CleanItem {
  /// Its path.
  final String path;

  /// Its size in bytes (a folder's, all of it).
  final int bytes;

  /// Why it can go.
  final String why;

  /// An item.
  const CleanItem(this.path, this.bytes, this.why);

  /// As JSON for the studio.
  Map<String, Object?> toJson() => {'path': path, 'bytes': bytes, 'why': why};
}

/// What `blaq_reel clean` removes from [project]'s output folder: the
/// working files every render and page leaves behind (previews of scratch
/// reels, stills, the map, looks and storyboard pages, thumbnails, stray
/// files), and with [finals] the finished videos too, all but the [keep]
/// newest. What the studio needs to work (the catalogue, the reels'
/// timelines, their latest previews) stays.
List<CleanItem> cleanPlan(
  Project project, {
  bool finals = false,
  int keep = 1,
}) {
  final out = Directory(project.out);
  if (!out.existsSync()) return const [];
  final items = <CleanItem>[];
  int size(FileSystemEntity e) => e is File
      ? e.lengthSync()
      : e is Directory
      ? e
            .listSync(recursive: true)
            .whereType<File>()
            .fold(0, (n, f) => n + f.lengthSync())
      : 0;
  void add(FileSystemEntity e, String why) =>
      items.add(CleanItem(e.path, size(e), why));

  const pages = {
    'stills': 'stills',
    'map': 'the parts map',
    'looks': 'the grounds compared',
    'storyboard': 'the storyboard',
  };
  final videos = <File>[];
  for (final e in out.listSync()) {
    final name = e.uri.pathSegments.where((s) => s.isNotEmpty).last;
    if (e is Directory && pages.containsKey(name)) {
      add(e, '${pages[name]}, made again when asked for');
    } else if (e is File) {
      if (name.endsWith('.silent.mp4')) {
        add(e, 'left over from mixing the sound');
      } else if (name.endsWith('.mp4')) {
        videos.add(e);
      } else if (name != 'last.log') {
        add(e, 'a loose file');
      }
    }
  }
  final studio = Directory('${project.out}/studio');
  if (studio.existsSync()) {
    for (final e in studio.listSync()) {
      final name = e.uri.pathSegments.where((s) => s.isNotEmpty).last;
      if (e is Directory && name == 'thumbs') {
        add(e, 'thumbnails, drawn again when shown');
      } else if (e is File &&
          (name.startsWith('_') || name.startsWith('look-'))) {
        add(e, 'a scratch render: a beat, the style or ground previews');
      } else if (e is File && name.endsWith('.silent.mp4')) {
        add(e, 'left over from mixing the sound');
      }
    }
  }
  if (finals) {
    videos.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    for (final v in videos.skip(keep)) {
      add(v, 'an older final');
    }
  }
  return items;
}

/// Removes everything in [items]; returns the bytes freed.
int cleanUp(List<CleanItem> items) {
  var freed = 0;
  for (final i in items) {
    final type = FileSystemEntity.typeSync(i.path);
    if (type == FileSystemEntityType.notFound) continue;
    if (type == FileSystemEntityType.directory) {
      Directory(i.path).deleteSync(recursive: true);
    } else {
      File(i.path).deleteSync();
    }
    freed += i.bytes;
  }
  return freed;
}

/// [bytes] as people read them.
String readableSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
  }
  return '${(bytes / 1024 / 1024 / 1024).toStringAsFixed(2)} GB';
}
