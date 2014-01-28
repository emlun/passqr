passqr
======
Export QR codes from Jason A. Donenfeld's [`pass`][pass] utility

This is a simple shell script that makes it easy to export passwords stored in
Jason A. Donenfeld's `pass` utility as QR codes (2D barcodes). This makes it
easy to input them on mobile devices, for example.

[pass]: http://www.zx2c4.com/projects/password-store/

Building
--------

The project consists of only shell scripts, to there is nothing to compile!

Installation
------------

Clone the `master` branch of the repo and use `make`:

    # make install

This will install files into the following directories:

 - `/etc/bash_completion.d`
 - `/usr/bin`

Dependencies
------------

 - [libqrencode][libqrencode]: For encoding as QR code
 - [ImageMagick][imagemagick]: For displaying QR code image

[libqrencode]: http://fukuchi.org/works/qrencode/
[imagemagick]: http://imagemagick.org

Usage
-----

Invoke `passqr` with a `pass` entry as parameter:

    $ passqr Email/zx2c4.com

This will invoke `pass show Email/zx2c4.com`, encode the first line of the
output as a QR code and show the result on screen. The image will close
automatically after 3 seconds, this timeout can be set using the `-t|--timeout`
option.

License
-------

passqr is licensed under the [GNU General Public License][gpl-home], version 2
or later.

[gpl-home]: http://www.gnu.org/licenses/
