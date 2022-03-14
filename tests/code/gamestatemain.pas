{
  Copyright 2022-2022 Andrzej Kilijański, Dean Zobec, Michael Van Canneyt, Michalis Kamburelis.

  This file is part of "Castle Game Engine".

  "Castle Game Engine" is free software; see the file COPYING.txt,
  included in this distribution, for details about the copyright.

  "Castle Game Engine" is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

  ----------------------------------------------------------------------------
}

{ Main state, where most of the application logic takes place. }
unit GameStateMain;

interface

uses Classes,
  CastleVectors, CastleUIState, CastleComponentSerialize,
  CastleUIControls, CastleControls, CastleKeysMouse, CastleTester;

type
  { Main state, where most of the application logic takes place. }
  TStateMain = class(TUIState)
  private
    { Components designed using CGE editor, loaded from gamestatemain.castle-user-interface. }
    LabelMessage: TCastleLabel;
    LabelCurrentTest: TCastleLabel;
    LabelTestPassed: TCastleLabel;
    LabelTestFailed: TCastleLabel;
    LabelFailedTests: TCastleLabel;
    LabelTestsCount: TCastleLabel;
    CheckboxStopOnFail: TCastleCheckbox;
    ButtonStartTests: TCastleButton;
    ButtonStopTests: TCastleButton;
    ButtonSelectTests: TCastleButton;

    Tester: TCastleTester;
    RunTests: Boolean;

    procedure ClickStartTests(Sender: TObject);
    procedure ClickStopTests(Sender: TObject);

    procedure TestPassedCountChanged(const TestCount: Integer);
    procedure TestFailedCountChanged(const TestCount: Integer);
    procedure EnabledTestCountChanged(Sender: TObject);
    procedure TestExecuted(const AName: String);
    procedure AssertFailed(const TestName, Msg: String);
    procedure LogFailedAssertion(const AMessage: String);

    procedure StartTesting;
    procedure StopTesting(const AMessage: String;
      const Exception: Boolean = false);

  public
    constructor Create(AOwner: TComponent); override;
    procedure Start; override;
    procedure Update(const SecondsPassed: Single;
      var HandleInput: Boolean); override;
    function Press(const Event: TInputPressRelease): Boolean; override;
  end;

var
  StateMain: TStateMain;

implementation

{$define CASTLE_TESTER}

uses SysUtils,
  CastleColors, CastleUtils,


 { Testing (mainly) things inside FPC standard library, not CGE }
  {$ifdef FPC}TestCompiler,{$endif}
  TestSysUtils,
  {$ifdef FPC}TestFGL,{$endif}
  TestGenericsCollections,
  {$ifdef FPC}TestOldFPCBugs,{$endif}
  {$ifdef FPC}TestFPImage,{$endif}
  //TestToolFpcVersion,


{ Testing CGE units }
  {$ifdef FPC}TestCastleUtils,{$endif}
  TestCastleRectangles,
  {$ifdef FPC}TestCastleGenericLists,{$endif}
  TestCastleFindFiles,
  TestCastleFilesUtils,
  TestCastleUtilsLists,
  TestCastleClassUtils,
  TestCastleVectors,
  TestCastleTriangles,
  TestCastleColors,
  TestCastleQuaternions,
  TestCastleKeysMouse,
  TestCastleImages,
  TestCastleImagesDraw,
  TestCastleBoxes,
  TestCastleFrustum,
  TestCastleFonts,
  TestCastleTransform,
  TestCastleParameters,
  TestCastleUIControls,
  TestCastleCameras,
  TestX3DFields,
  TestX3DNodes,
  TestX3DNodesOptimizedProxy,
  TestX3DNodesNurbs,
  TestCastleScene,
  TestCastleSceneCore,
  {$ifdef FPC}TestCastleSceneManager,{$endif}
  TestCastleVideos,
  TestCastleSpaceFillingCurves,
  TestCastleStringUtils,
  {$ifdef FPC}TestCastleScript,{$endif}
  {$ifdef FPC}TestCastleScriptVectors,{$endif}
  TestCastleCubeMaps,
  TestCastleGLVersion,
  TestCastleCompositeImage,
  TestCastleTriangulate,
  TestCastleGame,
  TestCastleURIUtils,
  TestCastleXMLUtils,
  TestCastleCurves,
  TestCastleTimeUtils,
  TestCastleControls,
  TestCastleRandom,
  TestCastleSoundEngine,
  TestCastleComponentSerialize,
  TestX3DLoadInternalUtils,
  TestCastleLevels,
  TestCastleDownload,
  {$ifdef FPC}TestCastleUnicode,{$endif}
  TestCastleResources,
  TestX3DLoadGltf,
  TestCastleTiledMap,
  TestCastleInternalAutoGenerated

  {$ifndef NO_WINDOW_SYSTEM},
  TestCastleWindow,
  TestCastleOpeningAndRendering3D,
  TestCastleWindowOpen
  {$endif}

  { Stuff requiring Lazarus LCL. }
  // {$ifdef FPC}TestCastleLCLUtils{$endif}
  ;

{ TStateMain ----------------------------------------------------------------- }

procedure TStateMain.AssertFailed(const TestName, Msg: String);
begin
  LogFailedAssertion(TestName + ': ' + Msg);
end;

procedure TStateMain.ClickStartTests(Sender: TObject);
begin
  Tester.StopOnFirstFail := CheckboxStopOnFail.Checked;
  Tester.PrepareTestListToRun;
  StartTesting;
end;

procedure TStateMain.ClickStopTests(Sender: TObject);
begin
  StopTesting('Testing aborted by user', false);
end;

constructor TStateMain.Create(AOwner: TComponent);
begin
  inherited;
  DesignUrl := 'castle-data:/gamestatemain.castle-user-interface';
end;

procedure TStateMain.EnabledTestCountChanged(Sender: TObject);
begin
  LabelTestsCount.Caption := Format('Tests: %d / %d', [
    Tester.EnabledTestCount,
    Tester.TestsCount
  ]);
end;

procedure TStateMain.LogFailedAssertion(const AMessage: String);
begin
  if LabelFailedTests.Caption = '' then
    LabelFailedTests.Caption :=  AMessage
  else
    LabelFailedTests.Caption := LabelFailedTests.Caption + NL + AMessage;
end;

procedure TStateMain.Start;
begin
  inherited;

  { Find components, by name, that we need to access from code }
  ButtonStartTests := DesignedComponent('ButtonStartTests') as TCastleButton;
  ButtonStartTests.OnClick := {$ifdef FPC}@{$endif}ClickStartTests;

  ButtonStopTests := DesignedComponent('ButtonStopTests') as TCastleButton;
  ButtonStopTests.OnClick := {$ifdef FPC}@{$endif}ClickStopTests;
  ButtonStopTests.Enabled := false;

  ButtonSelectTests := DesignedComponent('ButtonSelectTests') as TCastleButton;
  ButtonSelectTests.Enabled := true;
  ButtonSelectTests.Exists := false; // TODO: ButtonSelectTests functionality not implemented yet

  LabelTestPassed := DesignedComponent('LabelTestPassed') as TCastleLabel;
  LabelTestFailed := DesignedComponent('LabelTestFailed') as TCastleLabel;
  LabelMessage := DesignedComponent('LabelMessage') as TCastleLabel;
  LabelCurrentTest := DesignedComponent('LabelCurrentTest') as TCastleLabel;
  LabelFailedTests := DesignedComponent('LabelFailedTests') as TCastleLabel;
  LabelTestsCount := DesignedComponent('LabelTestsCount') as TCastleLabel;
  CheckboxStopOnFail := DesignedComponent('CheckboxStopOnFail') as TCastleCheckbox;

  { Make sure the tests are not running }
  RunTests := false;

  Tester := TCastleTester.Create(FreeAtStop);
  { We can just set values in Update but I think callbacks interface is more
    flexible in a variety of applications }
  Tester.NotifyTestPassedChanged := {$ifdef FPC}@{$endif}TestPassedCountChanged;
  Tester.NotifyTestFailedChanged := {$ifdef FPC}@{$endif}TestFailedCountChanged;
  Tester.NotifyEnabledTestCountChanged := {$ifdef FPC}@{$endif}EnabledTestCountChanged;
  Tester.NotifyTestCaseExecuted := {$ifdef FPC}@{$endif}TestExecuted;
  Tester.NotifyAssertFail := {$ifdef FPC}@{$endif}AssertFailed;


  { You can add all Registered tests by calling AddRegisteredTestCases }
  Tester.AddRegisteredTestCases;

  { Or add only one test case by code eg. }
  (*
  Tester.AddTestCase(TTestURIUtils.Create);
  Tester.AddTestCase(TTestCastleBoxes.Create);
  Tester.AddTestCase(TTestCameras.Create);
  Tester.AddTestCase(TTestCastleClassUtils.Create);
  Tester.AddTestCase(TTestCastleColors.Create);
  Tester.AddTestCase(TTestCastleComponentSerialize.Create); *)

  { Scans all tests }
  Tester.Scan;
  { First prepare to count acctualy selected tests }
  Tester.PrepareTestListToRun;
end;

procedure TStateMain.StartTesting;
begin
  RunTests := true;
  LabelMessage.Caption := 'Processing...';
  LabelMessage.Color := HexToColor('00CE00');
  ButtonStartTests.Enabled := false;
  ButtonStopTests.Enabled := true;
  ButtonSelectTests.Enabled := false;
end;

procedure TStateMain.StopTesting(const AMessage: String; const Exception: Boolean = false);
begin
  RunTests := false;

  LabelMessage.Caption := AMessage;

  { If some test ends with unhalted exception we want it on our error list }
  if Exception then
    LogFailedAssertion(AMessage);

  if (Tester.TestFailedCount > 0) or (Exception) then
    LabelMessage.Color := HexToColor('C60D0D')
  else
    LabelMessage.Color := HexToColor('00CE00');

  ButtonStartTests.Enabled := true;
  ButtonStopTests.Enabled := false;
  ButtonSelectTests.Enabled := true;
end;

procedure TStateMain.TestExecuted(const AName: String);
begin
  LabelCurrentTest.Caption := AName;
end;

procedure TStateMain.TestFailedCountChanged(const TestCount: Integer);
begin
  LabelTestFailed.Caption := IntToStr(TestCount);
end;

procedure TStateMain.TestPassedCountChanged(const TestCount: Integer);
begin
  LabelTestPassed.Caption := IntToStr(TestCount);
end;

procedure TStateMain.Update(const SecondsPassed: Single; var HandleInput: Boolean);
begin
  if RunTests then
  begin
    if Tester.IsNextTestToRun then
    begin
      try
        TEster.RunNextTest;
      except
        on E:Exception do
        begin
          { In case of UI application we don't want any unhandled exceptions }
          StopTesting('Unhalted exception: ' + E.Message, true);
        end;
      end;
    end else
    begin
      StopTesting('Testing finished');
    end;
  end;

  inherited;
end;

function TStateMain.Press(const Event: TInputPressRelease): Boolean;
begin
  Result := inherited;
  if Result then Exit; // allow the ancestor to handle keys

  { This virtual method is executed when user presses
    a key, a mouse button, or touches a touch-screen.

    Note that each UI control has also events like OnPress and OnClick.
    These events can be used to handle the "press", if it should do something
    specific when used in that UI control.
    The TStateMain.Press method should be used to handle keys
    not handled in children controls.
  }

  // Use this to handle keys:
  {
  if Event.IsKey(keyXxx) then
  begin
    // DoSomething;
    Exit(true); // key was handled
  end;
  }
end;

end.
