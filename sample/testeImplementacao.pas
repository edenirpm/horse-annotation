unit testeImplementacao;

interface

uses
  horse.annotation;
Type
  [Route('/app', 'uma descrição qualquer')]
  TTEste = class(THorseAnnotation)

    [SubRoute(rGET, '/teste', 'Descrição qualquer da subRota')]
    procedure getResult;

    [SubRoute(rGET, '/teste2', 'Descrição qualquer da subRota')]
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
