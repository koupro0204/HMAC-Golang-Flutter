# Golangで文字列を非対称キー暗号化して、Flutterで復号する

## はじめに
今回数独アプリを開発する上で、回答を隠したいという気持ちになりました。
そこで備忘録、勉強ついでにこれを書いていきます。

非対称キー暗号化というタイトルですが、最初ハッシュ化でやろうとしていたため序盤はハッシュ化の話です。
必要ない方は適宜飛ばしてください。

前提として、以下の通りです。
- Golangでハッシュ化（暗号化）
- Flutter（Dart）で復元

GolangでAPIを開発しているので、DBに保存する際にハッシュ化したいと考えています。
もちろんGolangでDBからデータを取得した後、Flutter側に渡す前に復元する方法も考えられます。
ただ、通信にそのまま載せるのは何かなーという気持ちから、Flutter側で復元することに決めました。

### 結論からいうとハッシュ化ではなく暗号化を使用した。
選定しなかった理由に書いてありますが、ハッシュ化はデータの復元を考慮していないためです。
Githubのリポジトリの名前がHMACになっているのは最初にHMACを使おうとしてたからです。

## Golangでのハッシュ化の方法
「Golang ハッシュ化」と検索すると、色々な方法が見つかります。
以下に一例を紹介します。

### 1. SHA-256
どんな長さの原文からも256ビットのハッシュ値を算出することができるハッシュ関数
自分が調べた感じ、SHA-256の記事が体感多かったです。
よく使われている感じですかね。

> 参考：[SHA-256 【Secure Hash Algorithm 256-bit】](https://e-words.jp/w/SHA-256.html)
> 参考：[golangで文字列からsha256でハッシュ化する方法](https://qiita.com/mergit/items/ffdb405173dee651856d)

```go
package main

import (
	"crypto/sha256"
	"encoding/hex"
	"fmt"
)

func main() {
	data := "secret data"
	hash := sha256.Sum256([]byte(data))
	fmt.Println(hex.EncodeToString(hash[:]))
}
```
### 2. bcrypt
Blowfish暗号を基盤としたパスワードハッシュアルゴリズム（暗号学的ハッシュ関数）です。
なのでパスワードのハッシュ化に主に用います。
参考の記事に色々詳しく書いてくれているため読んでみてください。
簡単に言うとセキュリティが高いみたいです。

参考のZennの記事は検証部分もあるためパスワードの部分では参考になりそうなのでここに残しておきます。

> 参考：[【パスワード】bcryptとは](https://medium-company.com/bcrypt/)
> 参考：[【Go】bcrypt を使ってパスワードのハッシュ値を生成して検証する](https://zenn.dev/kou_pg_0131/articles/go-digest-and-compare-by-bcrypt)

生成自体は以下です。
詳しく知りたい方は以下の公式へ。
https://pkg.go.dev/golang.org/x/crypto/bcrypt

```go
package main

import (
	"fmt"
	"golang.org/x/crypto/bcrypt"
)

func main() {
	password := "secret data"
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		panic(err)
	}
	fmt.Println(string(hashedPassword))
}
```

### 3. HMAC
HMACは、秘密鍵を利用してデータの正当性を確認します。
第三者によるデータの改ざんを防ぐことができます。

> 参考：[HMAC（Hash-based Message Authentication Code）とは？データ認証の基本概念を解説](https://the-simple.jp/what-is-hmac-hash-based-message-authentication-code-explain-basic-concepts-of-data-authentication)
> 参考：[Go言語でHMACを利用する方法](https://thiscalifornianlife.com/2020/12/29/post-863/)


詳しく知りたい方は以下の公式へ。
https://pkg.go.dev/crypto/hmac

```go
package main

import (
	"crypto/hmac"
	"crypto/sha256"
	"encoding/hex"
	"fmt"
)

func main() {
	data := "secret data"
	key := "secret key"

	mac := hmac.New(sha256.New, []byte(key))
	mac.Write([]byte(data))
	hash := mac.Sum(nil)
	fmt.Println(hex.EncodeToString(hash))
}
```

### 選定しなかった理由
SHA-256、bcrypt、およびHMACは、いずれも一方向性のハッシュ化アルゴリズムであり、
一度ハッシュ化されたデータを元の平文に戻すことは理論的に不可能です。
データの完全性とセキュリティを確保するためにデザインされていて、元のデータの復元を考慮していません。
っていうか戻せたらパスワードのハッシュ化とか影響出ちゃいますね😅
完全に考えていませんでした。

***Flutter側で復元する必要がある今回の場合、これらの方法は適していないと判断しました。***


### その他のアプローチ
以下にChatGPTに聞いたアプローチ方法です。
#### 対称キー暗号化
対称キー暗号化では、暗号化と復号化の両方で同じ鍵を使用します。
AES（Advanced Encryption Standard）が一般的な対称キー暗号化アルゴリズムです。
これを用いることで、Flutter側でデータを復元することが可能ですが、鍵の管理と安全な共有が重要となります。

#### 非対称キー暗号化
非対称キー暗号化では、公開鍵と秘密鍵のペアを使用します。
公開鍵で暗号化されたデータは、対応する秘密鍵でのみ復号化できます。
RSAが広く知られた非対称キー暗号化アルゴリズムです。
この方法も、Flutter側でのデータ復元に利用できますが、鍵のペアの管理が必要です。

これらの暗号化アプローチを採用することで、セキュリティを維持しつつFlutter側でデータの復元が可能となります。
ただし、鍵の管理は慎重に行う必要があります。

## 改めて今回使用するのは非対称キー暗号化です。
前置きがかなり長くなりましたが、本題に入っていきます。

### 選定理由
主な理由は、対応する秘密鍵でのみ復号化という点ですね。
対称キー暗号化では暗号化と復号化の両方で同じ鍵を使用します。
正直こっちでも問題はないと思います。
ただ、同じ鍵でする必要もないかなと思いました。
FlutterとGolangは分けたい気持ちだったのでそれぞれに異なる鍵を持たせます。

ってことで非対称キー暗号化をやっていきます。

## Golang側 - 非対称キー暗号化
Golang側で行うのは以下の二つです。
- 鍵の生成
- 暗号化

### インポート文
```go
import (
	"crypto/rand"
	"crypto/rsa"
	"crypto/sha1"
	"crypto/x509"
	"encoding/pem"
	"fmt"
	"io"
	"os"
)
```


### 鍵の生成
```go
func generateAndSaveKeys(privatePath string, publicPath string) error {
	// RSAキーペアの生成
	// 2048ビットのRSAキーを生成
	privateKey, err := rsa.GenerateKey(rand.Reader, 2048) 
	if err != nil {
		return err
	}

	// 秘密鍵の保存
	privateFile, err := os.Create(privatePath)
	if err != nil {
		return err
	}
	defer privateFile.Close()

	privateBlock := &pem.Block{
		Type:  "RSA PRIVATE KEY", // ここはRSA PRIVATE KEYで固定
		Bytes: x509.MarshalPKCS1PrivateKey(privateKey), // ASN.1 DER形式でエンコード
	}

	// pem形式でエンコードして書き込み
	if err := pem.Encode(privateFile, privateBlock); err != nil {
		return err
	}
	
	// 公開鍵の保存
	publicKey := &privateKey.PublicKey
	publicFile, err := os.Create(publicPath)
	if err != nil {
		return err
	}
	defer publicFile.Close()

	publicBlock := &pem.Block{
		Type:  "PUBLIC KEY",
		Bytes: x509.MarshalPKCS1PublicKey(publicKey),
	}
	if err := pem.Encode(publicFile, publicBlock); err != nil {
		return err
	}

	return nil
}
```
### 暗号化

```go
func loadPublicKey(path string) (*rsa.PublicKey, error) {
	file, err := os.Open(path)
	if err != nil {
		return nil, err
	}
	defer file.Close()

	data, err := io.ReadAll(file)
	if err != nil {
		return nil, err
	}

	block, _ := pem.Decode(data)
	if block == nil {
		return nil, fmt.Errorf("failed to decode PEM block")
	}

	publicKey, err := x509.ParsePKCS1PublicKey(block.Bytes)
	if err != nil {
		return nil, err
	}

	return publicKey, nil
}

func main() {
	publicKey, err := loadPublicKey("public.pem")
	if err != nil {
		panic(err)
	}

	message := []byte("secret data")
	ciphertext, err := rsa.EncryptOAEP(sha1.New(), rand.Reader, publicKey, message, nil)
	if err != nil {
		panic(err)
	}

	fmt.Printf("Ciphertext: %x\n", ciphertext)
}
```

## Flutter側 - 非対称キー暗号化
:::note alert
正直FlutterあんまりわかってないのでChatGPTに聞きながらコードを書いています。
:::
Flutter側で行うのは以下の一つです。
- 暗号文の復号

Flutterのプロジェクトを立ち上げてその中でやっていきます。
＊ここは分かっていると思うので解説なし。

imprt部分
```dart
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:rsa_encrypt/rsa_encrypt.dart';
import 'package:pointycastle/export.dart' as pc;
import 'package:convert/convert.dart';
import 'package:flutter/material.dart';
```

秘密鍵を読み込まないといけないのでassetsディレクトリを作成しそこに入れこんで読み込ませます。
dependenciesも書き込みます。
```yaml
flutter:
  assets:
    - assets/private.pem
dependencies:
  flutter:
    sdk: flutter
  encrypt: ^5.0.1
  pointycastle: ^3.3.3
  convert: ^3.0.1
```
### 復号部分
今回は、デフォルトのコードをいじって動くようにしています。
適宜変えてください。
```dart
// 以上変わらず
class _MyHomePageState extends State<MyHomePage> {
  // 以上変わらず
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
    // 「secret data」を暗号化したもの
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
  // 以降変わらず
}
```


## つまづいたところ
### GoとFlutterの互換性（rsa.EncryptOAEP）
Goの「rsa.EncryptOAEP & SHA256」で暗号化を行っていたが、Flutterの「pointycastle」との互換性がなく、復号がうまくいかなかった。
pointycastleはSHA1で行うためGolangでの暗号化もSHA1で行わなければならなかった。
