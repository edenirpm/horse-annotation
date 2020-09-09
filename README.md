# horse-annotation
Annotation for Horse


# How to use

program prjHorse;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  Horse,
  Horse.Annotation in 'modules\annotation\horse.annotation.pas',
  testeImplementacao in 'modules\annotation\testeImplementacao.pas';

begin
  THorse.Get('/ping',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    begin
      Res.Send('pong');
    end);
  Thorse.Use(TAnnotation.use<TTeste>);
  THorse.Listen(9000);
end.

# Annotation in TTeste class
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
