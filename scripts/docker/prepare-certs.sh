#!/bin/sh
# Export TLS inspection CA certificates for Docker builds.
# Required when go mod download fails with x509: certificate signed by unknown authority
# (e.g. behind Cloudflare Gateway, Zscaler, or other TLS-inspecting proxies).

set -e

CERT_DIR="$(cd "$(dirname "$0")/../../build/certs" && pwd)"
mkdir -p "$CERT_DIR"

export_macos_gateway_ca() {
	name="$1"
	outfile="$CERT_DIR/$2"
	if security find-certificate -a -p -c "$name" /Library/Keychains/System.keychain 2>/dev/null \
		| openssl x509 -outform PEM > "$outfile" 2>/dev/null; then
		echo "Exported $outfile"
	fi
}

case "$(uname -s)" in
Darwin)
	export_macos_gateway_ca \
		"Gateway CA - Cloudflare Managed G2 c1b48542cf403275c80745c42d11e580" \
		"cloudflare-gateway-ca.crt"
	;;
Linux)
	if [ -d /etc/ssl/certs ]; then
		cp /etc/ssl/certs/ca-certificates.crt "$CERT_DIR/host-ca-bundle.crt" 2>/dev/null \
			|| cp /etc/pki/tls/certs/ca-bundle.crt "$CERT_DIR/host-ca-bundle.crt" 2>/dev/null \
			|| true
	fi
	;;
esac

if ! ls "$CERT_DIR"/*.crt >/dev/null 2>&1; then
	echo "No extra CA certificates exported to $CERT_DIR" >&2
	exit 1
fi
