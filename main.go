package main

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
		Type:  "RSA PRIVATE KEY",                       // ここはRSA PRIVATE KEYで固定
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
	// if err := generateAndSaveKeys("private.pem", "public.pem"); err != nil {
	// 	panic(err)
	// }

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
