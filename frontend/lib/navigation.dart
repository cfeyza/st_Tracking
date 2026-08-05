import 'package:flutter/material.dart';

/// Lets non-widget code (like [ApiClient]) trigger navigation, e.g. bouncing
/// back to the login screen when a session expires.
final navigatorKey = GlobalKey<NavigatorState>();
