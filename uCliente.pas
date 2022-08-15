unit uCliente;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, IdBaseComponent, IdComponent,
  IdTCPConnection, IdTCPClient, uLkJSON, IdHTTP, OleCtrls, SHDocVw, xmldom,
  XMLIntf, msxmldom, XMLDoc, Buttons, IdExplicitTLSClientServerBase,
  IdMessageClient, IdSMTPBase, IdText, IdAttachmentFile, IdServerIOHandler, jpeg,
  IdFTP, IdIOHandler, IdIOHandlerSocket, IdIOHandlerStack, IdSSL, IdFTPList,
  IdAllFTPListParsers, Wininet, IniFiles, IdSMTP, IdMessage, IdSSLOpenSSL;

type
  TfrmCliente = class(TForm)
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    GroupBox1: TGroupBox;
    Label4: TLabel;
    Label13: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    edNumero: TEdit;
    edComplemento: TEdit;
    edBairro: TEdit;
    Label12: TLabel;
    edCEP: TEdit;
    Label7: TLabel;
    edCidade: TEdit;
    Label8: TLabel;
    edUF: TEdit;
    Label9: TLabel;
    edPais: TEdit;
    GroupBox3: TGroupBox;
    Label1: TLabel;
    edNome: TEdit;
    Label2: TLabel;
    edRG: TEdit;
    Label3: TLabel;
    edCPF: TEdit;
    Label11: TLabel;
    edEmail: TEdit;
    Label10: TLabel;
    edTelefone: TEdit;
    IdHTTP: TIdHTTP;
    edLogradouro: TEdit;
    MemoJSon: TMemo;
    Label14: TLabel;
    XMLGerar: TXMLDocument;
    btnFechar: TBitBtn;
    GroupBox2: TGroupBox;
    Label20: TLabel;
    edSmtp: TEdit;
    btnEMail: TBitBtn;
    Label16: TLabel;
    edUsuario: TEdit;
    Label17: TLabel;
    edSenha: TEdit;
    Label15: TLabel;
    edDDD: TEdit;
    Label18: TLabel;
    edPorta: TEdit;
    procedure edCEPExit(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure btnFecharClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnEMailClick(Sender: TObject);
  private
    { Private declarations }
    function RemoveCaractere(s: String): String;
    procedure ConverteJSON(sParam: String);
    procedure EnviaEmail();
  public
    { Public declarations }
  end;

var
  frmCliente: TfrmCliente;

implementation

uses IdURI, DateUtils;

{$R *.dfm}

// Função para remover Caracteres Especiais
function TfrmCliente.RemoveCaractere(s: String): String;
var
  i: Integer;
const
  sChr = '.-/,;';
begin
  Result := '';
  for i := 1 to Length(s) do
  begin
    if Pos(s[i], sChr) = 0 then
      Result := Result + s[i];
  end;
end;

procedure TfrmCliente.edCEPExit(Sender: TObject);
var
  sCEP: String;

  function ValidaCEP(s: String): Boolean;
  var
    i: Integer;
  const
    n = '0123456789';
  begin
    Result := True;
    for i := 1 to Length(Trim(s)) do
    begin
      if Pos(s[i], n) = 0 then
      begin
        Result := False;
        Break;
      end;
    end;
  end;

begin
  sCEP := Trim(edCEP.Text);
  sCEP := RemoveCaractere(sCEP);

  if (sCEP = '') or (Length(sCEP) <> 8) or not ValidaCEP(sCEP) then
    ShowMessage('Favor informar um CEP válido!')
  else
    ConverteJSON(sCEP);
end;

procedure TfrmCliente.ConverteJSON(sParam: String);
var
  jSonDados: TlkJSONobject;
  LHandler: TIdSSLIOHandlerSocketOpenSSL;
  sURL, sChave: String;
  slDados: TStringList;
  i: Integer;
begin
  LHandler := TIdSSLIOHandlerSocketOpenSSL.Create(nil);

  IdHTTP.IOHandler := LHandler;
  // IdHTTP.HTTPOptions := [hoForceEncodeParams];
  IdHTTP.ReadTimeout := 5000;
  IdHTTP.Request.ContentType := 'utf-16'; // 'application/json:odata=light;charset=utf-8;';
  IdHTTP.Request.CharSet := 'utf-16';

  try
    // Cria uma Lista de Strings
    slDados := TStringList.Create;
    // Busca Informações através da API dos CORREIOS
    sURL := 'http://viacep.com.br/ws/'+sParam+'/json/';
    // Retorna informações no formato JSON
    slDados.Text := idHTTP.URL.URLDecode(idHTTP.Get(sURL));
    if Pos('erro', slDados.Text) <> 0 then
    begin
      MessageDlg('CEP não encontrado!', mtInformation, [mbOK], 0);

      for i := 0 to ComponentCount -1 do
      begin
        if Components[i].ClassType = TEdit then
          if (Components[i] as TEdit).Tag = -1 then
            (Components[i] as TEdit).Text := '';
      end;

      edCEP.SetFocus;

      Exit;
    end;

    jSonDados := TlkJSON.ParseText(slDados.Text) as TlkJSONobject;
    // Apenas para visualização do JSON
    MemoJSon.Lines.Clear;
    MemoJSon.Lines.Add(slDados.Text);

    edDDD.Text         := RemoveCaractere(jSonDados.getString('ddd'));
    edLogradouro.Text  := RemoveCaractere(jSonDados.getString('logradouro'));
    edBairro.Text      := RemoveCaractere(jSonDados.getString('bairro'));
    edCidade.Text      := RemoveCaractere(jSonDados.getString('localidade'));
    edUF.Text          := RemoveCaractere(jSonDados.getString('uf'));

    sChave := IntToStr(YearOf(Now))+IntToStr(MonthOf(Now))+IntToStr(DayOf(Now));

    XMLGerar.Active := True;
    XMLGerar.AddChild('cadastroCliente').AddChild('chaveID').NodeValue := sChave;

    with XMLGerar.DocumentElement do
    begin
      // Nó das Informações Pessoais
      AddChild('informacaoPessoal');
      ChildNodes['informacao'].AddChild('nome').NodeValue := edNome.Text;
      ChildNodes['informacao'].AddChild('rg').NodeValue   := edRG.Text;
      ChildNodes['informacao'].AddChild('rg').NodeValue   := edCpf.Text;

      // Nó das Informações do Endereço
      AddChild('endereco');
      ChildNodes['endereco'].AddChild('email').NodeValue := edEmail.Text;
      ChildNodes['endereco'].AddChild('ddd').NodeValue := edDDD.Text;
      ChildNodes['endereco'].AddChild('telefone').NodeValue := edTelefone.Text;
      ChildNodes['endereco'].AddChild('logradouro').NodeValue := edLogradouro.Text;
      ChildNodes['endereco'].AddChild('numero').NodeValue := edNumero.Text;
      ChildNodes['endereco'].AddChild('complemento').NodeValue := edComplemento.Text;
      ChildNodes['endereco'].AddChild('bairro').NodeValue := edBairro.Text;
      ChildNodes['endereco'].AddChild('cep').NodeValue := edCEP.Text;
      ChildNodes['endereco'].AddChild('cidade').NodeValue := edCidade.Text;
      ChildNodes['endereco'].AddChild('uf').NodeValue := edUF.Text;
      ChildNodes['endereco'].AddChild('pais').NodeValue := edPais.Text;
    end;

    XMLGerar.SaveToFile(ExtractFileDir(Application.ExeName)+'\XMLCadastro_'+edCEP.Text+'.xml');
  finally
    XMLGerar.Active := False;
  end;
end;

procedure TfrmCliente.EnviaEmail();
var
  sFileName, sPath: String;
  bAttachmentFile: TIdAttachmentFile;
  SSLSocket: TIdSSLIOHandlerSocketOpenSSL;
  IdSMTP: TIdSMTP;
  Email: TIdMessage;
begin
  // Instanciação dos Objetos
  IdSMTP := TIdSMTP.Create(Self);
  Email  := TIdMessage.Create(Self);
  SSLSocket := TIdSSLIOHandlerSocketOpenSSL.Create(nil);

  try
    // Configurações do Componente de Protocolo
    SSLSocket.SSLOptions.Method := sslvSSLv23;
    SSLSocket.SSLOptions.VerifyMode := [];
    SSLSocket.SSLOptions.VerifyDepth := 0;

    // Configurações da Conexão com o Servidor de Email
    IdSMTP.IOHandler := SSLSocket;
    IdSMTP.UseTLS    := utNoTLSSupport;
    IdSMTP.Host      := edSmtp.Text;
    IdSMTP.Port      := StrToIntDef(edPorta.Text, 25);
    IdSMTP.Username  := edUsuario.Text;
    IdSMTP.Password  := edSenha.Text;
    IdSMTP.AuthType  := satDefault;

    // Configurações do Email
    Email.Recipients.EMailAddresses := edEmail.Text;
    Email.MessageParts.Clear;
    Email.Encoding     := MeMIME;
    Email.ContentType := 'multipart/related';
    Email.From.Address := edUsuario.Text;
    Email.From.Name    := edNome.Text;
    Email.Subject      := 'Arquivo XML Gerado pelo Cadastro do Cliente';
    Email.CharSet      := 'iso-8859-1';

    // Corpo do Email
    with Email do
    begin
      Body.Clear;
      Body.Add('Ao Setor de Desenvolvimento,');
      Body.Add('');
      Body.Add('Este Email foi enviado automaticamente pelo Sistema de Cadastro.');
      Body.Add('');
      Body.Add('Atenciosamente,');
      Body.Add('');
      Body.Add('Osvaldo Monteiro Costa');
      Body.Add('Desenvolvedor de Sistemas');
      Body.Add('(71) 99195-2541');
      Body.Add('');
      Body.Add('');
      Body.Add('Mensagem de confirmação enviada pelo aplicativo de cadastro de clientes.');
    end;

    // Busca o Arquivo XML gerado
    sFileName := ExtractFileDir(Application.ExeName)+'\XMLCadastro_'+edCEP.Text+'.xml';

    // Configurações do Envio de Arquivo Anexado
    bAttachmentFile := TIdAttachmentFile.Create(Email.MessageParts, sFileName);
    bAttachmentFile.ContentType        := 'xml';
    bAttachmentFile.FileIsTempFile     := True;
    bAttachmentFile.ContentDisposition := 'inline';
    bAttachmentFile.ExtraHeaders.Values['content-id'] := sFileName;
    bAttachmentFile.DisplayName := sFileName;

    // Verifica a existencia do Arquivo
    if FileExists(sFileName) then
    begin
      try
        // Estabelece a Conexão com o Servidor de Email
        idSMTP.Connect();
        if idSMTP.Connected then
        begin
          // Envia o Email
          idSMTP.Send(Email);
          // Desconecta o Servidor
          idSMTP.Disconnect();

          MessageDlg('Email enviado com sucesso!', mtInformation, [mbOK], 0);
        end;
      except
        MessageDlg('Falha na Conexão com o Servidor de Email.', mtError, [mbOK], 0);
      end;
    end
    else
      MessageDlg('Arquivo XML não encontrado!', mtError, [mbOK], 0);
  finally
    IdSMTP.Free;
    Email.Free;
    SSLSocket.Free;
  end;
end;

procedure TfrmCliente.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_RETURN then
    Perform(WM_NEXTDLGCTL,0,0);
end;

procedure TfrmCliente.btnFecharClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmCliente.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caFree;
end;

procedure TfrmCliente.btnEMailClick(Sender: TObject);
begin
  try
    if (edSmtp.Text = '') then
      MessageDlg('Favor configurar o SMTP!', mtInformation, [mbOK], 0)
    else if (edEmail.Text = '') then
      MessageDlg('Favor configurar o Email!', mtInformation, [mbOK], 0)
    else if (edSenha.Text = '') then
      MessageDlg('Favor configurar a Senha!', mtInformation, [mbOK], 0)
    else
      EnviaEmail();
  except
    MessageDlg('Erro ao tentar enviar Email.', mtError, [mbOK], 0);
  end;
end;


end.


