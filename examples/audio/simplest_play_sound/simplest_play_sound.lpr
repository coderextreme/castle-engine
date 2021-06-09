{
  Copyright 2003-2018 Michalis Kamburelis.

  This file is part of "Castle Game Engine".

  "Castle Game Engine" is free software; see the file COPYING.txt,
  included in this distribution, for details about the copyright.

  "Castle Game Engine" is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

  ----------------------------------------------------------------------------
}

{ Simply load and play sound using CastleSoundEngine. }
program simplest_play_sound;

uses
  {$ifndef CASTLE_DISABLE_THREADS}
    {$info Thread support enabled.}
    {$ifdef UNIX} CThreads, {$endif}
  {$endif}
  SysUtils,
  CastleUtils, CastleLog, CastleSoundEngine, CastleParameters, CastleTimeUtils,
  CastleVectors, CastleApplicationProperties;

var
  URL: string;
  Sound: TCastleSound;
begin
  ApplicationProperties.OnWarning.Add(@ApplicationProperties.WriteWarningOnConsole);

  // put in log various info about sound loading
  InitializeLog;
  SoundEngine.LogSoundLoading := true;

  { parse params }
  SoundEngine.ParseParameters;
  Parameters.CheckHighAtMost(1);
  if Parameters.High = 1 then
    URL := Parameters[1]
  else
    URL := 'castle-data:/temple-adam-goh.ogg';
    //'castle-data:/tone.wav';

  { Sound backend (like OpenAL) will be automatically initialized when needed below.
    Although you could also initialize it explicitly by SoundEngine.ContextOpen,
    check SoundEngine.Information, SoundEngine.IsContextOpenSuccess etc. }

  { Load and play sound, without any spatialization. }
  Sound := TCastleSound.Create(nil);
  try
    Sound.Spatial := false;
    Sound.URL := URL;
    Writeln('Sound loaded, duration in seconds: ', Sound.Duration:1:2);
    SoundEngine.Play(Sound);

    { Wait enough time to finish playing.
      In this simple program, we just sleep enough time
      to finish playing sound, with some margin.

      Alternative, more precise way to do this would be to query is sound playing.
      TODO: For now, to do this you'd need to use deprecatd Sound.PlaySound,
      get the resulting TInternalSoundSource,
      and register callback on TInternalSoundSource.OnRelease. }
    Sleep(Round(Sound.Duration * 1000) + 500);
  finally
    FreeAndNil(Sound);
  end;
end.
