unit testeImplementacao;

interface

uses
  horse.annotation;
Type
  [Route('/app', 'uma descri��o qualquer')]
  TTEste = class(THorseAnnotation)

    [SubRoute(rGET, '/teste', 'Descri��o qualquer da subRota')]
    procedure getResult;

    [SubRoute(rGET, '/teste2', 'Descri��o qualquer da subRota')]
    procedure outroteste;
  end;

implementation

uses
  System.SysUtils;

{ TTEste }

procedure TTEste.getResult;
begin
  Self.Send('implementado metodo send');
end;

procedure TTEste.outroteste;
begin
 Self.Send('outro endpoint implementado');
end;

end.
