Info-ZIP builds for Windows
===========================

Why?
----

There is no shortage of ZIP archivers out there, but none seem to be able to repack
Firefox's ``omni.ja``. Instructions__ are provided only for Info-ZIP's ``zip``:

.. __: http://www.devdoc.net/web/developer.mozilla.org/en-US/docs/About_omni.jar.html

::

    zip -qr9XD omni.ja *

``-XD`` is necessary for the creation of ``omni.ja``-like archives:

-X  Do not save extra file attributes.
-D  Do not create entries in the zip archive for directories.

Official builds at ftp://ftp.info-zip.org/pub/infozip/win32/ date back to 2008/2009 (x86/x64),
and do not include security patches that modern Linux builds have.

Also there are no official ARM64 builds. (Please note, however, that ARM64 builds provided here
are completely untested.)

Applied Patches
---------------

The following Fedora patches are downloaded along with Info-ZIP sources
(other Fedora patches are not relevant on Windows):

- `zip-3.0-currdir.patch`__

   .. __: https://src.fedoraproject.org/rpms/zip/blob/rawhide/f/zip-3.0-currdir.patch

- `zip-3.0-format-security.patch`__

  .. __: https://src.fedoraproject.org/rpms/zip/blob/rawhide/f/zip-3.0-format-security.patch

- `zipnote.patch`__

   .. __: https://src.fedoraproject.org/rpms/zip/blob/rawhide/f/zipnote.patch

Additional Windows-specific patches can be found in the `<patches>`_ directory:

- `no-compile-date.patch <patches/no-compile-date.patch>`_ is equivalent to Debian's
  `10-remove-build-date.patch`__, but patches Windows rather than Unix sources.

  .. __: https://sources.debian.org/patches/zip/3.0-12/10-remove-build-date.patch/

- `no-win98.patch <patches/no-win98.patch>`_ and `rename-cr.patch <patches/rename-cr.patch>`_
  fix compilation errors on Windows.

- Info-ZIP's x64 makefile ``makefile.a64`` mentions neither large file support nor a resource file.
  To fix this, `x64-makefile.patch <patches/x64-makefile.patch>`_ moves x64 assembly stuff
  to ``makefile.w32``, turning it into a universal makefile that can be used
  to build x86, x64 or ARM64 targets.
