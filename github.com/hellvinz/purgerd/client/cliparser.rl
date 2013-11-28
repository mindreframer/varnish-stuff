package client

%%{
    machine cliparser;
    write data;
}%%

type Cli struct {
    Status int
    Body []byte
}

func Cliparser(data []byte) (cli *Cli){
    cs, p, pe := 0, 0, len(data)
    cli = new(Cli)
    bodylength, bodypos := 0, 0
    %%{
        action status {cli.Status = cli.Status*10+(int(fc)-'0')}
        action bodylength {bodylength = bodylength*10+(int(fc)-'0')}
        action makebody {cli.Body = make([]byte,bodylength)}
        action body {if bodypos == bodylength {fbreak;}; cli.Body[bodypos]=fc; bodypos++}
        main := digit{,3}@status " " digit+ @bodylength %makebody space* "\n" (any*)@body;
        write init;
        write exec;
    }%%

    return cli
}

