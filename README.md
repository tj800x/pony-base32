# Pony-Base32 (Experimental Status)

## Introduction

>Base32 is a binary-to-text encoding scheme that represents binary data in an
ASCII string format by translating the data into a radix-32 representation.
Each non-final Base32 digit represents exactly 5 bits of data. Five 8-bit bytes
(i.e., a total of 40 bits) can therefore be represented by eight 5-bit Base32
digits; this is known as a block.  RFC4648 compliant encoding requires that the 
resultant string be a full block, so "remainder blocks" are padded with '=' characters.

This project is based on the Base64 component that is included in the Standard Pony Library.

## Code Samples

```pony
use "Base32"

actor Main
  new create(env: Env) =>
    env.out.print(Base32.encode("foobar"))
    try
      env.out.print(Base32.decode[String iso]("MZXW6YTBOI======")?)
    end
```
## Notes
* An error is raised during decoding if the string is not a valid Base32 encoded string. 


## Installation

Corral Instructions:

```shell
$ corral add github.com/tj800x/pony-base32.git
$ corral run -- ponyc
```

### Tests
Running the project executable will execute the tests, which should look something like this:

```shell
$ ./pony-base32
1 test started, 0 complete: Base32/Encode.Empty started
2 tests started, 0 complete: Base32/Encode.Basic started
2 tests started, 1 complete: Base32/Encode.Empty complete
3 tests started, 1 complete: Base32/Encode.foobar started
4 tests started, 1 complete: Base32/Decode.Empty started
4 tests started, 2 complete: Base32/Encode.foobar complete
5 tests started, 2 complete: Base32/Decode.Basic started
6 tests started, 2 complete: Base32/Decode.Foobar started
7 tests started, 2 complete: Base32/Decode.Impossible started
7 tests started, 3 complete: Base32/Decode.Basic complete
8 tests started, 3 complete: Base32/Decode.Impossible.Chunked started
8 tests started, 4 complete: Base32/Decode.Impossible.Chunked complete
8 tests started, 5 complete: Base32/Encode.Basic complete
8 tests started, 6 complete: Base32/Decode.Empty complete
8 tests started, 7 complete: Base32/Decode.Foobar complete
8 tests started, 8 complete: Base32/Decode.Impossible complete
---- Passed: Base32/Encode.Empty
---- Passed: Base32/Encode.Basic
---- Passed: Base32/Encode.foobar
---- Passed: Base32/Decode.Empty
---- Passed: Base32/Decode.Basic
---- Passed: Base32/Decode.Foobar
---- Passed: Base32/Decode.Impossible
---- Passed: Base32/Decode.Impossible.Chunked
----
---- 8 tests ran.
---- Passed: 8
```
