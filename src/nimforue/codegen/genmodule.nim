import std/[options, osproc, strutils, sugar, sequtils, strformat, strutils, genasts, macros, importutils, os]

import ../utils/ueutils

import ../utils/utils
import ../unreal/coreuobject/[uobjectflags]
import ../codegen/[nuemacrocache, models, modulerules]
import ../../buildscripts/nimforueconfig
import uebind

func genUClassTypeDefBinding(ueType: UEType, rule: UERule = uerNone): seq[NimNode] =
  if rule == uerCodeGenOnlyFields:
    @[]
  else:
    @[
      # type Type* {.importcpp.} = object of Parent
      nnkTypeDef.newTree(
        nnkPragmaExpr.newTree(
          nnkPostFix.newTree(ident "*", ident ueType.name),
          nnkPragma.newTree(
            nnkExprColonExpr.newTree(ident "importcpp", newStrLitNode("$1_")),
            nnkExprColonExpr.newTree(ident "header", newStrLitNode("UEGenClassDefs.h"))
        )
      ),
        newEmptyNode(),
        nnkObjectTy.newTree(
          newEmptyNode(),
          nnkOfInherit.newTree(ident ueType.parent),
          newEmptyNode()
        )
      ),
      # ptr type TypePtr* = ptr Type
      nnkTypeDef.newTree(
        nnkPostFix.newTree(ident "*", ident ueType.name & "Ptr"),
        newEmptyNode(),
        nnkPtrTy.newTree(ident ueType.name)
      )
    ]

func genUClassImportTypeDefBinding(ueType: UEType, rule: UERule = uerNone): seq[NimNode] =
  if rule == uerCodeGenOnlyFields:
    @[]
  else:
    @[
      # type Type* {.importcpp.} = object of Parent
      nnkTypeDef.newTree(
        nnkPragmaExpr.newTree(
          nnkPostFix.newTree(ident "*", ident ueType.name),
          nnkPragma.newTree(
            nnkExprColonExpr.newTree(ident "importcpp", newStrLitNode("$1_")),
            ident "inheritable",
            nnkExprColonExpr.newTree(ident "header", newStrLitNode("UEGenClassDefs.h"))
        )
      ),
        newEmptyNode(),
        nnkObjectTy.newTree(
          newEmptyNode(),
          nnkOfInherit.newTree(ident ueType.parent),
          newEmptyNode()
        )
      ),
      # ptr type TypePtr* = ptr Type
      nnkTypeDef.newTree(
        nnkPostFix.newTree(ident "*", ident ueType.name & "Ptr"),
        newEmptyNode(),
        nnkPtrTy.newTree(ident ueType.name)
      )
    ]

func genUEnumTypeDefBinding(ueType: UEType): NimNode =
  let enumTy = ueType.fields
    .map(f => ident f.name)
    .foldl(a.add b, nnkEnumTy.newTree)
  enumTy.insert(0, newEmptyNode()) #required empty node in enums
  nnkTypeDef.newTree(
    nnkPragmaExpr.newTree(
      nnkPostFix.newTree(ident "*", ident ueType.name),
      nnkPragma.newTree(nnkExprColonExpr.newTree(ident "size", nnkCall.newTree(ident "sizeof", ident "uint8")), ident "pure")
    ),
    newEmptyNode(),
    enumTy
  )


func genUStructImportCTypeDefBinding(ueType: UEType): NimNode =
  var recList = ueType.fields
    .map(prop => nnkIdentDefs.newTree(
        getFieldIdent(prop),
        prop.getTypeNodeFromUProp(isVarContext=false),
        newEmptyNode()
      )
    )
    .foldl(a.add b, nnkRecList.newTree)
  nnkTypeDef.newTree(
    nnkPragmaExpr.newTree([
      nnkPostfix.newTree([ident "*", ident ueType.name.nimToCppConflictsFreeName()]),
      nnkPragma.newTree(
        ident "inject",
        ident "inheritable",
        ident "pure",
        nnkExprColonExpr.newTree(ident "importcpp", newStrLitNode("$1_")),
        nnkExprColonExpr.newTree(ident "header", newStrLitNode("UEGenBindings.h"))
    )
  ]),
    newEmptyNode(),
    nnkObjectTy.newTree(
      newEmptyNode(), newEmptyNode(), recList
    )
  )


func genImportCProp(typeDef: UEType, prop: UEField): NimNode =
  let ptrName = ident typeDef.name & "Ptr"
  let className = typeDef.name.substr(1)
  let typeNode = case prop.kind:
    of uefProp: getTypeNodeFromUProp(prop, isVarContext=false)
    else: newEmptyNode() #No Support
  let typeNodeAsReturnValue = case prop.kind:
    of uefProp: prop.getTypeNodeForReturn(typeNode)
    else: newEmptyNode() #No Support as UProp getter/Seter
  let propIdent = ident (prop.name[0].toLowerAscii() & prop.name.substr(1)).nimToCppConflictsFreeName()
  let setPropertyName = newStrLitNode(&"set{prop.name.firstToLow()}(@)")
  result =
    genAst(propIdent, ptrName, typeNode, className, propUEName = prop.name, setPropertyName, typeNodeAsReturnValue):
      proc `propIdent`*(obj {.inject.}: ptrName): typeNodeAsReturnValue {.importcpp: "$1(@)", header: "UEGenBindings.h".}
      proc `propIdent=`*(obj {.inject.}: ptrName, val {.inject.}: typeNode): void {.importcpp: setPropertyName, header: "UEGenBindings.h".}


func genUClassImportCTypeDef(typeDef: UEType, rule: UERule = uerNone): NimNode =
  let ptrName = ident typeDef.name & "Ptr"
  let parent = ident typeDef.parent
  let props = nnkStmtList.newTree(
                            typeDef.fields
                              .filter(prop=>prop.kind == uefProp)
                              .map(prop=>genImportCProp(typeDef, prop)))

  let funcs = nnkStmtList.newTree(
                            typeDef.fields
                              .filter(prop=>prop.kind == uefFunction)
                              .map(fun=>genImportCFunc(typeDef, fun)))

  result =
    genAst(props, funcs):
      props
      funcs
  result = nnkStmtList.newTree(genInterfaceConverers(typeDef), result)

proc genImportCTypeDecl*(typeDef: UEType, rule: UERule = uerNone): NimNode =
  case typeDef.kind:
    of uetClass:
      genUClassImportCTypeDef(typeDef, rule)
    of uetStruct:
      genUStructTypeDef(typeDef, rule, uexImport)
    of uetEnum:
      genUEnumTypeDef(typeDef)
    of uetDelegate: #No exporting dynamic delegates. Not sure if they make sense at all.
      genDelType(typeDef, uexImport)



proc genDelTypeDef*(delType: UEType, exposure: UEExposure): NimNode =
  let typeName = ident delType.name

  let delBaseType =
    case delType.delKind
    of uedelDynScriptDelegate: ident "FScriptDelegate"
    of uedelMulticastDynScriptDelegate: ident "FMulticastScriptDelegate"

  if exposure == uexImport:
    genAst(typeName, delBaseType):
      typeName {.inject, importcpp: "$1_", header: "UEGenBindings.h".} = object of delBaseType
  else:
    genAst(typeName, delBaseType):
      typeName {.inject, exportcpp: "$1_".} = object of delBaseType


proc genImportCModuleDecl*(moduleDef: UEModule): NimNode =
  result = nnkStmtList.newTree()

  var typeSection = nnkTypeSection.newTree()
  for typeDef in moduleDef.types:
    let rules = moduleDef.getAllMatchingRulesForType(typeDef)
    case typeDef.kind:
      of uetClass:
        typeSection.add genUClassImportTypeDefBinding(typeDef, rules)
      of uetStruct:
        typeSection.add genUStructImportCTypeDefBinding(typedef)
      of uetEnum:
        typeSection.add genUEnumTypeDefBinding(typedef)
      of uetDelegate:
        typeSection.add genDelTypeDef(typeDef, uexImport)

  result.add typeSection

  for typeDef in moduleDef.types:
    let rules = moduleDef.getAllMatchingRulesForType(typeDef)
    case typeDef.kind:
    of uetClass:
      result.add genImportCTypeDecl(typeDef, rules)
    # of uetDelegate: #TODO genDelFuncs
    #     result.add genDelType(typeDef, uexImport)
    else:
      continue

proc genExportModuleDecl*(moduleDef: UEModule): NimNode =
  result = nnkStmtList.newTree()

  var typeSection = nnkTypeSection.newTree()
  for typeDef in moduleDef.types:
    let rules = moduleDef.getAllMatchingRulesForType(typeDef)
    case typeDef.kind:
    of uetClass:
      typeSection.add genUClassTypeDefBinding(typedef, rules)
    of uetStruct:
      typeSection.add genUStructTypeDefBinding(typedef, rules)
    of uetEnum:
      typeSection.add genUEnumTypeDefBinding(typedef)
    of uetDelegate:
      typeSection.add genDelTypeDef(typeDef, uexExport)

  result.add typeSection

  for typeDef in moduleDef.types:
    let rules = moduleDef.getAllMatchingRulesForType(typeDef)
    case typeDef.kind:
    of uetClass, uetStruct:
      result.add genTypeDecl(typeDef, rules, uexExport)
    #  of uetDelegate: #TODO genDelFuncs
    #     result.add genDelType(typeDef, uexExport)
    else: continue


#notice this is only for testing ATM the final shape probably wont be like this
macro genUFun*(className: static string, funField: static UEField): untyped =
  let ueType = UEType(name: className, kind: uetClass) #Notice it only looks for the name and the kind (delegates)
  genFunc(ueType, funField).impl


proc genHeaders*(moduleDef: UEModule, headersPath: string) =

  let validCppParents = moduleDef
                        .rules
                        .filter(rule=>rule.rule == uerCodeGenOnlyFields)
                        .mapIt(it.affectedTypes)
                        .head()
                        .get(@[])
  
  func getParentName(uet: UEType) : string =
    uet.parent & (if uet.parent in validCppParents: "" else: "_")


  let classDefs = moduleDef.types
    .filterIt(it.kind == uetClass and uerCodeGenOnlyFields != getAllMatchingRulesForType(moduleDef, it))
    .mapIt(&"class {it.name}_ : public {getParentName(it)}{{}};\n")
    .join()

  func headerName (name: string): string =
    const bindSuffix = "_NimBinding.h"
    let name = &"{name.firstToUpper()}"
    if name.endsWith(bindSuffix): name else: name & bindSuffix

  let includeHeader = (name: string) => &"#include \"{headerName(name)}\" \n"
  let headerPath = headersPath / "Modules" / headerName(moduleDef.name)
  let deps = moduleDef
    .dependencies
    .map(includeHeader)
    .join()
  let headerContent = &"""
#pragma once
#include "UEDeps.h"
{deps}
{classDefs}
"""
  writeFile(headerPath, headerContent)
  #Main header
  let headersAsDeps =
    walkDir(headersPath / "Modules")
    .toSeq()
    .filterIt(it[0] == pcFile and it[1].endsWith(".h"))
    .mapIt(it[1].split(PathSeparator)[^1]) #replace(".h", ""))
    .mapIt("#include \"Modules/" & it & "\"")
    # .map(includeHeader)
    .join("\n ")                           #&"#include \"{headerName(name)}\" \n"
  let mainHeaderPath = headersPath / "UEGenClassDefs.h"
  let headerAsDep = includeHeader(moduleDef.name)
  let mainHeaderContent = &"""
#pragma once
#include "UEDeps.h"
{headersAsDeps}
"""
  # if headerAsDep notin mainHeaderContent:
  writeFile(mainHeaderPath, mainHeaderContent)

proc genCode(filePath: string, moduleStrTemplate: string, moduleDef: UEModule, moduleNode: NimNode) =
  let code =
    moduleStrTemplate &
    #"{.experimental:\"codereordering\".}\n" &
    moduleDef.dependencies.mapIt("import " & it.toLower()).join("\n") &
    repr(moduleNode)
      .multiReplace(
    ("{.inject.}", ""),
    ("{.inject, ", "{."),
    ("<", "["),
    (">", "]"),     #Changes Gen. Some types has two levels of inherantce in cpp, that we dont really need to support
    ("::Type", ""), #Enum namespaces EEnumName::Type
    ("::Mode", ""), #Enum namespaces EEnumName::TypeB
    ("::", "."),    #Enum namespace
    ("\"##", "  ##"),
    ("__DelegateSignature", ""))
  writeFile(filePath, code)

macro genBindings*(moduleDef: static UEModule, exportPath: static string, importPath: static string, headersPath: static string) =
  let moduleStrTemplate = &"""
include ../../prelude
when defined(macosx):
  const BindingPrefix {{.strdefine.}} = ""
  {{.compile: BindingPrefix&"{moduleDef.name.tolower()}.nim.cpp".}}

"""

  genCode(exportPath, "include ../../prelude\n", moduleDef, genExportModuleDecl(moduleDef))

  genCode(importPath, moduleStrTemplate, moduleDef, genImportCModuleDecl(moduleDef))

  genHeaders(moduleDef, headersPath)


proc getModuleHashFromFile*(filePath: string): Option[string] =
  if not fileExists(filePath): return none[string]()
  readLines(filePath, 1)
    .head()
    .map(line => line.split(":")[^1].strip())


macro genProjectBindings*(project: static UEProject, pluginDir: static string) =
  let bindingsDir = pluginDir / BindingsDir

  let nimHeadersDir = pluginDir / NimHeadersDir # need this to store forward decls of classes

  for module in project.modules:
    let module = module
    let exportBindingsPath = bindingsDir / "exported" / module.name.toLower() & ".nim"
    let importBindingsPath = bindingsDir / module.name.toLower() & ".nim"
    let prevModHash = getModuleHashFromFile(importBindingsPath).get("_")
    if prevModHash == module.hash and uerIgnoreHash notin module.rules:
      echo "Skipping module: " & module.name & " as it has not changed"
      continue
    let moduleStrTemplate = &"""
#hash:{module.hash}
include ../prelude

const BindingPrefix {{.strdefine.}} = ""
{{.compile: BindingPrefix&"{module.name.tolower()}.nim.cpp".}}

"""
    echo &"Generating bindings for {module.name}"
    genCode(exportBindingsPath, "include ../../prelude\n", module, genExportModuleDecl(module))
    genCode(importBindingsPath, moduleStrTemplate, module, genImportCModuleDecl(module))

    genHeaders(module, nimHeadersDir)