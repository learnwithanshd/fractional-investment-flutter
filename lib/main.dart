import 'package:flutter/material.dart';
import 'api_service.dart';

void main() => runApp(const FractionalInvestmentApp());

class FractionalInvestmentApp extends StatelessWidget {
  const FractionalInvestmentApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xff3454d1),
      brightness: Brightness.light,
    );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Fractional Investment',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: const Color(0xfff5f7fb),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          backgroundColor: Color(0xfff5f7fb),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            borderSide: BorderSide.none,
          ),
        ),
        cardTheme: const CardThemeData(
          elevation: 0,
          color: Colors.white,
          margin: EdgeInsets.zero,
        ),
      ),
      home: const LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final user = TextEditingController();
  final pass = TextEditingController();
  bool hidden = true, loading = false;

  Future<void> login() async {
    if (user.text.trim().isEmpty || pass.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter username and password')),
      );
      return;
    }
    setState(() => loading = true);
    try {
      final token = await ApiService.login(user.text.trim(), pass.text);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomePage(token: token)),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    user.dispose();
    pass.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(Icons.account_balance_wallet,
                        color: Colors.white, size: 48),
                  ),
                  const SizedBox(height: 20),
                  const Text('Welcome Back',
                      style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Manage your fractional investments',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 35),
                  TextField(
                    controller: user,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: pass,
                    obscureText: hidden,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => hidden = !hidden),
                        icon: Icon(hidden ? Icons.visibility_off : Icons.visibility),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton(
                      onPressed: loading ? null : login,
                      child: loading
                          ? const CircularProgressIndicator()
                          : const Text('Login'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RegisterPage()),
                    ),
                    child: const Text('Create New Account'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Create Account')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Registration API will be connected in the next step.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
}

class HomePage extends StatefulWidget {
  final String token;
  const HomePage({super.key, required this.token});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int index = 0;
  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardPage(token: widget.token),
      OpportunitiesPage(token: widget.token),
      MyInvestmentsPage(token: widget.token),
      const ProfilePage(),
    ];
    return Scaffold(
      body: pages[index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (v) => setState(() => index = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.explore_outlined), selectedIcon: Icon(Icons.explore), label: 'Invest'),
          NavigationDestination(icon: Icon(Icons.wallet_outlined), selectedIcon: Icon(Icons.wallet), label: 'Portfolio'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class DashboardPage extends StatelessWidget {
  final String token;
  const DashboardPage({super.key, required this.token});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: FutureBuilder<List<dynamic>>(
        future: ApiService.getMyInvestments(token),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) return _error(snapshot.error.toString());
          final list = snapshot.data ?? [];
          final total = list.fold<double>(
            0,
            (sum, item) => sum + (double.tryParse('${item['amount']}') ?? 0),
          );
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text('Hello, Investor 👋',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Your investment journey starts here.',
                  style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),
              _metricCard(context, 'Total Investment', '₹${total.toStringAsFixed(2)}', Icons.account_balance_wallet),
              const SizedBox(height: 14),
              _metricCard(context, 'Investment Count', '${list.length}', Icons.trending_up),
              const SizedBox(height: 28),
              const Text('Quick Actions',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),
              _action(context, 'Explore Opportunities', Icons.explore,
                  () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => OpportunitiesPage(token: token)))),
              const SizedBox(height: 12),
              _action(context, 'My Portfolio', Icons.wallet,
                  () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => MyInvestmentsPage(token: token)))),
            ],
          );
        },
      ),
    );
  }

  Widget _metricCard(BuildContext context, String title, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(icon, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(width: 16),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 5),
              Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _action(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return SizedBox(
      height: 56,
      child: FilledButton.icon(onPressed: onTap, icon: Icon(icon), label: Text(title)),
    );
  }
}

class OpportunitiesPage extends StatefulWidget {
  final String token;
  const OpportunitiesPage({super.key, required this.token});
  @override
  State<OpportunitiesPage> createState() => _OpportunitiesPageState();
}

class _OpportunitiesPageState extends State<OpportunitiesPage> {
  late Future<List<dynamic>> future;
  final search = TextEditingController();

  @override
  void initState() {
    super.initState();
    future = ApiService.getOpportunities();
    search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Explore Investments')),
      body: FutureBuilder<List<dynamic>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) return _error(snapshot.error.toString());
          final query = search.text.toLowerCase();
          final items = (snapshot.data ?? []).where((item) =>
              '${item['title']}'.toLowerCase().contains(query) ||
              '${item['description']}'.toLowerCase().contains(query)).toList();

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text('Find Your Next Opportunity',
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Discover projects and invest fractionally.',
                  style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 20),
              TextField(
                controller: search,
                decoration: InputDecoration(
                  hintText: 'Search projects...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: search.text.isEmpty
                      ? null
                      : IconButton(onPressed: search.clear, icon: const Icon(Icons.clear)),
                ),
              ),
              const SizedBox(height: 22),
              ...items.map((item) => _opportunityCard(context, item)),
              if (items.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(30),
                  child: Center(child: Text('No investments found.')),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _opportunityCard(BuildContext context, dynamic item) {
    final title = '${item['title'] ?? 'Investment'}';
    final description = '${item['description'] ?? ''}';
    final price = '${item['price_per_unit'] ?? '0'}';
    final units = '${item['total_units'] ?? '0'}';
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(Icons.business_center,
                color: Theme.of(context).colorScheme.primary, size: 30),
          ),
          const SizedBox(height: 15),
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(description, maxLines: 3, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.grey, height: 1.5)),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            _smallValue('Price / Unit', '₹$price'),
            _smallValue('Units', units),
          ]),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => InvestmentDetailsPage(
                  token: widget.token,
                  opportunityId: item['id'],
                  title: title,
                  description: description,
                  price: price,
                  units: units,
                ))),
              child: const Text('View & Invest'),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _smallValue(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
    ],
  );
}

class InvestmentDetailsPage extends StatefulWidget {
  final String token, title, description, price, units;
  final dynamic opportunityId;
  const InvestmentDetailsPage({
    super.key, required this.token, required this.opportunityId,
    required this.title, required this.description, required this.price, required this.units,
  });
  @override
  State<InvestmentDetailsPage> createState() => _InvestmentDetailsPageState();
}

class _InvestmentDetailsPageState extends State<InvestmentDetailsPage> {
  int selectedUnits = 1;
  bool loading = false;
  double get unitPrice => double.tryParse(widget.price) ?? 0;
  double get total => selectedUnits * unitPrice;
  int get available => int.tryParse(widget.units) ?? 0;

  Future<void> invest() async {
    if (total < 500) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minimum investment is ₹500')),
      );
      return;
    }
    setState(() => loading = true);
    try {
      final result = await ApiService.createInvestment(
        token: widget.token,
        opportunityId: int.parse(widget.opportunityId.toString()),
        units: selectedUnits,
      );
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(
        builder: (_) => InvestmentSuccessPage(
          title: widget.title,
          units: selectedUnits,
          amount: double.tryParse('${result['amount']}') ?? total,
        )));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Investment Details')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          height: 150,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xff3454d1), Color(0xff6578e8)]),
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Icon(Icons.business_center, color: Colors.white, size: 70),
        ),
        const SizedBox(height: 22),
        Text(widget.title, style: const TextStyle(fontSize: 27, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Text(widget.description, style: const TextStyle(color: Colors.grey, height: 1.5)),
        const SizedBox(height: 22),
        Card(child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            _infoRow('Price per Unit', '₹${widget.price}'),
            const Divider(height: 25),
            _infoRow('Available Units', widget.units),
            const Divider(height: 25),
            _infoRow('Minimum Investment', '₹500'),
          ]),
        )),
        const SizedBox(height: 25),
        const Text('Select Units', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 15),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          IconButton.filledTonal(
            onPressed: selectedUnits > 1 ? () => setState(() => selectedUnits--) : null,
            icon: const Icon(Icons.remove),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 35),
            child: Text('$selectedUnits', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
          ),
          IconButton.filledTonal(
            onPressed: selectedUnits < available ? () => setState(() => selectedUnits++) : null,
            icon: const Icon(Icons.add),
          ),
        ]),
        const SizedBox(height: 20),
        Card(color: Theme.of(context).colorScheme.primaryContainer, child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(children: [
            const Text('Total Investment Amount'),
            const SizedBox(height: 8),
            Text('₹${total.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary)),
            const SizedBox(height: 8),
            Text(total >= 500 ? 'Minimum amount reached ✓' : 'Minimum investment: ₹500'),
          ]),
        )),
        const SizedBox(height: 25),
        SizedBox(height: 54, child: FilledButton.icon(
          onPressed: loading || total < 500 ? null : invest,
          icon: const Icon(Icons.lock_outline),
          label: loading ? const CircularProgressIndicator() : const Text('Confirm Investment'),
        )),
      ],
    ),
  );

  Widget _infoRow(String a, String b) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(a, style: const TextStyle(color: Colors.grey)),
      Flexible(child: Text(b, style: const TextStyle(fontWeight: FontWeight.bold))),
    ],
  );
}

class InvestmentSuccessPage extends StatelessWidget {
  final String title;
  final int units;
  final double amount;
  const InvestmentSuccessPage({super.key, required this.title, required this.units, required this.amount});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Confirmation'), automaticallyImplyLeading: false),
    body: Center(child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        const CircleAvatar(radius: 45, backgroundColor: Colors.green,
          child: Icon(Icons.check, color: Colors.white, size: 60)),
        const SizedBox(height: 25),
        const Text('Investment Successful!', textAlign: TextAlign.center,
          style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        const Text('Your investment has been completed successfully.',
          textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 25),
        Card(child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(children: [
            _row('Project', title),
            const Divider(height: 25),
            _row('Units', '$units'),
            const Divider(height: 25),
            _row('Total Amount', '₹${amount.toStringAsFixed(2)}'),
          ]),
        )),
        const SizedBox(height: 30),
        SizedBox(width: double.infinity, height: 54,
          child: FilledButton.icon(
            onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
            icon: const Icon(Icons.home),
            label: const Text('Back to Home'),
          )),
      ]),
    )),
  );

  Widget _row(String a, String b) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(a, style: const TextStyle(color: Colors.grey)),
      Flexible(child: Text(b, textAlign: TextAlign.end,
        style: const TextStyle(fontWeight: FontWeight.bold))),
    ],
  );
}

class MyInvestmentsPage extends StatefulWidget {
  final String token;
  const MyInvestmentsPage({super.key, required this.token});
  @override
  State<MyInvestmentsPage> createState() => _MyInvestmentsPageState();
}

class _MyInvestmentsPageState extends State<MyInvestmentsPage> {
  late Future<List<dynamic>> future;
  @override
  void initState() { super.initState(); load(); }
  void load() { future = ApiService.getMyInvestments(widget.token); }

  String date(dynamic value) {
    try {
      final d = DateTime.parse('$value').toLocal();
      final h = d.hour == 0 ? 12 : (d.hour > 12 ? d.hour - 12 : d.hour);
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} $h:${d.minute.toString().padLeft(2, '0')} ${d.hour >= 12 ? 'PM' : 'AM'}';
    } catch (_) { return '$value'; }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('My Portfolio'), actions: [
      IconButton(onPressed: () => setState(load), icon: const Icon(Icons.refresh)),
    ]),
    body: FutureBuilder<List<dynamic>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return _error(snapshot.error.toString());
        final list = snapshot.data ?? [];
        final total = list.fold<double>(0, (s, x) => s + (double.tryParse('${x['amount']}') ?? 0));
        return RefreshIndicator(
          onRefresh: () async { setState(load); await future; },
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text('Investment Overview', style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xff3454d1), Color(0xff6578e8)]),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Total Invested', style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 8),
                  Text('₹${total.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold)),
                ]),
              ),
              const SizedBox(height: 15),
              Card(child: ListTile(
                leading: const Icon(Icons.pie_chart),
                title: const Text('Investment Count'),
                subtitle: Text('${list.length} investments'),
              )),
              const SizedBox(height: 25),
              const Text('Your Investments', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              if (list.isEmpty) const Padding(
                padding: EdgeInsets.all(30), child: Center(child: Text('No investments available yet.'))),
              ...list.map((x) => Card(
                margin: const EdgeInsets.only(bottom: 14),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${x['opportunity_title'] ?? 'Investment'}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Date: ${date(x['created_at'])}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 15),
                    _line('Units', '${x['units']}'),
                    const SizedBox(height: 8),
                    _line('Amount', '₹${x['amount']}'),
                    const SizedBox(height: 14),
                    Container(width: double.infinity, padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.green.withOpacity(.1), borderRadius: BorderRadius.circular(10)),
                      child: const Text('Investment Successful', textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
                  ]),
                ),
              )),
            ],
          ),
        );
      },
    ),
  );

  Widget _line(String a, String b) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [Text(a, style: const TextStyle(color: Colors.grey)), Text(b, style: const TextStyle(fontWeight: FontWeight.bold))],
  );
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('My portfolio')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Card(child: Padding(padding: const EdgeInsets.all(25), child: Column(children: [
          const CircleAvatar(radius: 45, child: Icon(Icons.person, size: 55)),
          const SizedBox(height: 14),
          const Text('Investor', style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
          const Text('Fractional Investment User', style: TextStyle(color: Colors.grey)),
        ]))),
        const SizedBox(height: 25),
        const Text('Account Settings', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Card(child: Column(children: [
          _setting(context, Icons.person_outline, 'Personal Information', 'View your profile details'),
          const Divider(height: 1),
          _setting(context, Icons.security_outlined, 'Security', 'Manage account security'),
          const Divider(height: 1),
          _setting(context, Icons.notifications_outlined, 'Notifications', 'Manage notifications'),
        ])),
        const SizedBox(height: 30),
        SizedBox(height: 52, child: OutlinedButton.icon(
          onPressed: () => Navigator.pushAndRemoveUntil(context,
            MaterialPageRoute(builder: (_) => const LoginPage()), (_) => false),
          icon: const Icon(Icons.logout), label: const Text('Logout'),
        )),
      ],
    ),
  );

  Widget _setting(BuildContext context, IconData icon, String title, String subtitle) => ListTile(
    leading: Icon(icon), title: Text(title), subtitle: Text(subtitle),
    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
    onTap: () => Navigator.push(context, MaterialPageRoute(
      builder: (_) => SimpleProfilePage(title: title, message: '$title settings will appear here.'))),
  );
}

class SimpleProfilePage extends StatelessWidget {
  final String title, message;
  const SimpleProfilePage({super.key, required this.title, required this.message});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: Center(child: Padding(padding: const EdgeInsets.all(25), child: Text(message, textAlign: TextAlign.center))),
  );
}

Widget _error(String message) => Center(
  child: Padding(padding: const EdgeInsets.all(24), child: Text(message, textAlign: TextAlign.center)),
);
