{
  lib,
  python3,
  installShellFiles,
  swappy,
  libnotify,
  slurp,
  wl-clipboard,
  cliphist,
  xdg-utils,
  dart-sass,
  grim,
  fuzzel,
  gpu-screen-recorder,
  ffmpeg,
  dconf,
  killall,
  caelestia-shell ? null,
  withShell ? false,
  discordBin ? "discord",
  qtctStyle ? "Darkly",
}:
python3.pkgs.buildPythonApplication {
  pname = "orangeos-cli";
  version = "1.0.0";
  src = ./.;
  pyproject = true;

  build-system = [python3.pkgs.hatchling];

  dependencies = with python3.pkgs; [
    materialyoucolor
    pillow
  ];

  pythonImportsCheck = ["caelestia"];

  nativeBuildInputs = [installShellFiles];
  propagatedBuildInputs =
    [
      swappy
      libnotify
      slurp
      wl-clipboard
      cliphist
      xdg-utils
      dart-sass
      grim
      fuzzel
      gpu-screen-recorder
      ffmpeg
      dconf
      killall
    ]
    ++ lib.optionals (withShell && caelestia-shell != null) [caelestia-shell];

  # The Python module name stays `caelestia` for compatibility with the shell;
  # only the installed command is renamed to `orangeos`.
  patchPhase = lib.optionalString (withShell && caelestia-shell != null) ''
    substituteInPlace src/caelestia/subcommands/shell.py \
    	--replace-fail '"qs", "-c", "caelestia"' '"caelestia-shell"'
    substituteInPlace src/caelestia/subcommands/screenshot.py \
    	--replace-fail '"qs", "-c", "caelestia"' '"caelestia-shell"'

    substituteInPlace src/caelestia/subcommands/toggle.py \
    	--replace-fail 'discord' ${discordBin} \
      --replace-fail '["todoist"]' '["todoist.desktop"]'

    substituteInPlace src/caelestia/data/templates/qtengine.json \
    	--replace-fail 'Darkly' '${qtctStyle}'
  '';

  postInstall = "installShellCompletion completions/orangeos.fish";

  meta = {
    description = "The main control script for Orange OS (vendored Caelestia CLI)";
    homepage = "https://github.com/srivastava-ayush/OrangeDots";
    license = lib.licenses.gpl3Only;
    mainProgram = "orangeos";
    platforms = lib.platforms.linux;
  };
}
