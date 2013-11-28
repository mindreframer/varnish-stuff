
// line 1 "cliparser.rl"
package client


// line 7 "cliparser.go"
var _cliparser_actions []byte = []byte{
	0, 1, 0, 1, 1, 1, 2, 1, 3, 
}

var _cliparser_key_offsets []byte = []byte{
	0, 0, 3, 5, 11, 15, 18, 21, 
	22, 
}

var _cliparser_trans_keys []byte = []byte{
	32, 48, 57, 48, 57, 10, 32, 9, 
	13, 48, 57, 10, 32, 9, 13, 32, 
	48, 57, 32, 48, 57, 32, 
}

var _cliparser_single_lengths []byte = []byte{
	0, 1, 0, 2, 2, 1, 1, 1, 
	0, 
}

var _cliparser_range_lengths []byte = []byte{
	0, 1, 1, 2, 1, 1, 1, 0, 
	0, 
}

var _cliparser_index_offsets []byte = []byte{
	0, 0, 3, 5, 10, 14, 17, 20, 
	22, 
}

var _cliparser_indicies []byte = []byte{
	0, 2, 1, 3, 1, 5, 4, 4, 
	3, 1, 7, 6, 6, 1, 0, 8, 
	1, 0, 9, 1, 0, 1, 10, 
}

var _cliparser_trans_targs []byte = []byte{
	2, 0, 5, 3, 4, 8, 4, 8, 
	6, 7, 8, 
}

var _cliparser_trans_actions []byte = []byte{
	0, 0, 1, 3, 5, 5, 0, 0, 
	1, 1, 7, 
}

const cliparser_start int = 1
const cliparser_first_final int = 8
const cliparser_error int = 0

const cliparser_en_main int = 1


// line 6 "cliparser.rl"


type Cli struct {
    Status int
    Body []byte
}

func Cliparser(data []byte) (cli *Cli){
    cs, p, pe := 0, 0, len(data)
    cli = new(Cli)
    bodylength, bodypos := 0, 0
    
// line 74 "cliparser.go"
	{
	cs = cliparser_start
	}

// line 79 "cliparser.go"
	{
	var _klen int
	var _trans int
	var _acts int
	var _nacts uint
	var _keys int
	if p == pe {
		goto _test_eof
	}
	if cs == 0 {
		goto _out
	}
_resume:
	_keys = int(_cliparser_key_offsets[cs])
	_trans = int(_cliparser_index_offsets[cs])

	_klen = int(_cliparser_single_lengths[cs])
	if _klen > 0 {
		_lower := int(_keys)
		var _mid int
		_upper := int(_keys + _klen - 1)
		for {
			if _upper < _lower {
				break
			}

			_mid = _lower + ((_upper - _lower) >> 1)
			switch {
			case data[p] < _cliparser_trans_keys[_mid]:
				_upper = _mid - 1
			case data[p] > _cliparser_trans_keys[_mid]:
				_lower = _mid + 1
			default:
				_trans += int(_mid - int(_keys))
				goto _match
			}
		}
		_keys += _klen
		_trans += _klen
	}

	_klen = int(_cliparser_range_lengths[cs])
	if _klen > 0 {
		_lower := int(_keys)
		var _mid int
		_upper := int(_keys + (_klen << 1) - 2)
		for {
			if _upper < _lower {
				break
			}

			_mid = _lower + (((_upper - _lower) >> 1) & ^1)
			switch {
			case data[p] < _cliparser_trans_keys[_mid]:
				_upper = _mid - 2
			case data[p] > _cliparser_trans_keys[_mid + 1]:
				_lower = _mid + 2
			default:
				_trans += int((_mid - int(_keys)) >> 1)
				goto _match
			}
		}
		_trans += _klen
	}

_match:
	_trans = int(_cliparser_indicies[_trans])
	cs = int(_cliparser_trans_targs[_trans])

	if _cliparser_trans_actions[_trans] == 0 {
		goto _again
	}

	_acts = int(_cliparser_trans_actions[_trans])
	_nacts = uint(_cliparser_actions[_acts]); _acts++
	for ; _nacts > 0; _nacts-- {
		_acts++
		switch _cliparser_actions[_acts-1] {
		case 0:
// line 18 "cliparser.rl"

cli.Status = cli.Status*10+(int(data[p])-'0')
		case 1:
// line 19 "cliparser.rl"

bodylength = bodylength*10+(int(data[p])-'0')
		case 2:
// line 20 "cliparser.rl"

cli.Body = make([]byte,bodylength)
		case 3:
// line 21 "cliparser.rl"

if bodypos == bodylength {p++; goto _out
}; cli.Body[bodypos]=data[p]; bodypos++
// line 175 "cliparser.go"
		}
	}

_again:
	if cs == 0 {
		goto _out
	}
	p++
	if p != pe {
		goto _resume
	}
	_test_eof: {}
	_out: {}
	}

// line 25 "cliparser.rl"


    return cli
}

