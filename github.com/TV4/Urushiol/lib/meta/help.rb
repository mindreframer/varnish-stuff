module Urushiol
  HELP = "Usage: urushiol [-v] [-h] [-l] [-m] [<args>]

    If no flags are specified <args> should be test file(s).

    -v, --version                    Print the version and exit.
    -h, --help                       Print this help.
    -l, --live                       Runs tests on live vcl file; backends
                                     will be real servers. <args> should be
                                     path to vcl file and path to test file(s).
    -m, --mock                       Runs tests on mocked vcl file; backends
                                     will be mocked servers that return 200 as
                                     status code and the backend name as body.
                                     <args> should be path to vcl file and path
                                     to test file(s).
    "
end