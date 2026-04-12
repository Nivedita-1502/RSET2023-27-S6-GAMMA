import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'otp_verification_page.dart';

import '../../services/user_session.dart';
import '../../services/api_config.dart';
import '../../services/token_service.dart'; // ← NEW
import '../home/main_navigation.dart';


// ================= BACKGROUND =================

class KeralaBackground extends StatefulWidget {
  final Widget child;
  const KeralaBackground({super.key, required this.child});

  @override
  State<KeralaBackground> createState() => _KeralaBackgroundState();
}

class _KeralaBackgroundState extends State<KeralaBackground> {
  final videos = [
    "assets/videos/video1.mp4",
    "assets/videos/video2.mp4",
    "assets/videos/video3.mp4",
    "assets/videos/video4.mp4",
    "assets/videos/video5.mp4",
    "assets/videos/video6.mp4",
  ];

  late VideoPlayerController controller;
  int index = 0;

  @override
  void initState() {
    super.initState();
    loadVideo();
  }

  void loadVideo() {
    controller = VideoPlayerController.asset(videos[index])
      ..initialize().then((_) {
        controller.setVolume(0);
        controller.play();
        controller.addListener(() {
          if (controller.value.position >= controller.value.duration) {
            index = (index + 1) % videos.length;
            controller.dispose();
            loadVideo();
          }
        });
        setState(() {});
      });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Fallback background always visible while video loads
        Container(color: const Color(0xFF1A6B3C)),

        // Video plays on top once ready
        if (controller.value.isInitialized)
          SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: controller.value.size.width,
                height: controller.value.size.height,
                child: VideoPlayer(controller),
              ),
            ),
          ),

        // Gradient overlay always visible
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0x552E7D32), Color(0x5539A0ED)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),

        // Login card always visible
        widget.child,
      ],
    );
  }

  @override
  void dispose() {
    controller.pause();
    controller.dispose();
    super.dispose();
  }
}


// ================= COUNTRY DATA =================

class Country {
  final String name;
  final String code;
  const Country(this.name, this.code);
}

const List<Country> kCountries = [
  Country("Afghanistan", "+93"),
  Country("Albania", "+355"),
  Country("Algeria", "+213"),
  Country("Argentina", "+54"),
  Country("Australia", "+61"),
  Country("Austria", "+43"),
  Country("Bangladesh", "+880"),
  Country("Belgium", "+32"),
  Country("Brazil", "+55"),
  Country("Canada", "+1"),
  Country("Chile", "+56"),
  Country("China", "+86"),
  Country("Colombia", "+57"),
  Country("Croatia", "+385"),
  Country("Czech Republic", "+420"),
  Country("Denmark", "+45"),
  Country("Egypt", "+20"),
  Country("Ethiopia", "+251"),
  Country("Finland", "+358"),
  Country("France", "+33"),
  Country("Germany", "+49"),
  Country("Ghana", "+233"),
  Country("Greece", "+30"),
  Country("Hungary", "+36"),
  Country("India", "+91"),
  Country("Indonesia", "+62"),
  Country("Iran", "+98"),
  Country("Iraq", "+964"),
  Country("Ireland", "+353"),
  Country("Israel", "+972"),
  Country("Italy", "+39"),
  Country("Japan", "+81"),
  Country("Jordan", "+962"),
  Country("Kenya", "+254"),
  Country("Kuwait", "+965"),
  Country("Malaysia", "+60"),
  Country("Mexico", "+52"),
  Country("Morocco", "+212"),
  Country("Netherlands", "+31"),
  Country("New Zealand", "+64"),
  Country("Nigeria", "+234"),
  Country("Norway", "+47"),
  Country("Oman", "+968"),
  Country("Pakistan", "+92"),
  Country("Peru", "+51"),
  Country("Philippines", "+63"),
  Country("Poland", "+48"),
  Country("Portugal", "+351"),
  Country("Qatar", "+974"),
  Country("Romania", "+40"),
  Country("Russia", "+7"),
  Country("Saudi Arabia", "+966"),
  Country("Singapore", "+65"),
  Country("South Africa", "+27"),
  Country("South Korea", "+82"),
  Country("Spain", "+34"),
  Country("Sri Lanka", "+94"),
  Country("Sweden", "+46"),
  Country("Switzerland", "+41"),
  Country("Thailand", "+66"),
  Country("Turkey", "+90"),
  Country("UAE", "+971"),
  Country("UK", "+44"),
  Country("Ukraine", "+380"),
  Country("USA", "+1"),
  Country("Vietnam", "+84"),
];

final List<String> kNationalities = kCountries.map((c) => c.name).toList();


// ================= PASSWORD FIELD WITH SHOW/HIDE =================

class PasswordField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  const PasswordField({super.key, required this.label, required this.controller});

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: widget.controller,
        obscureText: _obscure,
        decoration: InputDecoration(
          labelText: widget.label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          suffixIcon: IconButton(
            icon: Icon(
              _obscure ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey,
            ),
            onPressed: () => setState(() => _obscure = !_obscure),
          ),
        ),
      ),
    );
  }
}


// ================= LOGIN =================

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email    = TextEditingController();
  final password = TextEditingController();
  String? errorMessage;
  bool _loading = false; // ← NEW: loading state

  // ── UPDATED login() with JWT + secure storage ─────────────────────────────
  Future<void> login() async {
    setState(() { errorMessage = null; _loading = true; });
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email.text, "password": password.text}),
      );
      final data = jsonDecode(response.body);

      if (data["status"] == "success") {
        // ── Save JWT token securely ─────────────────────────────────────────
        await TokenService.saveToken(data["token"]);

        // ── Save user session ───────────────────────────────────────────────
        UserSession.setUser(data["user"]);

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainNavigation()),
        );
      } else {
        setState(() => errorMessage = data["message"]);
      }
    } catch (e) {
      setState(() => errorMessage = "Connection error. Please try again.");
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: KeralaBackground(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height,
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: glassCard(
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset("assets/images/kathakali.png", height: 120),
                      const SizedBox(height: 20),
                      const Text(
                        "Explore Kerala With Us",
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                      ),
                      const Text("God's Own Country 🌊"),
                      const SizedBox(height: 25),
                      field("Email", controller: email),
                      PasswordField(label: "Password", controller: password),
                      if (errorMessage != null) inlineError(errorMessage!),
                      const SizedBox(height: 8),
                      // ── Show spinner while logging in ─────────────────────
                      _loading
                          ? const CircularProgressIndicator(color: Color(0xFF1A6B3C))
                          : actionButton("LOGIN", login),
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const RegisterPage()),
                        ),
                        child: const Text("New Tourist? Register"),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}


// ================= REGISTER =================

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final first     = TextEditingController();
  final middle    = TextEditingController();
  final last      = TextEditingController();
  final phone     = TextEditingController();
  final emergency = TextEditingController();
  final address   = TextEditingController();
  final email     = TextEditingController();
  final password  = TextEditingController();
  final confirm   = TextEditingController();

  String    gender         = "Male";
  String    blood          = "O+";
  String    selectedNation = "India";
  DateTime? dob;
  String?   errorMessage;
  bool      _loading       = false;

  Country selectedCountry    = kCountries.firstWhere((c) => c.name == "India");
  Country selectedEmgCountry = kCountries.firstWhere((c) => c.name == "India");

  bool get _hasLength  => password.text.length >= 8;
  bool get _hasUpper   => password.text.contains(RegExp(r'[A-Z]'));
  bool get _hasNumber  => password.text.contains(RegExp(r'[0-9]'));
  bool get _hasSpecial => password.text.contains(RegExp(r'[#@!$%^&*]'));

  @override
  void initState() {
    super.initState();
    password.addListener(() => setState(() {}));
  }

  // ── Step 1: Validate then send OTP ────────────────────────────────────────
  Future<void> signup() async {
    setState(() { errorMessage = null; _loading = true; });

    if (first.text.isEmpty || last.text.isEmpty) {
      setState(() { errorMessage = "Please enter your name."; _loading = false; });
      return;
    }
    if (dob == null) {
      setState(() { errorMessage = "Please select your date of birth."; _loading = false; });
      return;
    }
    if (phone.text.isEmpty) {
      setState(() { errorMessage = "Please enter your phone number."; _loading = false; });
      return;
    }
    if (!RegExp(r'^[\w\.\+\-]+@[\w\-]+\.[a-zA-Z]{2,}$').hasMatch(email.text)) {
      setState(() { errorMessage = "Please enter a valid email address."; _loading = false; });
      return;
    }
    if (!_hasLength || !_hasUpper || !_hasNumber || !_hasSpecial) {
      setState(() { errorMessage = "Password does not meet all requirements."; _loading = false; });
      return;
    }
    if (password.text != confirm.text) {
      setState(() { errorMessage = "Passwords do not match."; _loading = false; });
      return;
    }

    try {
      final otpRes = await http.post(
        Uri.parse("$baseUrl/otp/send"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email.text}),
      ).timeout(const Duration(seconds: 15));

      final otpData = jsonDecode(otpRes.body);

      if (otpData["status"] == "success") {
        setState(() => _loading = false);
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OTPVerificationPage(
              email: email.text,
              onVerified: _createAccount,
            ),
          ),
        );
      } else {
        setState(() {
          errorMessage = otpData["message"] ?? "Failed to send OTP.";
          _loading = false;
        });
      }
    } catch (_) {
      setState(() {
        errorMessage = "Connection error. Make sure backend is running.";
        _loading = false;
      });
    }
  }

  // ── Step 2: Create account after OTP verified ─────────────────────────────
  Future<void> _createAccount() async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/signup"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "first_name":        first.text,
          "middle_name":       middle.text,
          "last_name":         last.text,
          "gender":            gender,
          "dob":               dob.toString(),
          "phone":             "${selectedCountry.code} ${phone.text}",
          "emergency_contact": "${selectedEmgCountry.code} ${emergency.text}",
          "nationality":       selectedNation,
          "address":           address.text,
          "blood_group":       blood,
          "email":             email.text,
          "password":          password.text,
        }),
      );
      final data = jsonDecode(response.body);
      if (data["status"] == "success") {
        Navigator.popUntil(context, (route) => route.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created! Please login.'),
            backgroundColor: Color(0xFF1A6B3C),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data["message"] ?? "Signup failed"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Connection error. Please try again."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: KeralaBackground(
        child: Center(
          child: glassCard(
            SingleChildScrollView(
              child: Column(
                children: [
                  const Text(
                    "New User Registration",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  field("First Name",  controller: first),
                  field("Middle Name", controller: middle),
                  field("Last Name",   controller: last),
                  dropdown("Gender", ["Male", "Female", "Other"], (v) => gender = v!),
                  _datePicker(),
                  _phoneField("Phone", phone, selectedCountry, (c) {
                    setState(() => selectedCountry = c);
                  }),
                  _phoneField("Emergency Contact", emergency, selectedEmgCountry, (c) {
                    setState(() => selectedEmgCountry = c);
                  }),
                  _nationalityDropdown(),
                  field("Address", controller: address),
                  dropdown("Blood Group",
                      ["O+","O-","A+","A-","B+","B-","AB+","AB-"], (v) => blood = v!),
                  field("Email", controller: email),
                  PasswordField(label: "Password", controller: password),
                  _passwordChecklist(),
                  PasswordField(label: "Confirm Password", controller: confirm),
                  if (errorMessage != null) inlineError(errorMessage!),
                  const SizedBox(height: 10),
                  _loading
                      ? const CircularProgressIndicator(color: Color(0xFF1A6B3C))
                      : actionButton("SEND VERIFICATION CODE", signup),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _nationalityDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: selectedNation,
        isExpanded: true,
        items: kNationalities
            .map((n) => DropdownMenuItem(value: n, child: Text(n)))
            .toList(),
        onChanged: (v) => setState(() => selectedNation = v!),
        decoration: InputDecoration(
          labelText: "Nationality",
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _phoneField(
    String label,
    TextEditingController ctrl,
    Country selected,
    ValueChanged<Country> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Country>(
                value: selected,
                items: kCountries.map((c) => DropdownMenuItem(
                  value: c,
                  child: Text("${c.name} (${c.code})",
                      style: const TextStyle(fontSize: 13)),
                )).toList(),
                onChanged: (c) { if (c != null) onChanged(c); },
                selectedItemBuilder: (_) => kCountries.map((c) =>
                  Center(
                    child: Text(c.code,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.bold)),
                  )
                ).toList(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: ctrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: label,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _passwordChecklist() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Password must include:",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          _checkRow("At least 8 characters",            _hasLength),
          _checkRow("One uppercase letter (A-Z)",        _hasUpper),
          _checkRow("One number (0-9)",                  _hasNumber),
          _checkRow("One special character (#@!\$%^&*)", _hasSpecial),
        ],
      ),
    );
  }

  Widget _checkRow(String text, bool met) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color: met ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 6),
          Text(text,
              style: TextStyle(
                  fontSize: 12,
                  color: met ? Colors.green.shade700 : Colors.black54)),
        ],
      ),
    );
  }

  Widget _datePicker() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        shape: RoundedRectangleBorder(
          side: BorderSide(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(12),
        ),
        title: Text(
          dob == null ? "Select Date of Birth" : dob.toString().split(" ")[0],
          style: TextStyle(
              color: dob == null ? Colors.grey.shade600 : Colors.black),
        ),
        trailing: const Icon(Icons.calendar_today),
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: DateTime(2000),
            firstDate: DateTime(1950),
            lastDate: DateTime.now(),
          );
          if (picked != null) setState(() => dob = picked);
        },
      ),
    );
  }
}


// ================= UI HELPERS =================

Widget glassCard(Widget child) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(22),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
      child: Container(
        width: 360,
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.85),
          borderRadius: BorderRadius.circular(22),
        ),
        child: child,
      ),
    ),
  );
}

Widget field(String label,
    {bool hide = false, TextEditingController? controller}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: controller,
      obscureText: hide,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );
}

Widget dropdown(String label, List<String> items, Function(String?) onChange) {
  String value = items.first;
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: DropdownButtonFormField(
      value: value,
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChange,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );
}

Widget actionButton(String text, VoidCallback onTap) {
  return SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        padding: const EdgeInsets.all(14),
      ),
      onPressed: onTap,
      child: Text(text),
    ),
  );
}

Widget inlineError(String message) {
  return Builder(builder: (context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        border: Border.all(color: Colors.red.shade300),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Colors.red.shade800, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  });
}