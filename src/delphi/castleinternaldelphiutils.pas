{
  Copyright 2022-2024 Michalis Kamburelis.

  This file is part of "Castle Game Engine".

  "Castle Game Engine" is free software; see the file COPYING.txt,
  included in this distribution, for details about the copyright.

  "Castle Game Engine" is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

  ----------------------------------------------------------------------------
}

{ Utilities for Delphi UI that works the same in VCL and FMX. }
unit CastleInternalDelphiUtils;

{$I castleconf.inc}

interface

uses UITypes, Classes,
  CastleKeysMouse, CastleInternalContextBase;

{ Convert mouse button (from VCL or FMX) to CGE. }
function MouseButtonToCastle(const MouseButton: TMouseButton;
  out CastleMouseButton: TCastleMouseButton): Boolean;

{ Convert key (from VCL or FMX) to CGE.
  If not possible, returns keyNone. }
function KeyToCastle(const Key: Word; const Shift: TShiftState) : TKey;

{ Convert FMX information about keys (received on key up or key down)
  to CGE. }
procedure FmxKeysToCastle(
  const Key: Word; const KeyChar: WideChar; const Shift: TShiftState;
  out CastleKey: TKey; out CastleKeyString: String);

{ Hacky and quick conversion of TKey to String representation.
  Knows additionally modifiers state from Shift.

  Using this should be avoided: it's not localized (will not generate
  your language-specific chars), not complete, ignores caps lock,
  assumes specific keyboard layout (e.g. keyboard with = and + on
  the same physical key).
  IOW, it does a bunch of things it shouldn't do -- because it does not have
  necessary knowledge about your keyboard layout and state.
  Querying the underlying system (like WinAPI or VCL) for proper message
  is better, though sometimes complicated. }
function SimpleKeyToString(const Key: TKey; const Shift: TShiftState): String;

{ Convert cursor from CGE (TMouseCursor) to VCL or FMX (TCursor). }
function CursorFromCastle(const Cursor: TMouseCursor): TCursor;

type
  TDesignTimeProjectPathEvent = function: String;

var
  OnGetDesignTimeProjectPath: TDesignTimeProjectPathEvent;

{ Best TGLContext descendant for this platform. }
function ContextCreateBestInstance: TGLContext;

implementation

uses
  {$ifdef MSWINDOWS} CastleInternalContextWgl, {$endif}
  {$ifdef LINUX} CastleInternalContextEgl, {$endif}
  CastleStringUtils, CastleLog;

function MouseButtonToCastle(const MouseButton: TMouseButton;
  out CastleMouseButton: TCastleMouseButton): Boolean;
begin
  Result := true;
  case MouseButton of
    TMouseButton.mbLeft  : CastleMouseButton := buttonLeft;
    TMouseButton.mbRight : CastleMouseButton := buttonRight;
    TMouseButton.mbMiddle: CastleMouseButton := buttonMiddle;
    {$ifndef COMPILER_CASE_ANALYSIS}
    else Result := false;
    {$endif}
  end;
end;

function KeyToCastle(const Key: Word; const Shift: TShiftState): TKey;
begin
  { Note: vkXxx constants from FMX seem to be deliberately declared so that
    they match Windows VK_xxx constants, used also by VCL.
    So this routine should be good to convert both VCL and FMX keys. }

  Result := keyNone;
  case Key of
    vkBack:       Result := keyBackSpace;
    vkTab:        Result := keyTab;
    vkReturn:     Result := keyEnter;
    vkShift:      Result := keyShift;
    vkControl:    Result := keyCtrl;
    vkMenu:       Result := keyAlt;
    vkEscape:     Result := keyEscape;
    vkSpace:      Result := keySpace;
    vkPrior:      Result := keyPageUp;
    vkNext:       Result := keyPageDown;
    vkEnd:        Result := keyEnd;
    vkHome:       Result := keyHome;
    vkLeft:       Result := keyArrowLeft;
    vkUp:         Result := keyArrowUp;
    vkRight:      Result := keyArrowRight;
    vkDown:       Result := keyArrowDown;
    vkInsert:     Result := keyInsert;
    vkDelete:     Result := keyDelete;
    vkAdd:        Result := keyNumpadPlus;
    vkSubtract:   Result := keyNumpadMinus;
    vkSnapshot:   Result := keyPrintScreen;
    vkNumlock:    Result := keyNumLock;
    vkScroll:     Result := keyScrollLock;
    vkCapital:    Result := keyCapsLock;
    vkPause:      Result := keyPause;
    vkComma:      Result := keyComma;
    vkPeriod:     Result := keyPeriod;
    vkNumpad0:    Result := keyNumpad0;
    vkNumpad1:    Result := keyNumpad1;
    vkNumpad2:    Result := keyNumpad2;
    vkNumpad3:    Result := keyNumpad3;
    vkNumpad4:    Result := keyNumpad4;
    vkNumpad5:    Result := keyNumpad5;
    vkNumpad6:    Result := keyNumpad6;
    vkNumpad7:    Result := keyNumpad7;
    vkNumpad8:    Result := keyNumpad8;
    vkNumpad9:    Result := keyNumpad9;
    vkClear:      Result := keyNumpadBegin;
    vkMultiply:   Result := keyNumpadMultiply;
    vkDivide:     Result := keyNumpadDivide;
    vkMinus:      Result := keyMinus;
    vkEqual:
      if ssShift in Shift then
        Result := keyPlus
      else
        Result := keyEqual;
    vk0..vk9:
      begin
        Result := TKey(Ord(key0)  + Ord(Key) - vk0);
      end;
    vkA .. vkZ:
      begin
        Result := TKey(Ord(keyA)  + Ord(Key) - vkA);
      end;
    vkF1 .. vkF12:
      Result := TKey(Ord(keyF1) + Ord(Key) - vkF1);
  end;
end;

function SimpleKeyToString(const Key: TKey; const Shift: TShiftState): String;
const
  Map: array [TKey] of String = (
    '',
    '',
    '',
    '',
    '',
    '',
    '''',
    ';',
    CharBackSpace,
    CharTab,
    '/',
    '`',
    '-',
    CharEnter,
    '=',
    '',
    '',
    '',
    '',
    '+',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    CharEscape,
    '',
    '',
    '',
    '',
    ' ',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '0',
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    'a',
    'b',
    'c',
    'd',
    'e',
    'f',
    'g',
    'h',
    'i',
    'j',
    'k',
    'l',
    'm',
    'n',
    'o',
    'p',
    'q',
    'r',
    's',
    't',
    'u',
    'v',
    'w',
    'x',
    'y',
    'z',
    '[',
    '',
    ']',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '+',
    '',
    '-',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '0',
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '*',
    '/',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    ',',
    '',
    '.',
    ''
  );
begin
  Result := Map[Key];

  if (ssShift in Shift) and (Length(Result) = 1) then
  begin
    if Key in [keyA..keyZ] then
      Result := UpCase(Result[1])
    else
    if Key = keyEqual then
      Result := '+';
  end;
end;

{$ifdef LINUX}
{ Hacky way to convert key as WideChar into a TKey.

  Used only to workaround Delphi FMXLinux: FMXLinux never sends a key code
  (as Word, like vkA, vkSpace etc.) to OnKeyDown.
  It only sends the key as WideChar, and the key code is always 0.

  Confirmed with almost-blank FMX application (not using CGE), compiled for Linux.
  TForm.OnKeyDown, TEdit.OnKeyDown report Key = 0, and KeyChar = 'a' when
  you press key A.
  Weirdly, the non-zero Key *is* passed properly by FMXLinux for things that have
  no KeyChar representation, like arrow keys.
  Tested that doing
  "g_signal_connect(GLAreaGtk, 'key_press_event', @signal_key_press_event,
    LinuxHandle.NativeDrawingArea);" inside
  castleinternalfmxutils_linux.inc doesn't help (makes sense, since almost-blank
  FMX application, not using CGE, also shows this problem).

  So we workaround it in TCastleControl.KeyDown and TCastleWindow.OpenGLControlKeyDown,
  so that CGE applications don't see this problem. }

function SimpleWideCharToKey(const KeyChar: WideChar): TKey;
begin
  Result := keyNone;
  case KeyChar of
    CharBackSpace: Result := keyBackSpace;
    CharTab:       Result := keyTab;
    CharEnter:     Result := keyEnter;
    CharEscape:    Result := keyEscape;
    ' ':           Result := keySpace;
    ',':           Result := keyComma;
    '.':           Result := keyPeriod;
    '*':           Result := keyNumpadMultiply;
    '/':           Result := keyNumpadDivide;
    '-':           Result := keyMinus;
    '=':           Result := KeyEqual;
    '+':           Result := keyPlus;
    '0'..'9':
      begin
        Result := TKey(Ord(key0)  + Ord(KeyChar) - Ord('0'));
      end;
    'A'..'Z':
      begin
        Result := TKey(Ord(keyA)  + Ord(KeyChar) - Ord('A'));
      end;
    'a'..'z':
      begin
        Result := TKey(Ord(keyA)  + Ord(KeyChar) - Ord('a'));
      end;
  end;
end;

{ Workaround 2 FMXLinux bugs:

  - FMXLinux always passes Key=0 for regular
    keys that represent printable characters, like 'a' or space,
    see SimpleWideCharToKey comments.

  - On Enter, it passes vkReturn as Key, but KeyChar = #0.
    We want to pass CharEnter.
    Same thing for a few other special chars.
}
procedure FmxLinuxFixKeys(
  const FmxKey: Word; const FmxKeyChar: WideChar;
  var CastleKey: TKey; var CastleKeyString: String);
begin
  if (FmxKey = 0) and
     (FmxKeyChar <> #0) and
     (CastleKey = keyNone) then
    CastleKey := SimpleWideCharToKey(FmxKeyChar);

  if CastleKeyString = '' then
    case CastleKey of
      keyEnter :    CastleKeyString := CharEnter;
      keyEscape:    CastleKeyString := CharEscape;
      keyTab:       CastleKeyString := CharTab;
      keyBackSpace: CastleKeyString := CharBackSpace;
      else ;
    end;
end;
{$endif}

procedure FmxKeysToCastle(
  const Key: Word; const KeyChar: WideChar; const Shift: TShiftState;
  out CastleKey: TKey; out CastleKeyString: String);
begin
  // calculate CastleKey
  CastleKey := KeyToCastle(Key, Shift);

  // calculate CastleKeyString
  if KeyChar <> #0 then
    CastleKeyString := KeyChar
  else
    CastleKeyString := '';

  // apply FMXLinux fixes
  {$ifdef LINUX}
  FmxLinuxFixKeys(Key, KeyChar, CastleKey, CastleKeyString);
  {$endif}

  // Debug what happens
  WritelnLog('FMX Key', 'Key=%d KeyChar=%s CastleKey=%s CastleKeyString=%s', [
    Key,
    SReadableForm(KeyChar),
    KeyToStr(CastleKey),
    SReadableForm(CastleKeyString)
  ]);
end;

function CursorFromCastle(const Cursor: TMouseCursor): TCursor;
const
  Map: array [TMouseCursor] of TCursor =
  ( crDefault, //< mcDefault
    crNone,    //< mcNone
    crNone,    //< mcForceNone

    crArrow,       //< mcStandard
    crHourGlass,   //< mcWait
    crIBeam,       //< mcText
    crHandPoint,   //< mcHand
    crSizeNS,      //< mcResizeVertical
    crSizeWE,      //< mcResizeHorizontal
    crSizeNS { nothing better in Delphi },      //< mcResizeTopLeft
    crSizeNS { nothing better in Delphi },       //< mcResizeTop
    crSizeNS { nothing better in Delphi },      //< mcResizeTopRight
    crSizeWE { nothing better in Delphi },       //< mcResizeLeft
    crSizeWE { nothing better in Delphi },       //< mcResizeRight
    crSizeNS { nothing better in Delphi },      //< mcResizeBottomLeft
    crSizeNS { nothing better in Delphi },       //< mcResizeBottom
    crSizeNS { nothing better in Delphi }       //< mcResizeBottomRight
  );
begin
  Result := Map[Cursor];
end;

function ContextCreateBestInstance: TGLContext;
begin
  Result :=
    {$if defined(MSWINDOWS)} TGLContextWgl.Create
    {$elseif defined(LINUX)} TGLContextEgl.Create
    {$else}
      {$message fatal 'Define how to create OpenGL context for this platform.'}
    {$endif}
  ;
end;

end.
