"""
# Base32 package

The Base32 package contains support for doing Base32 binary-to-text encodings
based on rfc4648.  See https://tools.ietf.org/html/rfc4648.

## Example code

```pony
use "Base32"

actor Main
  new create(env: Env) =>
    env.out.print(Base32.encode("foobar"))
    try
      env.out.print(Base32.decode[String iso]("MZXW6YTBOI======")?)
    end
```
"""

use "collections"
use "assert"

// Primitives for the decoding state machine
primitive _XXXAAAAA
primitive _XXXAAABB
primitive _XXXBBBBB
primitive _XXXBCCCC
primitive _XXXCCCCC
primitive _XXXCCCCD
primitive _XXXDDDDD
primitive _XXXDDEEE
primitive _XXXEEEEE

type _Base32StateMachine is (_XXXAAAAA | _XXXAAABB | _XXXBBBBB | _XXXBCCCC | _XXXCCCCC | _XXXCCCCD | _XXXDDDDD | _XXXDDEEE | _XXXEEEEE)

primitive Base32
  
  fun isValidData(data:U8):Bool =>
    not ( ((data >='2') and (data <= '7')) or ((data >='A') and (data <= 'Z')) )


  fun encode[A: Seq[U8] iso = String iso](
    data: ReadSeq[U8],
    linelen: USize = 0,
    linesep: String = "\r\n")
    : A^
  =>
    """
    Standard base32 encoding with configurable line length and separators.
    """ 

    let padchar: U8 = '='  // 0b0111_1101
    let len = ((data.size() + 7) / 5) * 8
    let out = recover A(len) end
    let lineblocks = linelen / 8

    var srclen = data.size()
    var blocks = USize(0)
    var i = USize(0)

    try
        // Process in chunks of 5 bytes for speed
        while \likely\ srclen >= 5 do
            let a = data(i)?
            let b = data(i + 1)?
            let c = data(i + 2)?
            let d = data(i + 3)?
            let e = data(i + 4)?

            // Bit manipulation broken out for clarity
            let out1 = a >> 3                                       // 00 00 00 a7 a6 a5 a4 a3              // _XXXAAAAA
            let out2 = ((a and 0b00000111) << 2) + (b >> 6)         // 00 00 00 a2 a1 a0 b7 b6              // _XXXAAABB
            let out3 = ((b and 0b00111110) >> 1)                    // 00 00 00 b5 b4 b3 b2 b1              // _XXXBBBBB
            let out4 = ((b and 0b00000001) << 4) + (c >> 4)         // 00 00 00 b0 c7 c6 c5 c4              // _XXXBCCCC
            let out5 = ((c and 0b00001111) << 1) + (d >> 7)         // 00 00 00 c3 c2 c1 c0 d7              // _XXXCCCCC
            let out6 = ((d and 0b01111100) >> 2)                    // 00 00 00 d6 d5 d4 d3 d2              // _XXXDDDDD
            let out7 = ((d and 0b00000011) << 3) + (e >> 5)         // 00 00 00 d1 d0 e7 e6 e5              // _XXXDDEEE
            let out8 = ((e and 0b00011111))                         // 00 00 00 e4 e3 e2 e1 e0              // _XXXEEEEE

            out.push(_enc_byte(out1)?)
            out.push(_enc_byte(out2)?)
            out.push(_enc_byte(out3)?)
            out.push(_enc_byte(out4)?)
            out.push(_enc_byte(out5)?)
            out.push(_enc_byte(out6)?)
            out.push(_enc_byte(out7)?)
            out.push(_enc_byte(out8)?)

            i = i + 5
            srclen = srclen - 5

            if \unlikely\ lineblocks > 0 then
                blocks = blocks + 1
                if (blocks == lineblocks) then
                    out.append(linesep)
                    blocks = 0
                end
            end
        end

        ////////////////////////////////////////////////////////////
        // Process Remainder Block (Between 1 and 4 data bytes)
        ////////////////////////////////////////////////////////////

        if srclen >= 1 then
            let a = data(i)?
            let b = if srclen >= 2 then data(i + 1)? else 0 end
            let c = if srclen >= 3 then data(i + 2)? else 0 end
            let d = if srclen >= 4 then data(i + 3)? else 0 end

            let out1 = (a >> 3)                                     // 00 00 00 a7 a6 a5 a4 a3
            let out2 = ((a and 0b00000111) << 2) + (b >> 6)         // 00 00 00 a2 a1 a0 b7 b6
            let out3 = ((b and 0b00111110) >> 1)                    // 00 00 00 b5 b4 b3 b2 b1
            let out4 = ((b and 0b00000001) << 4) + (c >> 4)         // 00 00 00 b0 c7 c6 c5 c4
            let out5 = ((c and 0b00001111) << 1) + (d >> 7)         // 00 00 00 c3 c2 c1 c0 d7
            let out6 = ((d and 0b01111100) >> 2)                    // 00 00 00 d6 d5 d4 d3 d2
            let out7 = ((d and 0b00000011) << 3)                    // 00 00 00 d1 d0 00 00 00
            //  out8 (e) is unnecessary since it is always a pad    // 00 00 01 01 01 01 00 01

            // for testing
            let out8 = padchar

            // _XXXAAAAA
            // _XXXAAABB
            // _XXXBBBBB
            // _XXXBCCCC
            // _XXXCCCCC
            // _XXXCCCCD
            // _XXXDDDDD

            ////////////////////////////////////////////////////////////
            // Validate Remainder Block
            ////////////////////////////////////////////////////////////

            // At the start if out8 is a padchar then we validate the remainder block
            var valid=true
            if (out8 == padchar) then
                valid = valid and ( not((out1 == padchar) or (not isValidData(out1)) or
                        (out2 == padchar) or (not isValidData(out2))) )
                if out3 == padchar then
                    valid = valid and ((out2 and 0xE3) > 0)
                else 
                    valid = valid and isValidData(out3)
                    if out4 == padchar then
                        valid = valid and (((out2 and 0xE3) > 0) or (out3 > 0) )
                    else
                        valid = valid and isValidData(out4)
                        if out5 == padchar then
                            valid = valid and ((out4 and 0xEF) > 0)
                        else
                            valid = valid and isValidData(out5)
                            if out6 == padchar then
                                valid = valid and ((out5 and 0xE1) > 0)
                            else
                                valid = valid and isValidData(out6)
                                if out7 == padchar then
                                    valid = valid and (((out5 and 0xE1) > 0) or (out6 > 0) )
                                else
                                    valid = valid and isValidData(out7)
                                end
                            end
                        end
                    end
                end
            end

            if not valid then error end


            ////////////////////////////////////////////////////////////
            // Compose Remainder Block 
            ////////////////////////////////////////////////////////////

            // // Always push two first two outputs if doing any remainder
            out.push(_enc_byte(out1)?)  
            out.push(_enc_byte(out2)?)
            var padding: U8 = 0

            if srclen >= 2 then
                out.push(_enc_byte(out3)?)
                out.push(_enc_byte(out4)?)
            else
                padding=padding+2
            end

            if srclen >= 3 then
                out.push(_enc_byte(out5)?)
            else
                padding=padding+1
            end

            if srclen == 4 then
                out.push(_enc_byte(out6)?)
                out.push(_enc_byte(out7)?)
                padding=padding+1
            else
                padding=padding+3
            end

            // Padding
            for x in Range[U8](0, padding) do
                out.push(padchar)
            end    
        
        end


        if lineblocks > 0 then
            out.append(linesep)
        end

    else  //try failed
        out.clear()
    end

    out


fun decode[A: Seq[U8] iso = Array[U8] iso](
     data: ReadSeq[U8])
     : A^ ?
   =>

    """
    Decodes Base32 according to rfc4648.  Omitted padding at the end is
    not an error. Non-Base32 data, other than whitespace (which can appear at
    any time), is an error.
    """

    // Every 8 input bytes becomes 5 output bytes
    let len :USize = ((data.size() + 7) / 8) * 5
    var out = recover A(len) end

    var state : _Base32StateMachine = _XXXAAAAA
    var input = U8(0)
    var output = U8(0)
    let padchar: U8 = '='
 
    for i in Range(0, data.size()) do

        input = data(i)?

        let value =
            match input
            | ' ' | '\t' | '\r' | '\n' => continue
            | padchar => break
            | if (input >= 'A') and (input <= 'Z') =>
                (input - 'A')
            | if (input >= '2') and (input <= '7') =>
                ((input - '2') + 26)
            else
                error
            end

        match state
        | _XXXAAAAA =>
            output = value << 3
            state = _XXXAAABB

        | _XXXAAABB =>
            output = output or ((value and 0x1C)>> 2)
            out.push(output)                               
            output = (value and 0x03) << 6           
            state = _XXXBBBBB                           

        | _XXXBBBBB =>
            output = output or ((value and 0x1F) << 1)
            state = _XXXBCCCC
        
        | _XXXBCCCC =>
            output = output or ((value and 0x10) >> 4)
            out.push(output)                                
            output = value << 4                             
            state = _XXXCCCCD

        | _XXXCCCCD =>
            output = output or ((value and 0x1E) >> 1)     
            out.push(output)                               
            output = (value and 0x01) << 7                 
            state = _XXXDDDDD

        | _XXXDDDDD =>
            output = value << 2                            
            state = _XXXDDEEE

        | _XXXDDEEE =>
            output = output or ((value and 0x18) >> 3 )    
            out.push(output)                                
            output = value << 5                             
            state = _XXXEEEEE

        | _XXXEEEEE =>
            output = output or value                        
            out.push(output)                                
            output = 0
            state=_XXXAAAAA
        else
            error
        end //match

    end // for

    if output != 0 then
        Fact(input != padchar)?
        out.push(output)
    end

    out

  // A chomp is five bits...one more than a nibble.
  fun _enc_byte(chomp: U8): U8 ? =>
    """
    Encode a single byte.
    """
    match chomp
      | if chomp < 26 => 'A' + chomp
      | if chomp < 31 => '2' + (chomp - 26)
    else
      error
    end
