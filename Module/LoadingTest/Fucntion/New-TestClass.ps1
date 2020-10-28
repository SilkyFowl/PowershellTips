function New-TestClass {
    param (
        $TestInput
    )
    return [TestClass]::new($TestInput)
}
