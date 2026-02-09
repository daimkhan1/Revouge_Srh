// Location: lib/screens/return_portal.dart

import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'home_screen.dart'; // IMPORTANT: Imports your Buying Interface
import 'customer_dashboard.dart';

/* ----------------------------- MODELS ----------------------------- */

enum Role { customer, buyer, admin }
enum ReturnMode { loop, classic }
enum OfferStatus { available, accepted, rejected, warehouse }
enum Confidence { high, medium, low }

class UserProfile {
  final String id, name, email, password, address;
  UserProfile(this.id, this.name, this.email, this.password, this.address);
}

// Renamed to ReturnItem to avoid conflict with Product model
class ReturnItem {
  final String sku, name, brand, category, size;
  final double price;
  const ReturnItem({
    required this.sku,
    required this.name,
    required this.brand,
    required this.category,
    required this.size,
    required this.price,
  });
}

class Order {
  final String id, userId;
  final DateTime date;
  final List<ReturnItem> items;
  Order(this.id, this.userId, this.date, this.items);
}

class ReturnEvent {
  final String label;
  final DateTime time;
  ReturnEvent(this.label, this.time);
}

class ReturnRequest {
  final String id, orderId, sku, customerId;
  final String reason, condition, notes;
  final List<String> photoPaths;
  final int score;
  final Confidence confidence;
  final ReturnMode mode;
  final DateTime createdAt;
  final List<ReturnEvent> events;

  ReturnRequest({
    required this.id,
    required this.orderId,
    required this.sku,
    required this.customerId,
    required this.reason,
    required this.condition,
    required this.notes,
    required this.photoPaths,
    required this.score,
    required this.confidence,
    required this.mode,
    required this.createdAt,
    required this.events,
  });

  ReturnRequest copyWith({List<ReturnEvent>? events}) => ReturnRequest(
    id: id,
    orderId: orderId,
    sku: sku,
    customerId: customerId,
    reason: reason,
    condition: condition,
    notes: notes,
    photoPaths: photoPaths,
    score: score,
    confidence: confidence,
    mode: mode,
    createdAt: createdAt,
    events: events ?? this.events,
  );
}

class Offer {
  final String id, returnId, sku, customerId;
  final double price;
  final DateTime expiresAt;
  OfferStatus status;
  String? buyerId;

  Offer({
    required this.id,
    required this.returnId,
    required this.sku,
    required this.customerId,
    required this.price,
    required this.expiresAt,
    this.status = OfferStatus.available,
    this.buyerId,
  });
}

class RulesPolicy {
  Set<String> allowedCategories;
  int minScoreForLoop;
  int maxRejectsBeforeWarehouse;
  RulesPolicy({
    required this.allowedCategories,
    required this.minScoreForLoop,
    required this.maxRejectsBeforeWarehouse,
  });
}

/* ----------------------------- APP STATE ----------------------------- */

class AppState extends ChangeNotifier {
  UserProfile? me;
  Role role = Role.customer;

  final List<UserProfile> _users = [];
  final List<Order> _orders = [];
  final List<ReturnRequest> _returns = [];
  final List<Offer> _offers = [];

  RulesPolicy rules = RulesPolicy(
    allowedCategories: {'Shoes', 'Jackets', 'Hoodies', 'Books'},
    minScoreForLoop: 70,
    maxRejectsBeforeWarehouse: 2,
  );

  AppState() {
    _seedDemoData();
  }

  /* ---- AUTH ---- */

  bool register(String name, String email, String password, String address) {
    if (_users.any((u) => u.email.toLowerCase() == email.toLowerCase())) return false;
    final u = UserProfile(_id(), name.trim(), email.trim(), password, address.trim());
    _users.add(u);
    _orders.addAll(_sampleOrders(u.id));
    notifyListeners();
    return true;
  }

  bool signIn(String email, String password) {
    final match = _users.where((u) =>
    u.email.toLowerCase() == email.toLowerCase() && u.password == password);
    if (match.isEmpty) return false;
    me = match.first;
    notifyListeners();
    return true;
  }

  void signOut() {
    me = null;
    role = Role.customer;
    notifyListeners();
  }

  void setRole(Role r) {
    role = r;
    notifyListeners();
  }

  /* ---- GETTERS ---- */

  List<Order> get myOrders {
    final uid = me?.id;
    if (uid == null) return [];
    final list = _orders.where((o) => o.userId == uid).toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  List<ReturnRequest> get myReturns {
    final uid = me?.id;
    if (uid == null) return [];
    final list = _returns.where((r) => r.customerId == uid).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  ReturnItem? itemBySku(String sku) {
    for (final o in _orders) {
      for (final it in o.items) {
        if (it.sku == sku) return it;
      }
    }
    return null;
  }

  List<Offer> get availableDeals {
    final now = DateTime.now();
    return _offers
        .where((o) => o.status == OfferStatus.available && o.expiresAt.isAfter(now))
        .toList();
  }

  List<ReturnRequest> get exceptionsQueue {
    final low = _returns.where((r) => r.confidence == Confidence.low);
    final below = _returns.where((r) => r.mode == ReturnMode.loop && r.score < rules.minScoreForLoop);
    final whIds = _offers.where((o) => o.status == OfferStatus.warehouse).map((o) => o.returnId).toSet();
    final whReturns = _returns.where((r) => whIds.contains(r.id));
    final list = {...low, ...below, ...whReturns}.toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  /* ---- SCORING ---- */

  (int, Confidence) computeScore({
    required ReturnItem item,
    required String reason,
    required String condition,
    required int photoCount,
    required String notes,
  }) {
    var s = 50;
    s += min(30, photoCount * 10);
    if (condition == 'New') s += 25;
    if (condition == 'Like-new') s += 15;
    if (condition == 'Used') s -= 10;
    final r = reason.toLowerCase();
    if (r.contains('damag')) s -= 35;
    if (r.contains('size') || r.contains('fit')) s += 5;
    if (r.contains('changed') || r.contains('not needed') || r.contains('mind')) s += 3;
    if (rules.allowedCategories.contains(item.category)) { s += 10; } else { s -= 15; }
    if (notes.trim().length >= 15) s += 5;
    s = s.clamp(0, 100);
    final conf = s >= 80 ? Confidence.high : (s >= 50 ? Confidence.medium : Confidence.low);
    return (s, conf);
  }

  /* ---- CORE FLOW ---- */

  ReturnRequest createReturn({
    required Order order,
    required ReturnItem item,
    required String reason,
    required String condition,
    required String notes,
    required List<String> photoPaths,
    required ReturnMode mode,
  }) {
    final uid = me!.id;
    final (score, conf) = computeScore(
      item: item,
      reason: reason,
      condition: condition,
      photoCount: photoPaths.length,
      notes: notes,
    );

    final rr = ReturnRequest(
      id: _id(),
      orderId: order.id,
      sku: item.sku,
      customerId: uid,
      reason: reason,
      condition: condition,
      notes: notes,
      photoPaths: List.of(photoPaths),
      score: score,
      confidence: conf,
      mode: mode,
      createdAt: DateTime.now(),
      events: [
        ReturnEvent('Submitted', DateTime.now()),
        ReturnEvent('Verified (auto)', DateTime.now()),
      ],
    );

    _returns.add(rr);

    final eligible = mode == ReturnMode.loop &&
        score >= rules.minScoreForLoop &&
        rules.allowedCategories.contains(item.category);

    if (eligible) {
      _offers.add(Offer(
        id: _id(),
        returnId: rr.id,
        sku: rr.sku,
        customerId: rr.customerId,
        price: max(5, item.price * 0.75),
        expiresAt: DateTime.now().add(const Duration(hours: 2)),
      ));
      _appendEvent(rr.id, 'Offered to next customer');
    } else if (mode == ReturnMode.loop && !eligible) {
      _appendEvent(rr.id, 'Exception: Not eligible for Loop (score/policy)');
    } else {
      _appendEvent(rr.id, 'Classic return: back to company');
    }

    notifyListeners();
    return rr;
  }

  void acceptOffer(Offer o) {
    if (o.status != OfferStatus.available) return;
    o.status = OfferStatus.accepted;
    o.buyerId = me!.id;
    _appendEvent(o.returnId, 'Accepted by next customer');
    _appendEvent(o.returnId, 'Completed (no warehouse trip)');
    notifyListeners();
  }

  void rejectOffer(Offer o) {
    if (o.status != OfferStatus.available) return;
    o.status = OfferStatus.rejected;
    _appendEvent(o.returnId, 'Rejected by next customer');
    final rejects = _offers.where((x) => x.returnId == o.returnId && x.status == OfferStatus.rejected).length;
    if (rejects >= rules.maxRejectsBeforeWarehouse) {
      o.status = OfferStatus.warehouse;
      _appendEvent(o.returnId, 'Sent to warehouse for processing');
    } else {
      _offers.add(Offer(
        id: _id(),
        returnId: o.returnId,
        sku: o.sku,
        customerId: o.customerId,
        price: max(5, o.price * 0.97),
        expiresAt: DateTime.now().add(const Duration(hours: 2)),
      ));
      _appendEvent(o.returnId, 'Re-offered to another customer');
    }
    notifyListeners();
  }

  void adminApproveLoop(String returnId) {
    final rr = _returns.firstWhere((r) => r.id == returnId);
    _offers.add(Offer(
      id: _id(),
      returnId: rr.id,
      sku: rr.sku,
      customerId: rr.customerId,
      price: 19.99,
      expiresAt: DateTime.now().add(const Duration(hours: 2)),
    ));
    _appendEvent(returnId, 'Admin override: Offered to next customer');
    notifyListeners();
  }

  void adminSendToWarehouse(String returnId) {
    for (final o in _offers.where((x) => x.returnId == returnId)) {
      if (o.status == OfferStatus.available || o.status == OfferStatus.rejected) {
        o.status = OfferStatus.warehouse;
      }
    }
    _appendEvent(returnId, 'Admin action: Sent to warehouse');
    notifyListeners();
  }

  void updateRules({Set<String>? categories, int? minScore, int? maxRejects}) {
    if (categories != null) rules.allowedCategories = categories;
    if (minScore != null) rules.minScoreForLoop = minScore;
    if (maxRejects != null) rules.maxRejectsBeforeWarehouse = maxRejects;
    notifyListeners();
  }

  Map<String, String> get kpis {
    final total = _returns.length;
    final eligible = _returns.where((r) => r.mode == ReturnMode.loop && r.score >= rules.minScoreForLoop).length;
    final accepted = _offers.where((o) => o.status == OfferStatus.accepted).length;
    final rejected = _offers.where((o) => o.status == OfferStatus.rejected).length;
    final acceptance = (accepted + rejected) == 0 ? 0 : ((accepted / (accepted + rejected)) * 100).round();
    return {
      'Returns': '$total',
      'Loop eligible': total == 0 ? '0%' : '${((eligible / total) * 100).round()}%',
      'Acceptance': '$acceptance%',
      'Trips saved': '$accepted',
    };
  }

  /* ---- HELPERS + DEMO DATA ---- */

  void _appendEvent(String returnId, String label) {
    final idx = _returns.indexWhere((r) => r.id == returnId);
    if (idx < 0) return;
    final r = _returns[idx];
    _returns[idx] = r.copyWith(events: [...r.events, ReturnEvent(label, DateTime.now())]);
  }

  String _id() => Random().nextInt(99999999).toString().padLeft(8, '0');

  void _seedDemoData() {
    register('Demo Customer', 'customer@revouge.test', '123456', 'Berlin, DE');
    register('Demo Buyer', 'buyer@revouge.test', '123456', 'Munich, DE');
    register('Demo Admin', 'admin@revouge.test', '123456', 'Hamburg, DE');

    // Seed one offer so the app isn't empty
    signIn('customer@revouge.test', '123456');
    if (myOrders.isNotEmpty) {
      final o = myOrders.first;
      final it = o.items.first;
      createReturn(
        order: o,
        item: it,
        reason: 'Size/Fit issue',
        condition: 'Like-new',
        notes: 'Tried once indoors. Perfect condition.',
        photoPaths: const [],
        mode: ReturnMode.loop,
      );
    }
    signOut();
  }

  // --- FIXED: METHOD ADDED HERE INSIDE THE CLASS ---
  List<Order> _sampleOrders(String userId) {
    final now = DateTime.now();
    return [
      Order(_id(), userId, now.subtract(const Duration(days: 3)), const [
        ReturnItem(sku: 'SKU-1001', name: 'Running Shoes', brand: 'Adidas', category: 'Shoes', size: '42', price: 89.99),
        ReturnItem(sku: 'SKU-1002', name: 'Winter Jacket', brand: 'NorthPeak', category: 'Jackets', size: 'L', price: 149.99),
      ]),
      Order(_id(), userId, now.subtract(const Duration(days: 12)), const [
        ReturnItem(sku: 'SKU-2001', name: 'Casual Hoodie', brand: 'UrbanCo', category: 'Hoodies', size: 'M', price: 49.99),
        ReturnItem(sku: 'SKU-2002', name: 'Paperback Book', brand: 'BookHouse', category: 'Books', size: 'One size', price: 12.99),
      ]),
    ];
  }
} // <--- END OF APPSTATE CLASS

/* ----------------------------- APP + ROUTES ----------------------------- */

class ReturnPortalApp extends StatefulWidget {
  const ReturnPortalApp({super.key});
  @override
  State<ReturnPortalApp> createState() => _ReturnPortalAppState();
}

class _ReturnPortalAppState extends State<ReturnPortalApp> {
  final AppState state = AppState();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: state,
      builder: (_, __) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Revouge',
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: const Color(0xFF0F9AAE),
          scaffoldBackgroundColor: Colors.transparent,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
        ),
        // Background Image
        builder: (context, child) {
          return Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: const AssetImage('assets/Revouge.jpg'),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                        Colors.white.withOpacity(0.9), BlendMode.lighten),
                  ),
                ),
              ),
              if (child != null) child,
            ],
          );
        },
        initialRoute: '/splash',
        onGenerateRoute: (s) {
          switch (s.name) {
            case '/splash':
              return _r(const Splash(), s);
            case '/signin':
              return _r(SignIn(state: state), s);
            case '/register':
              return _r(Register(state: state), s);
            case '/role':
              return _r(RoleSelect(state: state), s);
            case '/customer_selection': // NEW ROUTE FOR MENU
              return _r(CustomerSelectionScreen(state: state), s);
            case '/customer_dashboard':
              return _r(CustomerDashboard(customerName: state.me?.name), s);
            case '/customer':
              return _r(CustomerHome(state: state), s);
            case '/return_form':
              return _r(ReturnForm(state: state, arg: s.arguments as ReturnFormArg), s);
            case '/photos':
              return _r(PhotoUpload(state: state, arg: s.arguments as PhotoArg), s);
            case '/score':
              return _r(ScoreScreen(state: state, arg: s.arguments as ScoreArg), s);
            case '/track':
              return _r(Tracking(state: state, rr: s.arguments as ReturnRequest), s);
            case '/buyer':
              return _r(BuyerDeals(state: state), s);
            case '/offer':
              return _r(OfferDetail(state: state, offer: s.arguments as Offer), s);
            case '/admin':
              return _r(AdminDashboard(state: state), s);
            case '/exceptions':
              return _r(AdminExceptions(state: state), s);
            case '/rules':
              return _r(AdminRules(state: state), s);
            default:
              return _r(Scaffold(body: Center(child: Text('Route not found: ${s.name}'))), s);
          }
        },
      ),
    );
  }

  MaterialPageRoute _r(Widget w, RouteSettings s) => MaterialPageRoute(builder: (_) => w, settings: s);
}

/* ----------------------------- SCREENS ----------------------------- */

class Splash extends StatelessWidget {
  const Splash({super.key});
  @override
  Widget build(BuildContext context) {
    Future.delayed(const Duration(milliseconds: 600), () => Navigator.pushReplacementNamed(context, '/signin'));
    return const Scaffold(
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.recycling, size: 72, color: Color(0xFF0F9AAE)),
          SizedBox(height: 10),
          Text('Revouge', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
          SizedBox(height: 6),
          Text('Reverse logistics, simplified'),
        ]),
      ),
    );
  }
}

class SignIn extends StatefulWidget {
  final AppState state;
  const SignIn({super.key, required this.state});
  @override
  State<SignIn> createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  final email = TextEditingController(text: 'customer@revouge.test');
  final pass = TextEditingController(text: '123456');
  String? err;
  Role selectedRole = Role.customer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign In')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          SegmentedButton<Role>(
            segments: const [
              ButtonSegment(value: Role.customer, label: Text('Customer')),
              ButtonSegment(value: Role.admin, label: Text('Company')),
            ],
            selected: {selectedRole},
            onSelectionChanged: (s) => setState(() => selectedRole = s.first),
          ),
          const SizedBox(height: 12),
          TextField(controller: email, decoration: const InputDecoration(labelText: 'Email')),
          const SizedBox(height: 10),
          TextField(controller: pass, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
          const SizedBox(height: 10),
          if (err != null) Text(err!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 10),
          FilledButton(
            onPressed: () {
              final ok = widget.state.signIn(email.text, pass.text);
              if (!ok) return setState(() => err = 'Invalid credentials');
              widget.state.setRole(selectedRole);

              // --- FIXED NAVIGATION LOGIC ---
              if (selectedRole == Role.customer) {
                // Navigate to the SELECTION MENU, not directly to shop
                Navigator.pushNamed(context, '/customer_selection');
              } else {
                // Admin goes to dashboard
                Navigator.pushNamed(context, '/admin');
              }
            },
            child: const Text('Sign In'),
          ),
          TextButton(onPressed: () => Navigator.pushNamed(context, '/register'), child: const Text('Create account')),
          const SizedBox(height: 10),
          const Text('Demo:\ncustomer@revouge.test / 123456\nadmin@revouge.test / 123456', textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}

class Register extends StatefulWidget {
  final AppState state;
  const Register({super.key, required this.state});
  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final name = TextEditingController();
  final email = TextEditingController();
  final pass = TextEditingController();
  final addr = TextEditingController();
  String? err;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
          const SizedBox(height: 10),
          TextField(controller: email, decoration: const InputDecoration(labelText: 'Email')),
          const SizedBox(height: 10),
          TextField(controller: pass, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
          const SizedBox(height: 10),
          TextField(controller: addr, decoration: const InputDecoration(labelText: 'Address')),
          const SizedBox(height: 10),
          if (err != null) Text(err!, style: const TextStyle(color: Colors.red)),
          FilledButton(
            onPressed: () {
              final ok = widget.state.register(name.text, email.text, pass.text, addr.text);
              if (!ok) return setState(() => err = 'Email already exists');
              widget.state.signIn(email.text, pass.text);
              Navigator.pushNamed(context, '/role');
            },
            child: const Text('Create Account'),
          )
        ]),
      ),
    );
  }
}

// --- NEW MENU SCREEN FOR CUSTOMERS ---
class CustomerSelectionScreen extends StatelessWidget {
  final AppState state;
  const CustomerSelectionScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final u = state.me;
    return Scaffold(
      appBar: AppBar(
        title: Text(u != null ? 'Welcome, ${u.name}' : 'Welcome'),
        actions: [
          IconButton(
            onPressed: () {
              state.signOut();
              Navigator.pushNamedAndRemoveUntil(context, '/signin', (_) => false);
            },
            icon: const Icon(Icons.logout),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "What would you like to do?",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),

            // BUTTON 1: GO TO BUYING (YOUR APP)
            _buildMenuCard(
              context,
              icon: Icons.shopping_bag_outlined,
              title: "Shop / Buy",
              subtitle: "Browse the marketplace",
              color: Colors.black,
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const HomeScreen())
                );
              },
            ),

            const SizedBox(height: 20),

            _buildMenuCard(
              context,
              icon: Icons.person_outline,
              title: "Customer Dashboard",
              subtitle: "Checkout & payment methods",
              color: const Color(0xFF0F9AAE),
              onTap: () {
                Navigator.pushNamed(context, '/customer_dashboard');
              },
            ),

            const SizedBox(height: 20),

            // BUTTON 2: GO TO SELLING (PARTNER APP)
            _buildMenuCard(
              context,
              icon: Icons.recycling,
              title: "Return / Sell",
              subtitle: "Return items & view history",
              color: const Color(0xFF0F9AAE),
              onTap: () {
                Navigator.pushNamed(context, '/customer');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, {required IconData icon, required String title, required String subtitle, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))
            ]
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Text(subtitle, style: const TextStyle(fontSize: 14, color: Colors.grey)),
              ],
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

// Keeping this for compatibility, though we use the new CustomerSelectionScreen now
class RoleSelect extends StatelessWidget {
  final AppState state;
  const RoleSelect({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    // Redirects directly to the new selection screen
    Future.delayed(Duration.zero, () {
      Navigator.pushReplacementNamed(context, '/customer_selection');
    });
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class CustomerHome extends StatelessWidget {
  final AppState state;
  const CustomerHome({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final orders = state.myOrders;
    final returns = state.myReturns;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Returns'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context), // Go back to Selection Screen
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('My Orders', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          for (final o in orders)
            Card(
              child: ExpansionTile(
                title: Text('Order ${o.id}'),
                subtitle: Text(_d(o.date)),
                children: [
                  for (final it in o.items)
                    ListTile(
                      title: Text('${it.brand} • ${it.name}'),
                      subtitle: Text('${it.category} • Size ${it.size} • ${it.sku}'),
                      trailing: FilledButton.tonal(
                        onPressed: () => Navigator.pushNamed(context, '/return_form', arguments: ReturnFormArg(o, it)),
                        child: const Text('Return'),
                      ),
                    )
                ],
              ),
            ),
          const SizedBox(height: 14),
          const Text('Return History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (returns.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(14), child: Text('No returns yet.'))),
          for (final r in returns)
            Card(
              child: ListTile(
                title: Text('Return ${r.id} • ${r.sku}'),
                subtitle: Text('Mode: ${r.mode.name} • Score: ${r.score} • ${r.confidence.name.toUpperCase()}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pushNamed(context, '/track', arguments: r),
              ),
            ),
        ],
      ),
    );
  }
}

class ReturnFormArg {
  final Order order;
  final ReturnItem item;
  ReturnFormArg(this.order, this.item);
}

class ReturnForm extends StatefulWidget {
  final AppState state;
  final ReturnFormArg arg;
  const ReturnForm({super.key, required this.state, required this.arg});

  @override
  State<ReturnForm> createState() => _ReturnFormState();
}

class _ReturnFormState extends State<ReturnForm> {
  String reason = 'Size/Fit issue';
  String condition = 'Like-new';
  final notes = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final it = widget.arg.item;
    return Scaffold(
      appBar: AppBar(title: const Text('Create Return')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Card(child: ListTile(title: Text('${it.brand} • ${it.name}'), subtitle: Text('${it.category} • ${it.sku}'))),
          const SizedBox(height: 12),
          DropdownButtonFormField(
            initialValue: reason,
            decoration: const InputDecoration(labelText: 'Reason'),
            items: const [
              DropdownMenuItem(value: 'Size/Fit issue', child: Text('Size/Fit issue')),
              DropdownMenuItem(value: 'Changed mind / not needed', child: Text('Changed mind / not needed')),
              DropdownMenuItem(value: 'Damaged item', child: Text('Damaged item')),
            ],
            onChanged: (v) => setState(() => reason = v ?? reason),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField(
            initialValue: condition,
            decoration: const InputDecoration(labelText: 'Condition'),
            items: const [
              DropdownMenuItem(value: 'New', child: Text('New')),
              DropdownMenuItem(value: 'Like-new', child: Text('Like-new')),
              DropdownMenuItem(value: 'Used', child: Text('Used')),
            ],
            onChanged: (v) => setState(() => condition = v ?? condition),
          ),
          const SizedBox(height: 12),
          TextField(controller: notes, maxLines: 3, decoration: const InputDecoration(labelText: 'Notes (optional)')),
          const Spacer(),
          FilledButton(
            onPressed: () => Navigator.pushNamed(
              context,
              '/photos',
              arguments: PhotoArg(widget.arg.order, it, reason, condition, notes.text),
            ),
            child: const Text('Next: Photos'),
          ),
        ]),
      ),
    );
  }
}

class PhotoArg {
  final Order order;
  final ReturnItem item;
  final String reason, condition, notes;
  PhotoArg(this.order, this.item, this.reason, this.condition, this.notes);
}

class PhotoUpload extends StatefulWidget {
  final AppState state;
  final PhotoArg arg;
  const PhotoUpload({super.key, required this.state, required this.arg});

  @override
  State<PhotoUpload> createState() => _PhotoUploadState();
}

class _PhotoUploadState extends State<PhotoUpload> {
  final picker = ImagePicker();
  final List<String> paths = [];

  Future<void> addPhoto(ImageSource src) async {
    final x = await picker.pickImage(source: src, imageQuality: 70);
    if (x == null) return;
    setState(() => paths.add(x.path));
  }

  @override
  Widget build(BuildContext context) {
    final it = widget.arg.item;
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Photos')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Card(
            child: ListTile(
              title: Text('${it.brand} • ${it.name}'),
              subtitle: const Text('Upload 1–3 photos (front / label / close-up)'),
            ),
          ),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: OutlinedButton.icon(onPressed: () => addPhoto(ImageSource.camera), icon: const Icon(Icons.photo_camera), label: const Text('Camera'))),
            const SizedBox(width: 12),
            Expanded(child: OutlinedButton.icon(onPressed: () => addPhoto(ImageSource.gallery), icon: const Icon(Icons.photo_library), label: const Text('Gallery'))),
          ]),
          const SizedBox(height: 10),
          Expanded(
            child: GridView.builder(
              itemCount: paths.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10),
              itemBuilder: (_, i) => Stack(children: [
                ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(File(paths[i]), fit: BoxFit.cover, width: double.infinity, height: double.infinity)),
                Positioned(
                  top: 4,
                  right: 4,
                  child: InkWell(
                    onTap: () => setState(() => paths.removeAt(i)),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                      child: const Icon(Icons.close, color: Colors.white, size: 16),
                    ),
                  ),
                )
              ]),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pushNamed(
              context,
              '/score',
              arguments: ScoreArg(widget.arg.order, widget.arg.item, widget.arg.reason, widget.arg.condition, widget.arg.notes, paths),
            ),
            child: const Text('Next: ReturnScore'),
          ),
        ]),
      ),
    );
  }
}

class ScoreArg {
  final Order order;
  final ReturnItem item;
  final String reason, condition, notes;
  final List<String> paths;
  ScoreArg(this.order, this.item, this.reason, this.condition, this.notes, this.paths);
}

class ScoreScreen extends StatefulWidget {
  final AppState state;
  final ScoreArg arg;
  const ScoreScreen({super.key, required this.state, required this.arg});

  @override
  State<ScoreScreen> createState() => _ScoreScreenState();
}

class _ScoreScreenState extends State<ScoreScreen> {
  ReturnMode mode = ReturnMode.loop;

  @override
  Widget build(BuildContext context) {
    final it = widget.arg.item;
    final (score, conf) = widget.state.computeScore(
      item: it,
      reason: widget.arg.reason,
      condition: widget.arg.condition,
      photoCount: widget.arg.paths.length,
      notes: widget.arg.notes,
    );

    final eligible = score >= widget.state.rules.minScoreForLoop &&
        widget.state.rules.allowedCategories.contains(it.category);

    final confColor = conf == Confidence.high ? Colors.green : (conf == Confidence.medium ? Colors.orange : Colors.red);

    return Scaffold(
      appBar: AppBar(title: const Text('ReturnScore')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Card(child: ListTile(title: Text('${it.brand} • ${it.name}'), subtitle: Text('${it.category} • ${it.sku}'))),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('ReturnScore (0–100)', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                LinearProgressIndicator(value: score / 100.0, minHeight: 12),
                const SizedBox(height: 10),
                Row(children: [
                  Text('Score: $score', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 10),
                  Chip(
                    label: Text(conf.name.toUpperCase()),
                    backgroundColor: confColor.withOpacity(0.15),
                    labelStyle: TextStyle(color: confColor, fontWeight: FontWeight.bold),
                  ),
                ]),
                const SizedBox(height: 6),
                Text(
                  eligible ? 'Eligible for Loop Mode (direct to next customer).' : 'Not eligible for Loop Mode; use Classic return.',
                  style: TextStyle(color: eligible ? Colors.green : Colors.red),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 10),
          SegmentedButton<ReturnMode>(
            segments: const [
              ButtonSegment(value: ReturnMode.loop, label: Text('Loop Mode')),
              ButtonSegment(value: ReturnMode.classic, label: Text('Classic Return')),
            ],
            selected: {mode},
            onSelectionChanged: (s) => setState(() => mode = s.first),
          ),
          const Spacer(),
          FilledButton(
            onPressed: () {
              final chosen = (mode == ReturnMode.loop && !eligible) ? ReturnMode.classic : mode;
              final rr = widget.state.createReturn(
                order: widget.arg.order,
                item: widget.arg.item,
                reason: widget.arg.reason,
                condition: widget.arg.condition,
                notes: widget.arg.notes,
                photoPaths: widget.arg.paths,
                mode: chosen,
              );
              Navigator.pushNamed(context, '/track', arguments: rr);
            },
            child: const Text('Submit Return'),
          )
        ]),
      ),
    );
  }
}

class Tracking extends StatelessWidget {
  final AppState state;
  final ReturnRequest rr;
  const Tracking({super.key, required this.state, required this.rr});

  @override
  Widget build(BuildContext context) {
    final latest = state.myReturns.where((x) => x.id == rr.id).isNotEmpty
        ? state.myReturns.firstWhere((x) => x.id == rr.id)
        : rr;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Return Tracking'),
        actions: [
          IconButton(onPressed: () => Navigator.pushNamed(context, '/customer_selection'), icon: const Icon(Icons.home)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              title: Text('Return ${latest.id} • ${latest.sku}'),
              subtitle: Text('Mode: ${latest.mode.name} • Score: ${latest.score} • ${latest.confidence.name.toUpperCase()}'),
            ),
          ),
          const SizedBox(height: 10),
          const Text('Timeline', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          for (final e in latest.events)
            ListTile(leading: const Icon(Icons.check_circle_outline), title: Text(e.label), subtitle: Text(_dt(e.time))),
        ],
      ),
    );
  }
}

/* ---- BUYER ---- */

class BuyerDeals extends StatelessWidget {
  final AppState state;
  const BuyerDeals({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final list = state.availableDeals;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Loop Deals'),
        actions: [IconButton(onPressed: () => Navigator.pushNamed(context, '/role'), icon: const Icon(Icons.swap_horiz))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (list.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(14), child: Text('No deals available right now.'))),
          for (final o in list) _OfferTile(state: state, offer: o),
        ],
      ),
    );
  }
}

class _OfferTile extends StatelessWidget {
  final AppState state;
  final Offer offer;
  const _OfferTile({required this.state, required this.offer});

  @override
  Widget build(BuildContext context) {
    final it = state.itemBySku(offer.sku);
    final mins = max(0, offer.expiresAt.difference(DateTime.now()).inMinutes);
    return Card(
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.local_offer)),
        title: Text(it == null ? offer.sku : '${it.brand} • ${it.name}'),
        subtitle: Text('€${offer.price.toStringAsFixed(2)} • expires in ${mins}m'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.pushNamed(context, '/offer', arguments: offer),
      ),
    );
  }
}

class OfferDetail extends StatelessWidget {
  final AppState state;
  final Offer offer;
  const OfferDetail({super.key, required this.state, required this.offer});

  @override
  Widget build(BuildContext context) {
    final it = state.itemBySku(offer.sku);
    final mins = max(0, offer.expiresAt.difference(DateTime.now()).inMinutes);

    return Scaffold(
      appBar: AppBar(title: const Text('Offer Detail')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Card(
            child: ListTile(
              title: Text(it == null ? offer.sku : '${it.brand} • ${it.name}'),
              subtitle: Text('Discounted: €${offer.price.toStringAsFixed(2)}'),
            ),
          ),
          const SizedBox(height: 10),
          Card(child: ListTile(leading: const Icon(Icons.timer), title: const Text('Countdown'), subtitle: Text('Expires in $mins minutes'))),
          const SizedBox(height: 10),
          const Card(child: Padding(padding: EdgeInsets.all(14), child: Text('Buyer protection (prototype): report issues within 48h.'))),
          const Spacer(),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  state.rejectOffer(offer);
                  Navigator.pop(context);
                },
                child: const Text('Reject'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: () {
                  state.acceptOffer(offer);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Accepted! (prototype)')));
                  Navigator.pop(context);
                },
                child: const Text('Accept'),
              ),
            ),
          ])
        ]),
      ),
    );
  }
}

/* ---- ADMIN ---- */

class AdminDashboard extends StatelessWidget {
  final AppState state;
  const AdminDashboard({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final k = state.kpis;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [IconButton(onPressed: () => Navigator.pushNamed(context, '/role'), icon: const Icon(Icons.swap_horiz))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(spacing: 12, runSpacing: 12, children: [
            _Kpi('Returns', k['Returns']!),
            _Kpi('Loop eligible', k['Loop eligible']!),
            _Kpi('Acceptance', k['Acceptance']!),
            _Kpi('Trips saved', k['Trips saved']!),
          ]),
          const SizedBox(height: 12),
          FilledButton.tonal(onPressed: () => Navigator.pushNamed(context, '/exceptions'), child: const Text('Exceptions Queue')),
          const SizedBox(height: 8),
          FilledButton.tonal(onPressed: () => Navigator.pushNamed(context, '/rules'), child: const Text('Rules & Policy')),
        ],
      ),
    );
  }
}

class _Kpi extends StatelessWidget {
  final String title, value;
  const _Kpi(this.title, this.value);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 175,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ]),
        ),
      ),
    );
  }
}

class AdminExceptions extends StatelessWidget {
  final AppState state;
  const AdminExceptions({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final list = state.exceptionsQueue;
    return Scaffold(
      appBar: AppBar(title: const Text('Exceptions Queue')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (list.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(14), child: Text('No exceptions right now.'))),
          for (final r in list)
            Card(
              child: ListTile(
                title: Text('Return ${r.id} • ${r.sku}'),
                subtitle: Text('Score ${r.score} • ${r.confidence.name.toUpperCase()} • Mode ${r.mode.name}'),
                trailing: PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'approve') state.adminApproveLoop(r.id);
                    if (v == 'warehouse') state.adminSendToWarehouse(r.id);
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'approve', child: Text('Approve Loop (override)')),
                    PopupMenuItem(value: 'warehouse', child: Text('Send to Warehouse')),
                  ],
                ),
                onTap: () => Navigator.pushNamed(context, '/track', arguments: r),
              ),
            ),
        ],
      ),
    );
  }
}

class AdminRules extends StatefulWidget {
  final AppState state;
  const AdminRules({super.key, required this.state});
  @override
  State<AdminRules> createState() => _AdminRulesState();
}

class _AdminRulesState extends State<AdminRules> {
  late int minScore;
  late int maxRejects;
  late Set<String> allowed;

  final allCats = const ['Shoes', 'Jackets', 'Hoodies', 'Books', 'Cosmetics', 'Underwear'];

  @override
  void initState() {
    super.initState();
    minScore = widget.state.rules.minScoreForLoop;
    maxRejects = widget.state.rules.maxRejectsBeforeWarehouse;
    allowed = Set.of(widget.state.rules.allowedCategories);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rules & Policy')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Allowed categories for Loop', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          for (final c in allCats)
            SwitchListTile(
              title: Text(c),
              value: allowed.contains(c),
              onChanged: (v) => setState(() => v ? allowed.add(c) : allowed.remove(c)),
            ),
          const Divider(),
          Text('Min ReturnScore for Loop: $minScore', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Slider(min: 0, max: 100, divisions: 20, value: minScore.toDouble(), onChanged: (v) => setState(() => minScore = v.round())),
          const Divider(),
          Text('Max rejections before warehouse: $maxRejects', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Slider(min: 1, max: 5, divisions: 4, value: maxRejects.toDouble(), onChanged: (v) => setState(() => maxRejects = v.round())),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () {
              widget.state.updateRules(categories: allowed, minScore: minScore, maxRejects: maxRejects);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rules updated')));
            },
            child: const Text('Save'),
          )
        ],
      ),
    );
  }
}

/* ----------------------------- HELPERS ----------------------------- */

String _d(DateTime t) => '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';
String _dt(DateTime t) => '${_d(t)} ${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
