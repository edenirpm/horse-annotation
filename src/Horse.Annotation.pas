unit Horse.Annotation;

interface

uses
  System.JSON, System.Classes, Rest.JSON,
  System.Rtti, System.generics.collections,
  Horse;

type

  TSingleton<T: constructor, class> = class
  strict private
    class var FInstancia: T;
  public
    class function getInstance: T;
  end;

  TRegisterMethods = class
  private
    FRegisterMethods: TDictionary<string, string>;
    procedure SetRegisterMethods(const Value: TDictionary<string, string>);
  public
    constructor create;
    destructor destroy; override;
    property RegisterMethods: TDictionary<string, string> read FRegisterMethods
      write SetRegisterMethods;
    class function formatRoute(aRoute: string): String;
  end;

  IAnnotation = interface
    ['{458FBFE8-FDC1-413A-80B1-DE27B5428507}']
    procedure Send(Content: String); overload;
    procedure Send(aObject: TObject); overload;
    procedure Send(aInterface: iInterface); overload;
    function execute: string;
  end;

  tpRota = (rGET, rPOST, rPUT, rDELETE, rPATCH);
  TParametrosSubRota = array of string;

  SubRota = class(TCustomAttribute)
  private
    Fsubrota: string;
    FMetodo: tpRota;
    FParametros: TParametrosSubRota;
    FDescricao: string;
    FPermissions: string;
    procedure Setsubrota(const Value: string);
    procedure setMetodo(const Value: tpRota);
    procedure SetParametros(const Value: TParametrosSubRota);
    procedure SetDescricao(const Value: string);

  public
    constructor create(Metodo: tpRota; SubRota: string); overload;
    constructor create(Metodo: tpRota; SubRota, Descricao: string); overload;
    constructor create(Metodo: tpRota; SubRota, Descricao: string;
      Permissions: string); overload;
    property Permissions: string read FPermissions write FPermissions;
    property SubRota: string read Fsubrota write Setsubrota;
    property Metodo: tpRota read FMetodo write setMetodo;
    property Parametros: TParametrosSubRota read FParametros
      write SetParametros;
    property Descricao: string read FDescricao write SetDescricao;
    destructor destroy; override;
  end;

  Rota = class(TCustomAttribute)
  private
    FRota: string;
    FMetodo: tpRota;
    FDescricao: string;
    procedure Setrota(const Value: string);
    procedure SetDescricao(const Value: string);
  public
    constructor create(Rota, Descricao: string);
    property Rota: string read FRota write Setrota;
    property Descricao: string read FDescricao write SetDescricao;
  end;

  THorseAnnotation = class(TInterfacedObject, IAnnotation)
  private
    FContent: string;
  public
    procedure Send(Content: String); overload;
    procedure Send(aObject: TObject); overload;
    procedure Send(aInterface: iInterface); overload;
    function execute: string;
  end;

  TAnnotation = class
    class function use<T: constructor, class>: THorseCallback;
    class function registerService<T: constructor, class>: THorseCallback;
  end;

implementation

uses
  System.SysUtils;

{ TAnnotation }

class function TAnnotation.registerService<T>: THorseCallback;
var
  TpCtx: TRttiType;
  CtxTp: TRttiContext;
  atr, atr2: TCustomAttribute;
  m: TRttiMethod;
  tipoRota: tpRota;
  R, S: string;
  annotation: IAnnotation;
  obj: T;
  Metodo: string;
begin
  result := procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    begin

    end;
  CtxTp := TRttiContext.create;
  TpCtx := CtxTp.GetType(T.ClassInfo);
  try
    for atr in TpCtx.GetAttributes do
    begin
      R := (Rota(atr).Rota);
    end;
    for m in TpCtx.GetMethods do
    begin
      for atr2 in m.GetAttributes do
      begin
        S := R + (atr2 as SubRota).SubRota;
        TSingleton<TRegisterMethods>.getInstance.RegisterMethods.Add
          (TRegisterMethods.formatRoute(S), m.name);
        case (atr2 as SubRota).Metodo of
          rGET:
            THorse.Get(S, result);
          rPOST:
            THorse.Get(S, result);
          rPUT:
            THorse.Get(S, result);
          rDELETE:
            THorse.Get(S, result);
        end;
      end;
    end;
  finally
    CtxTp.Free;
    TpCtx.DisposeOf;
  end;

end;

class function TAnnotation.use<T>: THorseCallback;
var
  Tp: TRttiType;
  Ctx: TRttiContext;
  atr: TCustomAttribute;
  Metodo: string;
  obj: T;
  annotation: IAnnotation;
begin
  registerService<T>;
  result := procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    begin
    end;
  result := procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    begin
      obj := T.create;
      Ctx := TRttiContext.create;
      Tp := Ctx.GetType(obj.ClassInfo);
      try
        try
          Metodo := TSingleton<TRegisterMethods>.getInstance.RegisterMethods.
            Items[THorseHackRequest(Req).GetWebRequest.PathInfo];
          Tp.GetMethod(Metodo).Invoke(obj, []);
          Res.Send(IAnnotation(obj).execute);
        except
          exit;
        end;
      finally
        Ctx.Free;
        obj.DisposeOf;
      end;
    end;
end;

{ Rota }

constructor Rota.create(Rota, Descricao: string);
begin
  FDescricao := Descricao;
  FRota := Rota;
end;

procedure Rota.SetDescricao(const Value: string);
begin
  FDescricao := Value;
end;

procedure Rota.Setrota(const Value: string);
begin
  FRota := Value;
end;

{ SubRota }

constructor SubRota.create(Metodo: tpRota; SubRota: string);
begin
  FMetodo := Metodo;
  Fsubrota := SubRota;
end;

constructor SubRota.create(Metodo: tpRota; SubRota, Descricao: string);
begin
  FMetodo := Metodo;
  Fsubrota := SubRota;
  FDescricao := Descricao;
end;

constructor SubRota.create(Metodo: tpRota;
  SubRota, Descricao, Permissions: string);
begin
  FPermissions := Permissions;
  FMetodo := Metodo;
  Fsubrota := SubRota;
  FDescricao := Descricao;
end;

destructor SubRota.destroy;
begin
  inherited;
end;

procedure SubRota.SetDescricao(const Value: string);
begin
  FDescricao := Value;
end;

procedure SubRota.setMetodo(const Value: tpRota);
begin
  FMetodo := Value;
end;

procedure SubRota.SetParametros(const Value: TParametrosSubRota);
begin
  FParametros := Value;
end;

procedure SubRota.Setsubrota(const Value: string);
begin
  Fsubrota := Value;
end;

{ THorseAnnotation }

function THorseAnnotation.execute: string;
begin
  result := FContent;
end;

procedure THorseAnnotation.Send(Content: String);
begin
  FContent := Content;
end;

procedure THorseAnnotation.Send(aObject: TObject);
begin
  FContent := Tjson.ObjectToJsonString(aObject);
  aObject.DisposeOf;
end;

procedure THorseAnnotation.Send(aInterface: iInterface);
begin
  FContent := Tjson.ObjectToJsonString(aInterface as TObject);
end;

{ TSingleton<T> }

class function TSingleton<T>.getInstance: T;
begin
  if not Assigned(FInstancia) then
    FInstancia := T.create;

  result := FInstancia;
end;

{ TRegisterMethods }

constructor TRegisterMethods.create;
begin
  FRegisterMethods := TDictionary<string, string>.create;
end;

destructor TRegisterMethods.destroy;
begin
  FRegisterMethods.DisposeOf;
  inherited;
end;

class function TRegisterMethods.formatRoute(aRoute: string): String;
begin
  result := aRoute;
end;

procedure TRegisterMethods.SetRegisterMethods(const Value
  : TDictionary<string, string>);
begin
  FRegisterMethods := Value;
end;

end.
