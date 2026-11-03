import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/app_colors.dart';
import 'firebase_options.dart';
import 'services/firestore_service.dart';
import 'services/notification_service.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/booking_viewmodel.dart';
import 'viewmodels/chat_viewmodel.dart';
import 'viewmodels/court_viewmodel.dart';
import 'viewmodels/notification_viewmodel.dart';
import 'views/auth/login_page.dart';
import 'views/auth/register_page.dart';
import 'views/booking/booking_cart_page.dart';
import 'views/booking/booking_detail_page.dart';
import 'views/booking/checkout_page.dart';
import 'views/chat/chat_room_page.dart';
import 'views/courts/court_detail_page.dart';
import 'views/home_screen.dart';
import 'views/map/map_page.dart';
import 'views/notification/notification_page.dart';
import 'views/profile/my_bookings_page.dart';
import 'views/profile/profile_page.dart';
import 'views/splash_screen.dart';
import 'views/owner/owner_courts_page.dart';
import 'views/owner/owner_court_form_page.dart';
import 'views/owner/owner_bookings_page.dart';
import 'views/admin/admin_dashboard_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final dbService = FirestoreService();

  // Khởi tạo local notifications
  await NotificationService().init();

  // Tạo ViewModels trước để router có thể dùng authViewModel
  final authVm = AuthViewModel(dbService);
  final courtVm = CourtViewModel(dbService);
  final bookingVm = BookingViewModel(dbService);
  final chatVm = ChatViewModel(dbService);
  final notifVm = NotificationViewModel(dbService);

  // Cấu hình router với refreshListenable = authVm để tự redirect khi login/logout
  final router = GoRouter(
    refreshListenable: authVm,
    initialLocation: '/',
    redirect: (context, state) {
      final isLoggedIn = authVm.currentUser != null;
      final loc = state.matchedLocation;
      final isPublic =
          loc == '/' || loc == '/login' || loc == '/register';
      if (!isLoggedIn && !isPublic) return '/login';
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        builder: (_, __) => const RegisterPage(),
      ),
      GoRoute(
        path: '/home',
        builder: (_, __) => const HomeScreen(),
      ),
      GoRoute(
        path: '/court/:id',
        builder: (_, state) {
          final id = int.parse(state.pathParameters['id']!);
          return CourtDetailPage(courtId: id);
        },
      ),
      GoRoute(
        path: '/booking-cart',
        builder: (_, __) => const BookingCartPage(),
      ),
      GoRoute(
        path: '/checkout',
        builder: (_, __) => const CheckoutPage(),
      ),
      GoRoute(
        path: '/map',
        builder: (_, __) => const MapPage(),
      ),
      GoRoute(
        path: '/chat/:courtId',
        builder: (_, state) {
          final courtId =
              int.parse(state.pathParameters['courtId']!);
          return ChatRoomPage(courtId: courtId);
        },
      ),
      GoRoute(
        path: '/notifications',
        builder: (_, __) => const NotificationPage(),
      ),
      GoRoute(
        path: '/my-bookings',
        builder: (_, __) => const MyBookingsPage(),
      ),
      GoRoute(
        path: '/booking-detail/:id',
        builder: (_, state) {
          final id = int.parse(state.pathParameters['id']!);
          return BookingDetailPage(bookingId: id);
        },
      ),
      GoRoute(
        path: '/profile',
        builder: (_, __) => const ProfilePage(),
      ),
      GoRoute(
        path: '/owner/courts',
        builder: (_, __) => const OwnerCourtsPage(),
      ),
      GoRoute(
        path: '/owner/court/add',
        builder: (_, __) => const OwnerCourtFormPage(),
      ),
      GoRoute(
        path: '/owner/court/edit/:id',
        builder: (_, state) {
          final id = int.parse(state.pathParameters['id']!);
          return OwnerCourtFormPage(courtId: id);
        },
      ),
      GoRoute(
        path: '/owner/bookings',
        builder: (_, __) => const OwnerBookingsPage(),
      ),
      GoRoute(
        path: '/admin/dashboard',
        builder: (_, __) => const AdminDashboardPage(),
      ),
    ],
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthViewModel>.value(value: authVm),
        ChangeNotifierProvider<CourtViewModel>.value(value: courtVm),
        ChangeNotifierProvider<BookingViewModel>.value(value: bookingVm),
        ChangeNotifierProvider<ChatViewModel>.value(value: chatVm),
        ChangeNotifierProvider<NotificationViewModel>.value(value: notifVm),
      ],
      child: SportZoneApp(router: router),
    ),
  );
}

class SportZoneApp extends StatelessWidget {
  final GoRouter router;
  const SportZoneApp({super.key, required this.router});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'SportZone',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          surface: AppColors.surface,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.surface,
          elevation: 0,
          scrolledUnderElevation: 0,
          titleTextStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
          iconTheme: IconThemeData(color: AppColors.textPrimary),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: AppColors.surface,
          elevation: 0,
          indicatorColor: AppColors.primaryLight,
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(
                fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ),
      ),
      routerConfig: router,
    );
  }
}
