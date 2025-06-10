import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:oraculum/config/routes.dart';
import 'package:oraculum/controllers/auth_controller.dart';
import 'package:oraculum/services/firebase_service.dart';

class GoogleRegisterCompleteScreen extends StatefulWidget {
  const GoogleRegisterCompleteScreen({super.key});

  @override
  State<GoogleRegisterCompleteScreen> createState() => _GoogleRegisterCompleteScreenState();
}

class _GoogleRegisterCompleteScreenState extends State<GoogleRegisterCompleteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _birthDateController = TextEditingController();
  final FirebaseService _firebaseService = Get.find<FirebaseService>();
  final AuthController _authController = Get.find<AuthController>();

  DateTime? _selectedDate;
  String _selectedGender = '';
  bool _isLoading = false;

  String _loginProvider = 'google';

  // Lista de opções de gênero
  final List<Map<String, dynamic>> _genderOptions = [
    {
      'value': 'masculino',
      'label': 'Masculino',
      'icon': Icons.male,
    },
    {
      'value': 'feminino',
      'label': 'Feminino',
      'icon': Icons.female,
    },
    {
      'value': 'outros',
      'label': 'Outros',
      'icon': Icons.more_horiz,
    },
  ];

  @override
  void initState() {
    super.initState();
    // Preencher o nome se disponível do Google
    if (_authController.currentUser.value?.displayName != null) {
      _nameController.text = _authController.currentUser.value!.displayName!;
    }

    _initializeUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  /// Valida e converte a data digitada
  DateTime? _parseDate(String dateString) {
    try {
      // Remove espaços e caracteres inválidos
      final cleanDate = dateString.replaceAll(RegExp(r'[^\d/]'), '');

      if (cleanDate.length != 10) return null; // DD/MM/AAAA deve ter 10 caracteres

      final parts = cleanDate.split('/');
      if (parts.length != 3) return null;

      final day = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final year = int.tryParse(parts[2]);

      if (day == null || month == null || year == null) return null;
      if (day < 1 || day > 31) return null;
      if (month < 1 || month > 12) return null;
      if (year < 1900 || year > DateTime.now().year) return null;

      return DateTime(year, month, day);
    } catch (e) {
      return null;
    }
  }

  /// Calcula a idade baseada na data
  int _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  Future<void> _initializeUserData() async {
    debugPrint('=== _initializeUserData() ===');

    final user = _authController.currentUser.value;
    if (user == null) {
      debugPrint('❌ Usuário não encontrado');
      return;
    }

    try {
      // Determinar o provedor de login
      _loginProvider = _determineLoginProvider(user);
      debugPrint('Provedor detectado: $_loginProvider');

      // Obter nome do usuário
      String userName = await _getUserDisplayName(user);
      debugPrint('Nome do usuário obtido: $userName');

      // Preencher o campo de nome se disponível
      if (userName.isNotEmpty && userName != 'Usuário Apple' && userName != 'Usuário') {
        _nameController.text = userName;
        debugPrint('✅ Campo de nome preenchido com: $userName');
      } else {
        debugPrint('⚠️ Nome não disponível ou é genérico, deixando campo vazio para entrada manual');
      }

      setState(() {});

    } catch (e) {
      debugPrint('❌ Erro ao inicializar dados do usuário: $e');
    }
  }

  Future<String> _getUserDisplayName(user) async {
    debugPrint('=== _getUserDisplayName() ===');

    try {
      // 1. Primeiro, tentar obter do Firebase Auth
      if (user.displayName != null &&
          user.displayName!.isNotEmpty &&
          user.displayName != 'Usuário Apple' &&
          user.displayName != 'Usuário') {
        debugPrint('Nome obtido do Firebase Auth: ${user.displayName}');
        return user.displayName!.trim();
      }

      // 2. Tentar obter do Firestore (pode ter sido salvo durante o login)
      try {
        final userDoc = await _firebaseService.getUserData(user.uid);
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;

          // Verificar nome no documento
          final firestoreName = userData['name'] as String?;
          if (firestoreName != null &&
              firestoreName.isNotEmpty &&
              firestoreName != 'Usuário Apple' &&
              firestoreName != 'Usuário') {
            debugPrint('Nome obtido do Firestore: $firestoreName');
            return firestoreName.trim();
          }

          // Para Apple, verificar se há dados salvos durante o login
          if (_loginProvider == 'apple') {
            final appleData = userData['appleSignInData'] as Map<String, dynamic>?;
            if (appleData != null) {
              final extractedName = appleData['extractedDisplayName'] as String?;
              if (extractedName != null &&
                  extractedName.isNotEmpty &&
                  extractedName != 'Usuário Apple') {
                debugPrint('Nome obtido dos dados Apple salvos: $extractedName');
                return extractedName.trim();
              }

              // Tentar construir nome dos dados Apple
              final givenName = appleData['givenName'] as String?;
              final familyName = appleData['familyName'] as String?;

              if (givenName != null && givenName.isNotEmpty) {
                final appleName = familyName != null && familyName.isNotEmpty
                    ? '$givenName $familyName'
                    : givenName;
                debugPrint('Nome construído dos dados Apple: $appleName');
                return appleName.trim();
              }
            }
          }
        }
      } catch (firestoreError) {
        debugPrint('⚠️ Erro ao obter dados do Firestore: $firestoreError');
      }

      // 3. Para Apple, tentar extrair nome do email
      if (_loginProvider == 'apple' && user.email != null) {
        final emailName = _extractNameFromEmail(user.email!);
        if (emailName.isNotEmpty) {
          debugPrint('Nome extraído do email Apple: $emailName');
          return emailName;
        }
      }

      // 4. Verificar argumentos passados pela navegação (se houver)
      final args = Get.arguments as Map<String, dynamic>?;
      if (args != null) {
        final argName = args['displayName'] as String?;
        if (argName != null && argName.isNotEmpty && argName != 'Usuário Apple') {
          debugPrint('Nome obtido dos argumentos: $argName');
          return argName.trim();
        }
      }

      debugPrint('⚠️ Nenhum nome válido encontrado');
      return '';

    } catch (e) {
      debugPrint('❌ Erro ao obter nome do usuário: $e');
      return '';
    }
  }

  String _extractNameFromEmail(String email) {
    try {
      // Não processar emails do Apple Private Relay
      if (email.contains('privaterelay.appleid.com')) {
        return '';
      }

      final localPart = email.split('@').first;

      // Remover números e caracteres especiais
      String cleanName = localPart
          .replaceAll(RegExp(r'[0-9_\.\-]'), ' ')
          .trim();

      // Capitalizar primeira letra de cada palavra
      if (cleanName.isNotEmpty) {
        return cleanName
            .split(' ')
            .where((word) => word.isNotEmpty)
            .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
            .join(' ');
      }
    } catch (e) {
      debugPrint('Erro ao extrair nome do email: $e');
    }

    return '';
  }

  String _determineLoginProvider(user) {
    try {
      final providerData = user.providerData;
      debugPrint('Provider data: ${providerData.map((p) => p.providerId).toList()}');

      for (final provider in providerData) {
        if (provider.providerId == 'apple.com') {
          return 'apple';
        } else if (provider.providerId == 'google.com') {
          return 'google';
        }
      }

      // Fallback: verificar pelo email
      final email = user.email ?? '';
      if (email.contains('privaterelay.appleid.com')) {
        return 'apple';
      }

      return 'google'; // Default
    } catch (e) {
      debugPrint('Erro ao determinar provedor: $e');
      return 'google';
    }
  }

  Future<void> _completeRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    // Validar a data digitada
    final parsedDate = _parseDate(_birthDateController.text);
    if (parsedDate == null) {
      Get.snackbar(
        'Data inválida',
        'Por favor, digite uma data válida no formato DD/MM/AAAA',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        icon: const Icon(Icons.error, color: Colors.white),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = _authController.currentUser.value;

      if (user == null) {
        throw Exception('Usuário não encontrado');
      }

      // Atualizar o displayName se foi modificado
      if (_nameController.text.trim() != user.displayName) {
        await user.updateDisplayName(_nameController.text.trim());
      }

      // Salvar as informações complementares no Firestore
      await _firebaseService.updateUserData(user.uid, {
        'name': _nameController.text.trim(),
        'birthDate': parsedDate,
        'gender': _selectedGender,
        'registrationCompleted': true,
        'completedAt': DateTime.now(),
        'profileCompleted': true,
      });

      // Recarregar os dados do usuário
      await _authController.loadUserData();

      // Navegar para a tela principal
      Get.offAllNamed(AppRoutes.navigation);

    } catch (e) {
      debugPrint('Erro ao completar registro: $e');

      Get.snackbar(
        'Erro',
        'Não foi possível salvar suas informações. Tente novamente.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        icon: const Icon(Icons.error, color: Colors.white),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildGenderSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gênero',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: _genderOptions.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            final isSelected = _selectedGender == option['value'];

            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedGender = option['value'];
                  });
                },
                child: Container(
                  margin: EdgeInsets.only(
                    right: index < _genderOptions.length - 1 ? 8 : 0,
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                          : Colors.grey.shade100,
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          option['icon'],
                          size: 24,
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey.shade600,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          option['label'],
                          style: TextStyle(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey.shade800,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(
                  delay: Duration(milliseconds: 100 * index),
                  duration: const Duration(milliseconds: 300),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF392F5A), Color(0xFF8C6BAE)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Ícone e título
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_add_rounded,
                      size: 50,
                      color: Colors.white,
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 600.ms)
                      .scale(delay: 300.ms),

                  const SizedBox(height: 24),

                  Text(
                    'Complete seu Perfil',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  )
                      .animate()
                      .fadeIn(delay: 400.ms)
                      .slideY(begin: 0.3, end: 0, curve: Curves.easeOutQuad),

                  const SizedBox(height: 12),

                  Text(
                    'Para uma experiência personalizada, precisamos de algumas informações básicas',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  )
                      .animate()
                      .fadeIn(delay: 600.ms),

                  const SizedBox(height: 32),

                  // Formulário
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 8,
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Informação sobre o Google
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: Colors.blue.shade700,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Login realizado com Google. Complete as informações abaixo.',
                                      style: TextStyle(
                                        color: Colors.blue.shade700,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Campo de nome
                            TextFormField(
                              controller: _nameController,
                              keyboardType: TextInputType.name,
                              decoration: const InputDecoration(
                                labelText: 'Nome Completo *',
                                prefixIcon: Icon(Icons.person_outline),
                                hintText: 'Digite seu nome completo',
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Por favor, digite seu nome';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 20),

                            // Campo de data de nascimento com máscara
                            TextFormField(
                              controller: _birthDateController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                _DateInputFormatter(),
                              ],
                              decoration: const InputDecoration(
                                labelText: 'Data de Nascimento *',
                                prefixIcon: Icon(Icons.calendar_today),
                                hintText: 'DD/MM/AAAA',
                                helperText: 'Digite no formato DD/MM/AAAA',
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Por favor, digite sua data de nascimento';
                                }

                                final parsedDate = _parseDate(value);
                                if (parsedDate == null) {
                                  return 'Data inválida. Use o formato DD/MM/AAAA';
                                }

                                // Verificar se a pessoa tem pelo menos 13 anos
                                final age = _calculateAge(parsedDate);
                                if (age < 13) {
                                  return 'Você deve ter pelo menos 13 anos';
                                }

                                if (age > 120) {
                                  return 'Data de nascimento parece incorreta';
                                }

                                // Atualizar a data selecionada se válida
                                _selectedDate = parsedDate;

                                return null;
                              },
                              onChanged: (value) {
                                // Atualizar _selectedDate em tempo real se a data for válida
                                final parsedDate = _parseDate(value);
                                if (parsedDate != null) {
                                  setState(() {
                                    _selectedDate = parsedDate;
                                  });
                                }
                              },
                            ),

                            const SizedBox(height: 24),

                            // Seletor de gênero
                            _buildGenderSelector(),

                            const SizedBox(height: 32),

                            // Botão de completar cadastro
                            ElevatedButton(
                              onPressed: _isLoading ? null : _completeRegistration,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                                  : const Text(
                                'Completar Cadastro',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Nota sobre privacidade
                            Text(
                              'Suas informações são seguras e serão usadas apenas para personalizar sua experiência no app.',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey.shade600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 800.ms, duration: 500.ms).slideY(begin: 0.2, end: 0),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Formatador personalizado para entrada de data DD/MM/AAAA
class _DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    final text = newValue.text;

    // Limitar a 8 dígitos (DDMMAAAA)
    if (text.length > 8) {
      return oldValue;
    }

    // Aplicar formatação conforme o usuário digita
    String formattedText = '';
    for (int i = 0; i < text.length; i++) {
      if (i == 2 || i == 4) {
        formattedText += '/';
      }
      formattedText += text[i];
    }

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}