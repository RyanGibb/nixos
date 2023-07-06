# https://gitlab.com/coffeetables/nix-matrix-appservices/-/blob/main/pkgs/mautrix-instagram/default.nix
{ stdenv
, lib
, python3
, makeWrapper
, fetchFromGitHub
}:

with python3.pkgs;

let
  # officially supported database drivers
  dbDrivers = [
    asyncpg
    # sqlite driver is already shipped with python by default
  ];

in

buildPythonApplication rec {
  pname = "mautrix-instagram";
  version = "unstable-2021-11-15";

  src = fetchFromGitHub {
    owner = "tulir";
    repo = pname;
    rev = "4863587bcfd3a70779f25f60fd75f442aff9d967";
    sha256 = "sha256-b8xuYVc2LwVsbeN/59pICINzIUzXic4KZmKm5lKJBy0=";
  };

  postPatch = ''
    sed -i -e '/alembic>/d' requirements.txt
  '';
  postFixup = ''
    makeWrapper ${python}/bin/python $out/bin/mautrix-instagram \
      --add-flags "-m mautrix_instagram" \
      --prefix PYTHONPATH : "$(toPythonPath ${mautrix}):$(toPythonPath $out):$PYTHONPATH"
  '';

  propagatedBuildInputs = [
    mautrix
    yarl
    aiohttp
    aiosqlite
    beautifulsoup4
    sqlalchemy
    CommonMark
    ruamel_yaml
    paho-mqtt
    python_magic
    attrs
    pillow
    qrcode
    phonenumbers
    pycryptodome
    python-olm
    unpaddedbase64
    setuptools
  ] ++ dbDrivers;

  checkInputs = [
    pytest
    pytestrunner
    pytest-mock
    pytest-asyncio
  ];

  doCheck = false;

  meta = with lib; {
    homepage = "https://github.com/tulir/mautrix-instagram";
    description = "A Matrix-Instagram DM puppeting bridge";
    license = licenses.agpl3Plus;
    platforms = platforms.linux;
  };
}
