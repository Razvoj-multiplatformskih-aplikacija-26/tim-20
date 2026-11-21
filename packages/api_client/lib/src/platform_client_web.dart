import 'package:http/browser_client.dart';
import 'package:http/http.dart' as http;

/// The browser keeps the session in an HttpOnly cookie, so the client sends credentials and no token.
const platformKeepsSessionInCookie = true;

http.Client platformHttpClient() => BrowserClient()..withCredentials = true;
