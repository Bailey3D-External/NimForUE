include ../unreal/prelude

import ../codegen/[modelconstructor, ueemit, uebind, models, uemeta]
import std/[json, jsonutils, sequtils, options, sugar, enumerate, strutils]

import ../vm/uecall
import ../test/testutils


uClass UObjectPOC of UObject:
  (BlueprintType)
  ufunc: 
    proc instanceFunc() = 
      UE_Log "Hola from UObjectPOC instanceFunc"

    proc instanceFuncWithOneArgAndReturnTest(arg : int) : FVector = FVector(x:arg.float32, y:arg.float32, z:arg.float32)

  ufuncs(Static):
    proc salute() = 
      UE_Log "Hola from UObjectPOC"
    proc saluteWithOneArg(arg : int) = 
      UE_Log "Hola from UObjectPOC with arg: " & $arg
    proc saluteWithOneArgStr(arg : FString) = 
      UE_Log "Hola from UObjectPOC with arg: " & $arg
    proc saluteWithTwoArgs(arg1 : int, arg2 : int) = 
      UE_Log "Hola from UObjectPOC with arg1: " & $arg1 & " and arg2: " & $arg2
    proc saluteWithTwoDifferentArgs(arg1 : FString, arg2 : FString) = 
      UE_Log "Hola from UObjectPOC with arg1: " & $arg1 & " and arg2: " & $arg2
    proc saluteWitthTwoDifferentIntSizes(arg1 : int32, arg2 : int64) = 
      UE_Log "Hola from UObjectPOC with arg1: " & $arg1 & " and arg2: " & $arg2
    proc saluteWitthTwoDifferentIntSizes2(arg1 : int64, arg2 : int32) = 
      UE_Log "Hola from UObjectPOC with arg1: " & $arg1 & " and arg2: " & $arg2
    proc printObjectName(obj:UObjectPtr) = 
      UE_Log "Object name: " & $obj.getName()
    proc printObjectNameWithSalute(obj:UObjectPtr, salute : FString) = 
      UE_Log "Object name: " & $obj.getName() & " Salute: " & $salute
    proc printObjectAndReturn(obj:UObjectPtr) : int = 
      UE_Log "Object name: " & $obj.getName() 
      10
    proc printObjectAndReturnPtr(obj:UObjectPtr) : UObjectPtr = 
      UE_Log "Object name: " & $obj.getName() 
      obj
    proc printObjectAndReturnStr(obj:UObjectPtr) : FString = 
      let str = "Object name: " & $obj.getName() 
      UE_Log str
      str
    proc printVector(vec : FVector) = 
      UE_Log "Vector: " & $vec


    proc printIntArray(ints : TArray[int]) = 
      UE_Log "Int array length: " & $ints.len
      for vec in ints:
        UE_Log "int: " & $vec
    proc printVectorArray(vecs : TArray[FVector]) = 
      UE_Log "Vector array length: " & $vecs.len
      for vec in vecs:
        UE_Log "Vector: " & $vec

    proc receiveFloat32(arg : float32) = #: float32 = 
      UE_Log "Float32: " & $arg
      # return arg

    
    proc receiveFloat64(arg : float) = 
      UE_Log "Float64: " & $arg

    proc receiveVectorAndFloat32(dir:FVector, scale:float32) = 
      UE_Error "receiveVectorAndFloat32 " & $dir & " scale:" & $scale

    proc modifyAndReturnVector(vec : FVector) : FVector = 
      var vec = vec
      vec.x = 10 * vec.x
      vec.y = 10 * vec.y
      vec.z = 10 * vec.z
      vec
    
#[
1. [x] Create a function that makes a call by fn name
2. [x] Create a function that makes a call by fn name and pass a value argument
  2.1 [x] Create a function that makes a call by fn name and pass a two values of the same types as argument
  2.2 [x] Create a function that makes a call by fn name and pass a two values of different types as argument
  2.3 [x] Pass a int32 and a int64
3. [x] Create a function that makes a call by fn name and pass a pointer argument
4. [x] Create a function that makes a call by fn name and pass a value and pointer argument
5. [x] Create a function that makes a call by fn name and pass a value and pointer argument and return a value
6. [x] Create a function that makes a call by fn name and pass a value and pointer argument and return a pointer
  6.1 [x] Create a function that makes a call by fn name and pass a value and pointer argument and returns a string
7. [ ] Repeat 1-6 where value arguments are complex types
8. [ ] Add support for missing basic types
8. Arrays
9. TMaps

]#

# proc registerVmTests*() = 
#   unregisterAllNimTests()
#   suite "Hello":
#     ueTest "should create a ":
#       assert true == false
#     ueTest "another create a test2":
#       assert true == true

template check*(expr: untyped) =
  if not expr:
    let exprStr = repr expr
    var msg = "Check failed: " & exprStr & " " 
    raise newException(CatchableError, msg)

#maybe the way to go is by raising. Let's do a test to see if we can catch the errors in the actual actor

#Later on this can be an uobject that pulls and the actor will just run them. But this is fine as started point
uClass ANimTestBase of AActor: 
  ufunc(CallInEditor):
    proc runTests() = 
     #Traverse all the tests and run them. A test is a function that starts with "test" or "should
      let testFns = self
                      .getClass()
                      .getFuncsFromClass()
                      .filterIt(
                        it.getName().tolower.startsWith("test") or 
                        it.getName().tolower.startsWith("should"))
      for fn in testFns:
        try:
          UE_Log "Running test: " & $fn.getName()
          self.processEvent(fn, nil)
        except CatchableError as e:
          UE_Error "Error in test: " & $fn.getName() & " " & $e.msg
         



uClass AActorPOCVMTest of ANimTestBase:
  (BlueprintType)
  ufuncs(CallInEditor):
    # proc test1() = 
    #   let callData = UECall( fn: makeUEFunc("salute", "UObjectPOC"))
    #   discard uCall(callData)
    #   check true == false
    # proc test2() =
    #   let callData = UECall(
    #       fn: makeUEFunc("saluteWithOneArg", "UObjectPOC"),
    #       value: (arg: 10).toJson()
    #     )
    #   discard uCall(callData)
    # proc test21() = 
    #   let callData = UECall(
    #       fn: makeUEFunc("saluteWithOneArgStr", "UObjectPOC"),
    #       value: (arg: "10 cadena").toJson()
    #     )
    #   discard uCall(callData)

    # proc test23() =
    #   let callData = UECall(
    #       fn: makeUEFunc("saluteWithTwoDifferentArgs", "UObjectPOC"),
    #       value: (arg1: "10 cadena", arg2: "Hola").toJson()
    #     )
    #   discard uCall(callData)
    # proc test24() = 
    #   let callData = UECall(
    #       fn: makeUEFunc("saluteWitthTwoDifferentIntSizes", "UObjectPOC"),
    #       value: (arg1: 10, arg2: 10).toJson()
    #     )
    #   discard uCall(callData)

    # proc test25() = 
    #   let callData = UECall(
    #       fn: makeUEFunc("saluteWitthTwoDifferentIntSizes2", "UObjectPOC"),
    #       value: (arg1: 15, arg2: 10).toJson()
    #     )
    #   discard uCall(callData)


    # proc test3() = 
    #   let callData = UECall(
    #       fn: makeUEFunc("saluteWithTwoArgs", "UObjectPOC"),
    #       value: (arg1: 10, arg2: 20).toJson()
    #     )
    #   discard uCall(callData)

    # proc test4() =
    #   let callData = UECall(
    #       fn: makeUEFunc("printObjectName", "UObjectPOC"),
    #       value: (obj: cast[int](self)).toJson()
    #     )
    #   discard uCall(callData)
    # proc test5() = 
    #   let callData = UECall(
    #       fn: makeUEFunc("printObjectNameWithSalute", "UObjectPOC"),
    #       value: (obj: cast[int](self), salute: "Hola").toJson()
    #     )
    #   discard uCall(callData)
    # proc test6() =
    #   let callData = UECall(
    #       fn: makeUEFunc("printObjectAndReturn", "UObjectPOC"),
    #       value: (obj: cast[int](self)).toJson()
    #     )
    #   UE_Log $uCall(callData)

    # proc test7() =
    #   let callData = UECall(
    #       fn: makeUEFunc("printObjectAndReturnPtr", "UObjectPOC"),
    #       value: (obj: cast[int](self)).toJson()
    #     )
    #   let objAddr = uCall(callData).jsonTo(int)
    #   let obj = cast[UObjectPtr](objAddr)
    #   UE_Log $obj
    # proc test8() = 
    #   let callData = UECall(
    #       fn: makeUEFunc("printObjectAndReturnStr", "UObjectPOC"),
    #       value: (obj: cast[int](self)).toJson()
    #     )
    #   UE_Log $uCall(callData).jsonTo(string)
    # proc test9() = 
    #   let callData = UECall(
    #       fn: makeUEFunc("printVector", "UObjectPOC"),
    #       value: (vec:FVector(x:12, y:10)).toJson()
    #     )
    #   UE_Log  $uCall(callData).jsonTo(string)

    # proc test10() = 
    #   let callData = UECall(
    #       fn: makeUEFunc("printIntArray", "UObjectPOC"),
    #       value: (ints:[2, 10]).toJson()
    #     )
    #   UE_Log  $uCall(callData).jsonTo(string)

    # proc test11() = 
    #   let callData = UECall(
    #       fn: makeUEFunc("printVectorArray", "UObjectPOC"),
    #       value: (vecs:[FVector(x:12, y:10), FVector(x:12, z:1)]).toJson()
    #     )
    #   UE_Log  $uCall(callData).jsonTo(string)

    # proc test12NoArray() = 
    #   let callData = UECall(
    #       fn: makeUEFunc("modifyAndReturnVector", "UObjectPOC"),
    #       value: (vec:FVector(x:12, y:10)).toJson()
    #     )
    #   UE_Log  $uCall(callData)

    # proc test13NoStatic() = 
    #   let callData = UECall(
    #       fn: makeUEFunc("instanceFunc", "UObjectPOC"),
        
    #       value: (vec:FVector(x:12, y:10)).toJson(),
    #       self: cast[int](self)
    #     )
    #   UE_Log  $uCall(callData)
    # proc vectorToJsonTest() =
    #   UE_Log $FVector(x:10, y:10).toJson()
    #   let vectorScriptStruct = staticStruct(FVector)
    #   let structProps = vectorScriptStruct.getFPropsFromUStruct()
    #   for prop in structProps:
    #     UE_Log $prop.getName()

    proc shouldReceiveFloat32() =
      let expected = 10.0
      let callData = UECall(
          fn: makeUEFunc("receiveFloat32", "UObjectPOC"),
          value: (arg: 10.0).toRuntimeField()
        )
      let val =  uCall(callData)#.jsonTo(float)
      # check val == expected

    proc shouldReceiveFloat64() =
      let callData = UECall(
          fn: makeUEFunc("receiveFloat64", "UObjectPOC"),
          value: (arg: 10.0).toRuntimeField()
        )
      discard uCall(callData)

    # proc shouldReceiveVectorAndFloat32() =
    #   let callData = UECall(
    #       fn: makeUEFunc("receiveVectorAndFloat32", "UObjectPOC"),
    #       value: (dir: FVector(x:10, y:10), scale: 10.0).toJson()
    #     )
    #   discard uCall(callData)