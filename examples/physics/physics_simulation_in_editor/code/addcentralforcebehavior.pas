unit AddCentralForceBehavior;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, CastleTransform, CastleBehaviors, CastleVectors,
  CastleComponentSerialize, AbstractTimeDurationBehavior;

type
  TAddCentralForceBehavior = class (TAbstractTimeDurationBehavior)
  private
    FForce: TVector3;

    FForcePersistent: TCastleVector3Persistent;

    function GetForceForPersistent: TVector3;
    procedure SetForceForPersistent(const AValue: TVector3);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy;override;

    procedure Update(const SecondsPassed: Single; var RemoveMe: TRemoveType); override;

    property Force: TVector3 read FForce write FForce;
  published
    property ForcePersistent: TCastleVector3Persistent read FForcePersistent;
  end;

implementation

{ TAddCentralForceBehavior --------------------------------------------------- }

function TAddCentralForceBehavior.GetForceForPersistent: TVector3;
begin
  Result := Force;
end;

procedure TAddCentralForceBehavior.SetForceForPersistent(const AValue: TVector3);
begin
  Force := AValue;
end;

constructor TAddCentralForceBehavior.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  FForcePersistent := TCastleVector3Persistent.Create;
  FForcePersistent.InternalGetValue := {$ifdef FPC}@{$endif}GetForceForPersistent;
  FForcePersistent.InternalSetValue := {$ifdef FPC}@{$endif}SetForceForPersistent;
  FForcePersistent.InternalDefaultValue := Force; // current value is default
end;

destructor TAddCentralForceBehavior.Destroy;
begin
  FreeAndNil(FForcePersistent);
  inherited;
end;

procedure TAddCentralForceBehavior.Update(const SecondsPassed: Single;
  var RemoveMe: TRemoveType);
var
  RigidBody: TCastleRigidBody;
begin
  inherited Update(SecondsPassed, RemoveMe);

  if not ShouldUpdate then
    Exit;

  RigidBody := Parent.FindBehavior(TCastleRigidBody) as TCastleRigidBody;
  if (RigidBody <> nil) and (RigidBody.Exists) then
  begin
    RigidBody.AddCenteralForce(Force);
    RigidBody.WakeUp;
  end;
end;

initialization

RegisterSerializableComponent(TAddCentralForceBehavior, 'Add Central Force Behavior');

end.

