import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zuburb_rider/bloc/auth/auth_bloc.dart';
import 'package:zuburb_rider/bloc/background_location/background_location_cubit.dart';
import 'package:zuburb_rider/bloc/session/auth_session_cubit.dart';
import 'package:zuburb_rider/presentation/screens/auth_wrapper.dart';
import 'package:zuburb_rider/presentation/screens/home_screen.dart';
import 'package:zuburb_rider/repository/auth_repository.dart';
import 'package:zuburb_rider/repository/ride_repository.dart';
import 'package:zuburb_rider/repository/rider_repository.dart';
import 'package:zuburb_rider/services/background_location_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await BackgroundLocationService.instance.initialise();
  runApp(const AppBootstrap());
}

class AppBootstrap extends StatelessWidget {
  const AppBootstrap({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (_) => AuthRepository()),
        RepositoryProvider(create: (_) => RiderRepository()),
        RepositoryProvider(create: (_) => RideRepository()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => AuthBloc(context.read<AuthRepository>()),
          ),
          BlocProvider(
            create: (context) => AuthSessionCubit(context.read<AuthRepository>()),
          ),
          BlocProvider(
            create: (_) => BackgroundLocationCubit(),
          ),
        ],
        child: const MyApp(),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const AuthWrapper(),
      routes: {"/home": (context) => const RiderHomeScreen()},
      debugShowCheckedModeBanner: false,
    );
  }
}
