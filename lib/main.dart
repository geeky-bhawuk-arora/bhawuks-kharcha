import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pocket_ledger/core/constants.dart';
import 'package:pocket_ledger/features/expenses/data/models/expense_model.dart';
import 'package:pocket_ledger/features/expenses/presentation/screens/dashboard_screen.dart';
import 'package:pocket_ledger/features/auth/presentation/auth_notifier.dart';
import 'package:pocket_ledger/features/auth/presentation/screens/auth_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(ExpenseAdapter());
  }
  final expenseBox = await Hive.openBox<Expense>('expenses');

  // Initialize Supabase
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  runApp(
    ProviderScope(
      overrides: [
        expenseBoxProvider.overrideWithValue(expenseBox),
      ],
      child: const PocketLedgerApp(),
    ),
  );
}

final expenseBoxProvider = Provider<Box<Expense>>((ref) => throw UnimplementedError());

class PocketLedgerApp extends ConsumerWidget {
  const PocketLedgerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return MaterialApp(
      title: 'PocketLedger',
      debugShowCheckedModeBanner: false,
      // "Bhawuk-Style" High-End Dark Theme
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF000000), // Midnight Black
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFFFFFF), // Electric White
          secondary: Color(0xFF888888), // Soft Slate
          surface: Color(0xFF0A0A0A), // Deep Charcoal
          outline: Color(0xFF1F1F1F), // Sharp Thin Borders
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
          displayLarge: GoogleFonts.robotoMono(color: Colors.white),
          displayMedium: GoogleFonts.robotoMono(color: Colors.white),
          bodyLarge: GoogleFonts.inter(color: Colors.white),
          bodyMedium: GoogleFonts.inter(color: const Color(0xFF888888)),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF0A0A0A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Color(0xFF1F1F1F), width: 1),
          ),
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF0A0A0A),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF1F1F1F)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF1F1F1F)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFFFFFFF)),
          ),
        ),
      ),
      themeMode: ThemeMode.dark,
      home: authState.isAuthenticated ? const DashboardScreen() : const AuthScreen(),
    );
  }
}
