unit formlayercollisionspropertyeditor;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  CastleTransform;

type
  TLayerCollisionsPropertyEditorForm = class(TForm)
    CheckboxesPanel: TPanel;
    VerticalNamesPanel: TPanel;
    HorizontalNamesPanel: TPanel;
    procedure FormCreate(Sender: TObject);
    procedure FormResize(Sender: TObject);
  strict private
    {
       Checkboxes matrix looking like that:
       19,0 18,0 17,0 ...
       19,1 18,1 17,1 ...
       19,2 18,2 17,1 ...
       ...
    }
    Checkboxes: array [TPhysicsLayer, TPhysicsLayer] of TCheckBox;
    CheckboxesPanels: array [TPhysicsLayer] of TPanel;
    { Horizontal names labels from 0  to 19 }
    HorizontalNames: array [TPhysicsLayer] of TLabel;

    procedure CreateCheckboxes;
    procedure CreateHorizontalNames;
    procedure CreateVerticalNames;

    procedure UpdateHorizontalNamesTop;
    procedure RepaintVerticalNames(Sender: TObject);
  public

  end;

//var
//  LayerCollisionsPropertyEditorForm: TLayerCollisionsPropertyEditorForm;

implementation

{$R *.lfm}

{ TLayerCollisionsPropertyEditorForm ----------------------------------------- }

procedure TLayerCollisionsPropertyEditorForm.FormCreate(Sender: TObject);
begin
  CreateCheckboxes;
  CreateHorizontalNames;
  CreateVerticalNames;
  UpdateHorizontalNamesTop;
end;


procedure TLayerCollisionsPropertyEditorForm.FormResize(Sender: TObject);
begin
  UpdateHorizontalNamesTop;
end;

procedure TLayerCollisionsPropertyEditorForm.CreateCheckboxes;
var
  Panel: TPanel;
  PreviousPanel: TPanel;
  I, J : TPhysicsLayer;

  function AddCheckbox(X, Y: TPhysicsLayer; Panel: TPanel): TCheckBox;
  var
    C: TCheckBox;
  begin
    C := TCheckBox.Create(Panel);
    C.Parent := Panel;
    C.AnchorSide[akTop].Side := asrCenter;
    C.AnchorSide[akTop].Control := Panel;
    C.Caption := '';
    C.Hint := '[' + IntToStr(X) + ',' + IntToStr(Y) + ']';
    C.ShowHint := true;
    C.ParentShowHint := false;
    C.AutoSize := true;

    if X = High(TPhysicsLayer) then
    begin
      C.AnchorSide[akLeft].Side := asrLeft;
      C.AnchorSide[akLeft].Control := Panel
    end else
    begin
      C.AnchorSide[akLeft].Side := asrRight;
      C.AnchorSide[akLeft].Control := CheckBoxes[X + 1, Y];
    end;
    Result := C;
  end;

begin
  PreviousPanel := nil;
  CheckboxesPanel.AutoSize := true;
  CheckboxesPanel.Caption := '';
  CheckboxesPanel.BevelOuter := bvNone;

  for I := Low(TPhysicsLayer) to High(TPhysicsLayer) do
  begin
    Panel := TPanel.Create(CheckboxesPanel);
    Panel.Parent := CheckboxesPanel;
    Panel.Caption := '';
    Panel.BevelOuter := bvNone;

    if PreviousPanel = nil then
    begin
      Panel.AnchorSide[akTop].Side  := asrTop;
      Panel.AnchorSide[akTop].Control := CheckboxesPanel
    end else
    begin
      Panel.AnchorSide[akTop].Side  := asrBottom;
      Panel.AnchorSide[akTop].Control := PreviousPanel;
    end;

    for J := High(TPhysicsLayer) downto I do
      Checkboxes[J, I] := AddCheckbox(J, I, Panel);

    Panel.AutoSize := true;
    CheckboxesPanels[I] := Panel;
    PreviousPanel := Panel;
  end;
end;

procedure TLayerCollisionsPropertyEditorForm.CreateHorizontalNames;
var
  ALabel: TLabel;
  I: TPhysicsLayer;
begin
  HorizontalNamesPanel.BevelOuter := bvNone;
  HorizontalNamesPanel.Caption := '';

  for I := Low(TPhysicsLayer) to High(TPhysicsLayer) do
  begin
    ALabel := TLabel.Create(HorizontalNamesPanel);
    ALabel.Parent := HorizontalNamesPanel;
    ALabel.Caption := IntToStr(I) + ': ';
    ALabel.AutoSize := true;

    ALabel.Anchors := [akTop, akRight];
    ALabel.AnchorSide[akTop].Side  := asrTop;
    ALabel.AnchorSide[akTop].Control := nil;
    ALabel.AnchorSide[akRight].Side := asrRight;
    ALabel.AnchorSide[akRight].Control := HorizontalNamesPanel;

    HorizontalNames[I] := ALabel;
  end;
end;

procedure TLayerCollisionsPropertyEditorForm.CreateVerticalNames;
begin
  VerticalNamesPanel.BevelOuter := bvNone;
  VerticalNamesPanel.Caption := '';
  VerticalNamesPanel.OnPaint := @RepaintVerticalNames;
  RepaintVerticalNames(VerticalNamesPanel);
end;

procedure TLayerCollisionsPropertyEditorForm.UpdateHorizontalNamesTop;
var
  Margin: Integer;
  I: TPhysicsLayer;
begin
  Margin := (CheckboxesPanels[0].Height - HorizontalNames[0].Height) div 2;
  for I := Low(TPhysicsLayer) to High(TPhysicsLayer) do
    HorizontalNames[I].Top :=  CheckboxesPanels[I].Top + Margin;
end;

procedure TLayerCollisionsPropertyEditorForm.RepaintVerticalNames(Sender: TObject);
var
  I: TPhysicsLayer;
  X, Y: Integer;
  CheckboxWidth: Integer;
  MaxWidth: Integer;
  VName: String;
  VNameWidth: Integer;
begin
  VerticalNamesPanel.Canvas.Font.Orientation := 900;
  VerticalNamesPanel.Canvas.Font.Color := clWindowText;
  VerticalNamesPanel.Color := clWindow;

  MaxWidth := 50;
  X := 0;
  CheckboxWidth := Checkboxes[High(TPhysicsLayer), Low(TPhysicsLayer)].Width;
  Y := VerticalNamesPanel.Height;
  for I := High(TPhysicsLayer) downto Low(TPhysicsLayer) do
  begin
    VName := IntToStr(I) + ': ';
    VNameWidth := VerticalNamesPanel.Canvas.TextExtent(VName).Width;
    if VNameWidth > MaxWidth then
       MaxWidth := VNameWidth;
    VerticalNamesPanel.Canvas.TextOut(X, Y, VName);
    X := X + CheckboxWidth;
  end;

  if MaxWidth <> VerticalNamesPanel.Constraints.MinHeight then
  begin
    VerticalNamesPanel.Constraints.MinHeight := MaxWidth;
    VerticalNamesPanel.Constraints.MaxHeight := MaxWidth;
  end;
end;

end.

