program prjHorse;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  Horse,
  horse.annotation in 'modules\annotation\horse.annotation.pas',
  testeImplementacao in 'testeImplementacao.pas';

begin
  //Horse default create endpoint
  THorse.Get('/ping',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    begin
      Res.Send('pong');
    end);

  //Simple Class with Annotation
  Thorse.Use(TAnnotation.use<TTeste>);

  THorse.Listen(9000);
end.
