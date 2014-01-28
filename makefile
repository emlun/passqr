DESTDIR=
PKGNAME=passqr

default:
	echo "Nothing to compile - nothing to do! :D"

install:
	install -D -m 755 passqr.sh "${DESTDIR}/usr/bin/passqr"
	install -D -m 644 passqr.bash-completion "${DESTDIR}/etc/bash_completion.d/password-store-qr"
