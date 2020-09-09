unit Horse.Annotation;

interface

uses
  System.JSON, System.Classes, Rest.JSON,
  System.Rtti, System.generics.collections,
  Horse;

type

  TSingleton<T: constructor, class> = class
  strict private
    class var FInstance: T;
  public
    class function GetInstance: T;
  end;

  TRegisterMethods = class
  private
    FRegisterMethods: TDictionary<string, string>;
    procedure SetRegisterMethods(const Value: TDictionary<string, string>);
  public
    constructor Create;
    destructor Destroy; override;
    property RegisterMethods: TDictionary<string, string> read FRegisterMethods
      write SetRegisterMethods;
    class function FormatRoute(aRoute: string): String;
  end;

  IAnnotation = interface
    ['{458FBFE8-FDC1-413A-80B1-DE27B5428507}']
    procedure Send(Content: String); overload;
    procedure Send(AObject: TObject); overload;
    procedure Send(AInterface: IInterface); overload;
    function Execute: string;
  end;

  tpRoute = (rGET, rPOST, rPUT, rDELETE, rPATCH);
  TParametrosSubRota = array of string;

  SubRoute = class(TCustomAttribute)
  private
    FSubRoute: string;
    FMethod: tpRoute;
    FParameters: TParametrosSubRota;
    FDescription: string;
    FPermissions: string;
    procedure Setsubrota(const Value: string);
    procedure SetMetodo(const Value: tpRoute);
    procedure SetParametros(const Value: TParametrosSubRota);
    procedure SetDescricao(const Value: string);

  public
    constructor Create(LStrMethod: tpRoute; SubRoute: string); overload;
    constructor Create(LStrMethod: tpRoute; SubRoute, Descricao: string); overload;
    constructor Create(LStrMethod: tpRoute; SubRoute, Descricao: string;
      Permissions: string); overload;
    property Permissions: string read FPermissions write FPermissions;
    property SubRoute: string read FSubRoute write Setsubrota;
    property LStrMethod: tpRoute read FMethod write SetMetodo;
    property Parametros: TParametrosSubRota read FParameters
      write SetParametros;
    property Descricao: string read FDescription write SetDescricao;
    destructor Destroy; override;
  end;

  Route = class(TCustomAttribute)
  private
    FRota: string;
    FMethod: tpRoute;
    FDescription: string;
    procedure Setrota(const Value: string);
    procedure SetDescricao(const Value: string);
  public
    constructor Create(Route, Descricao: string);
    property Route: string read FRota write Setrota;
    property Descricao: string read FDescription write SetDescricao;
  end;

  THorseAnnotation = class(TInterfacedObject, IAnnotation)
  private
    FContent: string;
  public
    procedure Send(Content: String); overload;
    procedure Send(AObject: TObject); overload;
    procedure Send(AInterface: IInterface); overload;
    function Execute: string;
  end;

  TAnnotation = class
    class function Use<T: constructor, class>: THorseCallback;
    class function RegisterService<T: constructor, class>: THorseCallback;
  end;

  var
   SingletonRegisterMethods:TRegisterMethods;
implementation

uses
  System.SysUtils;

{ TAnnotation }

class function TAnnotation.RegisterService<T>: THorseCallback;
var
  LTypeCtx: TRttiType;
  LCtx: TRttiContext;
  LAtr, LAtr2: TCustomAttribute;
  LMethod: TRttiMethod;
  LRouteType: tpRoute;
  LStrRoute, LStrSubRoute: string;
  LAnnotation: IAnnotation;
  LObj: T;
  LStrMethod: string;
begin
  Result := procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    begin

    end;
  LCtx := TRttiContext.Create;
  LTypeCtx := LCtx.GetType(T.ClassInfo);
  try
    for LAtr in LTypeCtx.GetAttributes do
    begin
      LStrRoute := (Route(LAtr).Route);
    end;
    for LMethod in LTypeCtx.GetMethods do
    begin
      for LAtr2 in LMethod.GetAttributes do
      begin
        LStrSubRoute := LStrRoute + (LAtr2 as SubRoute).SubRoute;
        SingletonRegisterMethods.RegisterMethods.Add
          (TRegisterMethods.FormatRoute(LStrSubRoute), LMethod.name);
        case (LAtr2 as SubRoute).LStrMethod of
          rGET:
            THorse.Get(LStrSubRoute, Result);
          rPOST:
            THorse.Post(LStrSubRoute, Result);
          rPUT:
            THorse.Put(LStrSubRoute, Result);
          rDELETE:
            THorse.Delete(LStrSubRoute, Result);
          rPATCH:
            THorse.Patch(LStrSubRoute, Result);
        end;
      end;
    end;
  finally
    LCtx.Free;
    LTypeCtx.DisposeOf;
  end;

end;

class function TAnnotation.Use<T>: THorseCallback;
var
  LTypeCtx: TRttiType;
  LCtx: TRttiContext;
  LAtr: TCustomAttribute;
  LStrMethod: string;
  LObj: T;
  LAnnotation: IAnnotation;
begin
  RegisterService<T>;
  Result := procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    begin
    end;
  Result := procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    begin
      LObj := T.Create;
      LCtx := TRttiContext.Create;
      LTypeCtx := LCtx.GetType(LObj.ClassInfo);
      try
        try
          LStrMethod := SingletonRegisterMethods.RegisterMethods.
            Items[THorseHackRequest(Req).GetWebRequest.PathInfo];
          LTypeCtx.GetMethod(LStrMethod).Invoke(LObj, []);
          Res.Send(IAnnotation(LObj).Execute);
        except
          exit;
        end;
      finally
        LCtx.Free;
        LObj.DisposeOf;
      end;
    end;
end;

{ Route }

constructor Route.Create(Route, Descricao: string);
begin
  FDescription := Descricao;
  FRota := Route;
end;

procedure Route.SetDescricao(const Value: string);
begin
  FDescription := Value;
end;

procedure Route.Setrota(const Value: string);
begin
  FRota := Value;
end;

{ SubRoute }

constructor SubRoute.Create(LStrMethod: tpRoute; SubRoute: string);
begin
  FMethod := LStrMethod;
  FSubRoute := SubRoute;
end;

constructor SubRoute.Create(LStrMethod: tpRoute; SubRoute, Descricao: string);
begin
  FMethod := LStrMethod;
  FSubRoute := SubRoute;
  FDescription := Descricao;
end;

constructor SubRoute.Create(LStrMethod: tpRoute;
  SubRoute, Descricao, Permissions: string);
begin
  FPermissions := Permissions;
  FMethod := LStrMethod;
  FSubRoute := SubRoute;
  FDescription := Descricao;
end;

destructor SubRoute.Destroy;
begin
  inherited;
end;

procedure SubRoute.SetDescricao(const Value: string);
begin
  FDescription := Value;
end;

procedure SubRoute.SetMetodo(const Value: tpRoute);
begin
  FMethod := Value;
end;

procedure SubRoute.SetParametros(const Value: TParametrosSubRota);
begin
  FParameters := Value;
end;

procedure SubRoute.Setsubrota(const Value: string);
begin
  FSubRoute := Value;
end;

{ THorseAnnotation }

function THorseAnnotation.Execute: string;
begin
  Result := FContent;
end;

procedure THorseAnnotation.Send(Content: String);
begin
  FContent := Content;
end;

procedure THorseAnnotation.Send(AObject: TObject);
begin
  FContent := Tjson.ObjectToJsonString(AObject);
  AObject.DisposeOf;
end;

procedure THorseAnnotation.Send(AInterface: IInterface);
begin
  FContent := Tjson.ObjectToJsonString(AInterface as TObject);
end;

{ TSingleton<T> }

class function TSingleton<T>.GetInstance: T;
begin
  if not Assigned(FInstance) then
    FInstance := T.Create;

  Result := FInstance;
end;

{ TRegisterMethods }

constructor TRegisterMethods.Create;
begin
  FRegisterMethods := TDictionary<string, string>.Create;
end;

destructor TRegisterMethods.Destroy;
begin
  FRegisterMethods.DisposeOf;
  inherited;
end;

class function TRegisterMethods.FormatRoute(aRoute: string): String;
begin
  Result := aRoute;
end;

procedure TRegisterMethods.SetRegisterMethods(const Value
  : TDictionary<string, string>);
begin
  FRegisterMethods := Value;
end;

initialization
  SingletonRegisterMethods:=TSingleton<TRegisterMethods>.GetInstance;
Finalization
  SingletonRegisterMethods.DisposeOf;
end.
