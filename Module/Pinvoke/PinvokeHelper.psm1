using namespace System.Management.Automation
using namespace System.Management.Automation.Language
using namespace System.Collections
using namespace System.Collections.Generic
using namespace System.Reflection
using namespace System.Reflection.Emit
using namespace System.Runtime.InteropServices
using namespace System.Text
using namespace System.Threading


#region Variables
$Script:counter ??= 0
$Script:DynamicClassAssemblyName = 'PowerShell PInvoke Helper Class Assembly'
#endregion

#region Completion Class
class TypeCompleter : IArgumentCompleter {
    [IEnumerable[CompletionResult]] CompleteArgument(
        [string] $CommandName,
        [string] $ParameterName,
        [string] $WordToComplete,
        [CommandAst] $CommandAst,
        [IDictionary] $FakeBoundParameters
    ) {
        $result = TabExpansion2 "[$WordToComplete"
        $index = $result.ReplacementIndex - 1
        $length = $result.ReplacementLength

        [CompletionResult[]]$CompletionResults = $result.CompletionMatches.where{ $_.ResultType -eq 'Type' }.foreach{
            [CompletionResult]::new(
                [StringBuilder]::new($WordToComplete).Remove($index, $length).Insert($index, $_.CompletionText),
                $_.ListItemText,
                $_.ResultType,
                $_.ToolTip
            )
        }        

        return $CompletionResults
    }
}
class TypeCompletionAttribute : ArgumentCompleterAttribute, IArgumentCompleterFactory {
    [IArgumentCompleter] Create() { return [TypeCompleter]::new() }
}

class ParameterCompleter : IArgumentCompleter {
    [IEnumerable[CompletionResult]] CompleteArgument(
        [string] $CommandName,
        [string] $ParameterName,
        [string] $WordToComplete,
        [CommandAst] $CommandAst,
        [IDictionary] $FakeBoundParameters
    ) {
        $trimedComplete = $WordToComplete -replace "^'" -replace "'$"
        $typeName, $parameterName = $trimedComplete -split ']'

        $result = TabExpansion2 $typeName
        $index = $result.ReplacementIndex
        $length = $result.ReplacementLength

        [CompletionResult[]]$CompletionResults = $result.CompletionMatches.where{ $_.ResultType -eq 'Type' }.foreach{
            [CompletionResult]::new(
                "'{0}'" -f
                [StringBuilder]::new($trimedComplete).Remove($index, $length).Insert($index, $_.CompletionText),
                $_.ListItemText,
                $_.ResultType,
                $_.ToolTip
            )
        }

        return $CompletionResults
    }
}
class ParameterCompletionAttribute : ArgumentCompleterAttribute, IArgumentCompleterFactory {
    [IArgumentCompleter] Create() { return [ParameterCompleter]::new() }
}

#endregion

function New-DynamicModule {
    # アセンブリ、モジュール、型ビルダー定義
    $assemblyName = [AssemblyName]@{
        Name    = $Script:DynamicClassAssemblyName
        Version = [version]::new(1, 0, 0, [Interlocked]::Increment([ref]$Script:counter))
    }
        
    $assembly = [AssemblyBuilder]::DefineDynamicAssembly($assemblyName, 'RunAndCollect')
    $assembly.DefineDynamicModule($Script:DynamicClassAssemblyName)
}

function Add-DelegateType {
    param (
        [string]$Typename,
        [TypeCompletionAttribute()]
        [Type]$ReturnType = [void],
        [TypeCompletionAttribute()]
        [Type[]]$ParameterTypes = [Type[]]::new(0)
    )
    $module = New-DynamicModule
    $typeBuilder = $module.DefineType(
        $TypeName,
        'Public, AutoClass, AnsiClass, Sealed',
        [MulticastDelegate],
        [Type[]]::new(0)
    )

    # .ctor
    $ConstructorBuilder = $typeBuilder.DefineConstructor(
        'Public, HideBySig, SpecialName, RTSpecialName',
        'Standard',
        $ParameterTypes
    )
    $ConstructorBuilder.SetImplementationFlags('Runtime, Managed')

    # Invoke
    $MethodBuilder = $typeBuilder.DefineMethod(
        'Invoke',
        'Public, HideBySig, NewSlot, Virtual',
        $ReturnType,
        $ParameterTypes
    )
    $MethodBuilder.SetImplementationFlags('Runtime, Managed')

    # BeginInvoke
    $MethodBuilder = $typeBuilder.DefineMethod(
        'BeginInvoke',
        'Public, HideBySig, NewSlot, Virtual',
        [IAsyncResult],
        ($ParameterTypes + [AsyncCallback],[Object])
    )
    $MethodBuilder.SetImplementationFlags('Runtime, Managed')
    
    # EndInvoke
    $MethodBuilder = $typeBuilder.DefineMethod(
        'EndInvoke',
        'Public, HideBySig, NewSlot, Virtual',
        [bool],
        [IAsyncResult]
    )
    $MethodBuilder.SetImplementationFlags('Runtime, Managed')

    return $typeBuilder.CreateType()
}

function Add-PinvokeType {
    param (
        [string]$TypeName,
        [string]$ProcName,
        [string]$ModuleFile,
        [string]$EntryPoint,
        [TypeCompletionAttribute()]
        [Type]$ReturnType = [void],
        [TypeCompletionAttribute()]
        [Type[]]$ParameterTypes = [Type]::EmptyTypes,
        [CallingConvention]$CallingConvention = [CallingConvention]::Stdcall,
        [CharSet]$CharSet = [CharSet]::Auto
    )
    $module = New-DynamicModule
    $typeBuilder = $module.DefineType($TypeName, 'Public, Class')

    # メソッド定義
    $methodBuilder = $typeBuilder.DefinePInvokeMethod(
        $ProcName,
        $ModuleFile,
        $EntryPoint,
        'Public, Static, PinvokeImpl, HideBySig',
        'Standard',
        $ReturnType,
        $ParameterTypes,
        $CallingConvention,
        $CharSet
    )
    $methodBuilder.SetImplementationFlags('PreserveSig')

    # 型作成
    return $typeBuilder.CreateType()
}

function New-PsMethod {
    param (
        [TypeCompletionAttribute()]
        [Type]$ReturnType = [void],
        [ParameterCompletionAttribute()]
        [string[]]$ParameterTypes = '',
        [scriptblock]$Acttion
    )

    Invoke-Expression @"
    class __TempClass {
        static [$ReturnType] TempMethod ($($ParameterTypes -join ', ')) {
            $Acttion
        }
    }
"@
    [__TempClass]::TempMethod
}