unit ANDKMoveClassUnit;

interface

uses Sysutils, Registry, windows, classes;


function dirNDK(): Integer;
function findNDKInReg(RootKey: HKEY; Path: string): integer;
function isAndroidNDKPath(Path: string): Boolean;
function getNDKPath(RootKey: HKEY; Path: string): string;
procedure FindFileInPath(Path: string; List: TStrings);
procedure setRegValue(RootKey: HKEY; Path: string; Name: string; Value: string);
procedure WriteLine();
procedure setDestPathName(destPath: string);
function CheckDestPathName(): Boolean;

function InputText(Caption: string): string;
procedure Print(str: string);


implementation

var DestNDKPath: string;

procedure Print(str: string);
begin
    Writeln(str);
end;



function InputText(Caption: string): string;
begin
    if (caption <> '') then
    begin
        print(caption);
    end;
    readln(result);
end;

function CheckDestPathName(): Boolean;
var tmpStr: string;
begin
    if (Trim(DestNDKPath) = '') then
    begin
        result := false;
        print('Please set params for dest NDK path!');
        print('Example ' + stringreplace(extractfilename(paramstr(0)), '.exe', '', [rfIgnoreCase]) + ' -d:\');
        tmpStr := InputText('Please input dest NDK path...');
        if directoryexists(tmpstr) then
        begin
            DestNDKPath := tmpstr;
            result := true;
        end;
    end
    else
        result := directoryexists(DestNDKPath);
end;

procedure setDestPathName(destPath: string);
begin
    DestNDKPath := destPath;
end;

procedure WriteLine();
begin
    Print('===============================================================');
end;

function dirNDK(): Integer;
var Reg: TRegistry;
    ECode: integer;
    tmpStr: string;
begin
    try
        if (CheckDestPathName()) then
        begin
            WriteLine();
            print('let''s go!');
            WriteLine();
            print('Start search registery table....');
            print('Search Root key HKEY_CURRENT_USER');
            WriteLine();
            result := findNDKInReg(HKEY_CURRENT_USER, '\');
            WriteLine();
            print('Search Root key HKEY_LOCAL_MACHINE');
            WriteLine();
            result := Result + findNDKInReg(HKEY_LOCAL_MACHINE, '\');
            WriteLine();
            print('Search Root key HKEY_USERS');
            WriteLine();
            result := Result + findNDKInReg(HKEY_USERS, '\');
            WriteLine();
            print('Search Root key HKEY_CURRENT_CONFIG');
            WriteLine();
            result := Result + findNDKInReg(HKEY_CURRENT_CONFIG, '\');
            WriteLine();
            print('Search completed! Leshance.com love you');
            WriteLine();
            print(format('Find Path %d ', [Result]));
        end
        else
        begin
            print('not set path');
        end;
    except
        on E: Exception do
        begin
            print('Open key fail:' + e.Message);
        end;
    end;
    InputText('Press [Enter] exit');
end;

function findNDKInReg(RootKey: HKEY; Path: string): integer;
var List: TStrings;
    i, j: integer;
    Reg: TRegistry;
    tmpStr, newDir, newFileName: string;
    moveFileList: TStringList;
begin
    Reg := TRegistry.Create(KEY_ALL_ACCESS);
    Result := 0;
    try
        List := TStringlist.Create();
        Reg.RootKey := RootKey;
        if (Reg.OpenKey(Path, false)) then
        begin
            Reg.GetKeyNames(list);
            for i := 0 to List.Count - 1 do
            begin
                if (isAndroidNDKPath(list[i])) then
                begin
                    tmpStr := getNDKPath(RootKey, Reg.CurrentPath + '\' + list[i]);
                    if (tmpStr <> '') then
                    begin
                        if (pos('c:\', tmpStr) > 0) then
                        begin
                            moveFileList := TStringList.Create;
                            FindFileInPath(tmpStr, MoveFileList);
                            for j := 0 to MoveFileList.count - 1 do
                            begin
                                if pos('c:\', lowercase(moveFileList[j])) > 0 then
                                begin
                                    if FileExists(moveFileList[i]) then
                                    begin
                                        print(moveFileList[j]);
                                        newFileName := Stringreplace(moveFileList[j], 'c:\', DestNDKPath, [rfIgnoreCase]);
                                        if not directoryExists(extractfilepath(newFileName)) then
                                        begin
                                            ForceDirectories(extractfilepath(newFileName));
                                        end;
                                        if not movefile(pchar(moveFileList[j]), pchar(newFileName)) then
                                        begin
                                            Print(Format('movefile error %d', [GetLastError]));
                                        end;
                                    end;
                                end;
                            end;
                            moveFileList.Free;
                        end;
                        newDir := stringReplace(tmpstr, 'c:\', DestNDKPath, [rfIgnoreCase]);
                        if not directoryExists(newDir) then
                        begin
                            ForceDirectories(newDir);
                        end;
                        setRegValue(RootKey, Reg.CurrentPath + '\' + list[i], 'NDK_HOME', newDir);
                        setRegValue(RootKey, Reg.CurrentPath + '\' + list[i], 'AndroidNdkDirectory', newDir);
                        inc(Result);
                    end;
                end
                else
                begin
                    Result := Result + findNDKInReg(RootKey, reg.CurrentPath + '\' + List[i]);
                end
            end;
            reg.closeKey;
        end;
        List.free;
    except
        on E: exception do
        begin
            print(E.Message);
        end;
    end;
    reg.Free;
end;

function getNDKPath(RootKey: HKEY; Path: string): string;
var List: TStrings;
    i: integer;
    Reg: TRegistry;
begin
    Reg := TRegistry.Create(KEY_ALL_ACCESS);
    Result := '';
    try
        List := TStringlist.Create();
        Reg.RootKey := RootKey;
        if (Reg.OpenKey(Path, false)) then
        begin
            if Reg.ValueExists('NDK_HOME') then
            begin
                if DirectoryExists(Reg.ReadString('NDK_HOME')) then
                begin
                    Result := Reg.ReadString('NDK_HOME');
                    print(Result);
                end;
            end;

            if Reg.ValueExists('AndroidNdkDirectory') then
            begin
                if DirectoryExists(Reg.ReadString('AndroidNdkDirectory')) then
                begin
                    Result := Reg.ReadString('AndroidNdkDirectory');
                    print(Result);
                end;
            end;
            reg.closeKey;
        end;
        List.free;
    except
        on E: exception do
        begin
            print(E.Message);
        end;
    end;
    reg.Free;
    if Length(Result) > 0 then
    begin
        if Result[Length(Result)] <> '\' then
        begin
            Result := Result + '\';
        end;
    end;
end;

procedure setRegValue(RootKey: HKEY; Path: string; Name: string; Value: string);
var
    Reg: TRegistry;
    cKeys: TStringlist;
    i: integer;
begin
    Reg := TRegistry.Create(KEY_ALL_ACCESS);
    try
        Reg.RootKey := RootKey;
        if (Reg.OpenKey(Path, false)) then
        begin
            if Reg.ValueExists(Name) then
            begin
                reg.WriteString(name, Value);
            end;
            cKeys := tStringList.Create();
            reg.GetKeyNames(ckeys);
            if cKeys.Count > 0 then
            begin
                for i := 0 to ckeys.count - 1 do
                begin
                    setRegValue(RootKey, Path + '\' + ckeys[i], Name, Value);
                end;
            end;
            ckeys.Free;
            reg.closeKey;
        end;
    except
        on E: exception do
        begin
            print(E.Message);
        end;
    end;
    reg.Free;
end;

function isAndroidNDKPath(Path: string): Boolean;
begin
    result := pos('androidndk', lowercase(Path)) > 0;
    result := Result or (LowerCase(path) = 'android');
    result := result or (Pos('mono for android', LowerCase(path)) > 0);
end;

procedure FindFileInPath(Path: string; List: TStrings);
var sr: TSearchRec;
    ret: Integer;
    tmpStr: string;
begin
    Ret := FindFirst(Path + '*.*', faHidden or faSysFile or faVolumeID or faDirectory, sr);
    while ret = 0 do
    begin
        tmpStr := sr.Name;
        if (tmpstr <> '.') and (tmpstr <> '..') then
        begin
            if (sr.Attr and faDirectory = fadirectory) then
            begin
                FindFileInPath(path + tmpstr + '\', list);
            end
            else
                list.Add(path + tmpstr);
        end;
        Ret := findNext(sr);
    end;
end;

end.

