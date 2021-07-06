namespace PsInvokeFs

open type Microsoft.Windows.Sdk.PInvoke

module Say =
    
    let boo ()  =
        0
    let hello name =
        printfn "Hello %s" name
