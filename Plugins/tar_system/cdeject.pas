unit cdeject;

interface

uses Windows, Regstr, mmsystem;

type
  tCDStat=(notCD, cdOPen, cdClose);
  tAct=(aOpen, aClose, aInvert);

var
  aDrives: array [0..25] of tCDStat;
  firstCD: char;

const
  AppName='Software\TypeAndRun\tar_system\';
  ar: array[tCDStat] of TAct =(aclose, aClose, Aopen);

procedure InitDrivesStat;
procedure SetDrvState;
procedure OpenCloseCD(CD:Char;Action:tAct=aopen);

implementation

function GetCDID(cd: char): MCIDEVICEID;
var
  s:string;
  OpenParm: TMCI_Open_Parms;
begin
  s:=cd+':\';
  FillChar(OpenParm,sizeof(OpenParm),0);
  with openParm do
  begin
    lpstrDeviceType:='cdaudio';
    lpstrElementName:=Pchar(s);
  end;
  mciSendCommand(0, mci_Open, MCI_NOTIFY or MCI_OPEN_TYPE or MCI_OPEN_ELEMENT, Longint(@OpenParm));
  result:=OpenParm.wDeviceID;
end;

function GetInvertState(i: integer): boolean;
var
  ahKey:HKEY;
  res:DWORD;
  d:dword;
  c:char;
begin
  result:=aDrives[i]=cdClose;
  if RegCreateKeyEx(HKEY_CURRENT_USER,AppName,0,nil,0,KEY_ALL_ACCESS,nil,ahKey,@res)=ERROR_SUCCESS then
  begin
    c:=char(i+ord('a'));
    if res=REG_Opened_Existing_Key then
    begin
      res:=sizeof(d);
      if RegQueryValueEx(ahKey,@c,nil,nil,@D,@res)=ERROR_SUCCESS then
        if ((getTickCount-d) div 1000) < 10 then
          result:=not result;
    end;
    d:=GetTickCount;
    if result then
      RegDeleteValue(ahKey, @c)
    else
      RegSetValueEx(ahKey, @c, 0, REG_DWORD, @d, sizeof(d));
    RegCloseKey(ahKey);
  end;
end;

// ����������, ������ �� ����
function IsCDOpen(cd: char): boolean;
var
  StatusParms: TMCI_Status_Parms;
  ID: MCIDEVICEID;
begin
  result:=false;
  ID:=GetCDID(cd);
  if ID<>0 then begin
    fillChar(StatusParms,Sizeof(StatusParms),0);
    StatusParms.dwItem:=MCI_STATUS_MODE;
    mciSendCommand(ID, MCI_STATUS,MCI_WAIT or MCI_STATUS_Item,longint(@STATUSPArms));
    //while 0<>mciSendCommand(ID, MCI_STATUS,MCI_WAIT or MCI_STATUS_Item,longint(@STATUSPArms)) do;
    result:=StatusParms.dwReturn = MCI_MODE_OPEN;
    mciSendCommand(ID,MCI_CLOSE,MCI_NOTIFY,0);
  end;
end;

// ������������� ������
procedure InitDrivesStat;
var
	ds:set of 0..25;
  i: 0..25;
  c:char;
const
  ar:array [boolean] of tCDStat=(cdClose,cdOpen);
begin
  dword(ds):=GetLogicalDrives;
  for i:=0 to 25 do begin
		if i in ds then begin
			aDrives[i]:=notCD;
      c:=chr(i+$41);
      if GetDriveType(Pchar(c+':\')) = DRIVE_CDROM then begin
        aDrives[i]:=ar[IsCDOpen(c) and getInvertState(i)];
        if firstcd=#0 then firstcd:=upcase(c);
      end;
    end;
  end;
end;

procedure SetDrvState;
var
  ahKey:HKEY;
  res:DWORD;
  d:dword;
  c:char;
  i:integer;
begin
  if RegCreateKeyEx(HKEY_CURRENT_USER,AppName,0,nil,0,KEY_ALL_ACCESS,nil,ahKey,@res)=ERROR_SUCCESS then
  begin
    for i:=0 to 25 do
    begin
      c:=char(i+ord('a'));
      case aDrives[i] of
        cdClose :  RegDeleteValue(ahKey,@c);
        cdOPen:  begin
                    d:=GetTickCount;
                    RegSetValueEx(ahKey,@c,0,REG_DWORD,@d,sizeof(d));
                  end;
      end;
    end;
    RegCloseKey(ahKey);
  end;
end;

procedure OpenCloseCD(CD: Char; Action: tAct=aopen);
var
  open: boolean;
  i: integer;
  ID: MCIDEVICEID;
const
  ar: array [boolean] of DWORD = (MCI_SET_DOOR_CLOSED,MCI_SET_DOOR_OPEN);
  ar2: array [boolean] of TCDStat =(cdClose,cdOPen);
begin
  i:=byte(upcase(cd))-ord('A');
  ID:=GetCDID(cd);
  if ID<>0 then
  begin
    if Action=aInvert then
      open:=aDrives[i]=cdClose
    else
      open:=Action=aOpen;
    if mciSendCommand(ID,MCI_SET,ar[open],0)=0 then
       aDrives[i]:=ar2[open];
    mciSendCommand(ID,MCI_CLOSE,MCI_WAIT,0);
  end;
end;

end.
