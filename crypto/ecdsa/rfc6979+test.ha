// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use bytes;
use crypto::ec;
use crypto::sha1;
use crypto::sha256;
use crypto::sha512;
use encoding::hex;
use hash;
use io;
use strings;
use test;

const p256q: [_]u8 = [
	0x04, 0x60, 0xfe, 0xd4, 0xba, 0x25, 0x5a, 0x9d, 0x31, 0xc9, 0x61, 0xeb,
	0x74, 0xc6, 0x35, 0x6d, 0x68, 0xc0, 0x49, 0xb8, 0x92, 0x3b, 0x61, 0xfa,
	0x6c, 0xe6, 0x69, 0x62, 0x2e, 0x60, 0xf2, 0x9f, 0xb6, 0x79, 0x03, 0xfe,
	0x10, 0x08, 0xb8, 0xbc, 0x99, 0xa4, 0x1a, 0xe9, 0xe9, 0x56, 0x28, 0xbc,
	0x64, 0xf2, 0xf1, 0xb2, 0x0c, 0x2d, 0x7e, 0x9f, 0x51, 0x77, 0xa3, 0xc2,
	0x94, 0xd4, 0x46, 0x22, 0x99
];

const p256x: [_]u8 = [
	0xc9, 0xaf, 0xa9, 0xd8, 0x45, 0xba, 0x75, 0x16, 0x6b, 0x5c, 0x21, 0x57,
	0x67, 0xb1, 0xd6, 0x93, 0x4e, 0x50, 0xc3, 0xdb, 0x36, 0xe8, 0x9b, 0x12,
	0x7b, 0x8a, 0x62, 0x2b, 0x12, 0x0f, 0x67, 0x21
];

const p384q: [_]u8 = [
	0x04, 0xec, 0x3a, 0x4e, 0x41, 0x5b, 0x4e, 0x19, 0xa4, 0x56, 0x86, 0x18,
	0x02, 0x9f, 0x42, 0x7f, 0xa5, 0xda, 0x9a, 0x8b, 0xc4, 0xae, 0x92, 0xe0,
	0x2e, 0x06, 0xaa, 0xe5, 0x28, 0x6b, 0x30, 0x0c, 0x64, 0xde, 0xf8, 0xf0,
	0xea, 0x90, 0x55, 0x86, 0x60, 0x64, 0xa2, 0x54, 0x51, 0x54, 0x80, 0xbc,
	0x13, 0x80, 0x15, 0xd9, 0xb7, 0x2d, 0x7d, 0x57, 0x24, 0x4e, 0xa8, 0xef,
	0x9a, 0xc0, 0xc6, 0x21, 0x89, 0x67, 0x08, 0xa5, 0x93, 0x67, 0xf9, 0xdf,
	0xb9, 0xf5, 0x4c, 0xa8, 0x4b, 0x3f, 0x1c, 0x9d, 0xb1, 0x28, 0x8b, 0x23,
	0x1c, 0x3a, 0xe0, 0xd4, 0xfe, 0x73, 0x44, 0xfd, 0x25, 0x33, 0x26, 0x47,
	0x20
];

const p384x: [_]u8 = [
	0x6b, 0x9d, 0x3d, 0xad, 0x2e, 0x1b, 0x8c, 0x1c, 0x05, 0xb1, 0x98, 0x75,
	0xb6, 0x65, 0x9f, 0x4d, 0xe2, 0x3c, 0x3b, 0x66, 0x7b, 0xf2, 0x97, 0xba,
	0x9a, 0xa4, 0x77, 0x40, 0x78, 0x71, 0x37, 0xd8, 0x96, 0xd5, 0x72, 0x4e,
	0x4c, 0x70, 0xa8, 0x25, 0xf8, 0x72, 0xc9, 0xea, 0x60, 0xd2, 0xed, 0xf5
];

const p521q: [_]u8 = [
	0x04, 0x01, 0x89, 0x45, 0x50, 0xd0, 0x78, 0x59, 0x32, 0xe0, 0x0e, 0xaa,
	0x23, 0xb6, 0x94, 0xf2, 0x13, 0xf8, 0xc3, 0x12, 0x1f, 0x86, 0xdc, 0x97,
	0xa0, 0x4e, 0x5a, 0x71, 0x67, 0xdb, 0x4e, 0x5b, 0xcd, 0x37, 0x11, 0x23,
	0xd4, 0x6e, 0x45, 0xdb, 0x6b, 0x5d, 0x53, 0x70, 0xa7, 0xf2, 0x0f, 0xb6,
	0x33, 0x15, 0x5d, 0x38, 0xff, 0xa1, 0x6d, 0x2b, 0xd7, 0x61, 0xdc, 0xac,
	0x47, 0x4b, 0x9a, 0x2f, 0x50, 0x23, 0xa4, 0x00, 0x49, 0x31, 0x01, 0xc9,
	0x62, 0xcd, 0x4d, 0x2f, 0xdd, 0xf7, 0x82, 0x28, 0x5e, 0x64, 0x58, 0x41,
	0x39, 0xc2, 0xf9, 0x1b, 0x47, 0xf8, 0x7f, 0xf8, 0x23, 0x54, 0xd6, 0x63,
	0x0f, 0x74, 0x6a, 0x28, 0xa0, 0xdb, 0x25, 0x74, 0x1b, 0x5b, 0x34, 0xa8,
	0x28, 0x00, 0x8b, 0x22, 0xac, 0xc2, 0x3f, 0x92, 0x4f, 0xaa, 0xfb, 0xd4,
	0xd3, 0x3f, 0x81, 0xea, 0x66, 0x95, 0x6d, 0xfe, 0xaa, 0x2b, 0xfd, 0xfc,
	0xf5
];

const p521x: [_]u8 = [
	0x00, 0xfa, 0xd0, 0x6d, 0xaa, 0x62, 0xba, 0x3b, 0x25, 0xd2, 0xfb, 0x40,
	0x13, 0x3d, 0xa7, 0x57, 0x20, 0x5d, 0xe6, 0x7f, 0x5b, 0xb0, 0x01, 0x8f,
	0xee, 0x8c, 0x86, 0xe1, 0xb6, 0x8c, 0x7e, 0x75, 0xca, 0xa8, 0x96, 0xeb,
	0x32, 0xf1, 0xf4, 0x7c, 0x70, 0x85, 0x58, 0x36, 0xa6, 0xd1, 0x6f, 0xcc,
	0x14, 0x66, 0xf6, 0xd8, 0xfb, 0xec, 0x67, 0xdb, 0x89, 0xec, 0x0c, 0x08,
	0xb0, 0xe9, 0x96, 0xb8, 0x35, 0x38
];

type hashf = enum {
	SHA1,
	SHA224,
	SHA256,
	SHA384,
	SHA512,
};

type tcurveid = enum {
	P256,
	P384,
	P521,
};

type testcase = struct {
	curve: tcurveid,
	qpoint: []u8,
	x: []u8,
	hashf: hashf,
	msg: str,
	k: str,
	sig: str,
};

// XXX: alloc is used to circumvent not initialisable during compiletime error.
fn rfc6979_cases() []testcase = alloc([

	// Test vectors for P-256, from RFC 6979
	testcase {
		curve = tcurveid::P256,
		qpoint = p256q,
		x = p256x,
		hashf = hashf::SHA1,
		msg = "sample",
		k = "882905f1227fd620fbf2abf21244f0ba83d0dc3a9103dbbee43a1fb858109db4",
		sig = "61340c88c3aaebeb4f6d667f672ca9759a6ccaa9fa8811313039ee4a35471d32"
			"6d7f147dac089441bb2e2fe8f7a3fa264b9c475098fdcf6e00d7c996e1b8b7eb",
	},
	testcase {
		curve = tcurveid::P256,
		qpoint = p256q,
		x = p256x,
		hashf = hashf::SHA256,
		msg = "sample",
		k = "a6e3c57dd01abe90086538398355dd4c3b17aa873382b0f24d6129493d8aad60",
		sig = "efd48b2aacb6a8fd1140dd9cd45e81d69d2c877b56aaf991c34d0ea84eaf3716f7cb1c942d657c41d436c7a1b6e29f65f3e900dbb9aff4064dc4ab2f843acda8",
	},
	testcase {
		curve = tcurveid::P256,
		qpoint = p256q,
		x = p256x,
		hashf = hashf::SHA256,
		msg = "sample",
		k = "a6e3c57dd01abe90086538398355dd4c3b17aa873382b0f24d6129493d8aad60",
		sig = "efd48b2aacb6a8fd1140dd9cd45e81d69d2c877b56aaf991c34d0ea84eaf3716f7cb1c942d657c41d436c7a1b6e29f65f3e900dbb9aff4064dc4ab2f843acda8",
	},
	testcase {
		curve = tcurveid::P256,
		qpoint = p256q,
		x = p256x,
		hashf = hashf::SHA384,
		msg = "sample",
		k = "09f634b188cefd98e7ec88b1aa9852d734d0bc272f7d2a47decc6ebeb375aad4",
		sig = "0eafea039b20e9b42309fb1d89e213057cbf973dc0cfc8f129edddc800ef77194861f0491e6998b9455193e34e7b0d284ddd7149a74b95b9261f13abde940954",
	},
	testcase {
		curve = tcurveid::P256,
		qpoint = p256q,
		x = p256x,
		hashf = hashf::SHA512,
		msg = "sample",
		k = "5fa81c63109badb88c1f367b47da606da28cad69aa22c4fe6ad7df73a7173aa5",
		sig = "8496a60b5e9b47c825488827e0495b0e3fa109ec4568fd3f8d1097678eb97f002362ab1adbe2b8adf9cb9edab740ea6049c028114f2460f96554f61fae3302fe",
	},
	testcase {
		curve = tcurveid::P256,
		qpoint = p256q,
		x = p256x,
		hashf = hashf::SHA1,
		msg = "test",
		k = "8c9520267c55d6b980df741e56b4adee114d84fbfa2e62137954164028632a2e",
		sig = "0cbcc86fd6abd1d99e703e1ec50069ee5c0b4ba4b9ac60e409e8ec5910d81a8901b9d7b73dfaa60d5651ec4591a0136f87653e0fd780c3b1bc872ffdeae479b1",
	},
	testcase {
		curve = tcurveid::P256,
		qpoint = p256q,
		x = p256x,
		hashf = hashf::SHA256,
		msg = "test",
		k = "d16b6ae827f17175e040871a1c7ec3500192c4c92677336ec2537acaee0008e0",
		sig = "f1abb023518351cd71d881567b1ea663ed3efcf6c5132b354f28d3b0b7d38367019f4113742a2b14bd25926b49c649155f267e60d3814b4c0cc84250e46f0083",
	},
	testcase {
		curve = tcurveid::P256,
		qpoint = p256q,
		x = p256x,
		hashf = hashf::SHA384,
		msg = "test",
		k = "16aeffa357260b04b1dd199693960740066c1a8f3e8edd79070aa914d361b3b8",
		sig = "83910e8b48bb0c74244ebdf7f07a1c5413d61472bd941ef3920e623fbccebeb68ddbec54cf8cd5874883841d712142a56a8d0f218f5003cb0296b6b509619f2c",
	},
	testcase {
		curve = tcurveid::P256,
		qpoint = p256q,
		x = p256x,
		hashf = hashf::SHA512,
		msg = "test",
		k = "6915d11632aca3c40d5d51c08daf9c555933819548784480e93499000d9f0b7f",
		sig = "461d93f31b6540894788fd206c07cfa0cc35f46fa3c91816fff1040ad1581a0439af9f15de0db8d97e72719c74820d304ce5226e32dedae67519e840d1194e55",
	},

	// Test vectors for P-384, from RFC 6979.
	testcase {
		curve = tcurveid::P384,
		qpoint = p384q,
		x = p384x,
		hashf = hashf::SHA1,
		msg = "sample",
		k = "4471ef7518bb2c7c20f62eae1c387ad0c5e8e470995db4acf694466e6ab096630f29e5938d25106c3c340045a2db01a7",
		sig = "ec748d839243d6fbef4fc5c4859a7dffd7f3abddf72014540c16d73309834fa37b9ba002899f6fda3a4a9386790d4eb2a3bcfa947beef4732bf247ac17f71676cb31a847b9ff0cbc9c9ed4c1a5b3facf26f49ca031d4857570ccb5ca4424a443",
	},

	testcase {
		curve = tcurveid::P384,
		qpoint = p384q,
		x = p384x,
		hashf = hashf::SHA256,
		msg = "sample",
		k = "180ae9f9aec5438a44bc159a1fcb277c7be54fa20e7cf404b490650a8acc414e375572342863c899f9f2edf9747a9b60",
		sig = "21b13d1e013c7fa1392d03c5f99af8b30c570c6f98d4ea8e354b63a21d3daa33bde1e888e63355d92fa2b3c36d8fb2cdf3aa443fb107745bf4bd77cb3891674632068a10ca67e3d45db2266fa7d1feebefdc63eccd1ac42ec0cb8668a4fa0ab0",
	},
	testcase {
		curve = tcurveid::P384,
		qpoint = p384q,
		x = p384x,
		hashf = hashf::SHA384,
		msg = "sample",
		k = "94ed910d1a099dad3254e9242ae85abde4ba15168eaf0ca87a555fd56d10fbca2907e3e83ba95368623b8c4686915cf9",
		sig = "94edbb92a5ecb8aad4736e56c691916b3f88140666ce9fa73d64c4ea95ad133c81a648152e44acf96e36dd1e80fabe4699ef4aeb15f178cea1fe40db2603138f130e740a19624526203b6351d0a3a94fa329c145786e679e7b82c71a38628ac8",
	},
	testcase {
		curve = tcurveid::P384,
		qpoint = p384q,
		x = p384x,
		hashf = hashf::SHA512,
		msg = "sample",
		k = "92fc3c7183a883e24216d1141f1a8976c5b0dd797dfa597e3d7b32198bd35331a4e966532593a52980d0e3aaa5e10ec3",
		sig = "ed0959d5880ab2d869ae7f6c2915c6d60f96507f9cb3e047c0046861da4a799cfe30f35cc900056d7c99cd7882433709512c8cceee3890a84058ce1e22dbc2198f42323ce8aca9135329f03c068e5112dc7cc3ef3446defceb01a45c2667fdd5",
	},
	testcase {
		curve = tcurveid::P384,
		qpoint = p384q,
		x = p384x,
		hashf = hashf::SHA1,
		msg = "test",
		k = "66cc2c8f4d303fc962e5ff6a27bd79f84ec812ddae58cf5243b64a4ad8094d47ec3727f3a3c186c15054492e30698497",
		sig = "4bc35d3a50ef4e30576f58cd96ce6bf638025ee624004a1f7789a8b8e43d0678acd9d29876daf46638645f7f404b11c7d5a6326c494ed3ff614703878961c0fde7b2c278f9a65fd8c4b7186201a2991695ba1c84541327e966fa7b50f7382282",
	},
	testcase {
		curve = tcurveid::P384,
		qpoint = p384q,
		x = p384x,
		hashf = hashf::SHA256,
		msg = "test",
		k = "0cfac37587532347dc3389fdc98286bba8c73807285b184c83e62e26c401c0faa48dd070ba79921a3457abff2d630ad7",
		sig = "6d6defac9ab64dabafe36c6bf510352a4cc27001263638e5b16d9bb51d451559f918eedaf2293be5b475cc8f0188636b2d46f3becbcc523d5f1a1256bf0c9b024d879ba9e838144c8ba6baeb4b53b47d51ab373f9845c0514eefb14024787265",
	},
	testcase {
		curve = tcurveid::P384,
		qpoint = p384q,
		x = p384x,
		hashf = hashf::SHA384,
		msg = "test",
		k = "015ee46a5bf88773ed9123a5ab0807962d193719503c527b031b4c2d225092ada71f4a459bc0da98adb95837db8312ea",
		sig = "8203b63d3c853e8d77227fb377bcf7b7b772e97892a80f36ab775d509d7a5feb0542a7f0812998da8f1dd3ca3cf023dbddd0760448d42d8a43af45af836fce4de8be06b485e9b61b827c2f13173923e06a739f040649a667bf3b828246baa5a5",
	},
	testcase {
		curve = tcurveid::P384,
		qpoint = p384q,
		x = p384x,
		hashf = hashf::SHA512,
		msg = "test",
		k = "3780c4f67cb15518b6acae34c9f83568d2e12e47deab6c50a4e4ee5319d1e8ce0e2cc8a136036dc4b9c00e6888f66b6c",
		sig = "a0d5d090c9980faf3c2ce57b7ae951d31977dd11c775d314af55f76c676447d06fb6495cd21b4b6e340fc236584fb277976984e59b4c77b0e8e4460dca3d9f20e07b9bb1f63beefaf576f6b2e8b224634a2092cd3792e0159ad9cee37659c736",
	},
	// Test vectors for P-521, from RFC 6979. */
	testcase {
		curve = tcurveid::P521,
		qpoint = p521q,
		x = p521x,
		hashf = hashf::SHA1,
		msg = "sample",
		k = "0089c071b419e1c2820962321787258469511958e80582e95d8378e0c2ccdb3cb42bede42f50e3fa3c71f5a76724281d31d9c89f0f91fc1be4918db1c03a5838d0f9",
		sig = "00343b6ec45728975ea5cba6659bbb6062a5ff89eea58be3c80b619f322c87910fe092f7d45bb0f8eee01ed3f20babec079d202ae677b243ab40b5431d497c55d75d00e7b0e675a9b24413d448b8cc119d2bf7b2d2df032741c096634d6d65d0dbe3d5694625fb9e8104d3b842c1b0e2d0b98bea19341e8676aef66ae4eba3d5475d5d16",
	},
	testcase {
		curve = tcurveid::P521,
		qpoint = p521q,
		x = p521x,
		hashf = hashf::SHA256,
		msg = "sample",
		k = "00edf38afcaaecab4383358b34d67c9f2216c8382aaea44a3dad5fdc9c32575761793fef24eb0fc276dfc4f6e3ec476752f043cf01415387470bcbd8678ed2c7e1a0",
		sig = "01511bb4d675114fe266fc4372b87682baecc01d3cc62cf2303c92b3526012659d16876e25c7c1e57648f23b73564d67f61c6f14d527d54972810421e7d87589e1a7004a171143a83163d6df460aaf61522695f207a58b95c0644d87e52aa1a347916e4f7a72930b1bc06dbe22ce3f58264afd23704cbb63b29b931f7de6c9d949a7ecfc",
	},
	testcase {
		curve = tcurveid::P521,
		qpoint = p521q,
		x = p521x,
		hashf = hashf::SHA384,
		msg = "sample",
		k = "01546a108bc23a15d6f21872f7ded661fa8431ddbd922d0dcdb77cc878c8553ffad064c95a920a750ac9137e527390d2d92f153e66196966ea554d9adfcb109c4211",
		sig = "01ea842a0e17d2de4f92c15315c63ddf72685c18195c2bb95e572b9c5136ca4b4b576ad712a52be9730627d16054ba40cc0b8d3ff035b12ae75168397f5d50c6745101f21a3cee066e1961025fb048bd5fe2b7924d0cd797babe0a83b66f1e35eeaf5fde143fa85dc394a7dee766523393784484bdf3e00114a1c857cde1aa203db65d61",
	},
	testcase {
		curve = tcurveid::P521,
		qpoint = p521q,
		x = p521x,
		hashf = hashf::SHA512,
		msg = "sample",
		k = "01dae2ea071f8110dc26882d4d5eae0621a3256fc8847fb9022e2b7d28e6f10198b1574fdd03a9053c08a1854a168aa5a57470ec97dd5ce090124ef52a2f7ecbffd3",
		sig = "00c328fafcbd79dd77850370c46325d987cb525569fb63c5d3bc53950e6d4c5f174e25a1ee9017b5d450606add152b534931d7d4e8455cc91f9b15bf05ec36e377fa00617cce7cf5064806c467f678d3b4080d6f1cc50af26ca209417308281b68af282623eaa63e5b5c0723d8b8c37ff0777b1a20f8ccb1dccc43997f1ee0e44da4a67a",
	},
	testcase {
		curve = tcurveid::P521,
		qpoint = p521q,
		x = p521x,
		hashf = hashf::SHA1,
		msg = "test",
		k = "00bb9f2bf4fe1038ccf4dabd7139a56f6fd8bb1386561bd3c6a4fc818b20df5ddba80795a947107a1ab9d12daa615b1ade4f7a9dc05e8e6311150f47f5c57ce8b222",
		sig = "013bad9f29abe20de37ebeb823c252ca0f63361284015a3bf430a46aaa80b87b0693f0694bd88afe4e661fc33b094cd3b7963bed5a727ed8bd6a3a202abe009d036701e9bb81ff7944ca409ad138dbbee228e1afcc0c890fc78ec8604639cb0dbdc90f717a99ead9d272855d00162ee9527567dd6a92cbd629805c0445282bbc916797ff",
	},
	testcase {
		curve = tcurveid::P521,
		qpoint = p521q,
		x = p521x,
		hashf = hashf::SHA256,
		msg = "test",
		k = "001de74955efaabc4c4f17f8e84d881d1310b5392d7700275f82f145c61e843841af09035bf7a6210f5a431a6a9e81c9323354a9e69135d44ebd2fcaa7731b909258",
		sig = "000e871c4a14f993c6c7369501900c4bc1e9c7b0b4ba44e04868b30b41d8071042eb28c4c250411d0ce08cd197e4188ea4876f279f90b3d8d74a3c76e6f1e4656aa800cd52dbaa33b063c3a6cd8058a1fb0a46a4754b034fcc644766ca14da8ca5ca9fde00e88c1ad60ccba759025299079d7a427ec3cc5b619bfbc828e7769bcd694e86",
	},
	testcase {
		curve = tcurveid::P521,
		qpoint = p521q,
		x = p521x,
		hashf = hashf::SHA384,
		msg = "test",
		k = "01f1fc4a349a7da9a9e116bfdd055dc08e78252ff8e23ac276ac88b1770ae0b5dceb1ed14a4916b769a523ce1e90ba22846af11df8b300c38818f713dadd85de0c88",
		sig = "014bee21a18b6d8b3c93fab08d43e739707953244fdbe924fa926d76669e7ac8c89df62ed8975c2d8397a65a49dcc09f6b0ac62272741924d479354d74ff6075578c0133330865c067a0eaf72362a65e2d7bc4e461e8c8995c3b6226a21bd1aa78f0ed94fe536a0dca35534f0cd1510c41525d163fe9d74d134881e35141ed5e8e95b979",
	},
	testcase {
		curve = tcurveid::P521,
		qpoint = p521q,
		x = p521x,
		hashf = hashf::SHA512,
		msg = "test",
		k = "016200813020ec986863bedfc1b121f605c1215645018aea1a7b215a564de9eb1b38a67aa1128b80ce391c4fb71187654aaa3431027bfc7f395766ca988c964dc56d",
		sig = "013e99020abf5cee7525d16b69b229652ab6bdf2affcaef38773b4b7d08725f10cdb93482fdcc54edcee91eca4166b2a7c6265ef0ce2bd7051b7cef945babd47ee6d01fbd0013c674aa79cb39849527916ce301c66ea7ce8b80682786ad60f98f7e78a19ca69eff5c57400e3b3a0ad66ce0978214d13baf4e9ac60752f7b155e2de4dce3",
	},
]);

@test fn ecdsa_rfc6979() void = {
	test::require("slow");

	let sigbuf: [MAX_SIGSZ]u8 = [0...];
	let sumbuf: [sha512::SZ]u8 = [0...];
	let hashbuf: [sha512::SZ * 2 + sha512::BLOCKSZ]u8 = [0...];
	let cases = rfc6979_cases();
	defer free(cases);

	for (let tc &.. cases) {
		let h: *hash::hash = switch (tc.hashf) {
		case hashf::SHA1 =>
			yield &sha1::sha1();
		case hashf::SHA224 =>
			abort("not implemented");
		case hashf::SHA256 =>
			yield &sha256::sha256();
		case hashf::SHA384 =>
			yield &sha512::sha384();
		case hashf::SHA512 =>
			yield &sha512::sha512();
		case =>
			abort();
		};

		let pub: *pubkey = switch (tc.curve) {
		case tcurveid::P256 =>
			yield &p256pub();
		case tcurveid::P384 =>
			yield &p384pub();
		case tcurveid::P521 =>
			yield &p521pub();
		case =>
			abort();
		};

		pubkey_buf(pub)[..] = tc.qpoint[..];

		let sum = sumbuf[..hash::sz(h)];
		io::writeall(h, strings::toutf8(tc.msg))!;
		hash::sum(h, sum);

		let sig = hex::decodestr(tc.sig)!;
		defer free(sig);

		sigbuf[..len(sig)] = sig[..];

		assert(verify(pub, sum, sigbuf[..len(sig)]) == 1);
		let priv: *privkey = switch (tc.curve) {
		case tcurveid::P256 =>
			yield &p256priv();
		case tcurveid::P384 =>
			yield &p384priv();
		case tcurveid::P521 =>
			yield &p521priv();
		case =>
			abort();
		};

		privkey_buf(priv)[..] = tc.x[..];

		const n = sign(priv, sum, h, hashbuf, sigbuf);
		assert(n == sigsz(pub));
		assert(bytes::equal(sigbuf[..n], sig));
	};
};
