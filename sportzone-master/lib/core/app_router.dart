import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../views/splash_screen.dart';
import '../views/auth/login_page.dart';
import '../views/auth/register_page.dart';
import '../views/home_screen.dart';
import '../views/courts/court_detail_page.dart';
import '../views/booking/booking_cart_page.dart';
import '../views/booking/checkout_page.dart';
import '../views/map/map_page.dart';
import '../views/chat/chat_room_page.dart';
import '../views/notification/notification_page.dart';
import '../views/booking/booking_detail_page.dart';
import '../views/profile/my_bookings_page.dart';
import '../views/profile/profile_page.dart';
import '../views/owner/owner_courts_page.dart';
import '../views/owner/owner_court_form_page.dart';
import '../views/owner/owner_bookings_page.dart';
import '../views/admin/admin_dashboard_page.dart';

/// Cấu hình router cho toàn bộ app
class AppRouter {
  AppRouter._();

  static GoRouter createRouter(BuildContext context) {
    return GoRouter(
      initialLocation: '/',
      redirect: (context, state) {
        final auth = context.read<AuthViewModel>();
        final publicRoutes = ['/login', '/register', '/'];
        final isLoggedIn = auth.currentUser != null;
        final isPublic =
            publicRoutes.any((r) => state.matchedLocation.startsWith(r));

        // Nếu đang ở splash thì không redirect
        if (state.matchedLocation == '/') return null;

        // Chưa login và không ở trang public → về login
        if (!isLoggedIn && !isPublic) return '/login';

        return null;
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginPage(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterPage(),
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/court/:id',
          builder: (context, state) {
            final id = int.parse(state.pathParameters['id']!);
            return CourtDetailPage(courtId: id);
          },
        ),
        GoRoute(
          path: '/booking-cart',
          builder: (context, state) => const BookingCartPage(),
        ),
        GoRoute(
          path: '/checkout',
          builder: (context, state) => const CheckoutPage(),
        ),
        GoRoute(
          path: '/map',
          builder: (context, state) => const MapPage(),
        ),
        GoRoute(
          path: '/chat/:courtId',
          builder: (context, state) {
            final courtId = int.parse(state.pathParameters['courtId']!);
            return ChatRoomPage(courtId: courtId);
          },
        ),
        GoRoute(
          path: '/notifications',
          builder: (context, state) => const NotificationPage(),
        ),
        GoRoute(
          path: '/my-bookings',
          builder: (context, state) => const MyBookingsPage(),
        ),
        GoRoute(
          path: '/booking-detail/:id',
          builder: (context, state) {
            final id = int.parse(state.pathParameters['id']!);
            return BookingDetailPage(bookingId: id);
          },
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfilePage(),
        ),
        GoRoute(
          path: '/owner/courts',
          builder: (context, state) => const OwnerCourtsPage(),
        ),
        GoRoute(
          path: '/owner/court/add',
          builder: (context, state) => const OwnerCourtFormPage(),
        ),
        GoRoute(
          path: '/owner/court/edit/:id',
          builder: (context, state) {
            final id = int.parse(state.pathParameters['id']!);
            return OwnerCourtFormPage(courtId: id);
          },
        ),
        GoRoute(
          path: '/owner/bookings',
          builder: (context, state) => const OwnerBookingsPage(),
        ),
        GoRoute(
          path: '/admin/dashboard',
          builder: (context, state) => const AdminDashboardPage(),
        ),
      ],
    );
  }
}
