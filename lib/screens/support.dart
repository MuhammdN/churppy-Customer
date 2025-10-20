import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class ContactSupportScreen extends StatefulWidget {
  const ContactSupportScreen({super.key});

  @override
  State<ContactSupportScreen> createState() => _ContactSupportScreenState();
}

class _ContactSupportScreenState extends State<ContactSupportScreen> {
  static const Color purple = Color(0xFF6C2FA0);
  final TextEditingController _controller = TextEditingController();

  List<_Msg> _messages = [];
  int _userId = 0;
  bool _loading = true;
  String? _profileImageUrl; // 👤 user profile image url

  final String apiUrl =
      "https://churppy.eurekawebsolutions.com/api/contact_support.php";

  @override
  void initState() {
    super.initState();
    _loadUserIdAndFetch();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString("user");

    if (userString != null) {
      final userMap = jsonDecode(userString);
      _userId = userMap['id'];

      debugPrint("🟢 User ID from prefs: $_userId");

      if (_userId != null) {
        final url =
            "https://churppy.eurekawebsolutions.com/api/user.php?id=$_userId";
        debugPrint("🌍 Fetching user profile from $url");

        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['status'] == 'success') {
            setState(() {
              _profileImageUrl = data['data']['image'];
            });
          }
        }
      }
    }
  }

  Future<void> _loadUserIdAndFetch() async {
    final prefs = await SharedPreferences.getInstance();

    final userString = prefs.getString("user");
    if (userString != null) {
      final userMap = jsonDecode(userString);
      _userId = userMap['id'] ?? 0;
      _profileImageUrl = userMap['image'];
    }

    debugPrint("👤 Loaded user_id: $_userId, image: $_profileImageUrl");

    if (_userId != 0) {
      await _fetchMessages();
    }

    setState(() => _loading = false);
  }

  Future<void> _fetchMessages() async {
    try {
      final url = "$apiUrl?user_id=$_userId";
      debugPrint("🌍 Fetching messages from $url");

      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body['status'] == 'success') {
          final List data = body['data'];
          setState(() {
            _messages = data
                .map((e) => _Msg(
                      text: e['message'] ?? '',
                      isUser: e['is_user'].toString() == "1",
                    ))
                .toList();
          });
        }
      }
    } catch (e) {
      debugPrint("❌ Error fetching messages: $e");
    }
  }

  Future<void> _sendMessage(String text) async {
    try {
      final body = jsonEncode({
        "user_id": _userId,
        "is_user": 1,
        "message": text,
      });

      debugPrint("📤 Sending message: $body");

      final res = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['status'] == 'success') {
          debugPrint("✅ Message sent successfully");
        } else {
          debugPrint("⚠️ API error: ${data['message']}");
        }
      } else {
        debugPrint("❌ Server error: ${res.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Error sending message: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final scale = (w / 390).clamp(0.85, 1.25);
    double fs(double x) => x * scale;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(fs(20)),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 18,
                          offset: Offset(0, 10),
                        )
                      ],
                    ),
                    child: Column(
                      children: [
                        // ---- Top bar ----
                        Padding(
                          padding: EdgeInsets.fromLTRB(0, fs(8), 0, fs(4)),
                          child: Row(
                            children: [
                              IconButton(
                                onPressed: () => Navigator.maybePop(context),
                                icon: const Icon(Icons.arrow_back_ios_new,
                                    size: 18),
                                color: Colors.black87,
                                tooltip: 'Back',
                              ),
                              const Spacer(),
                              Image.asset(
                                'assets/images/logo.png',
                                height: fs(30),
                                fit: BoxFit.contain,
                              ),
                              const Spacer(),
                              SizedBox(width: fs(40)),
                            ],
                          ),
                        ),

                        // ---- Chat list ----
                        Expanded(
                          child: ListView.separated(
                            padding: EdgeInsets.symmetric(
                                horizontal: fs(12), vertical: fs(6)),
                            physics: const BouncingScrollPhysics(),
                            itemCount: _messages.length,
                            separatorBuilder: (_, __) =>
                                SizedBox(height: fs(10)),
                            itemBuilder: (context, index) {
                              final m = _messages[index];
                              return _ChatRow(
                                msg: m,
                                fs: fs,
                                purple: purple,
                                profileImageUrl: _profileImageUrl,
                              );
                            },
                          ),
                        ),

                        // ---- Input bar ----
                        Container(
                          padding: EdgeInsets.fromLTRB(
                              fs(10), fs(6), fs(10), fs(12)),
                          color: Colors.white,
                          child: Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: fs(14),
                                    vertical: fs(6),
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF3F3F5),
                                    borderRadius:
                                        BorderRadius.circular(fs(16)),
                                  ),
                                  child: TextField(
                                    controller: _controller,
                                    minLines: 1,
                                    maxLines: 4,
                                    decoration: InputDecoration(
                                      isDense: true,
                                      border: InputBorder.none,
                                      hintText: "Type here…",
                                      hintStyle: TextStyle(
                                        color: Colors.black38,
                                        fontSize: fs(14),
                                      ),
                                    ),
                                    style: TextStyle(fontSize: fs(14)),
                                  ),
                                ),
                              ),
                              SizedBox(width: fs(10)),
                              InkWell(
                                onTap: _handleSend,
                                borderRadius: BorderRadius.circular(fs(20)),
                                child: Container(
                                  width: fs(44),
                                  height: fs(44),
                                  decoration: BoxDecoration(
                                    color: purple,
                                    shape: BoxShape.circle,
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 10,
                                        offset: Offset(0, 4),
                                      )
                                    ],
                                  ),
                                  child: const Icon(Icons.send,
                                      color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  void _handleSend() {
    final txt = _controller.text.trim();
    if (txt.isEmpty) return;

    setState(() {
      _messages.add(_Msg(text: txt, isUser: true));
    });
    _controller.clear();

    _sendMessage(txt);
  }
}

// ===== Models & Widgets =====

class _Msg {
  final String text;
  final bool isUser;
  _Msg({required this.text, required this.isUser});
}

class _ChatRow extends StatelessWidget {
  final _Msg msg;
  final double Function(double) fs;
  final Color purple;
  final String? profileImageUrl;

  const _ChatRow({
    super.key,
    required this.msg,
    required this.fs,
    required this.purple,
    this.profileImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = msg.isUser;

    final bubble = Flexible(
      child: _Bubble(
        text: msg.text,
        isUser: isUser,
        fs: fs,
        purple: purple,
      ),
    );

    final avatar = isUser
        ? CircleAvatar(
            radius: fs(14),
            backgroundColor: Colors.grey[300],
            backgroundImage: profileImageUrl != null &&
                    profileImageUrl!.startsWith("http")
                ? NetworkImage(profileImageUrl!)
                : null,
            child: (profileImageUrl == null ||
                    !profileImageUrl!.startsWith("http"))
                ? Icon(
                    Icons.person,
                    size: fs(20),
                    color: Colors.grey[800],
                  )
                : null,
          )
        : CircleAvatar(
            radius: fs(14),
            backgroundImage: const AssetImage('assets/images/bot.png'),
            backgroundColor: Colors.transparent,
          );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment:
          isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: isUser
          ? [bubble, SizedBox(width: fs(6)), avatar]
          : [avatar, SizedBox(width: fs(6)), bubble],
    );
  }
}

class _Bubble extends StatelessWidget {
  final String text;
  final bool isUser;
  final double Function(double) fs;
  final Color purple;

  const _Bubble({
    required this.text,
    required this.isUser,
    required this.fs,
    required this.purple,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isUser ? purple : const Color(0xFFF1F0F6);
    final fg = isUser ? Colors.white : Colors.black87;

    final lines = text.split('\n');
    final children = <Widget>[];
    for (final line in lines) {
      if (line.trimLeft().startsWith('-')) {
        final clean = line.replaceFirst('-', '').trimLeft();
        children.add(
          Padding(
            padding: EdgeInsets.only(bottom: fs(4)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: fs(6),
                  height: fs(6),
                  margin: EdgeInsets.only(top: fs(6), right: fs(8)),
                  decoration: BoxDecoration(
                    color: fg.withOpacity(isUser ? 1 : 0.75),
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Text(
                    clean,
                    style: TextStyle(color: fg, fontSize: fs(13), height: 1.35),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        children.add(
          Padding(
            padding: EdgeInsets.only(bottom: fs(4)),
            child: Text(
              line,
              style: TextStyle(color: fg, fontSize: fs(13), height: 1.35),
            ),
          ),
        );
      }
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: fs(12), vertical: fs(10)),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(fs(14)),
          topRight: Radius.circular(fs(14)),
          bottomLeft: Radius.circular(isUser ? fs(14) : fs(4)),
          bottomRight: Radius.circular(isUser ? fs(4) : fs(14)),
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}
