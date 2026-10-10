
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';

void main() => runApp(const KisanSetuApp());

const forest = Color(0xFF245C43);
const deepForest = Color(0xFF173D2D);
const cream = Color(0xFFF7F6F0);
const gold = Color(0xFFE6C98A);

class KisanSetuApp extends StatelessWidget {
  const KisanSetuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KisanSetu AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: forest),
        scaffoldBackgroundColor: cream,
        appBarTheme: const AppBarTheme(
          backgroundColor: cream,
          foregroundColor: deepForest,
        ),
      ),
      home: const KisanHome(),
    );
  }
}

class Market {
  final String name;
  final double rate;
  final double transport;
  final double handling;
  final String distance;

  const Market(this.name, this.rate, this.transport, this.handling,
      this.distance);
}

class Buyer {
  final String name;
  final String crop;
  final double rate;
  final String type;
  final String distance;

  const Buyer(this.name, this.crop, this.rate, this.type, this.distance);
}

class KisanHome extends StatefulWidget {
  const KisanHome({super.key});

  @override
  State<KisanHome> createState() => _KisanHomeState();
}

class _KisanHomeState extends State<KisanHome> {
  final SpeechToText speech = SpeechToText();
  final FlutterTts tts = FlutterTts();

  final quantityController = TextEditingController(text: '1000');
  final locationController = TextEditingController(text: 'Gurugram');
  final questionController = TextEditingController();

  bool speechReady = false;
  bool listening = false;
  bool hindi = false;
  bool buyerMode = false;

  int tab = 0;
  String crop = 'Wheat';
  String heardText = '';
  String reply = '';

  final crops = const [
    'Wheat', 'Mustard', 'Rice', 'Bajra', 'Potato', 'Tomato'
  ];

  final markets = const [
    Market('Nearby Mandi', 24, 800, 200, '12 km'),
    Market('Regional Market', 25, 1800, 300, '35 km'),
    Market('Direct Buyer', 24.5, 500, 150, '8 km'),
  ];

  final buyers = const [
    Buyer('Haryana Grain Traders', 'Wheat', 24.5,
        'Bulk procurement', '18 km'),
    Buyer('FreshFarm Foods', 'Wheat', 25,
        'Food processing', '32 km'),
    Buyer('Green Basket Procurement', 'Mustard', 58,
        'Retail supply', '24 km'),
    Buyer('Regional Agri Collective', 'Rice', 22,
        'FPO procurement', '40 km'),
  ];

  int get quantity =>
      (int.tryParse(quantityController.text) ?? 0).clamp(0, 100000000);

  String money(num amount) => '₹${amount.round()}';

  double net(Market m) =>
      m.rate * quantity - m.transport - m.handling;

  @override
  void initState() {
    super.initState();
    prepareVoice();
  }

  Future<void> prepareVoice() async {
    try {
      speechReady = await speech.initialize(
        onStatus: (_) {
          if (mounted) {
            setState(() => listening = speech.isListening);
          }
        },
        onError: (_) {
          if (mounted) {
            setState(() => listening = false);
            message(hindi
                ? 'आवाज़ पहचानने में समस्या हुई। दोबारा कोशिश करें।'
                : 'Speech recognition failed. Please try again.');
          }
        },
      );
      await configureTts();
    } catch (_) {
      speechReady = false;
    }
    if (mounted) setState(() {});
  }

  Future<void> configureTts() async {
    await tts.setLanguage(hindi ? 'hi-IN' : 'en-IN');
    await tts.setSpeechRate(0.45);
    await tts.setVolume(1);
    await tts.setPitch(1);
  }

  Future<void> changeLanguage(bool value) async {
    setState(() => hindi = value);
    await tts.stop();
    await configureTts();
    message(hindi ? 'भाषा हिंदी में बदल दी गई है।' : 'Language changed to English.');
  }

  Future<void> toggleListening() async {
    if (speech.isListening) {
      await speech.stop();
      if (mounted) setState(() => listening = false);
      return;
    }

    if (!speechReady) await prepareVoice();

    if (!speechReady) {
      message(hindi
          ? 'स्पीच सेवा उपलब्ध नहीं है। माइक्रोफोन अनुमति और फोन की स्पीच सेटिंग जाँचें।'
          : 'Speech service unavailable. Check microphone permission and speech settings.');
      return;
    }

    await tts.stop();
    setState(() {
      heardText = '';
      listening = true;
    });

    try {
      await speech.listen(
        localeId: hindi ? 'hi_IN' : 'en_IN',
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        onResult: (result) {
          if (!mounted) return;
          setState(() => heardText = result.recognizedWords);
          if (result.finalResult && result.recognizedWords.trim().isNotEmpty) {
            handleQuestion(result.recognizedWords);
          }
        },
      );
      if (mounted) setState(() => listening = speech.isListening);
    } catch (_) {
      if (mounted) setState(() => listening = false);
      message('Could not start the microphone. Please try again.');
    }
  }

  Future<void> handleQuestion(String question) async {
    final q = question.toLowerCase();
    String answer;

    if (q.contains('net') || q.contains('profit') ||
        q.contains('return') || q.contains('मुनाफा') ||
        q.contains('कमाई') || q.contains('बचत')) {
      answer = hindi
          ? 'नेट रियलाइजेशन का मतलब है बिक्री की अनुमानित रकम में से परिवहन और हैंडलिंग का खर्च घटाना। सिर्फ ऊँची कीमत देखकर मंडी न चुनें।'
          : 'Net realisation means your estimated sale value minus transport and handling costs. Do not choose a market only because its listed price is higher.';
    } else if (q.contains('market') || q.contains('mandi') ||
        q.contains('price') || q.contains('मंडी') ||
        q.contains('बाजार') || q.contains('भाव')) {
      answer = hindi
          ? 'मार्केट्स टैब खोलें। वहाँ बिक्री मूल्य, परिवहन और हैंडलिंग खर्च की तुलना करें। ये उदाहरण वाले आँकड़े हैं, लाइव मंडी भाव नहीं।'
          : 'Open Markets to compare estimated sale values, transport and handling costs. These are illustrative figures, not live mandi prices.';
    } else if (q.contains('buyer') || q.contains('sell') ||
        q.contains('खरीदार') || q.contains('बेच')) {
      answer = hindi
          ? 'Buyers टैब में अपनी फसल के लिए संभावित खरीदारों की उदाहरण सूची देखें। ये वास्तविकता में सत्यापित खरीदार नहीं हैं।'
          : 'Open Buyers to explore sample procurement opportunities. These are illustrative buyer listings and have not been verified.';
    } else if (q.contains('transport') || q.contains('cost') ||
        q.contains('खर्च') || q.contains('परिवहन')) {
      answer = hindi
          ? 'मंडी चुनते समय परिवहन, लोडिंग और हैंडलिंग जैसे खर्च देखें। इस डेमो में परिवहन और हैंडलिंग शामिल हैं।'
          : 'Compare transport, loading and handling costs before choosing a market. This demo includes transport and handling.';
    } else if (q.contains('hello') || q.contains('hi') ||
        q.contains('नमस्ते') || q.contains('हेलो')) {
      answer = hindi
          ? 'नमस्ते! मैं सिया हूँ। आप मंडी, कीमत, खरीदार या खर्च के बारे में पूछ सकते हैं।'
          : 'Hello! I am SIYA, your farming decision assistant. Ask me about markets, prices, buyers or costs.';
    } else {
      answer = hindi
          ? 'अपनी फसल और मात्रा दर्ज करें। फिर Markets टैब में कीमत और खर्च की तुलना करें।'
          : 'Enter your crop and quantity, then open Markets to compare estimated prices and costs.';
    }

    if (!mounted) return;
    setState(() {
      reply = answer;
      tab = 3;
    });
    await speak(answer);
  }

  Future<void> speak(String text) async {
    try {
      await configureTts();
      await tts.stop();
      await tts.speak(text);
    } catch (_) {
      message('Text-to-speech is unavailable on this device.');
    }
  }

  void submitTypedQuestion() {
    final question = questionController.text.trim();
    if (question.isEmpty) return;
    questionController.clear();
    handleQuestion(question);
  }

  void message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  void dispose() {
    speech.stop();
    tts.stop();
    quantityController.dispose();
    locationController.dispose();
    questionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      buyerMode ? buyerDashboard() : farmerDashboard(),
      marketPage(),
      buyerPage(),
      siyaPage(),
    ];

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 76,
        title: const Row(
          children: [
            CircleAvatar(
              backgroundColor: forest,
              child: Icon(Icons.agriculture, color: Colors.white),
            ),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('KisanSetu AI',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                Text('SMARTER AGRICULTURAL DECISIONS',
                    style: TextStyle(fontSize: 9, letterSpacing: 1)),
              ],
            ),
          ],
        ),
        actions: [
          PopupMenuButton<bool>(
            onSelected: (value) => setState(() {
              buyerMode = value;
              tab = 0;
            }),
            itemBuilder: (_) => const [
              PopupMenuItem(value: false, child: Text('Farmer mode')),
              PopupMenuItem(value: true, child: Text('Buyer mode')),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Chip(
                avatar: Icon(buyerMode ? Icons.store : Icons.person, color: forest),
                label: Text(buyerMode ? 'Buyer' : 'Farmer'),
                backgroundColor: const Color(0xFFE4EDE3),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: IndexedStack(index: tab, children: pages),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (value) => setState(() => tab = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.insights_outlined), selectedIcon: Icon(Icons.insights), label: 'Markets'),
          NavigationDestination(icon: Icon(Icons.storefront_outlined), selectedIcon: Icon(Icons.storefront), label: 'Buyers'),
          NavigationDestination(icon: Icon(Icons.auto_awesome_outlined), selectedIcon: Icon(Icons.auto_awesome), label: 'SIYA'),
        ],
      ),
    );
  }

  Widget heading(String eyebrow, String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(eyebrow.toUpperCase(),
            style: const TextStyle(color: forest, fontSize: 11, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
        const SizedBox(height: 7),
        Text(title, style: const TextStyle(color: deepForest, fontSize: 25, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text(subtitle, style: const TextStyle(color: Colors.black54, height: 1.5)),
      ],
    );
  }

  Widget farmerDashboard() {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(color: deepForest, borderRadius: BorderRadius.circular(22)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(children: [
                Icon(Icons.auto_awesome, color: gold),
                SizedBox(width: 8),
                Text('YOUR SMART FARMING ASSISTANT', style: TextStyle(color: Colors.white70, fontSize: 10)),
              ]),
              const SizedBox(height: 18),
              Text(hindi ? 'बेहतर मंडी चुनें।\nसमझदारी से फैसला लें।' : 'Find the better market.\nMake the smarter choice.',
                  style: const TextStyle(color: Colors.white, fontSize: 27, fontWeight: FontWeight.bold, height: 1.25)),
              const SizedBox(height: 12),
              Text(hindi ? 'कीमत, खर्च और खरीदारों की तुलना करें।' : 'Compare prices, costs and potential buyers.',
                  style: const TextStyle(color: Colors.white70, height: 1.5)),
              const SizedBox(height: 18),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: gold, foregroundColor: deepForest),
                onPressed: () => setState(() => tab = 1),
                child: Text(hindi ? 'मंडी की तुलना करें' : 'Compare markets'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        heading('Get started', hindi ? 'फसल का विवरण' : 'Your crop details',
            hindi ? 'अपनी फसल और मात्रा दर्ज करें।' : 'Enter your produce details to explore opportunities.'),
        const SizedBox(height: 15),
        Card(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('SELECT CROP'),
                const SizedBox(height: 7),
                DropdownButtonFormField<String>(
                  value: crop,
                  isExpanded: true,
                  decoration: const InputDecoration(border: OutlineInputBorder(), prefixIcon: Icon(Icons.grass)),
                  items: crops.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (value) { if (value != null) setState(() => crop = value); },
                ),
                const SizedBox(height: 14),
                const Text('QUANTITY IN KG'),
                const SizedBox(height: 7),
                TextField(
                  controller: quantityController,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(border: OutlineInputBorder(), prefixIcon: Icon(Icons.scale_outlined), suffixText: 'kg'),
                ),
                const SizedBox(height: 14),
                const Text('LOCATION'),
                const SizedBox(height: 7),
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(border: OutlineInputBorder(), prefixIcon: Icon(Icons.location_on_outlined)),
                ),
                const SizedBox(height: 17),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () { FocusScope.of(context).unfocus(); setState(() => tab = 1); },
                    icon: const Icon(Icons.analytics_outlined),
                    label: Text(hindi ? 'अवसरों का विश्लेषण करें' : 'Analyse opportunities'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        feature(Icons.compare_arrows, 'Net Realisation Intelligence', 'Compare estimated proceeds after transport and handling.'),
        feature(Icons.handshake_outlined, 'Buyer matching', 'Explore illustrative crop procurement opportunities.'),
        feature(Icons.record_voice_over, 'SIYA Voice Assistant', 'Ask questions in English or Hindi and hear the response.'),
        demoNote(),
      ],
    );
  }

  Widget marketPage() {
    final sorted = [...markets]..sort((a, b) => net(b).compareTo(net(a)));
    final best = sorted.first;

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        heading('Market intelligence', 'Compare your options', '$crop · $quantity kg · ${locationController.text}'),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: deepForest, borderRadius: BorderRadius.circular(20)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('BEST ESTIMATED NET VALUE', style: TextStyle(color: gold, fontWeight: FontWeight.bold, letterSpacing: 1, fontSize: 11)),
              const SizedBox(height: 12),
              Text(best.name, style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 5),
              Text(money(net(best)), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 9),
              const Text('Ranked by estimated net value among sample options. Figures are illustrative.',
                  style: TextStyle(color: Colors.white70, height: 1.5)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text('Market breakdown', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19)),
        const SizedBox(height: 10),
        ...sorted.map((m) => Card(
          color: Colors.white,
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(m.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                const SizedBox(height: 5),
                Text('${m.distance} · ${money(m.rate)}/kg', style: const TextStyle(color: Colors.black54)),
                const Divider(height: 24),
                detail('Estimated sale value', money(m.rate * quantity)),
                detail('Transport and handling', money(m.transport + m.handling)),
                const Divider(),
                detail('Estimated net value', money(net(m)), bold: true),
              ],
            ),
          ),
        )),
        demoNote(),
      ],
    );
  }

  Widget detail(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(color: bold ? forest : Colors.black54, fontWeight: bold ? FontWeight.bold : FontWeight.normal))),
          Text(value, style: TextStyle(color: bold ? forest : Colors.black87, fontWeight: FontWeight.bold, fontSize: bold ? 17 : 14)),
        ],
      ),
    );
  }

  Widget buyerPage() {
    final list = buyers.where((b) => buyerMode || b.crop == crop).toList();
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        heading('Procurement network', buyerMode ? 'Buyer workspace' : 'Discover buyers',
            'Explore illustrative crop procurement opportunities.'),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(color: const Color(0xFFE5EDE3), borderRadius: BorderRadius.circular(17)),
          child: const Row(children: [
            Icon(Icons.handshake, color: forest, size: 32),
            SizedBox(width: 12),
            Expanded(child: Text('Connecting farmers, buyers and procurement opportunities.',
                style: TextStyle(color: deepForest, fontWeight: FontWeight.w600, height: 1.5))),
          ]),
        ),
        const SizedBox(height: 20),
        const Text('Available demo listings', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        ...list.map((b) => Card(
          color: Colors.white,
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.storefront, color: forest, size: 28),
                const SizedBox(height: 9),
                Text(b.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 5),
                Text('${b.type} · ${b.distance}', style: const TextStyle(color: Colors.black54)),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: Text('Crop: ${b.crop}')),
                  Text('${money(b.rate)}/kg', style: const TextStyle(color: forest, fontWeight: FontWeight.bold, fontSize: 17)),
                ]),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Demo opportunity'),
                        content: Text('Buyer: ${b.name}\nCrop: ${b.crop}\nIndicative rate: ${money(b.rate)}/kg\n\nSample data only. No real buyer has been contacted.'),
                        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
                      ),
                    ),
                    child: const Text('View opportunity'),
                  ),
                ),
              ],
            ),
          ),
        )),
        demoNote(),
      ],
    );
  }

  Widget buyerDashboard() {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        heading('Procurement workspace', 'Source produce smarter', 'Explore crop supply and indicative prices.'),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(color: deepForest, borderRadius: BorderRadius.circular(22)),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.storefront, color: gold, size: 36),
              SizedBox(height: 15),
              Text('A more connected supply chain.', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
              SizedBox(height: 12),
              Text('Explore sample supply listings, compare indicative rates and discover procurement opportunities.',
                  style: TextStyle(color: Colors.white70, height: 1.6)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        feature(Icons.grass, 'Supply discovery', 'Explore produce listings by crop.'),
        feature(Icons.price_change_outlined, 'Price intelligence', 'Compare indicative market values.'),
        feature(Icons.handshake_outlined, 'Market linkages', 'Explore potential farmer-buyer connections.'),
        FilledButton(onPressed: () => setState(() => tab = 2), child: const Text('Explore listings')),
        demoNote(),
      ],
    );
  }

  Widget siyaPage() {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Container(
          padding: const EdgeInsets.all(21),
          decoration: BoxDecoration(color: deepForest, borderRadius: BorderRadius.circular(22)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(backgroundColor: Color(0xFFE4EDE3), child: Icon(Icons.auto_awesome, color: forest)),
              const SizedBox(height: 15),
              Text(hindi ? 'नमस्ते, मैं सिया हूँ' : 'Hello, I am SIYA',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 27)),
              const SizedBox(height: 9),
              Text(hindi ? 'फसल, मंडी, कीमत या खरीदारों के बारे में पूछें।' : 'Ask me about crops, markets, prices and buyers.',
                  style: const TextStyle(color: Colors.white70, height: 1.6)),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Card(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Assistant language', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                const SizedBox(height: 12),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, icon: Icon(Icons.language), label: Text('English')),
                    ButtonSegment(value: true, icon: Icon(Icons.translate), label: Text('हिंदी')),
                  ],
                  selected: {hindi},
                  onSelectionChanged: (selection) => changeLanguage(selection.first),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 18),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 112,
                height: 112,
                decoration: BoxDecoration(color: listening ? const Color(0xFFFFE7E3) : const Color(0xFFE5EDE3), shape: BoxShape.circle),
                child: IconButton(
                  tooltip: listening ? 'Stop listening' : 'Start listening',
                  iconSize: 52,
                  onPressed: toggleListening,
                  icon: Icon(listening ? Icons.stop_circle : Icons.mic, color: listening ? Colors.red : forest),
                ),
              ),
              const SizedBox(height: 13),
              Text(listening ? (hindi ? 'सुन रही हूँ...' : 'Listening...') : (hindi ? 'बोलने के लिए माइक दबाएँ' : 'Tap the microphone to speak'),
                  textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Text(heardText.isEmpty ? (hindi ? 'उदाहरण: मेरे लिए कौन सी मंडी बेहतर है?' : 'Example: Which market is better for me?') : heardText,
                  textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54, height: 1.5)),
              const SizedBox(height: 18),
              if (listening) const LinearProgressIndicator(color: forest),
              const SizedBox(height: 10),
              Text(speechReady ? 'Speech service is ready' : 'Starting speech service or unavailable',
                  textAlign: TextAlign.center, style: const TextStyle(color: Colors.black45, fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (reply.isNotEmpty)
          Card(
            color: const Color(0xFFE5EDE3),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(children: [Icon(Icons.auto_awesome, color: forest), SizedBox(width: 8), Text('SIYA response', style: TextStyle(fontWeight: FontWeight.bold))]),
                  const SizedBox(height: 12),
                  Text(reply, style: const TextStyle(height: 1.6)),
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton.icon(
                      onPressed: () => speak(reply),
                      icon: const Icon(Icons.volume_up),
                      label: Text(hindi ? 'फिर सुनें' : 'Speak again'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 12),
        TextField(
          controller: questionController,
          textInputAction: TextInputAction.send,
          onSubmitted: (_) => submitTypedQuestion(),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            hintText: hindi ? 'यहाँ अपना सवाल लिखें...' : 'Type your question...',
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(onPressed: submitTypedQuestion, icon: const Icon(Icons.send, color: forest)),
          ),
        ),
        const SizedBox(height: 14),
        const Text('Try a question', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        const SizedBox(height: 8),
        ...[
          hindi ? 'नेट रियलाइजेशन क्या है?' : 'What is net realisation?',
          hindi ? 'मंडी की तुलना कैसे करूँ?' : 'How do I compare markets?',
          hindi ? 'मैं खरीदार कैसे ढूँढूँ?' : 'How can I find buyers?',
        ].map((q) => Card(
          color: Colors.white,
          child: ListTile(
            leading: const Icon(Icons.chat_outlined, color: forest),
            title: Text(q),
            trailing: const Icon(Icons.arrow_forward_ios, size: 15),
            onTap: () => handleQuestion(q),
          ),
        )),
        demoNote(),
      ],
    );
  }

  Widget feature(IconData icon, String title, String description) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: const Color(0xFFE5EDE3), child: Icon(icon, color: forest)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(description),
      ),
    );
  }

  Widget demoNote() {
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 16),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(color: const Color(0xFFF0E9D9), borderRadius: BorderRadius.circular(12)),
      child: const Text(
        'DEMO DATA: Market prices and buyer records are illustrative, not live data. Actual returns may vary. No real transactions or live AI service are connected.',
        style: TextStyle(fontSize: 11, height: 1.5),
      ),
    );
  }
}
