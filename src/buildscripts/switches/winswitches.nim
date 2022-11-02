
import std / [ options, strscans, algorithm, os, osproc, parseopt, sequtils, strformat, strutils, sugar, tables, times ]
import buildscripts/[buildcommon, buildscripts, nimforueconfig]


let config = getNimForUEConfig()


let pluginDir = config.pluginDir
let pchDir = pluginDir / "Intermediate\\Build\\Win64\\UnrealEditor\\Development\\NimForUE"
let pchObjPath = pchDir / "PCH.NimForUE.h.obj"

let pchCompileFlags = @[
  &"/FI\"{pchDir}\\PCH.NimForUE.h\"",
  &"/Yu\"{pchDir}\\PCH.NimForUE.h\"",
  &"/Fp\"{pchDir}\\PCH.NimForUE.h.pch\"",
  # &"/Fd\"{pchDir}\\PCH.NimForUE.h.pdb\"",
]


proc vccPchCompileFlags*(withDebug, withPch:bool) : seq[string] = 
  @[
    
    "/Zc:inline", #Remove unreferenced functions or data if they're COMDAT or have internal linkage only (off by default).
    "/nologo",
    "/Oi",
    "/FC",
    "/c",
    "/Gw", # Enables whole-program global data optimization.
    "/Gy", # Enables function-level linking.
    "/Zm1000", 
    "/wd4819",
    "/D_CRT_STDIO_LEGACY_WIDE_SPECIFIERS=1",
    "/D_SILENCE_STDEXT_HASH_DEPRECATION_WARNINGS=1",
    "/D_WINDLL",
    "/D_DISABLE_EXTENDED_ALIGNED_STORAGE",
    "/source-charset:utf-8",
    "/execution-charset:utf-8",
    "/Ob2",
    "/Od",
    "/errorReport:prompt",
    "/EHsc",
    "/DPLATFORM_EXCEPTIONS_DISABLED=0",
    "/MD",
    "/bigobj", # Increases the number of addressable sections in an .obj file.
    "/fp:fast", # "fast" floating-point model; results are less predictable.
    "/Zp8",
    # /we<n>	Treat the specified warning as an error.

    "/we4456", # // 4456 - declaration of 'LocalVariable' hides previous local declaration
    "/we4458",#  4458 - declaration of 'parameter' hides class member
    "/we4459",# 4459 - declaration of 'LocalVariable' hides global declaration
    "/wd4463",#  4463 - overflow; assigning 1 to bit-field that can only hold values from -1 to 0
    "/we4668",
    "/wd4244",
    "/wd4838",
    "/TP",
    "/GR-", # /GR[-]	Enables run-time type information (RTTI).
    "/W4",
    "/std:c++latest",
    "/wd5054",
    # "/FS", #syn writes
    #extras:
    "/Zc:strictStrings-", # need this for converting const char []  to NCString since it loses const, for std:c++20
    #
    "/Zf", #faster pdb gen
    "/MP",
  
    "--sdkversion:10.0.18362.0" #for nim vcc wrapper. It sets the SDK to match the unreal one. This could be extracted from UBT if it causes issues down the road
  ] & 
    (if withPch:pchCompileFlags else: @[]) & 
    (if withDebug: @["/Od", "/Z7"] else: @["/O2"])


proc getPdbFilePath*(folder="guest"): string =
 # This has some hardcoded paths for guestpch!
  let pdbFolder = pluginDir / ".nimcache" / folder / "pdbs"
  createDir(pdbFolder)

  # clean up pdbs
  for pdbPath in walkFiles(pdbFolder/"nimforue*.pdb"):
    discard tryRemoveFile(pdbPath) # ignore if the pdb is locked by the debugger

  proc toVersion(s: string):int =
    let (_, f, _) = s.splitFile
    var n : int
    discard f.scanf("nimforue-$i", n)
    n

  # generate a new pdb name
  # get the version numbers and inc the highest to get the next
  let versions : seq[int] = walkFiles(pdbFolder/"nimforue*.pdb").toSeq.map(toVersion).sorted(Descending)
  let version : string =
    if versions.len > 0:
      "-" & $(versions[0]+1)
    else: ""
    
  
  let pdbFile = pdbFolder / "nimforue" & version & ".pdb"
  pdbFile

proc vccPchCompileSwitches*(withDebug : bool, debugFolder:string) : seq[string]= 
  let switches = vccPchCompileFlags(withDebug, withPch = true).filterIt(len(it)>1).mapIt("-t:" & it) & @[&"--cc:vcc", "-l:" & pchObjPath]
  if withDebug: 
      let debugSwitches = (&"-l:/link /INCREMENTAL /DEBUG /PDB:\"{getPdbFilePath(debugFolder)}\"").split("/").filterIt(len(it)>1).mapIt("-l:/" & it.strip())
      switches & debugSwitches
  else: switches & @["-l:/INCREMENTAL"]



proc getPlatformSwitches*(withPch, withDebug : bool, debugFolder:string) : seq[string] = 
  result = vccPchCompileSwitches(withDebug, debugFolder) 
