DESTDIR=

default:
	echo "Nothing to compile - nothing to do! :D"

install:
	@install -Dv -m 755 passqr.sh "${DESTDIR}/usr/bin/passqr"
	@install -Dv -m 644 passqr.bash-completion "${DESTDIR}/etc/bash_completion.d/password-store-qr"
