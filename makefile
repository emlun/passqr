DESTDIR=

default:
	@echo "Nothing to compile - nothing to do! :D"

install:
	@install -Dv -m 755 passqr.sh "${DESTDIR}/usr/bin/passqr"
	@install -Dv -m 644 passqr.bash-completion "${DESTDIR}/etc/bash_completion.d/password-store-qr"
	@install -Dv -m 644 passqr.conf "${DESTDIR}/etc/passqr.conf"
	@install -Dv -m 644 passqr.1 "${DESTDIR}/usr/share/man/man1/passqr.1"

uninstall:
	@rm -fv "${DESTDIR}/usr/bin/passqr"
	@rm -fv "${DESTDIR}/etc/bash_completion.d/password-store-qr"
	@rm -fv "${DESTDIR}/etc/passqr.conf"
	@rm -fv "${DESTDIR}/usr/share/man/man1/passqr.1"
