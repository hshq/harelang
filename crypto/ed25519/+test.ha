// License: MPL-2.0
// (c) 2022 Luke Champine <luke.champine@gmail.com>
use bytes;
use encoding::hex;
use strings;

@test fn roundtrip() void = {
	let seed: seed = [1...];
	let priv_key: privatekey = [0...];
	private_init(&priv_key, &seed);
	let pub_key = skey_getpublic(&priv_key);

	const msg = strings::toutf8("hello, world!");
	let sig = sign(&priv_key, msg);
	assert(verify(&pub_key, msg, &sig));

	let bad_pub_key = pub_key;
	bad_pub_key[0] ^= 1;
	const bad_msg = strings::toutf8("HELLO, WORLD!");
	let bad_sig = sig;
	bad_sig[0] ^= 1;

	assert(!verify(&bad_pub_key, msg, &sig));
	assert(!verify(&pub_key, bad_msg, &sig));
	assert(!verify(&pub_key, msg, &bad_sig));
};

@test fn golden() void = {
	// TODO https://todo.sr.ht/~sircmpwn/hare/596
	let priv_key: privatekey = [0...];
	let priv_key_u8 = hex::decode("8ed7a797b9cea8a8370d419136bcdf683b759d2e3c6947f17e13e2485aa9d420b49f3a78b1c6a7fca8f3466f33bc0e929f01fba04306c2a7465f46c3759316d9") as []u8;
	priv_key[..] = priv_key_u8[..];
	free(priv_key_u8);
	const pub_key = skey_getpublic(&priv_key);

	let msg = hex::decode("a750c232933dc14b1184d86d8b4ce72e16d69744ba69818b6ac33b1d823bb2c3") as []u8;
	defer free(msg);

	let good_sig: privatekey = [0...];
	let sig_u8 = hex::decode("04266c033b91c1322ceb3446c901ffcf3cc40c4034e887c9597ca1893ba7330becbbd8b48142ef35c012c6ba51a66df9308cb6268ad6b1e4b03e70102495790b") as []u8;
	good_sig[..] = sig_u8[..];
	free(sig_u8);

	const sig = sign(&priv_key, msg);
	assert(bytes::equal(sig, good_sig));
	assert(verify(&pub_key, msg, &sig));
};
