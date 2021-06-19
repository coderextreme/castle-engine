{ Auto-generated unit with information about the project.
  The information set here reflects the CastleEngineManifest.xml properties.

  You should not modify this file manually.
  Regenerate it using CGE editor "Regenerate Program" menu item
  (or command-line: "castle-engine generate-program").
  Along with this file, we also generate lpi and lpr files of the project. }
unit CastleAutoGenerated;

interface

implementation

uses CastleApplicationProperties, CastleWindow, CastleLog;

initialization
  ApplicationProperties.ApplicationName := 'creature_behaviors';
  ApplicationProperties.Caption := 'Creature Behaviors';
  ApplicationProperties.Version := '0.1';

  if not IsLibrary then
    Application.ParseStandardParameters;

  { Start logging.

    Should be done after setting ApplicationProperties.ApplicationName/Version,
    since they are recorded in the first automatic log messages.

    Should be done after basic command-line parameters are parsed
    for standalone programs (when "not IsLibrary").
    This allows to handle --version and --help command-line parameters
    without any extra output on Unix, and to set --log-file . }
  InitializeLog;
end.
