{ lib
, fetchurl
, fetchpatch
, nixosTests
, python3
, ghostscript
, imagemagick
, jbig2enc
, optipng
, pngquant
, qpdf
, tesseract4
, unpaper
, liberation_ttf
}:

let
  py = python3.override {
    packageOverrides = self: super: {
      django = super.django_3;

      # Incompatible with aioredis 2
      aioredis = super.aioredis.overridePythonAttrs (oldAttrs: rec {
        version = "1.3.1";
        src = oldAttrs.src.override {
          inherit version;
          sha256 = "0fi7jd5hlx8cnv1m97kv9hc4ih4l8v15wzkqwsp73is4n0qazy0m";
        };
      });
    };
  };

  path = lib.makeBinPath [ ghostscript imagemagick jbig2enc optipng pngquant qpdf tesseract4 unpaper ];
in
py.pkgs.pythonPackages.buildPythonApplication rec {
  pname = "paperless-ngx";
  version = "1.6.0";

  src = fetchurl {
    url = "https://github.com/paperless-ngx/paperless-ngx/releases/download/ngx-${version}/${pname}-${version}.tar.xz";
    sha256 = "07mrxbwahkm00n9nvssd6d13p80w333g84cd38bzp0l34nzim5zl";
  };

  format = "other";

  propagatedBuildInputs = with py.pkgs.pythonPackages; [
    aioredis
    arrow
    asgiref
    async-timeout
    attrs
    autobahn
    automat
    blessed
    certifi
    cffi
    channels-redis
    channels
    chardet
    click
    coloredlogs
    concurrent-log-handler
    constantly
    cryptography
    daphne
    dateparser
    django-cors-headers
    django-extensions
    django-filter
    django-picklefield
    django-q
    django
    djangorestframework
    filelock
    fuzzywuzzy
    gunicorn
    h11
    hiredis
    httptools
    humanfriendly
    hyperlink
    idna
    imap-tools
    img2pdf
    incremental
    inotify-simple
    inotifyrecursive
    joblib
    langdetect
    lxml
    msgpack
    numpy
    ocrmypdf
    pathvalidate
    pdfminer-six
    pikepdf
    pillow
    pluggy
    portalocker
    psycopg2
    pyasn1-modules
    pyasn1
    pycparser
    pyopenssl
    python-dateutil
    python-dotenv
    python-gnupg
    python-Levenshtein
    python-magic
    pytz
    pyyaml
    redis
    regex
    reportlab
    requests
    scikit-learn
    scipy
    service-identity
    six
    sortedcontainers
    sqlparse
    threadpoolctl
    tika
    tqdm
    twisted.optional-dependencies.tls
    txaio
    tzlocal
    urllib3
    uvicorn
    uvloop
    watchdog
    watchgod
    wcwidth
    websockets
    whitenoise
    whoosh
    zope_interface
  ];

  # Compile manually because `pythonRecompileBytecodeHook` only works for
  # files in `python.sitePackages`
  postBuild = ''
    ${py.interpreter} -OO -m compileall src
  '';

  installPhase = ''
    mkdir -p $out/lib
    cp -r . $out/lib/paperless-ngx
    chmod +x $out/lib/paperless-ngx/src/manage.py
    makeWrapper $out/lib/paperless-ngx/src/manage.py $out/bin/paperless-ngx \
      --prefix PYTHONPATH : "$PYTHONPATH" \
      --prefix PATH : "${path}"
  '';

  checkInputs = with py.pkgs.pythonPackages; [
    pytest-django
    pytest-env
    pytest-sugar
    pytest-xdist
    factory_boy
    pytestCheckHook
  ];

  pytestFlagsArray = [ "src" ];

  # The tests require:
  # - PATH with runtime binaries
  # - A temporary HOME directory for gnupg
  # - XDG_DATA_DIRS with test-specific fonts
  preCheck = ''
    export PATH="${path}:$PATH"
    export HOME=$(mktemp -d)
    export XDG_DATA_DIRS="${liberation_ttf}/share:$XDG_DATA_DIRS"

    # Disable unneeded code coverage test
    substituteInPlace src/setup.cfg \
      --replace "--cov --cov-report=html" ""
  '';

  passthru = {
    # PYTHONPATH of all dependencies used by the package
    pythonPath = python3.pkgs.makePythonPath propagatedBuildInputs;
    inherit path;

    tests = { inherit (nixosTests) paperless; };
  };

  meta = with lib; {
    description = "A supercharged version of paperless: scan, index, and archive all of your physical documents";
    homepage = "https://paperless-ngx.readthedocs.io/en/latest/";
    license = licenses.gpl3Only;
    maintainers = with maintainers; [ lukegb ];
  };
}
