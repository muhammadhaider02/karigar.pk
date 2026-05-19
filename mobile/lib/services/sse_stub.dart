// Stub used on non-web platforms. The native flow uses streamSession in
// api_client.dart directly via package:http. This is just here so conditional
// imports compile.
Stream<Map<String, dynamic>> webStreamSession(String url) async* {}
