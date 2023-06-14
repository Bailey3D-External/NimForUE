
include ../definitions
import ../Core/Containers/[unrealstring, array, map]
import ../Core/ftext
import nametypes
import std/[genasts, options, strformat, macros, sequtils, typetraits, tables, strformat, strutils]
import ../../utils/utils
import uobjectflags
import sugar
export uobjectflags


type 
    
    FField* {. importcpp, inheritable, pure .} = object 
        next*  {.importcpp:"Next".} : ptr FField
    FFieldPtr* = ptr FField 
    FProperty* {. importcpp, inheritable,  pure.} = object of FField 
    FPropertyPtr* = ptr FProperty
    FFieldClass* {. importcpp, inheritable, pure .} = object
    FFieldClassPtr* = ptr FFieldClass
    FFieldPath* {. importcpp, inheritable, pure .} = object
      field* {.importcpp:"Field".}: FFieldPtr
      fieldClass* {.importcpp:"FieldClass".}: FFieldClassPtr
      fieldPathString* {.importcpp:"FieldPathString".}: FString

    UObject* {.importcpp, inheritable, pure.} = object #TODO Create a macro that takes the header path as parameter?
    UObjectPtr* = ptr UObject #This can be autogenerated by a macro

    UField* {.importcpp, inheritable, pure .} = object of UObject
        Next* : ptr UField #Next Field in the linked list 
    UFieldPtr* = ptr UField 

    UEnum* {.importcpp, inheritable, pure .} = object of UField
    UEnumPtr* = ptr UEnum
   

    UStruct* {.importcpp, inheritable, pure .} = object of UField
        Children* : UFieldPtr # Pointer to start of linked list of child fields */
        childProperties* {.importcpp:"ChildProperties".}: FFieldPtr #  /** Pointer to start of linked list of child fields */
        propertyLink* {.importcpp:"PropertyLink".}: FPropertyPtr #  /** 	/** In memory only: Linked list of properties from most-derived to base */

    UStructPtr* = ptr UStruct 

    FObjectInitializer* {.importcpp.} = object
    FReferenceCollector* {.importcpp.} = object

    #Notice this is not really the signature. It has const 
    UClassConstructor* = proc (objectInitializer:var FObjectInitializer) : void {.cdecl.}
    VTableConstructor* = proc (helper:var FVTableHelper) : UObjectPtr  {.cdecl.}
    
    FOutParmRec* {.importcpp.} = object
        property* {.importcpp:"Property".} : FPropertyPtr
        propAddr* {.importcpp:"PropAddr".}: pointer 
        nextOutParm* {.importcpp:"NextOutParm".}: ptr FOutParmRec
        mostRecentProperty* {.importcpp:"MostRecentProperty".}: FPropertyPtr
    FFrame* {.importcpp .} = object
        code* {.importcpp:"Code".} : ptr uint8
        node* {.importcpp:"Node".} : UFunctionPtr
        obj* {.importcpp:"Object".} : UObjectPtr
        locals* {.importcpp:"Locals".} : ptr uint8
        outParms* {.importcpp:"OutParms".} : ptr FOutParmRec
        propertyChainForCompiledIn* {.importcpp:"PropertyChainForCompiledIn".}: FFieldPtr
        mostRecentPropertyAddress* {.importcpp:"MostRecentPropertyAddress".}: ptr uint8
    UClassAddReferencedObjectsType* = proc (obj:UObjectPtr, collector:var FReferenceCollector) : void {.cdecl.}
    UFunctionNativeSignature* = proc (context:UObjectPtr, stack:var FFrame,  result: pointer) : void {. cdecl .}
    FImplementedInterface* {.importcpp.} = object
        class* {.importcpp:"Class".}: UClassPtr
    FUObjectCppClassStaticFunctions* {.importcpp.} = object
    UClass* {.importcpp, inheritable, pure .} = object of UStruct
        classWithin* {.importcpp:"ClassWithin".}: UClassPtr #  The required type for the outer of instances of this class */
        classConfigName* {.importcpp:"ClassConfigName".}: FName 
        classFlags* {.importcpp:"ClassFlags".}: EClassFlags
        classCastFlags* {.importcpp:"ClassCastFlags".}: EClassCastFlags
        classConstructor* {.importcpp:"ClassConstructor".}: UClassConstructor
        classVTableHelperCtorCaller* {.importcpp:"ClassVTableHelperCtorCaller".}: VTableConstructor
        addReferencedObjects* {.importcpp:"AddReferencedObjects".}: UClassAddReferencedObjectsType
        interfaces* {.importcpp:"Interfaces".}: TArray[FImplementedInterface]
        cppClassStaticFunctions* {.importcpp:"CppClassStaticFunctions".}: FUObjectCppClassStaticFunctions

    UClassPtr* = ptr UClass
    UInterface* {.importcpp, inheritable, pure .} = object of UObject
    UInterfacePtr* = ptr UInterface

    UScriptStruct* {.importcpp, inheritable, pure .} = object of UStruct
        structFlags* {.importcpp:"StructFlags".}: EStructFlags
    UScriptStructPtr* = ptr UScriptStruct
    ICppStructOps {.importcpp:"UScriptStruct::ICppStructOps".} = object
    ICppStructOpsPtr = ptr ICppStructOps


    UFunction* {.importcpp, inheritable, pure .} = object of UStruct
        functionFlags* {.importcpp:"FunctionFlags".} : EFunctionFlags
        numParms* {.importcpp:"NumParms".}: uint8
        parmsSize* {.importcpp:"ParmsSize".}: uint16
        returnValueOffset* {.importcpp:"ReturnValueOffset".}: uint16
    UFunctionPtr* = ptr UFunction
    UDelegateFunction* {.importcpp, inheritable, pure .} = object of UFunction
    UDelegateFunctionPtr* = ptr UDelegateFunction

    TObjectPtr*[T ] {.importcpp.} = object 
    TLazyObjectPtr*[out T ] {.importcpp.} = object 
    TEnumAsByte*[T : enum] {.importcpp.} = object

    TWeakObjectPtr*[out T] {.importcpp.} = object
    TScriptInterface*[out T] {.importcpp.} = object

    UWorld* {.importcpp, pure .} = object of UObject
    UWorldPtr* = ptr UWorld

    ConstructorHelpers* {.importcpp, pure .} = object
    FObjectFinder*[T] {.importcpp, pure .} = object
      obj* {.importcpp:"Object".} : ptr T

    FClassFinder*[T] {.importcpp:"ConstructorHelpers::FClassFinder<'0>", nodecl, pure .} = object
      class* {.importcpp:"Class".} : TSubclassOf[T]

    TSubclassOf*[out T]  {. importcpp: "TSubclassOf<'0>".} = object
    TFieldPath*[out T]  {. importcpp: "TFieldPath<'0>".} = object

    FVTableHelper* {.importcpp, pure.} = object

    FPropertyChangedEvent* {.importcpp, pure, inheritable} = object
      property*  {.importcpp: "Property" .} : FPropertyPtr #	 * The actual property that changed
      memberProperty*  {.importcpp: "MemberProperty" .} : FPropertyPtr #	 * The property that was actually modified (in the case of a struct member)
      #TODO bind EPropertyChangeType
    FPropertyChangedChainEvent* {.importcpp, pure} = object of FPropertyChangedEvent
    FObjectPostSaveRootContext* {.importcpp, pure.} = object
    FScriptArray* {.importcpp, pure.} = object #used only for interoping with the vm. 
    FScriptArrayHelper* {.importcpp, pure.} = object 
    FScriptMap* {.importcpp, pure.} = object #used only for interoping with the vm.
    FScriptMapHelper* {.importcpp.} = object
    FScriptMapLayout* {.importcpp.} = object
        #keyoffset is always 0
        valueOffset* {.importcpp:"ValueOffset".}: int32


#LOGS here because we need them. Maybe they should leave in a separated file

proc UE_LogInternal(msg: FString) : void {.importcpp: "UReflectionHelpers::NimForUELog(@)".}
proc UE_WarnInternal(msg: FString) : void {.importcpp: "UReflectionHelpers::NimForUEWarn(@)".}
proc UE_ErrorInteral(msg: FString) : void {.importcpp: "UReflectionHelpers::NimForUEError(@)".}


template UE_Log*(msg: FString): untyped =
  let pos = instantiationInfo()
  let meta = "[$1:$2]: " % [pos.filename, $pos.line]
  UE_LogInternal(meta & msg)


template UE_Warn*(msg: FString): untyped =
  let pos = instantiationInfo()
  let meta = "[$1:$2]: " % [pos.filename, $pos.line]
  UE_WarnInternal(meta & msg)


template UE_Error*(msg: FString): untyped =
  let pos = instantiationInfo()
  let meta = "[$1:$2]: " % [pos.filename, $pos.line]
  UE_ErrorInteral(meta & msg)


proc getDefaultObject*(fieldClass:FFieldClassPtr) : FFieldPtr {.importcpp:"#->GetDefaultObject()" .}

proc makeFImplementedInterface*(class: UClassPtr, offset:int32 = 0, implementedByK2:bool = true) : FImplementedInterface {.importcpp:"FImplementedInterface(@)", constructor.}


proc castField*[T : FField ](src:FFieldPtr) : ptr T {. importcpp:"CastField<'*0>(#)" .}
proc ueCast*[T : UObject ](src:UObjectPtr) : ptr T {. importcpp:"Cast<'*0>(#)" .}
proc ueCast*(src:UObjectPtr, T : typedesc) : ptr T = ueCast[T](src)

proc createDefaultSubobject*[T : UObject ](obj:var FObjectInitializer, outer:UObjectPtr, subObjName:FName, bTransient=false) : ptr T {. importcpp:"#.CreateDefaultSubobject<'*0>(@)" .}
proc createDefaultSubobject*(obj:var FObjectInitializer, outer:UObjectPtr, subObjName:FName, returnCls, default: UClassPtr, bIsRequired, bTransient:bool) : UObjectPtr {. importcpp:"#.CreateDefaultSubobject(@)" .}

#todo change this for ActorComponent?
proc createDefaultSubobjectNim*[T:UObject](outer:UObjectPtr, name:FName) : ptr T {.importcpp:"UReflectionHelpers::CreateDefaultSubobjectNim<'*0>(@)" .}



proc getName*(prop:FFieldPtr | FFieldClassPtr) : FString {. importcpp:"#->GetName()" .}

proc initializeValue*(prop:FPropertyPtr, dest: pointer) {. importcpp:"#->InitializeValue(#)" .}
proc copySingleValue*(prop:FPropertyPtr, dest: pointer, src: pointer) {. importcpp:"#->CopySingleValue(@)" .}
proc getOffsetForUFunction*(prop:FPropertyPtr) : int32 {. importcpp:"#->GetOffset_ForUFunction()".}
proc initializeValueInContainer*(prop:FPropertyPtr, container:pointer) : void {. importcpp:"#->InitializeValue_InContainer(#)".}

proc getSize*(prop:FPropertyPtr) : int32 {. importcpp:"#->GetSize()".}
proc getMinAlignment*(prop:FPropertyPtr) : int32 {. importcpp:"#->GetMinAlignment()".}
proc getOffset*(prop:FPropertyPtr) : int32 {. importcpp:"#->GetOffset_ForInternal()".}

proc setPropertyFlags*(prop:FPropertyPtr, flags:EPropertyFlags) : void {. importcpp:"#->SetPropertyFlags(#)".}
proc getPropertyFlags*(prop:FPropertyPtr) : EPropertyFlags {. importcpp:"#->GetPropertyFlags()".}
proc getNameCPP*(prop:FPropertyPtr) : FString {.importcpp: "#->GetNameCPP()".}
proc getCPPType*(prop:FPropertyPtr) : FString {.importcpp: "#->GetCPPType()".}
proc getTypeName*(prop:FPropertyPtr) : FString {.importcpp: "#->GetTypeName()".}
proc getOwnerStruct*(str:FPropertyPtr) : UStructPtr {.importcpp:"#->GetOwnerStruct()".}


type FFieldVariant* {.importcpp.} = object
# proc makeFieldVariant*(field:FFieldPtr) : FFieldVariant {. importcpp: "'0(#)", constructor.}
proc makeFieldVariant*(obj:UObjectPtr | FFieldPtr) : FFieldVariant {. importcpp: "'0(#)", constructor.}
proc toUObject*(field:FFieldVariant) : UObjectPtr {. importcpp: "#.ToUObject()".}
proc toField*(field:FFieldVariant) : FFieldPtr {. importcpp: "#.ToField()".}
proc isUObject*(field:FFieldVariant) : bool {. importcpp: "#.IsUObject()".}

macro bindFProperty(propNames : static openarray[string] ) : untyped = 
    proc bindProp(name:string) : NimNode = 
        let constructorName = ident "new"&name
        let constructorNameWithEqualityAndSerializer = ident "new"&name & "WithEqualityAndSerializer"
        let ptrName = ident name&"Ptr"

        genAst(name=ident name, ptrName, constructorName, constructorNameWithEqualityAndSerializer):
            type 
                name* {.inject, importcpp.} = object of FProperty
                ptrName* {.inject.} = ptr name

            proc constructorName*(fieldVariant:FFieldVariant, propName:FName, objFlags:EObjectFlags) : ptrName {. importcpp: "new '*0(@)", inject.}
            proc constructorName*(fieldVariant:FFieldVariant, propName:FName, objFlags:EObjectFlags, offset:int32, propFlags:EPropertyFlags) : ptrName {. importcpp: "new '*0(@)", inject.}
            proc constructorNameWithEqualityAndSerializer*(fieldVariant:FFieldVariant, propName:FName, objFlags:EObjectFlags) : ptrName {. importcpp: "new '*0(@)", inject.}
            proc constructorNameWithEqualityAndSerializer*(fieldVariant:FFieldVariant, propName:FName, objFlags:EObjectFlags, offset:int32, propFlags:EPropertyFlags) : ptrName {. importcpp: "new '*0(@)", inject.}

    
    nnkStmtList.newTree(propNames.map(bindProp))

bindFProperty([ 
        "FBoolProperty",
        "FInt8Property", "FInt16Property","FIntProperty", "FInt64Property",
        "FByteProperty", "FUInt16Property","FUInt32Property", "FUInt64Property",
        "FStrProperty", "FFloatProperty", "FDoubleProperty", "FNameProperty",
        "FArrayProperty", "FStructProperty", "FObjectProperty", "FObjectPtrProperty", "FClassProperty",
        "FSoftObjectProperty", "FSoftClassProperty", "FEnumProperty", 
        "FMapProperty", "FDelegateProperty", "FSetProperty", "FInterfaceProperty",
        "FMulticastDelegateProperty", #It seems to be abstract. Review Sparse vs Inline
        "FMulticastInlineDelegateProperty", "FFieldPathProperty",
        
        ])


#TypeClass
type DelegateProp* = FDelegatePropertyPtr | FMulticastInlineDelegatePropertyPtr | FMulticastDelegatePropertyPtr
proc containerPtrToValuePtr*(prop:FPropertyPtr, container: pointer) : pointer {. importcpp: "(#->ContainerPtrToValuePtr<void>(@))".}

#Concrete methods
proc setScriptStruct*(prop:FStructPropertyPtr, scriptStruct:UScriptStructPtr) : void {. importcpp: "(#->Struct=#)".}
proc getScriptStruct*(prop:FStructPropertyPtr) : UScriptStructPtr {. importcpp: "(#->Struct)".}
proc setPropertyClass*(prop:FObjectPtrPropertyPtr | FObjectPropertyPtr | FSoftObjectPropertyPtr | FClassPropertyPtr, propClass:UClassPtr) : void {. importcpp: "(#->PropertyClass=#)".}
proc getPropertyClass*(prop:FObjectPtrPropertyPtr | FObjectPropertyPtr | FSoftObjectPropertyPtr | FClassPropertyPtr) : UClassPtr {. importcpp: "(#->PropertyClass)".}
# proc setPropertyMetaClass*(prop:FClassPropertyPtr | FSoftClassPropertyPtr, propClass:UClassPtr) : void {. importcpp: "(#->MetaClass=#)".}
proc setPropertyMetaClass*(prop:FClassPropertyPtr | FSoftClassPropertyPtr, propClass:UClassPtr) : void {. importcpp: "#->SetMetaClass(#)".}
proc setEnum*(prop:FEnumPropertyPtr, uenum:UEnumPtr) : void {. importcpp: "(#->SetEnum(#))".}

proc getElementProp*(setProp:FSetPropertyPtr) : FPropertyPtr {.importcpp:"(#->ElementProp)".}
proc getInnerProp*(arrProp:FArrayPropertyPtr) : FPropertyPtr {.importcpp:"(#->Inner)".}
proc setInnerProp*(arrProp:FArrayPropertyPtr, innerProp:FPropertyPtr) : void {.importcpp:"(#->Inner=#)".}
proc getInterfaceClass*(interfaceProp:FInterfacePropertyPtr) : UClassPtr {.importcpp:"(#->InterfaceClass)".}

proc getPropertyClass*(prop:FFieldPathPropertyPtr) : FFieldClassPtr {.importcpp:"(#->PropertyClass)".}
proc setPropertyClass*(prop:FFieldPathPropertyPtr, propClass:FFieldClassPtr) : void {.importcpp:"(#->PropertyClass=#)".}

proc addCppProperty*(arrProp:FArrayPropertyPtr | FSetPropertyPtr | FMapPropertyPtr | FEnumPropertyPtr, cppProp:FPropertyPtr) : void {. importcpp:"(#->AddCppProperty(#))".}

proc getKeyProp*(arrProp:FMapPropertyPtr) : FPropertyPtr {.importcpp:"(#->KeyProp)".}
proc getValueProp*(arrProp:FMapPropertyPtr) : FPropertyPtr {.importcpp:"(#->ValueProp)".}
proc getMapLayout*(arrProp:FMapPropertyPtr) : FScriptMapLayout {.importcpp:"(#->MapLayout)".}


proc getSignatureFunction*(delProp:DelegateProp) : UFunctionPtr {.importcpp:"(#->SignatureFunction)".}
proc setSignatureFunction*(delProp:DelegateProp, signature : UFunctionPtr) : void {.importcpp:"(#->SignatureFunction=#)".}

#	void SetBoolSize( const uint32 InSize, const bool bIsNativeBool = false, const uint32 InBitMask = 0 );
proc setBoolSize*(prop:FBoolPropertyPtr, size:uint32, isNativeBool:bool) : void {. importcpp: "(#->SetBoolSize(@))".}
proc setPropertyValue*(prop:FBoolPropertyPtr, container: pointer, value:bool) : void {. importcpp: "(#->SetPropertyValue(@))".}
proc getPropertyValue*(prop:FBoolPropertyPtr, container: pointer) : bool {. importcpp: "(#->GetPropertyValue(@))".}
#BoolReturn->GetPropertyValue(BoolReturn->ContainerPtrToValuePtr<void>(InBaseParamsAddr));
#[
    			
                    				uint8* CurrentPropAddr = It->ContainerPtrToValuePtr<uint8>(Buffer);

						((FBoolProperty*)*It)->SetPropertyValue( CurrentPropAddr, true );
]#



#Notice T is not an UObject but the Cpp interface
proc getInterface*[T](scriptInterface:TScriptInterface[T]) : ptr T {. importcpp: "(#.GetInterface())".}
proc getUObject*(scriptInterface:TScriptInterface) : UObjectPtr {. importcpp: "(#.GetObject())".}
proc getUInterface*[T](scriptInterface:TScriptInterface) : ptr T =
    scriptInterface.getUObject().ueCast[:T]()


proc bindType*(field:UFieldPtr) : void {. importcpp:"#->Bind()" .} #notice bind is a reserverd keyword in nim
proc getPrefixCpp*(str:UFieldPtr | UStructPtr) : FString {.importcpp:"FString(#->GetPrefixCPP())".}



#UOBJECT
proc getFName*(obj:UObjectPtr|FFieldPtr) : FName {. importcpp: "#->GetFName()" .}
proc getFlags*(obj:UObjectPtr|FFieldPtr) : EObjectFlags {. importcpp: "#->GetFlags()" .}
proc setFlags*(obj:UObjectPtr, inFlags : EObjectFlags) : void {. importcpp: "#->SetFlags(#)" .}
proc clearFlags*(obj:UObjectPtr, inFlags : EObjectFlags) : void {. importcpp: "#->ClearFlags(#)" .}

proc addToRoot*(obj:UObjectPtr) : void {. importcpp: "#->AddToRoot()" .}

proc getClass*(obj : UObjectPtr) : UClassPtr {. importcpp: "#->GetClass()" .}
proc getOuter*(obj : UObjectPtr) : UObjectPtr {. importcpp: "#->GetOuter()" .}
proc getWorld*(obj : UObjectPtr) : UWorldPtr {. importcpp: "#->GetWorld()" .}

proc getName*(obj : UObjectPtr) : FString {. importcpp:"#->GetName()" .}
proc conditionalBeginDestroy*(obj:UObjectPtr) : void {. importcpp:"#->ConditionalBeginDestroy()".}
proc processEvent*(obj : UObjectPtr, fn:UFunctionPtr, params:pointer) : void {. importcpp:"#->ProcessEvent(@)" .}


#USTRUCT
proc staticLink*(str:UStructPtr, bRelinkExistingProperties:bool) : void {.importcpp:"#->StaticLink(@)".}

#This belongs to this file due to nim not being able to forward declate types. We may end up merging this file into uobject
proc addCppProperty*(str:UStructPtr, prop:FPropertyPtr) : void {.importcpp:"#->AddCppProperty(@)".}
#     virtual const TCHAR* GetPrefixCPP() const { return TEXT("F"); }
proc setSuperStruct*(str, suprStruct :UStructPtr) : void {.importcpp:"#->SetSuperStruct(#)".}

#UCLASS
proc findFunctionByName*(cls : UClassPtr, name:FName) : UFunctionPtr {. importcpp: "#.FindFunctionByName(#)"}
proc findFunctionByNameExcludeSuper*(cls : UClassPtr, name:FName) : UFunctionPtr {. importcpp: "#.FindFunctionByName(#, EIncludeSuperFlag::ExcludeSuper)"}
proc findFuncByName*(cls : UClassPtr, name:FName) : UFunctionPtr {.inline.} = 
    var fn = cls.findFunctionByNameExcludeSuper(name)
    if fn.isNil(): #try again with super, this is needed in order to override. 
        fn = cls.findFunctionByName(name)
    # UE_Error "Could not find function " & $name & " in class " & cls.getName()
    return fn

proc addFunctionToFunctionMap*(cls : UClassPtr, fn : UFunctionPtr, name:FName) : void {. importcpp: "#.AddFunctionToFunctionMap(@)"}
proc removeFunctionFromFunctionMap*(cls : UClassPtr, fn : UFunctionPtr) : void {. importcpp: "#.RemoveFunctionFromFunctionMap(@)"}
proc getDefaultObject*(cls:UClassPtr) : UObjectPtr {. importcpp:"#->GetDefaultObject()" .}
proc getCDO*[T:UObject](cls:UClassPtr) : ptr T = ueCast[T](cls.getDefaultObject())
proc getSuperClass*(cls:UClassPtr) : UClassPtr {. importcpp:"#->GetSuperClass()" .}
proc assembleReferenceTokenStream*(cls:UClassPtr, bForce = false) : void {. importcpp:"#->AssembleReferenceTokenStream(@)" .}

#ScriptStruct
proc getSuperStruct*(str:UScriptStructPtr) : UScriptStructPtr {. importcpp:"#->GetSuperStruct()" .}
proc hasStructOps*(str:UScriptStructPtr) : bool {.importcpp:"(#->GetCppStructOps() != nullptr)".}
proc getAlignment*(str:UScriptStructPtr) : int32 {.importcpp:"#->GetCppStructOps()->GetAlignment()".}
proc getSize*(str:UScriptStructPtr) : int32 {.importcpp:"#->GetCppStructOps()->GetSize()".}
proc hasAddStructReferencedObjects*(str:UScriptStructPtr) : bool {.importcpp:"#->GetCppStructOps()->HasAddStructReferencedObjects()".}
proc getCppStructOps*(str:UScriptStructPtr) : ICppStructOpsPtr {. importcpp:"#->GetCppStructOps()" .}
#struct ops #TODO need to fill FProperty
proc copy*(ops:ICppStructOpsPtr; dest: pointer; src: pointer; arrayDim: int32 = 1): bool {. importcpp:"#->Copy(#, #, #)" .}



# proc getCppStructOps*(str:UScriptStructPtr) : ICppStructOpsPtr {. importcpp:"#->GetCppStructOps()" .}

#TObjectPtr


proc get*[T : UObject](obj:TObjectPtr[T]) : ptr T {.importcpp:"#.Get()".}
converter toUObjectPtr*[T : UObject](obj:TObjectPtr[T]) : ptr T {.importcpp:"#.Get()".}
converter fromObjectPtr*[T : UObject](obj:ptr T) : TObjectPtr[T] {.importcpp:"TObjectPtr<'*0>(#)".}

type ERenameFlag* = distinct uint32
const REN_None* = ERenameFlag(0x0000)
const REN_DontCreateRedirectors* = ERenameFlag(0x0010)
proc rename*(obj:UObjectPtr, InName:FString, newOuter:UObjectPtr, flags:ERenameFlag) : bool {. importcpp:"#->Rename(*#, #, #)" .}

#FUNC
proc initializeDerivedMembers*(fn:UFunctionPtr) : void {.importcpp:"#->InitializeDerivedMembers()".}
proc getReturnProperty*(fn:UFunctionPtr) : FPropertyPtr {.importcpp:"#->GetReturnProperty()".}
proc tryGetReturnProperty*(fn:UFunctionPtr) : Option[FPropertyPtr] = someNil fn.getReturnProperty()
proc doesReturn*(fn:UFunctionPtr) : bool  = tryGetReturnProperty(fn).isSome()


#UENUM
#virtual bool SetEnums(TArray<TPair<FName, int64>>& InNames, ECppForm InCppForm, EEnumFlags InFlags = EEnumFlags::None, bool bAddMaxKeyIfMissing = true) override;

proc setEnums*(uenum:UENumPtr, inName:TArray[TPair[FName, int64]]) : bool {. importcpp:"#->SetEnums(#, UEnum::ECppForm::Regular)" .}



#ITERATOR
type TFieldIterator* [T:UStruct] {.importcpp.} = object
proc makeTFieldIterator*[T](inStruct : UStructPtr, flag:EFieldIterationFlags) : TFieldIterator[T] {. importcpp:"'0(@)" constructor .}

proc next*[T](it:var TFieldIterator[T]) : void {. importcpp:"(++#)" .} 
proc isValid[T](it: TFieldIterator[T]): bool {.importcpp: "((bool)(#))", noSideEffect.}
proc get*[T](it:TFieldIterator[T]) : ptr T {. importcpp:"*#" .} 

iterator items*[T](it:var TFieldIterator[T]) : var TFieldIterator[T] =
    while it.isValid():
        yield it
        it.next()

type FRawObjectIterator* {.importcpp.} = object
proc makeFRawObjectIterator*() : FRawObjectIterator {. importcpp:"FRawObjectIterator()" constructor .}
proc next*(it:var FRawObjectIterator) : void {. importcpp:"(++#)" .}
proc isValid*(it: FRawObjectIterator): bool {.importcpp: "((bool)(#))", noSideEffect.}
proc get*(it:FRawObjectIterator) : UObjectPtr {. importcpp:"static_cast<UObject*>(#->Object)" .}

iterator items*(it:var FRawObjectIterator) : var FRawObjectIterator =
    while it.isValid():
        yield it
        it.next()


#StepExplicitProperty
proc stepExplicitProperty*(frame:var FFrame, result:pointer, prop:FPropertyPtr) {.importcpp:"#.StepExplicitProperty(@)".}
proc step*(frame:var FFrame, contex:UObjectPtr, result:pointer) {.importcpp:"#.Step(@)".}

#object initializer
proc getObj*(obj: var FObjectInitializer) : UObjectPtr {.importcpp:"#.GetObj()".}

iterator items*(ustr: UStructPtr): FFieldPtr =
    var currentProp = ustr.childProperties
    while not currentProp.isNil():
        yield currentProp
        currentProp = currentProp.next



#CONSTRUCTOR HELPERS
proc getUTypeByName*[T :UObject](typeName:FString) : ptr T {.importcpp:"UReflectionHelpers::GetUTypeByName<'*0>(@)".}
proc tryGetUTypeByName*[T :UObject](typeName:FString) : Option[ptr T] = someNil getUTypeByName[T](typeName)
proc getClassByName*(className:FString) : UClassPtr {.exportcpp.} = getUTypeByName[UClass](className)
proc getScriptStructByName*(strName:FString) : UScriptStructPtr {.exportcpp.} = getUTypeByName[UScriptStruct](strName)

proc staticClass*[T:UObject]() : UClassPtr = #TODO we should autogen a function and call it instead of searching
    let className : FString = typeof(T).name.substr(1) #Removes the prefix of the class name (i.e U, A etc.)
    getClassByName(className) #TODO stop doing this and use fname instead
    
proc staticClass*(T:typedesc) : UClassPtr = staticClass[T]()
proc staticStruct*[T]() : UScriptStructPtr = 
    let structName : FString = typeof(T).name.substr(1) 
    getScriptStructByName(structName) 
proc staticStruct*(T:typedesc) : UScriptStructPtr = staticStruct[T]()


proc isChildOf*(str:UStructPtr, someBase:UStructPtr) : bool {.importcpp:"#->IsChildOf(@)".}


proc isChildOf*[T:UObject](cls: UClassPtr) : bool =
    let someBase = staticClass[T]()
    isChildOf(cls, someBase)

proc isChildOf*[C:UStruct, P:UStruct] : bool = isChildOf(staticClass[C](), staticClass[P]())

proc isA*[T:UObject](obj:UObjectPtr) : bool = obj.isA(staticClass(T))
   
proc isCDO*(self : UObjectPtr) : bool = RF_ClassDefaultObject in self.getFlags()
# Iterators
iterator UObjects*() : UObjectPtr =
  var objIter = makeFRawObjectIterator()
  for it in objIter.items():
    let obj = it.get()
    yield obj

func getAllObjectsOfClass*(cls:UClassPtr) : TArray[UObjectPtr] = 
  result = makeTArray[UObjectPtr]()
  for obj in UObjects():
    if obj.getClass() == cls:
      result.add(obj)

func getAllUClasses*() : TArray[UClassPtr] = 
  let cls = staticClass(UClass)
  result = makeTArray[UClassPtr]()
  for obj in UObjects():
    if obj.getClass() == cls:
      result.add(ueCast[UClass](obj))
  

#other

proc succeeded*(clsFinder : FClassFinder) : bool {.importcpp:"#.Succeeded()".}
proc makeClassFinder*[T](classToFind : FString) : FClassFinder[T]{.importcpp:"'0(*#)" .}
proc makeObjectFinder*[T](objectToFind : FString) : FObjectFinder[T]{.importcpp:"'0(*#)" .}


proc makeTSubclassOf*[T](cls:UClassPtr) : TSubclassOf[T] {. importcpp: "TSubclassOf<'*0>(#)", constructor.}
proc makeTSubclassOf*[T : UObject]() : TSubclassOf[T] = makeTSubclassOf[T](staticClass(T))
proc makeTSubclassOf*(T: typedesc) : TSubclassOf[T] = makeTSubclassOf[T]()
func staticSubclass*[T : UObject]() : TSubclassOf[T] = makeTSubclassOf(T)

proc get*(softObj : TSubclassOf) : UClassPtr {.importcpp:"#.Get()".}




#UFIELD
when WithEditor:
    proc setMetadata*(field:UFieldPtr|FFieldPtr, key, inValue:FString) : void {.importcpp:"#->SetMetaData(*#, *#)".}
    # proc getMetadata*(field:UFieldPtr|FFieldPtr, key:FString) :var FString {.importcpp:"#->GetMetaData(*#)".}
    proc findMetaData*(field:UFieldPtr|FFieldPtr, key:FString) : ptr FString {.importcpp:"const_cast<FString*>(#->FindMetaData(*#))".}
    #notice it also checks for the ue value. It will return false on "false"
    proc copyMetadata*(src, dst : UObjectPtr) : void {.importcpp:"UMetaData::CopyMetadata(@)".}

    func getMetaDataMapPtr(field:FFieldPtr) : ptr TMap[FName, FString] {.importcpp:"const_cast<'0>(#->GetMetaDataMap())".}
    
    func getMetaDataMapPtr(field:UObjectPtr) : ptr TMap[FName, FString] {.importcpp:"(UMetaData::GetMapForObject(#))".}

    func getMetadataMap*(field:FFieldPtr) : TMap[FName, FString] =
        when WithEditor:
            let metadataMap = getMetadataMapPtr(field)
            if metadataMap.isNil: makeTMap[FName, FString]()
            else: metadataMap[]
        else: makeTMap[FName, FString]()

    func getMetadataMap*(field:UObjectPtr) : TMap[FName, FString] =
        when WithEditor:
            let metadataMap = getMetadataMapPtr(field)
            if metadataMap.isNil: makeTMap[FName, FString]()
            else: metadataMap[]
        else: makeTMap[FName, FString]()
else:
    #only used in non editor builds (metadata is not available in non editor builds)
    var metadataTable* = newTable[pointer, TMap[FName, FString]]()
    func getMetadataMap*(field :UFieldPtr|FFieldPtr|UObjectPtr  ) : TMap[FName, FString] = 
        let outerKey = field.getFName()
        {.cast(noSideEffect).}:
            if field notin metadataTable:
                metadataTable.add(field, makeTMap[FName, FString]())
            metadataTable[field]
    proc setMetadata*(field:UFieldPtr|FFieldPtr, key, inValue:FString) = 
        
        let outerKey = field.getFName()
        # UE_Log "Adding key for field: " & $field.getFName() & " key: " & key & " value: " & inValue
        {.cast(noSideEffect).}:
            let map = field.getMetadataMap()
            let nkey = n key
            if nKey in map:
                map[nkey] = inValue
            else:
                map.add(nkey, inValue)
            metadataTable[field] = map
    proc copyMetadata*(src, dst : UObjectPtr) : void = 
        #assumes dst doesnt exists
        let srcMap = src.getMetadataMap()
        let dstMap = dst.getMetadataMap()
        metadataTable[dst] = srcMap

proc `$`*(pt:pointer) : string = $cast[int](pt)

func getMetadata*(field:UFieldPtr|FFieldPtr, key:FString) : Option[FString] = 
    let map = field.getMetadataMap()
    # {.cast(noSideEffect).}:

    #     UE_Log $metadataTable
    # UE_Log "Looking for key: " & key & " in map: " & $map & " for field: " & $field.getFName()
    let nKey = n key
    if nkey in map:
        some map[nkey]
    else:
        none[FString]()

func hasMetadata*(field:UFieldPtr|FFieldPtr, key:FString) : bool = field.getMetadata(key).isSome()


type ScriptContainer = FScriptArrayHelper | FScriptMapHelper
#ScriptArray
#  FScriptArrayHelper(const FArrayProperty* InProperty, const void* InArray)
proc makeScriptArrayHelper*(prop:FArrayPropertyPtr, inArray: pointer) : FScriptArrayHelper {.importcpp:"FScriptArrayHelper(#, #)", constructor .}
proc makeScriptArrayHelperInContainer*(prop:FArrayPropertyPtr, inArray: pointer) : FScriptArrayHelper {.importcpp:"FScriptArrayHelper_InContainer(#, #)", constructor .}

proc num*(helper: ScriptContainer | FScriptMap) : int32 {.importcpp:"#.Num()".}

proc addUninitializedValues*(helper : FScriptArrayHelper , count : int32) : void {.importcpp:"#.AddValues(#)".}
proc emptyAndAddUninitializedValues*(helper : FScriptArrayHelper, count : int32) : void {.importcpp:"#.EmptyAndAddUninitializedValues(#)".}
#returns the index of the last added
proc addValue*(helper: FScriptArrayHelper) : int32 {.importcpp:"#.AddValue()".}

#returns the raw pointer to the value 
proc getRawPtr*(helper: FScriptArrayHelper, idx:int32) : pointer {.importcpp:"#.GetRawPtr(#)".}

#ScriptMap
proc makeScriptMapHelper*(prop:FMapPropertyPtr, inMap: pointer) : FScriptMapHelper {.importcpp:"FScriptMapHelper(#, #)", constructor .}
proc makeScriptMapHelperInContainer*(prop:FMapPropertyPtr, inMap: pointer) : FScriptMapHelper {.importcpp:"FScriptMapHelper_InContainer(#, #)", constructor .}


proc getKeyPtr*(helper : FScriptMapHelper, idx:int32) : pointer {.importcpp:"#.GetKeyPtr(#)".}
proc getValuePtr*(helper : FScriptMapHelper, idx:int32) : pointer {.importcpp:"#.GetValuePtr(#)".}

proc getKeyProperty*(helper : FScriptMapHelper) : FPropertyPtr {.importcpp:"#.GetKeyProperty()".}
proc getValueProperty*(helper : FScriptMapHelper) : FPropertyPtr {.importcpp:"#.GetValueProperty()".}
proc addUninitializedValue*(helper : FScriptMapHelper) : void {.importcpp:"#.AddUninitializedValue()".}
proc emptyValues*(helper : FScriptMapHelper, stack: int32 = 0) : void {.importcpp:"#.EmptyValues(#)".} 
proc addPair*(helper : FScriptMapHelper, key, value: pointer) : void {.importcpp:"#.AddPair(@)".}
proc addDefaultValue_Invalid_NeedsRehash*(scriptMap: FScriptMapHelper) : void {.importcpp:"#.AddDefaultValue_Invalid_NeedsRehash()" .}
proc rehash*(scriptMap: FScriptMapHelper) : void {.importcpp:"#.Rehash()" .}

proc `=copy`*(dest: var FScriptMap, source: FScriptMap) {.error.}
proc addUninitialized*(scriptMap: FScriptMap, layout: var FScriptMapLayout) : void {.importcpp:"#.AddUninitialized(#)".}