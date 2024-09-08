// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>
// This is an auto generated file. Do not edit.

use encoding::asn1;

const _db = asn1::oiddb {
	lut = [
		0x03, 0x2b, 0x65, 0x70, 0x09, 0x2a, 0x86, 0x48, 0x86, 0xf7, 0x0d, 0x01,
		0x01, 0x01, 0x09, 0x2a, 0x86, 0x48, 0x86, 0xf7, 0x0d, 0x01, 0x01, 0x05,
		0x09, 0x2a, 0x86, 0x48, 0x86, 0xf7, 0x0d, 0x01, 0x01, 0x08, 0x09, 0x2a,
		0x86, 0x48, 0x86, 0xf7, 0x0d, 0x01, 0x01, 0x0a, 0x09, 0x2a, 0x86, 0x48,
		0x86, 0xf7, 0x0d, 0x01, 0x01, 0x0e, 0x09, 0x2a, 0x86, 0x48, 0x86, 0xf7,
		0x0d, 0x01, 0x01, 0x0b, 0x09, 0x2a, 0x86, 0x48, 0x86, 0xf7, 0x0d, 0x01,
		0x01, 0x0c, 0x09, 0x2a, 0x86, 0x48, 0x86, 0xf7, 0x0d, 0x01, 0x01, 0x0d,
		0x05, 0x2b, 0x0e, 0x03, 0x02, 0x1a, 0x09, 0x60, 0x86, 0x48, 0x01, 0x65,
		0x03, 0x04, 0x02, 0x01, 0x09, 0x60, 0x86, 0x48, 0x01, 0x65, 0x03, 0x04,
		0x02, 0x02, 0x09, 0x60, 0x86, 0x48, 0x01, 0x65, 0x03, 0x04, 0x02, 0x03,
		0x09, 0x60, 0x86, 0x48, 0x01, 0x65, 0x03, 0x04, 0x02, 0x04, 0x07, 0x2a,
		0x86, 0x48, 0xce, 0x3d, 0x02, 0x01, 0x08, 0x2a, 0x86, 0x48, 0xce, 0x3d,
		0x03, 0x01, 0x07, 0x08, 0x2a, 0x86, 0x48, 0xce, 0x3d, 0x03, 0x01, 0x07,
		0x05, 0x2b, 0x81, 0x04, 0x00, 0x22, 0x05, 0x2b, 0x81, 0x04, 0x00, 0x23,
		0x07, 0x2a, 0x86, 0x48, 0xce, 0x3d, 0x04, 0x01, 0x08, 0x2a, 0x86, 0x48,
		0xce, 0x3d, 0x04, 0x03, 0x01, 0x08, 0x2a, 0x86, 0x48, 0xce, 0x3d, 0x04,
		0x03, 0x02, 0x08, 0x2a, 0x86, 0x48, 0xce, 0x3d, 0x04, 0x03, 0x03, 0x08,
		0x2a, 0x86, 0x48, 0xce, 0x3d, 0x04, 0x03, 0x04, 0x03, 0x55, 0x04, 0x03,
		0x03, 0x55, 0x04, 0x04, 0x03, 0x55, 0x04, 0x05, 0x03, 0x55, 0x04, 0x06,
		0x03, 0x55, 0x04, 0x07, 0x03, 0x55, 0x04, 0x08, 0x03, 0x55, 0x04, 0x0a,
		0x03, 0x55, 0x04, 0x0b, 0x03, 0x55, 0x04, 0x0c, 0x03, 0x55, 0x04, 0x2a,
		0x03, 0x55, 0x04, 0x2b, 0x03, 0x55, 0x04, 0x2b, 0x03, 0x55, 0x04, 0x2e,
		0x03, 0x55, 0x04, 0x41, 0x0a, 0x09, 0x92, 0x26, 0x89, 0x93, 0xf2, 0x2c,
		0x64, 0x01, 0x19, 0x03, 0x55, 0x1d, 0x0f, 0x03, 0x55, 0x1d, 0x11, 0x03,
		0x55, 0x1d, 0x13, 0x03, 0x55, 0x1d, 0x25,
	],
	index = [
		0x0000, 0x0004, 0x000e, 0x0018, 0x0022, 0x002c, 0x0036, 0x0040, 0x004a,
		0x0054, 0x005a, 0x0064, 0x006e, 0x0078, 0x0082, 0x008a, 0x0093, 0x009c,
		0x00a2, 0x00a8, 0x00b0, 0x00b9, 0x00c2, 0x00cb, 0x00d4, 0x00d8, 0x00dc,
		0x00e0, 0x00e4, 0x00e8, 0x00ec, 0x00f0, 0x00f4, 0x00f8, 0x00fc, 0x0100,
		0x0104, 0x0108, 0x010c, 0x0117, 0x011b, 0x011f, 0x0123,
	],
	names = [
		"ed25519",
		"rsaEncryption",
		"sha1WithRSAEncryption",
		"id-mgf1",
		"rsassa-pss",
		"sha224WithRSAEncryption",
		"sha256WithRSAEncryption",
		"sha384WithRSAEncryption",
		"sha512WithRSAEncryption",
		"id-sha1",
		"id-sha256",
		"id-sha384",
		"id-sha512",
		"id-sha224",
		"id-ecPublicKey",
		"prime256v1",
		"ansix9p256r1",
		"ansix9p384r1",
		"ansix9p521r1",
		"ecdsa-with-SHA1",
		"ecdsa-with-SHA224",
		"ecdsa-with-SHA256",
		"ecdsa-with-SHA384",
		"ecdsa-with-SHA512",
		"id-at-commonName",
		"id-at-surname",
		"id-at-serialNumber",
		"id-at-countryName",
		"id-at-localityName",
		"id-at-stateOrProvinceName",
		"id-at-organizationName",
		"id-at-organizationalUnitName",
		"id-at-title",
		"id-at-givenName",
		"id-at-initials",
		"id-at-generationQualifier",
		"id-at-dnQualifier",
		"id-at-pseudonym",
		"id-domainComponent",
		"id-ce-keyUsage",
		"id-ce-subjectAltName",
		"id-ce-basicConstraints",
		"id-ce-extKeyUsage",
	],
};

// Database
export const db = &_db;

// id:   1.3.101.112
// name: ed25519
export def ED25519: asn1::oid = 0;

// id:   1.2.840.113549.1.1.1
// name: rsaEncryption
export def RSA_ENCRYPTION: asn1::oid = 1;

// id:   1.2.840.113549.1.1.5
// name: sha1WithRSAEncryption
export def SHA1_WITH_RSAENCRYPTION: asn1::oid = 2;

// id:   1.2.840.113549.1.1.8
// name: id-mgf1
export def ID_MGF1: asn1::oid = 3;

// id:   1.2.840.113549.1.1.10
// name: rsassa-pss
export def RSASSA_PSS: asn1::oid = 4;

// id:   1.2.840.113549.1.1.14
// name: sha224WithRSAEncryption
export def SHA224_WITH_RSAENCRYPTION: asn1::oid = 5;

// id:   1.2.840.113549.1.1.11
// name: sha256WithRSAEncryption
export def SHA256_WITH_RSAENCRYPTION: asn1::oid = 6;

// id:   1.2.840.113549.1.1.12
// name: sha384WithRSAEncryption
export def SHA384_WITH_RSAENCRYPTION: asn1::oid = 7;

// id:   1.2.840.113549.1.1.13
// name: sha512WithRSAEncryption
export def SHA512_WITH_RSAENCRYPTION: asn1::oid = 8;

// id:   1.3.14.3.2.26
// name: id-sha1
export def ID_SHA1: asn1::oid = 9;

// id:   2.16.840.1.101.3.4.2.1
// name: id-sha256
export def ID_SHA256: asn1::oid = 10;

// id:   2.16.840.1.101.3.4.2.2
// name: id-sha384
export def ID_SHA384: asn1::oid = 11;

// id:   2.16.840.1.101.3.4.2.3
// name: id-sha512
export def ID_SHA512: asn1::oid = 12;

// id:   2.16.840.1.101.3.4.2.4
// name: id-sha224
export def ID_SHA224: asn1::oid = 13;

// id:   1.2.840.10045.2.1
// name: id-ecPublicKey
export def ID_EC_PUBLIC_KEY: asn1::oid = 14;

// id:   1.2.840.10045.3.1.7
// name: prime256v1
export def PRIME256V1: asn1::oid = 15;

// id:   1.2.840.10045.3.1.7
// name: ansix9p256r1
export def ANSIX9P256R1: asn1::oid = 16;

// id:   1.3.132.0.34
// name: ansix9p384r1
export def ANSIX9P384R1: asn1::oid = 17;

// id:   1.3.132.0.35
// name: ansix9p521r1
export def ANSIX9P521R1: asn1::oid = 18;

// id:   1.2.840.10045.4.1
// name: ecdsa-with-SHA1
export def ECDSA_WITH_SHA1: asn1::oid = 19;

// id:   1.2.840.10045.4.3.1
// name: ecdsa-with-SHA224
export def ECDSA_WITH_SHA224: asn1::oid = 20;

// id:   1.2.840.10045.4.3.2
// name: ecdsa-with-SHA256
export def ECDSA_WITH_SHA256: asn1::oid = 21;

// id:   1.2.840.10045.4.3.3
// name: ecdsa-with-SHA384
export def ECDSA_WITH_SHA384: asn1::oid = 22;

// id:   1.2.840.10045.4.3.4
// name: ecdsa-with-SHA512
export def ECDSA_WITH_SHA512: asn1::oid = 23;

// id:   2.5.4.3
// name: id-at-commonName
export def ID_AT_COMMON_NAME: asn1::oid = 24;

// id:   2.5.4.4
// name: id-at-surname
export def ID_AT_SURNAME: asn1::oid = 25;

// id:   2.5.4.5
// name: id-at-serialNumber
export def ID_AT_SERIAL_NUMBER: asn1::oid = 26;

// id:   2.5.4.6
// name: id-at-countryName
export def ID_AT_COUNTRY_NAME: asn1::oid = 27;

// id:   2.5.4.7
// name: id-at-localityName
export def ID_AT_LOCALITY_NAME: asn1::oid = 28;

// id:   2.5.4.8
// name: id-at-stateOrProvinceName
export def ID_AT_STATE_OR_PROVINCE_NAME: asn1::oid = 29;

// id:   2.5.4.10
// name: id-at-organizationName
export def ID_AT_ORGANIZATION_NAME: asn1::oid = 30;

// id:   2.5.4.11
// name: id-at-organizationalUnitName
export def ID_AT_ORGANIZATIONAL_UNIT_NAME: asn1::oid = 31;

// id:   2.5.4.12
// name: id-at-title
export def ID_AT_TITLE: asn1::oid = 32;

// id:   2.5.4.42
// name: id-at-givenName
export def ID_AT_GIVEN_NAME: asn1::oid = 33;

// id:   2.5.4.43
// name: id-at-initials
export def ID_AT_INITIALS: asn1::oid = 34;

// id:   2.5.4.43
// name: id-at-generationQualifier
export def ID_AT_GENERATION_QUALIFIER: asn1::oid = 35;

// id:   2.5.4.46
// name: id-at-dnQualifier
export def ID_AT_DN_QUALIFIER: asn1::oid = 36;

// id:   2.5.4.65
// name: id-at-pseudonym
export def ID_AT_PSEUDONYM: asn1::oid = 37;

// id:   0.9.2342.19200300.100.1.25
// name: id-domainComponent
export def ID_DOMAIN_COMPONENT: asn1::oid = 38;

// id:   2.5.29.15
// name: id-ce-keyUsage
export def ID_CE_KEY_USAGE: asn1::oid = 39;

// id:   2.5.29.17
// name: id-ce-subjectAltName
export def ID_CE_SUBJECT_ALT_NAME: asn1::oid = 40;

// id:   2.5.29.19
// name: id-ce-basicConstraints
export def ID_CE_BASIC_CONSTRAINTS: asn1::oid = 41;

// id:   2.5.29.37
// name: id-ce-extKeyUsage
export def ID_CE_EXT_KEY_USAGE: asn1::oid = 42;
