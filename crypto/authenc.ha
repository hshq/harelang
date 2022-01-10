// A secret session key.
export type sessionkey = [32]u8;

// A value which is only used once.
export type nonce = [24]u8;

// A message authentication code.
export type mac = [24]u8;

// An encrypted, authenticated message.
export type box = (mac, nonce, []u8);

// Performs authenticated encryption on a message. The result may be
// authenticated and decrypted with [[decrypt]].
//
// To use this function, you must first establish a session key which is shared
// with both parties. This key must be random and secret. You may derive this
// key with a key exchange (such as [[exchange]] or [[crypto::dh]]), or with a
// key derivation function (such as [[derivekey]]), or by sharing it in person,
// or some other, similar means which preserves the traits of randomness and
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
	additional: []u8...
) box;

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
) ([]u8 | errors::invalid);

// TODO: Add additional entry-points which provide a finer degree of control
// over buffer usage.