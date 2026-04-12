import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import '../../../services/api_config.dart';// ← centralized URL
import 'dart:convert';

const _bg      = Color(0xFFF5F6F8);
const _white   = Colors.white;
const _primary = Color(0xFF1A6B3C);
const _dark    = Color(0xFF0D1B12);
const _light   = Color(0xFF9EB5A8);


class PriceCheckerPage extends StatefulWidget {
  const PriceCheckerPage({super.key});

  @override
  State<PriceCheckerPage> createState() => _PriceCheckerPageState();
}

class _PriceCheckerPageState extends State<PriceCheckerPage> {
  String service = "auto_per_km";

  final TextEditingController priceController    = TextEditingController();
  final TextEditingController quantityController = TextEditingController();

  String? resultExpected;
  String? resultStatus;
  String? errorMessage;
  bool    loading = false;

  // Maps service key → display label
  static const _services = {
    "taxi_per_km":   "Taxi (per km)",
    "auto_per_km":   "Auto Rickshaw (per km)",
    "bus_ticket":    "Bus Ticket",
    "museum_entry":  "Museum Entry",
  };

  Future<void> checkPrice() async {
    setState(() { errorMessage = null; resultExpected = null; resultStatus = null; });

    if (priceController.text.isEmpty || quantityController.text.isEmpty) {
      setState(() => errorMessage = "Please enter both price and quantity.");
      return;
    }

    final charged  = double.tryParse(priceController.text);
    final quantity = int.tryParse(quantityController.text);

    if (charged == null || quantity == null) {
      setState(() => errorMessage = "Please enter valid numbers.");
      return;
    }

    setState(() => loading = true);

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/assistant/price-check"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "service":       service,
          "charged_price": charged,
          "quantity":      quantity,
        }),
      );

      final data = jsonDecode(response.body);
      setState(() {
        resultExpected = "₹${data["expected_price"]}";
        resultStatus   = data["price_status"];
        loading        = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = "Connection error. Check backend.";
        loading      = false;
      });
    }
  }

  Color _statusColor(String status) {
    if (status.toLowerCase().contains("fair") ||
        status.toLowerCase().contains("ok")) return const Color(0xFF1A6B3C);
    if (status.toLowerCase().contains("over")) return Colors.red.shade700;
    return Colors.orange.shade700;
  }

  IconData _statusIcon(String status) {
    if (status.toLowerCase().contains("fair") ||
        status.toLowerCase().contains("ok")) return Icons.check_circle_rounded;
    if (status.toLowerCase().contains("over")) return Icons.warning_rounded;
    return Icons.info_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Price Checker",
          style: GoogleFonts.urbanist(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: _dark,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Header banner ───────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.price_check_rounded,
                      color: Colors.white70, size: 40),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Check Overpricing",
                          style: GoogleFonts.urbanist(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: _white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Verify if you're being charged fairly",
                          style: GoogleFonts.urbanist(
                            fontSize: 12,
                            color: Colors.white60,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Form card ───────────────────────────────────────────────────
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Service dropdown
                  Text("Select Service",
                      style: GoogleFonts.urbanist(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _light)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: _bg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _primary.withOpacity(.15)),
                    ),
                    child: DropdownButton<String>(
                      value: service,
                      isExpanded: true,
                      underline: const SizedBox(),
                      icon: const Icon(Icons.keyboard_arrow_down_rounded,
                          color: _primary),
                      items: _services.entries
                          .map((e) => DropdownMenuItem(
                                value: e.key,
                                child: Text(e.value,
                                    style: GoogleFonts.urbanist(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: _dark)),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() {
                        service = v!;
                        resultExpected = null;
                        resultStatus   = null;
                      }),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Price field
                  Text("Charged Price (₹)",
                      style: GoogleFonts.urbanist(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _light)),
                  const SizedBox(height: 8),
                  _inputField(
                    controller: priceController,
                    hint: "e.g. 150",
                    icon: Icons.currency_rupee_rounded,
                  ),

                  const SizedBox(height: 18),

                  // Quantity field
                  Text("Quantity (km / tickets / people)",
                      style: GoogleFonts.urbanist(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _light)),
                  const SizedBox(height: 8),
                  _inputField(
                    controller: quantityController,
                    hint: "e.g. 10",
                    icon: Icons.numbers_rounded,
                  ),

                  const SizedBox(height: 22),

                  // Error
                  if (errorMessage != null)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEBEE),
                        border: Border.all(color: Colors.red.shade300),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline,
                              color: Colors.red.shade700, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(errorMessage!,
                                style: TextStyle(
                                    color: Colors.red.shade800,
                                    fontSize: 13)),
                          ),
                        ],
                      ),
                    ),

                  // Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: loading ? null : checkPrice,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        padding: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              "Check Price",
                              style: GoogleFonts.urbanist(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: _white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Result card ─────────────────────────────────────────────────
            if (resultStatus != null) ...[
              const SizedBox(height: 16),
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Result",
                      style: GoogleFonts.urbanist(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: _dark,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEF5F1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Expected Price",
                                    style: GoogleFonts.urbanist(
                                        fontSize: 12,
                                        color: _light,
                                        fontWeight: FontWeight.w600)),
                                const SizedBox(height: 4),
                                Text(
                                  resultExpected!,
                                  style: GoogleFonts.urbanist(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: _primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _statusColor(resultStatus!)
                                  .withOpacity(.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: _statusColor(resultStatus!)
                                      .withOpacity(.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Status",
                                    style: GoogleFonts.urbanist(
                                        fontSize: 12,
                                        color: _light,
                                        fontWeight: FontWeight.w600)),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(_statusIcon(resultStatus!),
                                        color: _statusColor(resultStatus!),
                                        size: 18),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        resultStatus!,
                                        style: GoogleFonts.urbanist(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: _statusColor(resultStatus!),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: GoogleFonts.urbanist(fontSize: 15, color: _dark),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.urbanist(color: _light, fontSize: 14),
        prefixIcon: Icon(icon, color: _primary, size: 18),
        filled: true,
        fillColor: _bg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _primary.withOpacity(.4)),
        ),
      ),
    );
  }
}