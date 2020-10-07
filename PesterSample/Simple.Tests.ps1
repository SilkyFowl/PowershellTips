Describe "d" {

    BeforeAll {
        function f ($a) { "real" }
        Mock f { "mock" } -ParameterFilter { $a -eq 10 }
    }

    It "i" {
        f 10
        Should -Invoke f -Exactly 1
    }

    It "j" {
        f 20
        Should -Invoke f -Exactly 0
    }
}