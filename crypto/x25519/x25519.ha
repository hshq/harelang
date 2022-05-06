// License: MPL-2.0
// (c) 2022 Armin Preiml <apreiml@strohwolke.at>
use crypto::curve25519;

// Type for private, public or shared keys.
export type key = [32]u8;

// Initializes a new x25519 private key from the provided 32-byte seed,
// which should be generated with [[crypto::random]].
export fn newkey(priv: *key, seed: *[32]u8) void = {
	priv[..] = seed[..];
	curve25519::clamp(priv);
};

// Derives the public key from a private key prepared with [[newkey]],
// writing it to the 'pub' parameter.
export fn pubkey(pub: *key, priv: const *key) void =
	curve25519::scalarmult_base(pub, priv);

// Derives a 32-byte shared key from the private key of one key-pair and
// the public key of a second key-pair.
export fn derive(shared: *key, priv: *key, pub: *key) void = {
	curve25519::x25519(shared, priv, pub);

	// TODO figure out if checking for low order points is required
	// https://github.com/jedisct1/libsodium/blob/cec56d867f741e66f78b9fde37d9081643599a2a/src/libsodium/crypto_scalarmult/curve25519/ref10/x25519_ref10.c#L90
};
