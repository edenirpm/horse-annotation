unit Horse.Annotation;

interface

uses
  System.JSON, System.Classes, Rest.JSON,
  System.Rtti, System.generics.collections,
  Horse, System.TypInfo;

type
  tpRoute = (rGET, rPOST, rPUT, rDELETE, rPATCH);

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
    class function EncodeKeyRoute(aRoute: string; metodo: tpRoute): String;
    class function DecodeKeyRoute(RotaExecutada: string;
      MethodType: tpRoute): string;
  end;

  IAnnotation = interface
    ['{458FBFE8-FDC1-413A-80B1-DE27B5428507}']
    procedure SetParams(const Value: TDictionary<String, String>);
    procedure SetQuery(const Value: TDictionary<String, String>);
    function getParams: TDictionary<String, String>;
    function getQuery: TDictionary<String, String>;
    function getRequest: THorseRequest;
    procedure setRequest(aReq: THorseRequest);
    property Query: TDictionary<String, String> read getQuery write SetQuery;
    property Params: TDictionary<String, String> read getParams write SetParams;
    procedure Send(Content: String); overload;
    procedure Send(AObject: TObject); overload;
    procedure Send(AInterface: IInterface); overload;
    function Execute: string;
  end;

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
    constructor Create(LStrMethod: tpRoute;
      SubRoute, Descricao: string); overload;
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
    FParams: TDictionary<String, String>;
    FQuery: TDictionary<String, String>;
    FReq: THorseRequest;
    FRes: THorseResponse;
    procedure SetParams(const Value: TDictionary<String, String>);
    procedure SetQuery(const Value: TDictionary<String, String>);
    function getParams: TDictionary<String, String>;
    function getQuery: TDictionary<String, String>;
  public

    procedure Send(Content: String); overload;
    procedure Send(AObject: TObject); overload;
    procedure Send(AInterface: IInterface); overload;
    function Execute: string;
    procedure setRequest(aReq: THorseRequest);
    function getRequest: THorseRequest;
    property Query: TDictionary<String, String> read getQuery write SetQuery;
    property Params: TDictionary<String, String> read getParams write SetParams;
  end;

  TAnnotation = class
  class var
    internalUrl: string;
    class procedure RegisterApiManager(apiManagerUrl: string;
      JObj: TJsonObject);
    class function Use<T: constructor, class>: THorseCallback;
    class function UseAutoRegistry<T: constructor, class>(RegisterUrl: string)
      : THorseCallback;
    class function RegisterService<T: constructor, class>(AutoRegisterUrl
      : string): THorseCallback;
    class function ExecAnnotation<T: constructor, class>
      (out Callback: THorseCallback): THorseCallback;
  end;

var
  SingletonRegisterMethods: TRegisterMethods;

implementation

uses
  System.SysUtils, System.Net.HTTPClient, System.Net.URLClient;

{ TAnnotation }

class function TAnnotation.ExecAnnotation<T>(out Callback: THorseCallback)
  : THorseCallback;
var
  LTypeCtx: TRttiType;
  LCtx: TRttiContext;
  LAtr: TCustomAttribute;
  LStrMethod: string;
  LObj: T;
  LAnnotation: IAnnotation;
  MethodRota: tpRoute;
begin
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
          LStrMethod := TSingleton<TRegisterMethods>.GetInstance.
            RegisterMethods.Items
            [TRegisterMethods.DecodeKeyRoute(THorseHackRequest(Req)
            .GetWebRequest.PathInfo, MethodRota)];
          IAnnotation(LObj).setRequest(Req);
          IAnnotation(LObj).Query := Req.Query;
          IAnnotation(LObj).Params := Req.Params;

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
  Callback := Result;
end;

class procedure TAnnotation.RegisterApiManager(apiManagerUrl: string;
  JObj: TJsonObject);
var
  LHTTPClient: THTTPClient;
  LHTTPRequest: IHTTPRequest;
  LHTTPResponse: IHTTPResponse;
  LURL, LRoute, LClass, LSubRoute: string;
begin
  LRoute := JObj.GetValue<string>('Route');
  LClass := JObj.GetValue<string>('ClassName');
  LSubRoute := JObj.GetValue<string>('SubRoute');
  LURL := apiManagerUrl + LRoute + '/' + LClass + LSubRoute + '.json';
  LHTTPClient := THTTPClient.Create;
  LHTTPRequest := LHTTPClient.getRequest(sHTTPMethodPut, TURI.Create(LURL));
  LHTTPRequest.Accept := 'application/json';
  LHTTPRequest.AddHeader('Content-Type', 'application/json');
  LHTTPRequest.SourceStream := TStringStream.Create(JObj.ToJson);
  try
    LHTTPResponse := LHTTPClient.Execute(LHTTPRequest);
    // LStringJsonResponse :=LHTTPResponse.ContentAsString(TEncoding.UTF8);
  finally
    LHTTPClient.DisposeOf;
  end;

end;

class function TAnnotation.RegisterService<T>(AutoRegisterUrl: string)
  : THorseCallback;
var
  LTypeCtx: TRttiType;
  LCtx: TRttiContext;
  LAtr, LAtr2: TCustomAttribute;
  LMethod: TRttiMethod;
  LRouteType: tpRoute;
  LStrRoute, LStrSubRoute, LSubRouteClean, LStrMethod, LStrDescription,
    _SubRota, LStrRouteDescription: string;
  LAnnotation: IAnnotation;
  LJObj: TJsonObject;
  LClass: TClass;

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
      LStrRouteDescription := (Route(LAtr).Descricao);
    end;
    for LMethod in LTypeCtx.GetMethods do
    begin
      for LAtr2 in LMethod.GetAttributes do
      begin
        LStrSubRoute := LStrRoute + (LAtr2 as SubRoute).SubRoute;
        LStrDescription := (LAtr2 as SubRoute).Descricao;
        LSubRouteClean := (LAtr2 as SubRoute).SubRoute;

        TSingleton<TRegisterMethods>.GetInstance.RegisterMethods.Add
          (TRegisterMethods.EncodeKeyRoute(LStrSubRoute,
          (LAtr2 as SubRoute).LStrMethod), LMethod.name);
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

        try
          LClass := T;
          LJObj := TJsonObject.Create;
          LJObj.addPair('Route', LStrRoute).addPair('ClassName',
            LClass.ClassName).addPair('Method', LMethod.name)
            .addPair('Implementation', LMethod.ToString)
            .addPair('Service', LStrRouteDescription)
            .addPair('SubRoute', LSubRouteClean).addPair('Endpoint',
            LStrSubRoute).addPair('Description', LStrDescription);
          if AutoRegisterUrl <> EmptyStr then
            RegisterApiManager(AutoRegisterUrl, LJObj);
        finally
          LJObj.DisposeOf;
        end;
      end;
    end;
  finally
    LCtx.Free;
    LTypeCtx.DisposeOf;
  end;

end;

class function TAnnotation.Use<T>: THorseCallback;
begin
  Result := procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    begin

    end;
  RegisterService<T>(EmptyStr);
  ExecAnnotation<T>(Result);
end;

class function TAnnotation.UseAutoRegistry<T>(RegisterUrl: string)
  : THorseCallback;
begin
  Result := procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    begin

    end;
  RegisterService<T>(RegisterUrl);
  ExecAnnotation<T>(Result);
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

function THorseAnnotation.getParams: TDictionary<String, String>;
begin
  Result := FParams;
end;

function THorseAnnotation.getQuery: TDictionary<String, String>;
begin
  Result := FQuery;
end;

function THorseAnnotation.getRequest: THorseRequest;
begin
  Result := FReq;
end;

procedure THorseAnnotation.Send(AInterface: IInterface);
begin
  FContent := Tjson.ObjectToJsonString(AInterface as TObject);
end;

procedure THorseAnnotation.SetParams(const Value: TDictionary<String, String>);
begin
  FParams := Value;
end;

procedure THorseAnnotation.SetQuery(const Value: TDictionary<String, String>);
begin
  FQuery := Value;
end;

procedure THorseAnnotation.setRequest(aReq: THorseRequest);
begin
  FReq := aReq;
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

class function TRegisterMethods.DecodeKeyRoute(RotaExecutada: string;
  MethodType: tpRoute): string;
var
  Lpos: Integer;
  Parte: TStringList;
begin
  Result := '';

  if RotaExecutada.Trim = '' then
    exit;

  if not TSingleton<TRegisterMethods>.GetInstance.RegisterMethods.ContainsKey
    (RotaExecutada + '[' + GetEnumName(TypeInfo(tpRoute), Integer(MethodType))
    + ']') then
  begin
    Parte := TStringList.Create;
    try
      Parte.Clear;
      Parte.Delimiter := '/';
      Parte.DelimitedText := RotaExecutada;
      Lpos := Parte[Parte.Count - 1].Length + 1;
      Result := Copy(RotaExecutada, 0, RotaExecutada.Length - Lpos);
      Result := Self.DecodeKeyRoute(Result, MethodType);
    finally
      Parte.Free;
    end;
  end
  else
    Result := RotaExecutada + '[' + GetEnumName(TypeInfo(tpRoute),
      Integer(MethodType)) + ']';
end;

class function TRegisterMethods.EncodeKeyRoute(aRoute: string;
  metodo: tpRoute): String;
var
  LPosSeparator: Integer;
  LRoute: string;
begin

  LPosSeparator := Pos(':', aRoute);
  if LPosSeparator > 0 then
    LRoute := Copy(aRoute, 0, LPosSeparator - 2)
  else
    LRoute := aRoute;

  LRoute := LRoute + '[' + GetEnumName(TypeInfo(tpRoute),
    Integer(metodo)) + ']';

  Result := LRoute;
end;

procedure TRegisterMethods.SetRegisterMethods(const Value
  : TDictionary<string, string>);
begin
  FRegisterMethods := Value;
end;

initialization

SingletonRegisterMethods := TSingleton<TRegisterMethods>.GetInstance;

Finalization

SingletonRegisterMethods.DisposeOf;

end.
