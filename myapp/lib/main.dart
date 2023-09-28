import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:encrypt/encrypt.dart' as en;
import 'package:pointycastle/export.dart' as pc;
import 'package:convert/convert.dart';
import 'package:flutter/material.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:pointycastle/asymmetric/oaep.dart';
import 'package:pointycastle/asymmetric/rsa.dart';
import 'package:pointycastle/digests/sha256.dart';
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a blue toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    // アセットから秘密鍵を読み込む
    final privateKeyContent = await rootBundle.loadString('assets/private.pem');
    final en.RSAKeyParser parser = en.RSAKeyParser();
    final RSAPrivateKey privateKey = parser.parse(privateKeyContent) as RSAPrivateKey;

    // 16進数の暗号文をバイト配列にデコード
    final ciphertext = hex.decode("164e6cfa75bb6f724f5717b449af4b005919479daeda8c4a3e4300ea2df2e83aebcd4cbb2251ca2ac9bca65d96b80de8cfb7709fdb8ecd5ed9028842114f2e41b72cdcab7bfd06b9025f86c07e6dd2297688d1d4ceb72816f796f6687519b962ebd38d811feca186c2697b5fb6c5b40d78bc07f850204604256cdc4d75be4b8ef9f5493277c8f0bf8d8a560bf935c8613fa2b7c68b3c736a9322c957248aacbae09037ec108c72818c8adc70bb388977f5cd36e127b0e36355ba986c7e96234b5f49005b5dc1a13d897e6c13a9b18d667861293f383a80e64c3834e43fbb88a8821b2d57ff79a93c65669b1b5718587243c40c77f2548626800fa9d28e95822f");

    // OAEPパディングとRSAエンジンを使ってデコーダを初期化
    final decryptor = OAEPEncoding(RSAEngine())
      ..init(false, pc.PrivateKeyParameter<RSAPrivateKey>(privateKey));


    // 暗号文を復号化してUTF-8でデコード
    try {
      final decrypted = utf8.decode(decryptor.process(Uint8List.fromList(ciphertext)));
      print('Decrypted String: $decrypted');
    } catch (e) {
      print('Error: $e');
    }
  }
  

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
