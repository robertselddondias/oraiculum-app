import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oraculum/controllers/auth_controller.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AppleSignInButton extends StatelessWidget {
  final String? text;
  final double? height;
  final double? borderRadius;

  const AppleSignInButton({
    super.key,
    this.text,
    this.height = 50,
    this.borderRadius = 25,
  });

  @override
  Widget build(BuildContext context) {
    // Só mostrar o botão no iOS ou se estivermos testando
    if (!Platform.isIOS) {
      return const SizedBox.shrink();
    }

    // Obter o AuthController
    final AuthController authController = Get.find<AuthController>();

    return FutureBuilder<bool>(
      future: authController.isAppleSignInAvailable(),
      builder: (context, snapshot) {
        // Se não conseguir verificar ou não estiver disponível, não mostrar
        if (!snapshot.hasData || !snapshot.data!) {
          return const SizedBox.shrink();
        }

        return Obx(() {
          final isLoading = authController.isLoading.value;

          return SizedBox(
            height: height,
            width: double.infinity,
            child: SignInWithAppleButton(
              text: text ?? 'Continuar com Apple',
              height: height!,
              style: SignInWithAppleButtonStyle.black,
              borderRadius: BorderRadius.circular(borderRadius!),
              onPressed: isLoading
                  ? () {}
                  : () async {
                await authController.signInWithApple();
              },
            ),
          );
        });
      },
    );
  }
}

class CustomAppleSignInButton extends StatelessWidget {
  final String? text;
  final double? height;
  final double? borderRadius;
  final Color? backgroundColor;
  final Color? textColor;

  const CustomAppleSignInButton({
    super.key,
    this.text,
    this.height = 50,
    this.borderRadius = 10,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    // Só mostrar o botão no iOS
    if (!Platform.isIOS) {
      return const SizedBox.shrink();
    }

    // Obter o AuthController
    final AuthController authController = Get.find<AuthController>();

    return FutureBuilder<bool>(
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!) {
          return const SizedBox.shrink();
        }

        return Obx(() {
          final isLoading = authController.isLoading.value;

          return SizedBox(
            height: height,
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isLoading
                  ? null
                  : () async {
                await authController.signInWithApple();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: backgroundColor ?? Colors.black,
                foregroundColor: textColor ?? Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(borderRadius!),
                ),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              icon: isLoading
                  ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    textColor ?? Colors.white,
                  ),
                ),
              )
                  : _buildAppleIcon(),
              label: Text(
                isLoading
                    ? 'Entrando...'
                    : (text ?? 'Continuar com Apple'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textColor ?? Colors.white,
                ),
              ),
            ),
          );
        });
      },
      future: authController.isAppleSignInAvailable(),
    );
  }

  Widget _buildAppleIcon() {
    return SizedBox(
      width: 20,
      height: 20,
      child: Icon(
        Icons.apple,
        color: textColor ?? Colors.white,
        size: 20,
      ),
    );
  }
}