use net::dns;
use net::ip;

// Performs DNS resolution on a given address string for a given service,
// including /etc/hosts lookup and SRV resolution, and returns a list of
// candidate IP addresses and the appropriate port, or an error.
export fn resolve(addr: str, service: str) (([]ip::addr, u16) | dns::error) = {
	abort(); // TODO
};
