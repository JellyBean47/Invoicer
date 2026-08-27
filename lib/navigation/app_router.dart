import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/screens/forgot_password_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/verify_email_screen.dart';
import '../features/customers/screens/customer_form_screen.dart';
import '../features/customers/screens/customer_profile_screen.dart';
import '../features/customers/screens/customers_list_screen.dart';
import '../features/dashboard/screens/dashboard_screen.dart';
import '../features/expenses/screens/expense_details_screen.dart';
import '../features/expenses/screens/expense_form_screen.dart';
import '../features/expenses/screens/expenses_list_screen.dart';
import '../features/jobs/screens/job_details_screen.dart';
import '../features/jobs/screens/job_form_screen.dart';
import '../features/jobs/screens/jobs_list_screen.dart';
import '../features/invoices/screens/invoice_details_screen.dart';
import '../features/invoices/screens/invoice_form_screen.dart';
import '../features/invoices/screens/invoices_list_screen.dart';
import '../features/payments/screens/record_payment_screen.dart';
import '../features/quotes/screens/quote_details_screen.dart';
import '../features/quotes/screens/quote_form_screen.dart';
import '../features/quotes/screens/quotes_list_screen.dart';
import '../features/notifications/screens/notifications_list_screen.dart';
import '../features/reports/screens/reports_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import '../features/setup/screens/business_setup_wizard_screen.dart';
import '../features/shell/screens/main_shell.dart';
import '../providers/app_providers.dart';
import '../shared/widgets/app_loading.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final authRefresh = ValueNotifier<int>(0);

  ref.listen(authStateProvider, (_, _) {
    authRefresh.value++;
  });
  ref.listen(userProfileProvider, (_, _) {
    authRefresh.value++;
  });

  ref.onDispose(authRefresh.dispose);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: authRefresh,
    redirect: (context, state) {
      final authAsync = ref.read(authStateProvider);
      final profileAsync = ref.read(userProfileProvider);
      final location = state.matchedLocation;

      final isAuthRoute = location == '/login' ||
          location == '/register' ||
          location == '/forgot-password';
      final isSplash = location == '/splash';

      if (authAsync.isLoading || profileAsync.isLoading) {
        return isSplash ? null : '/splash';
      }

      if (authAsync.hasError) {
        return isAuthRoute ? null : '/login';
      }

      final user = authAsync.valueOrNull;
      final profile = profileAsync.valueOrNull;

      if (user == null) {
        return isAuthRoute ? null : '/login';
      }

      if (!user.emailVerified) {
        return location == '/verify-email' ? null : '/verify-email';
      }

      final hasBusiness = profile?.hasBusiness == true;
      if (!hasBusiness) {
        return location == '/setup' ? null : '/setup';
      }

      if (isAuthRoute ||
          isSplash ||
          location == '/verify-email' ||
          location == '/setup') {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const Scaffold(
          body: AppLoading(message: 'Starting Business Buddy...'),
        ),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/verify-email',
        builder: (context, state) => const VerifyEmailScreen(),
      ),
      GoRoute(
        path: '/setup',
        builder: (context, state) => const BusinessSetupWizardScreen(),
      ),
      GoRoute(
        path: '/settings',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/notifications',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const NotificationsListScreen(),
      ),
      GoRoute(
        path: '/expenses',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ExpensesListScreen(),
        routes: [
          GoRoute(
            path: 'new',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => const ExpenseFormScreen(),
          ),
          GoRoute(
            path: ':expenseId',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) {
              final expenseId = state.pathParameters['expenseId']!;
              return ExpenseDetailsScreen(expenseId: expenseId);
            },
            routes: [
              GoRoute(
                path: 'edit',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) {
                  final expenseId = state.pathParameters['expenseId']!;
                  return ExpenseFormScreen(expenseId: expenseId);
                },
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/quotes',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const QuotesListScreen(),
        routes: [
          GoRoute(
            path: 'new',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) {
              final customerId = state.uri.queryParameters['customerId'];
              return QuoteFormScreen(initialCustomerId: customerId);
            },
          ),
          GoRoute(
            path: ':quoteId',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) {
              final quoteId = state.pathParameters['quoteId']!;
              return QuoteDetailsScreen(quoteId: quoteId);
            },
            routes: [
              GoRoute(
                path: 'edit',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) {
                  final quoteId = state.pathParameters['quoteId']!;
                  return QuoteFormScreen(quoteId: quoteId);
                },
              ),
            ],
          ),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/customers',
                builder: (context, state) => const CustomersListScreen(),
                routes: [
                  GoRoute(
                    path: 'new',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const CustomerFormScreen(),
                  ),
                  GoRoute(
                    path: ':customerId',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) {
                      final customerId = state.pathParameters['customerId']!;
                      return CustomerProfileScreen(customerId: customerId);
                    },
                    routes: [
                      GoRoute(
                        path: 'edit',
                        parentNavigatorKey: _rootNavigatorKey,
                        builder: (context, state) {
                          final customerId =
                              state.pathParameters['customerId']!;
                          return CustomerFormScreen(customerId: customerId);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/jobs',
                builder: (context, state) => const JobsListScreen(),
                routes: [
                  GoRoute(
                    path: 'new',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) {
                      final customerId =
                          state.uri.queryParameters['customerId'];
                      return JobFormScreen(initialCustomerId: customerId);
                    },
                  ),
                  GoRoute(
                    path: ':jobId',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) {
                      final jobId = state.pathParameters['jobId']!;
                      return JobDetailsScreen(jobId: jobId);
                    },
                    routes: [
                      GoRoute(
                        path: 'edit',
                        parentNavigatorKey: _rootNavigatorKey,
                        builder: (context, state) {
                          final jobId = state.pathParameters['jobId']!;
                          return JobFormScreen(jobId: jobId);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/invoices',
                builder: (context, state) => const InvoicesListScreen(),
                routes: [
                  GoRoute(
                    path: 'new',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) {
                      final customerId =
                          state.uri.queryParameters['customerId'];
                      final jobId = state.uri.queryParameters['jobId'];
                      return InvoiceFormScreen(
                        initialCustomerId: customerId,
                        initialJobId: jobId,
                      );
                    },
                  ),
                  GoRoute(
                    path: ':invoiceId',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) {
                      final invoiceId = state.pathParameters['invoiceId']!;
                      return InvoiceDetailsScreen(invoiceId: invoiceId);
                    },
                    routes: [
                      GoRoute(
                        path: 'edit',
                        parentNavigatorKey: _rootNavigatorKey,
                        builder: (context, state) {
                          final invoiceId =
                              state.pathParameters['invoiceId']!;
                          return InvoiceFormScreen(invoiceId: invoiceId);
                        },
                      ),
                      GoRoute(
                        path: 'pay',
                        parentNavigatorKey: _rootNavigatorKey,
                        builder: (context, state) {
                          final invoiceId =
                              state.pathParameters['invoiceId']!;
                          return RecordPaymentScreen(invoiceId: invoiceId);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/reports',
                builder: (context, state) => const ReportsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
