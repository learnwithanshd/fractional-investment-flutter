import 'package:flutter/material.dart';
import 'api_service.dart';

void main() {
  runApp(const FractionalInvestmentApp());
}

class FractionalInvestmentApp extends StatelessWidget {
  const FractionalInvestmentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Fractional Investment',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        scaffoldBackgroundColor: const Color(0xfff7f8fc),
      ),
      home: const LoginPage(),
    );
  }
}

// ================= LOGIN =================

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final username = TextEditingController();
  final password = TextEditingController();
  bool loading = false;
  bool hidden = true;

  Future<void> login() async {
    if (username.text.trim().isEmpty || password.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter username and password')),
      );
      return;
    }

    setState(() => loading = true);

    try {
      final token = await ApiService.login(
        username.text.trim(),
        password.text,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomePage(accessToken: token),
        ),
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
    username.dispose();
    password.dispose();
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
              constraints: const BoxConstraints(maxWidth: 450),
              child: Column(
                children: [
                  const Icon(Icons.account_balance, size: 70),
                  const SizedBox(height: 20),
                  const Text(
                    'Fractional Investment',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Invest in opportunities, one fraction at a time.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  TextField(
                    controller: username,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: password,
                    obscureText: hidden,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          hidden
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() => hidden = !hidden);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: loading ? null : login,
                      child: loading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Login'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RegisterPage(),
                        ),
                      );
                    },
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

// ================= REGISTER =================

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
}

// ================= HOME =================

class HomePage extends StatefulWidget {
  final String accessToken;

  const HomePage({
    super.key,
    required this.accessToken,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardPage(token: widget.accessToken),
      OpportunitiesPage(token: widget.accessToken),
      MyInvestmentsPage(token: widget.accessToken),
      const ProfilePage(),
    ];

    return Scaffold(
      body: pages[index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) {
          setState(() => index = value);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Invest',
          ),
          NavigationDestination(
            icon: Icon(Icons.wallet_outlined),
            selectedIcon: Icon(Icons.wallet),
            label: 'Portfolio',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ================= DASHBOARD =================

class DashboardPage extends StatelessWidget {
  final String token;

  const DashboardPage({
    super.key,
    required this.token,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        centerTitle: true,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: ApiService.getMyInvestments(token),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('${snapshot.error}'));
          }

          final data = snapshot.data ?? [];
          double total = 0;

          for (final item in data) {
            total += double.tryParse(item['amount'].toString()) ?? 0;
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'Hello, Investor 👋',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Welcome to your investment dashboard.',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 25),
              _summaryCard(
                icon: Icons.account_balance_wallet,
                title: 'Total Investment',
                value: '₹${total.toStringAsFixed(2)}',
              ),
              const SizedBox(height: 18),
              _summaryCard(
                icon: Icons.trending_up,
                title: 'Investment Count',
                value: '${data.length}',
              ),
              const SizedBox(height: 28),
              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              SizedBox(
                height: 52,
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MyInvestmentsPage(token: token),
                      ),
                    );
                  },
                  icon: const Icon(Icons.wallet),
                  label: const Text('My Investments'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 52,
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OpportunitiesPage(token: token),
                      ),
                    );
                  },
                  icon: const Icon(Icons.explore),
                  label: const Text('Explore Opportunities'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _summaryCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Row(
          children: [
            Icon(icon, size: 35),
            const SizedBox(width: 18),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ================= OPPORTUNITIES =================

class OpportunitiesPage extends StatefulWidget {
  final String token;

  const OpportunitiesPage({
    super.key,
    required this.token,
  });

  @override
  State<OpportunitiesPage> createState() => _OpportunitiesPageState();
}

class _OpportunitiesPageState extends State<OpportunitiesPage> {
  late Future<List<dynamic>> future;
  final searchController = TextEditingController();
  String searchText = '';

  @override
  void initState() {
    super.initState();
    future = ApiService.getOpportunities();

    searchController.addListener(() {
      setState(() {
        searchText = searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Explore Investments',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('${snapshot.error}'));
          }

          final allItems = snapshot.data ?? [];

          final items = allItems.where((item) {
            final title = item['title']?.toString().toLowerCase() ?? '';
            final description =
                item['description']?.toString().toLowerCase() ?? '';

            return title.contains(searchText) ||
                description.contains(searchText);
          }).toList();

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'Grow Your Investments',
                style: TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Explore opportunities and invest in your future.',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 22),
              TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Search investments...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: searchText.isNotEmpty
                      ? IconButton(
                          onPressed: searchController.clear,
                          icon: const Icon(Icons.clear),
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 25),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Available Opportunities',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${items.length} Projects',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              if (items.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(30),
                  child: Center(
                    child: Text('No investments found.'),
                  ),
                ),
              ...items.map((item) {
                final title = item['title']?.toString() ?? 'Investment';
                final description =
                    item['description']?.toString() ?? '';
                final price =
                    item['price_per_unit']?.toString() ?? '0';
                final units =
                    item['total_units']?.toString() ?? '0';

                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.only(bottom: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.indigo.shade50,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Icon(
                            Icons.business_center,
                            size: 32,
                            color: Colors.indigo.shade700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          description,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.grey,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Divider(),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _labelValue('Price / Unit', '₹$price'),
                            _labelValue('Available Units', units),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: FilledButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => InvestmentDetailsPage(
                                    token: widget.token,
                                    opportunityId: item['id'],
                                    title: title,
                                    description: description,
                                    price: price,
                                    units: units,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.arrow_forward),
                            label: const Text('View & Invest'),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  Widget _labelValue(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

// ================= INVESTMENT DETAILS =================

class InvestmentDetailsPage extends StatefulWidget {
  final String token;
  final dynamic opportunityId;
  final String title;
  final String description;
  final String price;
  final String units;

  const InvestmentDetailsPage({
    super.key,
    required this.token,
    required this.opportunityId,
    required this.title,
    required this.description,
    required this.price,
    required this.units,
  });

  @override
  State<InvestmentDetailsPage> createState() =>
      _InvestmentDetailsPageState();
}

class _InvestmentDetailsPageState extends State<InvestmentDetailsPage> {
  int selectedUnits = 1;
  bool loading = false;
  final double minimumInvestment = 500;

  double get unitPrice => double.tryParse(widget.price) ?? 0;
  double get total => selectedUnits * unitPrice;

  Future<void> confirmInvestment() async {
    if (total < minimumInvestment) {
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

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => InvestmentSuccessPage(
            title: widget.title,
            units: selectedUnits,
            amount: double.tryParse(result['amount'].toString()) ?? total,
          ),
        ),
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
  Widget build(BuildContext context) {
    final availableUnits = int.tryParse(widget.units) ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Investment Details'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            height: 150,
            decoration: BoxDecoration(
              color: Colors.indigo.shade700,
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Center(
              child: Icon(
                Icons.business_center,
                size: 70,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            widget.title,
            style: const TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            widget.description,
            style: const TextStyle(
              color: Colors.grey,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 25),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _row('Price per Unit', '₹${widget.price}'),
                  const Divider(height: 25),
                  _row('Available Units', widget.units),
                  const Divider(height: 25),
                  _row('Minimum Investment', '₹500'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 25),
          const Text(
            'Select Investment Units',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.filledTonal(
                onPressed: selectedUnits > 1
                    ? () => setState(() => selectedUnits--)
                    : null,
                icon: const Icon(Icons.remove),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Text(
                  '$selectedUnits',
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton.filledTonal(
                onPressed: selectedUnits < availableUnits
                    ? () => setState(() => selectedUnits++)
                    : null,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Card(
            color: Colors.indigo.shade50,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text(
                    'Total Investment Amount',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '₹${total.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    total >= minimumInvestment
                        ? 'Minimum amount reached ✓'
                        : 'Minimum investment: ₹500',
                    style: TextStyle(
                      color: total >= minimumInvestment
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 25),
          SizedBox(
            height: 54,
            child: FilledButton.icon(
              onPressed: loading ||
                      total < minimumInvestment
                  ? null
                  : confirmInvestment,
              icon: const Icon(Icons.lock_outline),
              label: loading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Confirm Investment'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(color: Colors.grey),
        ),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

// ================= SUCCESS PAGE =================

class InvestmentSuccessPage extends StatelessWidget {
  final String title;
  final int units;
  final double amount;

  const InvestmentSuccessPage({
    super.key,
    required this.title,
    required this.units,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('Investment Confirmation'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 70,
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Investment Successful!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Your investment has been completed successfully.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 28),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    children: [
                      const Text(
                        'Investment Details',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _successRow('Project', title),
                      const Divider(height: 25),
                      _successRow('Units', '$units'),
                      const Divider(height: 25),
                      _successRow(
                        'Total Amount',
                        '₹${amount.toStringAsFixed(2)}',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 35),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.popUntil(
                      context,
                      (route) => route.isFirst,
                    );
                  },
                  icon: const Icon(Icons.home_outlined),
                  label: const Text('Back to Home'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _successRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.grey),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

// ================= PORTFOLIO =================

class MyInvestmentsPage extends StatefulWidget {
  final String token;

  const MyInvestmentsPage({
    super.key,
    required this.token,
  });

  @override
  State<MyInvestmentsPage> createState() => _MyInvestmentsPageState();
}

class _MyInvestmentsPageState extends State<MyInvestmentsPage> {
  late Future<List<dynamic>> investmentsFuture;

  @override
  void initState() {
    super.initState();
    loadInvestments();
  }

  void loadInvestments() {
    investmentsFuture = ApiService.getMyInvestments(widget.token);
  }

  Future<void> refreshInvestments() async {
    setState(loadInvestments);
    await investmentsFuture;
  }

  String formatDate(dynamic rawDate) {
    if (rawDate == null || rawDate.toString().isEmpty) {
      return 'Date unavailable';
    }

    try {
      final date = DateTime.parse(rawDate.toString()).toLocal();

      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year.toString();

      final hour = date.hour == 0
          ? 12
          : date.hour > 12
              ? date.hour - 12
              : date.hour;

      final minute = date.minute.toString().padLeft(2, '0');
      final period = date.hour >= 12 ? 'PM' : 'AM';

      return '$day/$month/$year, $hour:$minute $period';
    } catch (_) {
      return rawDate.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Portfolio',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () => setState(loadInvestments),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: investmentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('${snapshot.error}'));
          }

          final investments = snapshot.data ?? [];
          double totalAmount = 0;

          for (final item in investments) {
            totalAmount +=
                double.tryParse(item['amount'].toString()) ?? 0;
          }

          return RefreshIndicator(
            onRefresh: refreshInvestments,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  'Investment Overview',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.indigo,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Invested',
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '₹${totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                Card(
                  child: ListTile(
                    leading: const Icon(
                      Icons.pie_chart,
                      color: Colors.indigo,
                      size: 30,
                    ),
                    title: const Text('Investment Count'),
                    subtitle: Text('${investments.length} investments'),
                  ),
                ),
                const SizedBox(height: 25),
                const Text(
                  'Your Investments',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),
                if (investments.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(30),
                    child: Center(
                      child: Text('No investments available yet.'),
                    ),
                  ),
                ...investments.map(
                  (investment) => Card(
                    margin: const EdgeInsets.only(bottom: 15),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            investment['opportunity_title'] ??
                                'Investment',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_month_outlined,
                                size: 16,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Date: ${formatDate(investment['created_at'])}',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),
                          _portfolioRow(
                            'Units',
                            '${investment['units']}',
                          ),
                          const SizedBox(height: 10),
                          _portfolioRow(
                            'Amount',
                            '₹${investment['amount']}',
                          ),
                          const SizedBox(height: 15),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'Investment Successful',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _portfolioRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.grey),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

// ================= PROFILE =================

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  void openPage(
    BuildContext context,
    String title,
    String message,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SimpleProfilePage(
          title: title,
          message: message,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(25),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 48,
                    child: Icon(Icons.person, size: 55),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'Investor',
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Fractional Investment User',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 25),
          const Text(
            'Account Settings',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: const Text('Personal Information'),
                  subtitle: const Text('View your profile details'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    openPage(
                      context,
                      'Personal Information',
                      'Your personal information will appear here.',
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.security_outlined),
                  title: const Text('Security'),
                  subtitle: const Text('Manage account security'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    openPage(
                      context,
                      'Security',
                      'Your security settings will appear here.',
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.notifications_outlined),
                  title: const Text('Notifications'),
                  subtitle: const Text('Manage your notifications'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    openPage(
                      context,
                      'Notifications',
                      'Your notification settings will appear here.',
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LoginPage(),
                  ),
                  (_) => false,
                );
              },
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
            ),
          ),
        ],
      ),
    );
  }
}

// ================= SIMPLE PROFILE =================

class SimpleProfilePage extends StatelessWidget {
  final String title;
  final String message;

  const SimpleProfilePage({
    super.key,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(25),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18),
          ),
        ),
      ),
    );
  }
}
