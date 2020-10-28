function New-TestChildClass {
    param (
        $TestInput,
        $TestInput2
    )
    return [TestChildClass]::new($TestInput,$TestInput2)
}