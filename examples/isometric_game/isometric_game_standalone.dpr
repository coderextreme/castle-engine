{ AUTO-GENERATED PROGRAM FILE.

  This file is used to build and run the application on desktop (standalone) platforms,
  from various tools:
  - Castle Game Engine command-line build tool
  - Castle Game Engine editor
  - Lazarus IDE
  - Delphi IDE

  You should not modify this file manually.
  Regenerate it using CGE editor "Code -> Regenerate Program" menu item
  or the command-line: "castle-engine generate-program".
  Along with this file, we also generate CastleAutoGenerated unit. }

{ Do not specify program name below.
  It is not used anyway, and this way allows developer
  to change standalone_source in CastleEngineManifest.xml easier. }
// program isometric_game_standalone;

{$ifdef MSWINDOWS} {$apptype GUI} {$endif}

{ This adds icons and version info for Windows,
  automatically created by "castle-engine compile". }
{$ifdef CASTLE_AUTO_GENERATED_RESOURCES} {$R castle-auto-generated-resources.res} {$endif}

uses
  {$if defined(FPC) and (not defined(CASTLE_DISABLE_THREADS))}
    {$info Thread support enabled.}
    {$ifdef UNIX} CThreads, {$endif}
  {$endif}
  CastleAutoGenerated, CastleWindow, GameInitialize;

{ Forces using a dedicated (faster) GPU on laptops with multiple GPUs.
  See https://castle-engine.io/dedicated_gpu }
{$if (not defined(CASTLE_NO_FORCE_DEDICATED_GPU)) and (defined(cpu386) or defined(cpux64) or defined(cpuamd64)) and (defined(MSWINDOWS) or defined(Linux))}
    {$ifdef fpc}
     {$asmmode intel}
    {$endif}

    procedure NvOptimusEnablement; {$ifdef fpc}assembler; nostackframe;{$endif}
    asm
    {$ifdef cpu64}
    {$ifndef fpc}
     .NOFRAME
    {$endif}
    {$endif}
     dd 1
    end;

    procedure AmdPowerXpressRequestHighPerformance; {$ifdef fpc}assembler; nostackframe;{$endif}
    asm
    {$ifdef cpu64}
    {$ifndef fpc}
     .NOFRAME
    {$endif}
    {$endif}
     dd 1
    end;

    exports
      NvOptimusEnablement,
      AmdPowerXpressRequestHighPerformance;
{$ifend}

begin
  Application.MainWindow.OpenAndRun;
end.
