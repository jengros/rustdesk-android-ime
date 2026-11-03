import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

const personalUpdateManifestUrl =
    'https://raw.githubusercontent.com/jengros/rustdesk-android-ime/personal/android-korean-ime/personal/update.json';
const personalUpdateDownloadUrl =
    'https://drive.google.com/file/d/1wi2K5OqEb2EIuNcDF6BfgBPOJi0yQXra/view';
const personalAndroidPackage = 'com.carriez.flutter_hbb.kykpersonal';

class PersonalAndroidUpdate {
  final String version;
  final Uri downloadUrl;

  const PersonalAndroidUpdate(this.version, this.downloadUrl);

  static PersonalAndroidUpdate? parse(String body, String installedVersion) {
    final data = jsonDecode(body);
    if (data is! Map<String, dynamic> ||
        data['schema'] != 1 ||
        data['package_id'] != personalAndroidPackage ||
        data['download_url'] != personalUpdateDownloadUrl ||
        data['version'] is! String) return null;
    List<int>? parts(String version) {
      final match =
          RegExp(r'^(\d+)\.(\d+)\.(\d+)-kyk\.(\d+)$').firstMatch(version);
      return match == null
          ? null
          : [for (var i = 1; i <= 4; i++) int.parse(match.group(i)!)];
    }

    final latest = parts(data['version']);
    final current = parts(installedVersion);
    if (latest == null || current == null) return null;
    for (var i = 0; i < latest.length; i++) {
      if (latest[i] < current[i]) return null;
      if (latest[i] > current[i]) {
        return PersonalAndroidUpdate(
            data['version'], Uri.parse(personalUpdateDownloadUrl));
      }
    }
    return null;
  }
}

Future<PersonalAndroidUpdate?> fetchPersonalAndroidUpdate(
    http.Client client, String installedVersion) async {
  final response = await client.get(Uri.parse(personalUpdateManifestUrl),
      headers: {
        'Cache-Control': 'no-cache'
      }).timeout(const Duration(seconds: 8));
  if (response.statusCode != 200 || response.bodyBytes.length > 16384) {
    return null;
  }
  return PersonalAndroidUpdate.parse(
      utf8.decode(response.bodyBytes), installedVersion);
}

class PersonalAndroidUpdateNotice extends StatefulWidget {
  const PersonalAndroidUpdateNotice({super.key});

  @override
  State<PersonalAndroidUpdateNotice> createState() =>
      _PersonalAndroidUpdateNoticeState();
}

class _PersonalAndroidUpdateNoticeState
    extends State<PersonalAndroidUpdateNotice> {
  final _client = http.Client();
  PersonalAndroidUpdate? _update;
  bool _opening = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    try {
      final installed = await PackageInfo.fromPlatform();
      if (installed.packageName != personalAndroidPackage) return;
      final update =
          await fetchPersonalAndroidUpdate(_client, installed.version);
      if (!mounted || update == null) return;
      setState(() => _update = update);
    } catch (error) {
      // Startup/network failure must not interrupt a remote connection.
      debugPrint('Personal update check failed: $error');
    }
  }

  Future<void> _download() async {
    if (_opening || _update == null) return;
    setState(() {
      _opening = true;
      _error = null;
    });
    try {
      if (!await launchUrl(_update!.downloadUrl,
          mode: LaunchMode.externalApplication)) {
        throw StateError('Drive could not be opened');
      }
    } catch (_) {
      if (mounted) setState(() => _error = '다운로드 화면을 열지 못했습니다. 다시 눌러주세요.');
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  void dispose() {
    _client.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final update = _update;
    if (update == null) return const SizedBox.shrink();
    return Card(
      child: ListTile(
        leading: const Icon(Icons.system_update),
        title: Text('새 버전 ${update.version}'),
        subtitle: Text(_error ?? '눌러서 다운로드·설치 (Drive 로그인이 필요할 수 있습니다)'),
        trailing: _opening
            ? const SizedBox(
                width: 20, height: 20, child: CircularProgressIndicator())
            : const Icon(Icons.download),
        onTap: _opening ? null : _download,
      ),
    );
  }
}
