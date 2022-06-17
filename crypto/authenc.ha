// License: MPL-2.0
// (c) 2022 Armin Preiml <apreiml@strohwolke.at>
// (c) 2022 Drew DeVault <sir@cmpwn.com>
use bytes;
use bufio;
use crypto::chacha;
use crypto::cipher;
use crypto::poly1305;
use crypto::mac;
use crypto::math;
use endian;
use errors;
use io;

// A secret session key.
export type sessionkey = [32]u8;

// A value which is only used once.
export type nonce = [24]u8;

// A message authentication code.
export type mac = [16]u8;

// An encrypted, authenticated message.
export type box = (mac, nonce, []u8);

// Performs authenticated encryption on a message. The result may be
// authenticated and decrypted with [[decrypt]].
//
// To use this function, you must first establish a session key which is shared
// with both parties. This key must be random and secret. You may derive this
// key with a key exchange (such as [[exchange]] or [[dh]]), or with a key
// derivation function (such as [[derivekey]]), or by sharing it in person, or
// some other, similar means which preserves the traits of randomness and
// secrecy.
//
// You must also establish a unique nonce for each message, which you must not
// reuse for any future messages using the same session key. It is recommended
// to generate this randomly with [[crypto::random]].
//
// The plaintext parameter provides the message to encrypt. It will be
// overwritten with the ciphertext. The buffer provided in the return value is
// borrowed from this parameter.
//
// The optional 'additional' parameters provide additional data to be
// authenticated with the same MAC. This data is not encrypted, but [[decrypt]]
// will fail if it has been tampered with. The order of these arguments must be
// consistent between [[encrypt]] and [[decrypt]].
//
// The return value contains all of the information which should be transmitted
// to the other party, including the computed MAC, a copy of the nonce, and the
// ciphertext. It is safe to transmit these values over an unsecured connection,
// or to encode them with something like [[encoding::base64]].
//
// Any 'additional' data, if provided, is not included in the [[box]] type. The
// user must provide for this data to be transmitted to the other party
// themselves.
//
// 	let key: crypto::sessionkey = [0...];
// 	let nonce: crypto::nonce = [0...];
// 	random::buffer(key); // Or some other means of establishing the key
// 	random::buffer(nonce);
//
// 	let buf: [64]u8 = [0...]; // Populate with your message
// 	let box = crypto::encrypt(&key, &nonce, buf[..], buf[..]);
//
//	// To decrypt this message:
// 	let plaintext = match (crypto::decrypt(&key, &box, buf[..])) {
// 	case let buf: []u8 =>
// 		yield buf;
// 	case errors::invalid =>
// 		abort("Message authentication or decryption failed");
// 	};
//
// The current implementation of this algorithm is based on RFC 8439, but uses
// XChaCha20 instead of ChaCha20.
export fn encrypt(
	key: *sessionkey,
	nonce: *nonce,
	plaintext: []u8,
	additional: []u8...,
) box = {
	let s = chacha::chacha20();
	defer io::close(&s)!;

	let otk: poly1305::key = [0...];
	defer bytes::zero(otk);

	let otkbuf = bufio::fixed(otk, io::mode::WRITE);
	chacha::xchacha20_init(&s, &otkbuf, key, nonce);
	io::writeall(&s, otk[..])!;

	let ciphertext = plaintext;
	let cipherbuf = bufio::fixed(ciphertext, io::mode::WRITE);

	chacha::xchacha20_init(&s, &cipherbuf, key, nonce);
	chacha::setctr(&s, 1);
	io::writeall(&s, plaintext)!;

	let m: mac = [0...];
	writemac(&m, &otk, ciphertext, additional...);
	return (m, *nonce, ciphertext);
};

fn writemac(
	m: *mac,
	otk: *poly1305::key,
	ciphertext: []u8,
	additional: []u8...,
) void = {
	let poly = poly1305::poly1305();
	poly1305::init(&poly, otk);
	defer mac::finish(&poly);

	let adlen: size = 0;
	for (let i = 0z; i < len(additional); i += 1) {
		adlen += len(additional[i]);
		mac::write(&poly, additional[i]);
	};
	polypad(&poly, adlen);

	mac::write(&poly, ciphertext);
	polypad(&poly, len(ciphertext));

	let nbuf: [8]u8 = [0...];
	endian::leputu64(nbuf, adlen: u32);
	mac::write(&poly, nbuf);

	endian::leputu64(nbuf, len(ciphertext): u32);
	mac::write(&poly, nbuf);

	mac::sum(&poly, m[..]);
};

fn polypad(p: *poly1305::state, n: size) void = {
	if (n % poly1305::BLOCKSIZE == 0) {
		return;
	};

	const pad: [poly1305::BLOCKSIZE]u8 = [0...];
	const padlen = poly1305::BLOCKSIZE - (n % poly1305::BLOCKSIZE);
	mac::write(p, pad[..padlen]);
};


// Authenticates and decrypts a message encrypted with [[encrypt]]. If the
// decryption is successful, the plaintext slice is returned, and if not,
// [[errors::invalid]] is returned.
//
// The 'sessionkey' parameter is the shared key. The 'box' parameter is the
// output of [[encrypt]]. If additional data should be authenticated, it may be
// provided in the variadic 'additional' parameters.
//
// Note that the data is decrypted in-place, such that the box's ciphertext
// becomes overwritten with the plaintext. The return value is borrowed from
// this buffer. If decryption fails, this buffer will be zeroed, causing the
// ciphertext to be destroyed as well. It is advised to zero the plaintext
// buffer yourself after you are done using it, see [[bytes::zero]].
//
// See [[decrypt]] for the full details and a usage example.
export fn decrypt(
	key: *sessionkey,
	box: *box,
	additional: []u8...
) ([]u8 | errors::invalid) = {
	let s = chacha::chacha20();
	defer io::close(&s)!;

	let otk: poly1305::key = [0...];
	defer bytes::zero(otk);

	let otkbuf = bufio::fixed(otk, io::mode::WRITE);
	chacha::xchacha20_init(&s, &otkbuf, key, &box.1);
	io::writeall(&s, otk)!;

	let ciphertext = box.2;

	let m: mac = [0...];
	writemac(&m, &otk, ciphertext, additional...);

	if (!compare(m, box.0)) {
		bytes::zero(ciphertext);
		return errors::invalid;
	};

	let plaintext = ciphertext;
	let cipherbuf = bufio::fixed(ciphertext, io::mode::READ);

	chacha::xchacha20_init(&s, &cipherbuf, key, &box.1);
	chacha::setctr(&s, 1);

	io::readall(&s, plaintext)!;

	return plaintext;
};

// Compares two slices and returns true if they are equal. Comparison is done
// in constant time, meaning that the time it takes depends only on the size of
// the slices and not the content.
export fn compare(a: []u8, b: []u8) bool = {
	if (len(a) != len(b)) {
		return false;
	};

	return math::cmpslice(a, b) == 1;
};

// TODO: Add additional entry-points which provide a finer degree of control
// over buffer usage.
