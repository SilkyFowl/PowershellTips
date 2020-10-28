class TestChildClass : TestClass {
    [int]$Bar

    TestChildClass([string]$Foo,[int]$Bar) : base($Foo) {
        $this.Bar = $Bar
    }
}