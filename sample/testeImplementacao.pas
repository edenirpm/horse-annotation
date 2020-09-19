unit testeImplementacao;

interface

uses
  horse.annotation,horse;
Type
  [Route('/app', 'uma descri��o qualquer')]
  TTEste = class(THorseAnnotation)

    [SubRoute(rGET, '/teste', 'Descri��o qualquer da subRota')]
    procedure getResult;

    [SubRoute(rGET, '/teste2', 'Descri��o qualquer da subRota')]
    procedure outroteste;

    [SubRoute(rGET, '/teste2/:id/:cpf', 'Descri��o qualquer da subRota')]
    procedure getwithid;
  end;

implementation

uses
  System.SysUtils;

{ TTEste }

procedure TTEste.getResult;
var
 LQueryStr:string;
begin
  Query.TryGetValue('id',LqueryStr);
  Self.Send('implementado metodo send '+LqueryStr);
end;

procedure TTEste.getwithid;
var
LPathStr:string;
  I: Integer;
begin
Params.TryGetValue('id',LPathStr);
LPathStr:= //Params.Count.ToString;
//THorseHackRequest(Self.getRequest).Query.Count.ToString;

Self.Send('Contain id: ' + LPathStr);
end;

procedure TTEste.outroteste;
begin
 Self.Send('outro endpoint implementado');
end;

end.
