package client

import "testing"

func TestCliparserEmpty(t *testing.T){
    in := []byte(`200 0`)
    out := Cli{200, []byte("")}

    result := Cliparser(in)
    if result.Status != out.Status {
        t.Errorf("%i\n\nreturned want:\n %i", result.Status, out.Status)
    }

    if string(result.Body) != string(out.Body) {
        t.Errorf("%s returned want %s", result.Body, out.Body)
    }

}

func TestCliparserShort(t *testing.T){
    in := []byte(`200 13
VCL compiled.`)
    out := Cli{200, []byte(`VCL compiled.`)}

    result := Cliparser(in)
    if result.Status != out.Status {
        t.Errorf("%i\n\nreturned want:\n %i", result.Status, out.Status)
    }

    if string(result.Body) != string(out.Body) {
        t.Errorf("%s returned want %s", result.Body, out.Body)
    }

}

func TestCliparserLong(t *testing.T){
    in := []byte(`200 233     
-----------------------------
Varnish Cache CLI 1.0
-----------------------------
Darwin,13.0.0,x86_64,-sfile,-smalloc,-hcritbit

Type 'help' for command list.
Type 'quit' to close CLI session.
Type 'start' to launch worker process.
`)
    out := Cli{200, []byte(
`-----------------------------
Varnish Cache CLI 1.0
-----------------------------
Darwin,13.0.0,x86_64,-sfile,-smalloc,-hcritbit

Type 'help' for command list.
Type 'quit' to close CLI session.
Type 'start' to launch worker process.
`)}

    result := Cliparser(in)
    if result.Status != out.Status {
        t.Errorf("%i\n\nreturned want:\n %i", result.Status, out.Status)
    }

    if string(result.Body) != string(out.Body) {
        t.Errorf("%s returned want %s", result.Body, out.Body)
    }

}

func BenchmarkCliparserLong(b *testing.B){
    b.StopTimer()
    in := []byte(`200 233     
-----------------------------
Varnish Cache CLI 1.0
-----------------------------
Darwin,13.0.0,x86_64,-sfile,-smalloc,-hcritbit

Type 'help' for command list.
Type 'quit' to close CLI session.
Type 'start' to launch worker process.
`)

    b.StartTimer()
    for i := 0; i < b.N; i++ {
        Cliparser(in)
    }
}
