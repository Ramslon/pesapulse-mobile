import 'package:flutter/material.dart';
import 'dart:async';
import '../services/api_services.dart';
import 'package:flutter/services.dart';
import '../widgets/custom_button.dart';
import '../widgets/auth_message_helper.dart';

import 'reset_password_screen.dart';

class VerifyOtpScreen extends StatefulWidget {
  final String email;

  const VerifyOtpScreen({super.key, required this.email});

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final _formKey = GlobalKey<FormState>();

  bool _autoValidate = false;

  bool isLoading = false;

  final List<TextEditingController> otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );

  final List<FocusNode> otpFocusNodes = List.generate(6, (_) => FocusNode());

  String get enteredOtp => otpControllers.map((e) => e.text).join();

  Timer? _timer;

  int _remainingSeconds = 600; // 10 minutes

  int _resendCooldown = 60;

  Timer? _resendTimer;

  Future<void> verifyOtp() async {
    if (enteredOtp.length != 6) {
      AuthMessageHelper.showError(context, "Please enter the complete OTP.");
      return;
    }

    FocusScope.of(context).unfocus();

    if (isLoading) return;

    setState(() => isLoading = true);

    try {
      final response = await ApiService.verifyOtp(widget.email, enteredOtp);

      if (!mounted) return;

      setState(() => isLoading = false);

      // Use helper for success message
      AuthMessageHelper.showSuccess(context, response["message"]);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              ResetPasswordScreen(email: widget.email, otp: enteredOtp),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => isLoading = false);

      // Use helper for offline/error
      AuthMessageHelper.showOffline(context);
    }
  }

  Future<void> resendOtp() async {
    try {
      final response = await ApiService.forgotPassword(widget.email);

      if (!mounted) return;

      AuthMessageHelper.showSuccess(context, response["message"]);

      // Restart timers
      startCountdown();

      startResendCooldown();
    } catch (e) {
      if (!mounted) return;

      // Use helper for offline/error
      AuthMessageHelper.showOffline(context);
    }
  }

  void startCountdown() {
    _timer?.cancel();

    _remainingSeconds = 600;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds == 0) {
        timer.cancel();
      } else {
        if (mounted) {
          setState(() {
            _remainingSeconds--;
          });
        }
      }
    });
  }

  void startResendCooldown() {
    _resendTimer?.cancel();

    _resendCooldown = 60;

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCooldown == 0) {
        timer.cancel();
      } else {
        if (mounted) {
          setState(() {
            _resendCooldown--;
          });
        }
      }
    });
  }

  String get formattedTime {
    final minutes = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');

    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');

    return "$minutes:$seconds";
  }

  @override
  void initState() {
    super.initState();

    startCountdown();

    _resendTimer?.cancel();

    startResendCooldown();
  }

  @override
  void dispose() {
    _timer?.cancel();

    _resendTimer?.cancel();

    for (final controller in otpControllers) {
      controller.dispose();
    }

    for (final node in otpFocusNodes) {
      node.dispose();
    }

    super.dispose();
  }

  Widget _buildOtpBox(int index) {
    return SizedBox(
      width: 52,
      height: 62,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            if (otpFocusNodes[index].hasFocus)
              BoxShadow(
                color: Theme.of(context).primaryColor.withOpacity(.18),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: TextFormField(
          controller: otpControllers[index],
          focusNode: otpFocusNodes[index],

          textAlign: TextAlign.center,

          keyboardType: TextInputType.number,

          textInputAction: TextInputAction.next,

          maxLength: index == 0 ? 6 : 1,

          inputFormatters: [FilteringTextInputFormatter.digitsOnly],

          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),

          decoration: InputDecoration(
            counterText: "",

            filled: true,

            fillColor: Colors.grey.shade100,

            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),

            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),

            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(
                color: Theme.of(context).primaryColor,
                width: 2,
              ),
            ),
          ),

          onChanged: (value) {
            // paste
            if (index == 0 && value.length > 1) {
              final digits = value.replaceAll(RegExp(r'[^0-9]'), '');

              for (int i = 0; i < digits.length && i < 6; i++) {
                otpControllers[i].text = digits[i];
              }

              FocusScope.of(context).unfocus();

              return;
            }

            if (value.isNotEmpty && index < 5) {
              otpFocusNodes[index + 1].requestFocus();
            }

            if (value.isEmpty && index > 0) {
              otpFocusNodes[index - 1].requestFocus();
            }

            if (enteredOtp.length == 6) {
              FocusScope.of(context).unfocus();
            }

            setState(() {});
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,

      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 30),

                IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),

                const SizedBox(height: 20),

                Center(
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
                      ),
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: const Icon(
                      Icons.verified_user_rounded,
                      color: Colors.green,
                      size: 36,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                Text(
                  "Verify OTP",
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  "Enter the 6-digit verification code sent to:",
                  style: TextStyle(color: Colors.grey.shade600),
                ),

                const SizedBox(height: 6),

                Text(
                  widget.email,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 20),

                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: _remainingSeconds > 60
                          ? Colors.green.shade50
                          : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _remainingSeconds > 60
                            ? Colors.green.shade200
                            : Colors.red.shade200,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 20,
                          color: _remainingSeconds > 60
                              ? Colors.green
                              : Colors.red,
                        ),

                        const SizedBox(width: 8),

                        Text(
                          "Code expires in",
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        const SizedBox(width: 8),

                        Text(
                          formattedTime,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: _remainingSeconds > 60
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 35),

                Form(
                  key: _formKey,
                  autovalidateMode: _autoValidate
                      ? AutovalidateMode.onUserInteraction
                      : AutovalidateMode.disabled,
                  child: Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 10,
                            runSpacing: 10,
                            children: List.generate(
                              6,
                              (index) => _buildOtpBox(index),
                            ),
                          ),

                          const SizedBox(height: 30),

                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: CustomButton(
                              text: "Verify OTP",
                              isLoading: isLoading,
                              onPressed: enteredOtp.length == 6
                                  ? () async {
                                      await verifyOtp();
                                    }
                                  : null,
                            ),
                          ),

                          const SizedBox(height: 20),

                          TextButton.icon(
                            onPressed: _resendCooldown == 0 ? resendOtp : null,
                            icon: const Icon(Icons.refresh_rounded),
                            label: Text(
                              _resendCooldown == 0
                                  ? "Resend OTP"
                                  : "Resend in ${_resendCooldown}s",
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
