unit ToolDebian;

{$I castleconf.inc}

interface

uses
  CastleFindFiles,
  ToolArchitectures, ToolManifest, ToolPackage;

type
  { Package a project to a directory. }
  TPackageDebian = class(TPackageDirectoryAbstract)
  strict private
    { Total size of all binaries in the project, required for Debian metadata }
    BinariesSize: Int64;
    { Helper to find total size of all files inside the folder,
      To satisfy FindFile syntax has to be of Object }
    procedure FoundFile(const FileInfo: TFileInfo; var StopSearch: Boolean);
  public
    procedure Make(const OutputProjectPath: String; const PackageFileName: String;
      const Cpu: TCpu; const Manifest: TCastleManifest);
  end;

implementation
uses
  SysUtils, Process, {$ifdef UNIX} BaseUnix, {$endif}
  CastleUtils, CastleFilesUtils, CastleDownload, CastleImages,
  ToolCommonUtils, ToolUtils;

procedure TPackageDebian.FoundFile(const FileInfo: TFileInfo; var StopSearch: Boolean);
begin
  BinariesSize += FileInfo.Size;
end;

procedure TPackageDebian.Make(const OutputProjectPath: String; const PackageFileName: String;
      const Cpu: TCpu; const Manifest: TCastleManifest);

  function CpuToArchitectureString(const Cpu: TCpu): String;
  begin
    case Cpu of
      { Architectures supported by https://packages.debian.org/buster/bash }
      x86_64: Result := 'amd64';
      aarch64: Result := 'arm64';
      arm: begin
          Result := 'armel';
          WriteLn('WARNING: Architecture ' + CpuToString(Cpu) + ' is ambiguous between "armel" and "armhf" in Debian.');
        end;
      i386: Result := 'i386';
      mips: Result := 'mips';
      mipsel: Result := 'mipsel';
      powerpc64: begin
          Result := 'ppc64el';
          WriteLn('WARNING: Architecture ' + CpuToString(Cpu) + ' is ambiguous between "ppc64el" and "ppc64" in Debian.');
        end;
      // "mips64el"
      // "s390x"
      { Unofficial Debian ports https://packages.debian.org/sid/bash }
      m68k: Result := 'm68k';
      riscv64: Result := 'riscv64';
      sparc64: Result := 'sparc64';
      // "alpha"
      // "sh4"
      // "x32" = X32 is an ABI for amd64/x86_64 CPUs using 32-bit integers, longs and pointers
      else {powerpc,sparc,avr,jvm,i8086,riscv32,armeb}
      begin
        Result := CpuToString(Cpu);
        WriteLn('WARNING: Architecture ' + CpuToString(Cpu) + ' is not officially supported by Debian.');
      end;
    end;
  end;

var
  PathToExecutableLocal, PathToExecutableUnix: String;
  PathToIconFileLocal, PathToIconFileUnix: String;
  ShareDirLocal, ShareDirUrl: String;
  OutString: String;
  PackageDirLocal, PackageDirUrl: String;
begin
  PackageDirLocal := 'castle-engine-output' + PathDelim + PackageFileName;
  PackageDirUrl := StringReplace(PackageDirLocal, PathDelim, '/', [rfReplaceAll]);
  if DirectoryExists(PackageDirLocal) then
    RemoveNonEmptyDir(PackageDirLocal);

  // Copy the binaries

  PathToExecutableUnix := '/usr/' + Manifest.DebianInstallFolder + '/' + Manifest.Name;
  PathToExecutableLocal := StringReplace(PathToExecutableUnix, '/', PathDelim, [rfReplaceAll]);
  CopyDirectory(Path, PackageDirLocal + PathToExecutableLocal);

  ShareDirLocal := PackageDirLocal + PathDelim + 'usr' + PathDelim + 'share';
  ShareDirUrl := StringReplace(ShareDirLocal, PathDelim, '/', [rfReplaceAll]);
  CreateDir(ShareDirLocal);

  // Calculate binaries size

  BinariesSize := 0;
  FindFiles(PackageDirLocal + PathToExecutableLocal, '*', false, {$ifdef CASTLE_OBJFPC}@{$endif} FoundFile, [ffRecursive]);

  // Copy XPM icon

  CreateDir(ShareDirLocal + PathDelim + 'pixmaps');
  PathToIconFileUnix := '/usr/share/pixmaps/' + Manifest.ExecutableName + '.xpm';
  PathToIconFileLocal := StringReplace(PathToIconFileUnix, '/', PathDelim, [rfReplaceAll]);
  if Manifest.Icons.FindExtension(['.xpm']) <> '' then
    CheckCopyFile(Manifest.Icons.FindExtension(['.xpm']), PackageDirLocal + PathToIconFileLocal)
  else
  begin
    // using ImageMagic - FPWriteXPM first doesn't properly write alpha channel, second uses palette char size = 2 which is not a good idea for an icon
    //RunCommandSimple(FindExe('convert'), [Manifest.Icons.FindExtension(['.png']), PackageDirLocal + PathToIconFileLocal]);
    if not RunCommand('/bin/convert', [Manifest.Icons.FindExtension(['.png']), PackageDirLocal + PathToIconFileLocal], OutString) then
      WriteLn('ImageMagick failed.');
    WriteLn(OutString);
  end;

  // Create menu item for the game

  CreateDir(ShareDirLocal + PathDelim + 'menu');
  StringToFile(
    ShareDirUrl + '/menu/' + Manifest.Name,
    '?package(' + Manifest.Name + '): \' + NL +
    'needs="X11" \' + NL +
    'section="' + Manifest.DebianSection + '" \' + NL +
    'title="' + Manifest.Caption + '" \' + NL +
    'command="bash -c ''cd ' + PathToExecutableUnix + ' && ./' + Manifest.ExecutableName + '''" \' + NL +
    'icon="' + PathToIconFileUnix +'"'
  );

  CreateDir(ShareDirLocal + PathDelim + 'applications');
  StringToFile(
    ShareDirUrl + '/applications/' + Manifest.ExecutableName + '.desktop',
    '[Desktop Entry]' + NL +
    'Version=' + Manifest.Version.DisplayValue + NL +
    'Terminal=false' + NL +
    'Exec=bash -c ''cd ' + PathToExecutableUnix + ' && ./' + Manifest.ExecutableName + '''' + NL +
    'Icon=' + PathToIconFileUnix + NL +
    'Type=Application' + NL +
    'Categories=' + Manifest.DebianCategories + NL +
    'Name=' + Manifest.Caption + NL +
    'Comment=' + Manifest.DebianComment
  );

  CreateDir(PackageDirLocal + PathDelim + 'DEBIAN');
  StringToFile(
    PackageDirUrl + '/DEBIAN/control',
    'Package: ' + Manifest.Name + NL +
    'Version: ' + Manifest.Version.DisplayValue + NL +
    'Section: ' + Manifest.DebianInstallFolder + NL +
    'Priority: optional' + NL +
    'Architecture: ' + CpuToArchitectureString(Cpu) + NL +
    'Maintainer: ' + Manifest.Author + NL +
    'Installed-Size: ' + IntToStr(BinariesSize div 1024) + NL +
    'Depends: libopenal1, libpng16-16, zlib1g, libvorbis0a, libvorbisfile3, libfreetype6, libgl1-mesa-dri, libgtk2.0-0' + NL +
    'Description: ' + Manifest.Caption + NL +
    ' ' + Manifest.DebianComment + NL //final new line
  );

  // Post-installation running - assign executable permissions

  StringToFile(
    PackageDirUrl + '/DEBIAN/postinst',
    '#!/bin/sh' + NL + NL +
    'chmod +x ' + PathToExecutableUnix + '/' + Manifest.ExecutableName + NL + NL +
    'exit 0'
  );
  DoMakeExecutable(PackageDirLocal + PathDelim + 'DEBIAN' + PathDelim + 'postinst');

  // Workaround, we need to execute a shell script somehow

  StringToFile(
    'castle-engine-output/package-debian.sh',
    'cd castle-engine-output' + NL +
    'cd ' + PackageFileName + NL +
    'find -type f | egrep -v ''^\./DEBIAN'' | xargs --replace=hh -n1 md5sum "hh" | sed ''s/\ \.\///'' > DEBIAN/md5sums' + NL +
    'cd ..' + NL +
    'dpkg-deb --build ' + PackageFileName
  );

  RunCommand('/bin/bash', ['castle-engine-output/package-debian.sh'], OutString);
  WriteLn(OutString);
  RenameFile(PackageDirLocal + '.deb', PackageFileName + '.deb');

  // And finally clean up the temporary files
  RemoveNonEmptyDir(PackageDirLocal);
  DeleteFile('castle-engine-output' + PathDelim + 'package-debian.sh');
end;

end.

