unit frmHome_u;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, pngimage, jpeg, dmLittleLinqData_u, clsUser_u,
  Buttons, StrUtils;

type
  TfrmHome = class(TForm)
    pnlLogin: TPanel;
    lblLoginHeading: TLabel;
    lblUsername: TLabel;
    lblPassword: TLabel;
    edtUsername: TEdit;
    edtPassword: TEdit;
    imgAdmin: TImage;
    imgPassword: TImage;
    btnLogin: TButton;
    pnlLandingPage: TPanel;
    pnlLearnerManagement: TPanel;
    pnlInformation: TPanel;
    pnlParentManagement: TPanel;
    pnlNavigation: TPanel;
    imgIcon: TImage;
    lblHeading: TLabel;
    lblUser: TLabel;
    lblAdmin: TLabel;
    btnLogs: TButton;
    btnUserSettings: TButton;
    btnLogout: TButton;
    btnClose: TBitBtn;
    imgParentIcon: TImage;
    btnParentManagement: TButton;
    imgLeanerIcon: TImage;
    btnLearnerManagement: TButton;
    // Custom functions & procedures
    procedure LoginUser;
    procedure LogoutUser;
    function populateUserObject(sUser: String): TUser;

    procedure imgPasswordClick(Sender: TObject);
    procedure edtUsernameChange(Sender: TObject);
    procedure btnLogoutClick(Sender: TObject);
    procedure btnLoginClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure btnUserSettingsClick(Sender: TObject);
    procedure btnLearnerManagementClick(Sender: TObject);
    procedure btnParentManagementClick(Sender: TObject);
    procedure btnLogsClick(Sender: TObject);
  private
    { Private declarations }
    sUsername: String;
    isAdmin: Boolean;
  public
    { Public declarations }
    objUser: TUser;
  end;

var
  frmHome: TfrmHome;

implementation
  uses frmUserSettings_u, frmLearnerManagement_u, frmParentManagement_u, frmLogsViewer_u;

{$R *.dfm}

procedure TfrmHome.btnLearnerManagementClick(Sender: TObject);
begin
  frmLearnerManagement.Show;
  Self.Hide;
end;

procedure TfrmHome.btnLoginClick(Sender: TObject);
var
  sPassword: String;
begin
  // Login Logic
  sUsername := edtUsername.Text;
  sPassword := edtPassword.Text;

  // Existance check and length check
  if (sUsername = '') then begin
    ShowMessage('Please enter your username.');
    Exit;
  end;
  if (sPassword = '') then begin
    ShowMessage('Please enter your password.');
    Exit;
  end else begin
    if not(Length(sPassword) >= 8) or not(Length(sPassword) <= 32) then begin
      ShowMessage('Password Length is not correct.');
      Exit;
    end;
  end;

  // Querying and validating username and password
  with dmLittleLinqData do begin
    qryUsers.SQL.Text := 'SELECT username, password, admin FROM tblusers WHERE username = :usernameParam';
    qryUsers.Parameters.ParamByName('usernameParam').Value := sUsername;
    qryUsers.Open;

    if not qryUsers.IsEmpty then begin
      if not(qryUsers.FieldByName('password').AsString = sPassword) then begin
        ShowMessage('Incorrect Password.');
      end else begin
        // Logging user in
        isAdmin := qryUsers.FieldByName('admin').AsBoolean;
        Self.LoginUser;
      end;
    end else begin
      ShowMessage('Username not found.');
    end;
    qryUsers.Close;
  end;

end;

procedure TfrmHome.btnLogoutClick(Sender: TObject);
begin
  // Confirmation
  case MessageDlg('Are you sure you would like to logout?', mtWarning, [mbYes, mbNo], 1) of
    mrYes:
      begin
        // Run logout procedure
        Self.LogoutUser;
      end;
    mrNo:
      begin
        Exit;
      end;
  end;
end;

procedure TfrmHome.btnLogsClick(Sender: TObject);
begin
  frmLogsViewer.Show;
  Self.Hide;
end;

procedure TfrmHome.btnParentManagementClick(Sender: TObject);
begin
  frmParentManagement.Show;
  Self.Hide;
end;

procedure TfrmHome.btnUserSettingsClick(Sender: TObject);
begin
  frmUserSettings.Show;
  Self.Hide;
end;

procedure TfrmHome.edtUsernameChange(Sender: TObject);
var
  privileged: Boolean;
begin
  privileged := false;
  imgAdmin.Visible := false;

  // Determining whether user has admin privileges or not
  with dmLittleLinqData do begin
    qryUsers.SQL.Text :='SELECT admin FROM tblusers WHERE username = :usernameParam';
    qryUsers.Parameters.ParamByName('usernameParam').Value := edtUsername.Text;
    qryUsers.Open;

    if not qryUsers.IsEmpty then begin
      privileged := qryUsers.FieldByName('admin').AsBoolean;
    end;
  end;
  if (privileged = true) then begin
    imgAdmin.Visible := true;
  end else begin
    imgAdmin.Visible := false;
  end;
end;

procedure TfrmHome.FormActivate(Sender: TObject);
begin
  // Time saving (REMOVE)
  edtUsername.Text := 'admin';
  edtPassword.Text := 'admin@12345';
end;

procedure TfrmHome.imgPasswordClick(Sender: TObject);
begin
  // This is to show and hide the password.
  if (edtPassword.PasswordChar = #0) then begin
    imgPassword.Picture.LoadFromFile('./images/ShowPassword.png');
    edtPassword.PasswordChar := '*';
  end else begin
    imgPassword.Picture.LoadFromFile('./images/HidePassword.png');
    edtPassword.PasswordChar := #0;
  end;
end;

procedure TfrmHome.LoginUser;
begin
  // Setting form caption
  Self.Caption := 'LittleLinq | Landing Page';

  // Clearing edits for future logins
  edtUsername.Clear;
  edtPassword.Clear;
  imgAdmin.Hide;

  // Here the user object will be created
  objUser := populateUserObject(sUsername);
  if (objUser = nil) then begin
    ShowMessage('Something broke');
    Exit;
  end;

  // Setting lblUser and lblAdminIndicator
  lblUser.Caption := 'User: ' + objUser.GetUsername;
  lblAdmin.Caption := 'Admin: ' + objUser.PrivilegedAsString;

  // Hiding login panel and then showing landing panel
  pnlLogin.Hide;
  pnlLandingPage.Show;

  // Alerting user of successful login
  ShowMessage('Login Complete.');
end;

procedure TfrmHome.LogoutUser;
begin
  // Clearing object and variables
  sUsername := '';
  isAdmin := false;

  // Clearing object
  objUser.Free;

  // Hiding landing panel and showing login panel.
  pnlLandingPage.Hide;
  pnlLogin.Show;
end;

function TfrmHome.populateUserObject(sUser: String): tUser;
begin
  // Query all user data from db using username passed
  dmLittleLinqData.tblUsers.Open;
  if (dmLittleLinqData.tblUsers.Locate('username', sUser, [])) then begin
    result := tUser.Create(dmLittleLinqData.tblUsers['educatorID'], sUser, dmLittleLinqData.tblUsers['names'], dmLittleLinqData.tblUsers['email'], dmLittleLinqData.tblUsers['class'], dmLittleLinqData.tblUsers['password'], dmLittleLinqData.tblUsers['admin']);
    dmLittleLinqData.tblUsers.Close;
  end;

  // Just a quick validation check to make sure
  if not (result.GetUsername = sUser) then begin
    result := nil;
  end;
end;

end.
