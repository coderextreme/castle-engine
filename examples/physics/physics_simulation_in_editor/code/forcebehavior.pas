unit ForceBehavior;

{$ifdef FPC}{$mode ObjFPC}{$H+}{$endif}

interface

uses
  Classes, SysUtils, CastleTransform, CastleBehaviors, CastleVectors,
  CastleComponentSerialize, CastleClassUtils, AbstractTimeDurationBehavior;

type
  { Add this behavior to another body and select body you want to use it }
  TForceBehavior = class (TAbstractTimeDurationBehavior)
  private
    FValue: Single;
    FTarget: TCastleTransform;

  public
    procedure Update(const SecondsPassed: Single; var RemoveMe: TRemoveType); override;

    function PropertySections(const PropertyName: String): TPropertySections; override;
  published
    property Target: TCastleTransform read FTarget write FTarget;
    property Value: Single read FValue write FValue;
  end;

implementation

{ TForceBehavior ------------------------------------------------------------- }

procedure TForceBehavior.Update(const SecondsPassed: Single;
  var RemoveMe: TRemoveType);
var
  RigidBody: TCastleRigidBody;
  Direction: TVector3;
begin
  inherited Update(SecondsPassed, RemoveMe);

  if not ShouldUpdate then
    Exit;

  if FTarget = nil then
    Exit;

  if not FTarget.ExistsInRoot then
    Exit;

  RigidBody := FTarget.FindBehavior(TCastleRigidBody) as TCastleRigidBody;
  if (RigidBody <> nil) and (RigidBody.ExistsInRoot) then
  begin
    Direction := FTarget.LocalToWorld(FTarget.Translation) - Parent.LocalToWorld(Parent.Translation);
    Direction := Direction.Normalize;
    RigidBody.AddForce(Direction * Value, Parent.LocalToWorld(Parent.Translation));
    RigidBody.WakeUp;
  end;
end;

function TForceBehavior.PropertySections(const PropertyName: String
  ): TPropertySections;
begin
  if (PropertyName = 'Target') or
     (PropertyName = 'Value') then
    Result := [psBasic]
  else
    Result := inherited PropertySections(PropertyName);
end;

initialization
  RegisterSerializableComponent(TForceBehavior, 'Force Behavior');

end.

