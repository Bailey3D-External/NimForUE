include ../unreal/prelude
import std/[strformat, options, sugar, json, osproc, jsonutils,  sequtils, os]
import ../typegen/uemeta
import ../../buildscripts/nimforueconfig
import ../macros/makestrproc


makeStrProc(UEMetadata)
makeStrProc(UEField)
makeStrProc(UEType)
makeStrProc(UEModule)

uClass AActorScratchpad of AActor:
  (BlueprintType)
  uprops(EditAnywhere, BlueprintReadWrite, ExposeOnSpawn):
    stringProp : FString
    intProp : int32#
    # intProp2 : int32
  
  ufuncs(CallInEditor):
    proc generateUETypes() = 
      let moduleName = "NimForUEBindings"
      let module = tryGetPackageByName(moduleName)
                    .flatmap(toUEModule)
      
     
      let moduleStr = $module.get()
      let config = getNimForUEConfig()
      let reflectionDataPath = config.pluginDir / ".reflectiondata"
      createDir(reflectionDataPath)
      let modulePath = reflectionDataPath / moduleName & ".nim"
      UE_Log &"The module path is {modulePath} "
      
      
      # UE_Warn ($module)
      try:
        writeFile(modulePath, moduleStr)
        let nueCmd = config.pluginDir/"nue codegen"
        let result = execProcess(nueCmd, workingDir = config.pluginDir)
        UE_Log &"The result is {result} "
      except:
        let e : ref Exception = getCurrentException()
        
        UE_Log &"Error: {e.msg}"
        UE_Log &"Error: {e.getStackTrace()}"
        UE_Log &"Failed to generate JSON"
        
      # let json = $module.toJson()

      # UE_Log &"JSON: {json}"

      # let moduleRestored = parseJson(json).jsonTo(UEModule)
      # UE_Warn $len($moduleRestored)
    proc showUEConfig() = 
      let config = getNimForUEConfig()
      createDir(config.pluginDir / ".reflectiondata")
