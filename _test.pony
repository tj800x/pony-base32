use "json" 
use "ponytest"
use "collections"

actor Main is TestList
  new create(env: Env) => PonyTest(env, this)
  new make() => None

  fun tag tests(test: PonyTest) =>

    test(_TestBase32EncodeEmpty)
    test(_TestBase32EncodeBasic)
    test(_TestBase32EncodeFoobar)

    test(_TestBase32DecodeEmpty)
    test(_TestBase32DecodeBasic)
    test(_TestBase32DecodeFoobar)

    test(_TestBase32DecodeImpossible)
    test(_TestBase32DecodeImpossibleChunked)


class iso _TestBase32EncodeEmpty is UnitTest
  """
  Test the encoding of an empty string to empty
  """
  fun name(): String => "Base32/Encode.Empty"
  fun label(): String => "encode"

    fun apply(h: TestHelper)  =>

        // Empty strings encode to empty strings per RFC4648
        h.assert_eq[String val]("", Base32.encode("") )


class iso _TestBase32EncodeBasic is UnitTest
  """
  Test the encoding of simple values as Base32
  """
  fun name(): String => "Base32/Encode.Basic"
  fun label(): String => "encode"

    fun apply(h: TestHelper)  =>

        h.assert_eq[String val]("GE======", Base32.encode("1") )
        h.assert_eq[String val]("GI======", Base32.encode("2") )
        h.assert_eq[String val]("GM======", Base32.encode("3") )

        h.assert_eq[String val]("ME======", Base32.encode("a") )
        h.assert_eq[String val]("IE======", Base32.encode("A") )
        h.assert_eq[String val]("MFQQ====", Base32.encode("aa") )
        h.assert_eq[String val]("MFQWC===", Base32.encode("aaa") )
        h.assert_eq[String val]("MFQWCYI=", Base32.encode("aaaa") )
        h.assert_eq[String val]("MFQWCYLB", Base32.encode("aaaaa") )
        h.assert_eq[String val]("MFQWCYLBME======", Base32.encode("aaaaaa") )


class iso _TestBase32EncodeFoobar is UnitTest
  """
  In an incremental fashion, test the encoding of "foobar" as Base32
  """
  fun name(): String => "Base32/Encode.foobar"
  fun label(): String => "encode"

    fun apply(h: TestHelper)  =>

        h.assert_eq[String val](Base32.encode(""),"")
        h.assert_eq[String val](Base32.encode("f"),"MY======" )
        h.assert_eq[String val](Base32.encode("fo"),"MZXQ====" )
        h.assert_eq[String val](Base32.encode("foo"),"MZXW6===" )
        h.assert_eq[String val](Base32.encode("foob"),"MZXW6YQ=" )
        h.assert_eq[String val](Base32.encode("fooba"),"MZXW6YTB" )
        h.assert_eq[String val](Base32.encode("foobar"),"MZXW6YTBOI======" )


class iso _TestBase32DecodeEmpty is UnitTest
    """
    Test Base32 decoding of various strings
    """
    fun name(): String => "Base32/Decode.Empty"
    fun label(): String => "decode"

    fun apply(h: TestHelper)  =>

        h.assert_no_error({() ? =>
            h.assert_eq[String]("1", Base32.decode[String iso]("GE======")?)
        })


class iso _TestBase32DecodeBasic is UnitTest
    """
    Test Base32 decoding of various strings
    """
    fun name(): String => "Base32/Decode.Basic"
    fun label(): String => "decode"

    fun apply(h: TestHelper)  =>

        h.assert_no_error({() ? =>
            h.assert_eq[String]("1", Base32.decode[String iso]("GE======")?)
            h.assert_eq[String]("2", Base32.decode[String iso]("GI======")?)
            h.assert_eq[String]("3", Base32.decode[String iso]("GM======")?)

            h.assert_eq[String]("a", Base32.decode[String iso]("ME======")?)
            h.assert_eq[String]("A", Base32.decode[String iso]("IE======")?)
            h.assert_eq[String]("aa", Base32.decode[String iso]("MFQQ")?)
            h.assert_eq[String]("aa", Base32.decode[String iso]("MFQQ====")?)  
            h.assert_eq[String]("aaa", Base32.decode[String iso]("MFQWC===")?)  
            h.assert_eq[String]("aaaa", Base32.decode[String iso]("MFQWCYI=")?)  
            h.assert_eq[String]("aaaaa", Base32.decode[String iso]("MFQWCYLB")?) 
            h.assert_eq[String]("aaaaaa", Base32.decode[String iso]("MFQWCYLBME======")?) 
            h.assert_eq[String]("aaaaaa", Base32.decode[String iso]("MFQWCYLBME")?)
        })


class iso _TestBase32DecodeFoobar is UnitTest
    """
    Test Base32 decoding of various strings
    """
    fun name(): String => "Base32/Decode.Foobar"
    fun label(): String => "decode"

    fun apply(h: TestHelper)  =>

        h.assert_no_error({() ? =>
            h.assert_eq[String]("f", Base32.decode[String iso]("MY======")?)
            h.assert_eq[String]("fo", Base32.decode[String iso]("MZXQ====")?)
            h.assert_eq[String]("foo", Base32.decode[String iso]("MZXW6===")?)
            h.assert_eq[String]("foob", Base32.decode[String iso]("MZXW6YQ=")?)
            h.assert_eq[String]("fooba", Base32.decode[String iso]("MZXW6YTB")?)
            h.assert_eq[String]("foobar", Base32.decode[String iso]("MZXW6YTBOI======")?)
        })


// From https://commons.apache.org/proper/commons-codec/xref-test/org/apache/commons/codec/binary/Base32Test.html
class iso _TestBase32DecodeImpossible is UnitTest
    """
    Test Base32 impossible cases.  These should error.
    """
    fun name(): String => "Base32/Decode.Impossible"
    fun label(): String => "decode"

    fun apply(h: TestHelper)  =>

        h.assert_error({() ? => 
            Base32.decode[String iso]("MC======")? })

        h.assert_error({() ? =>
            Base32.decode[String iso]("MZXE====")? })

        h.assert_error({() ? =>
            Base32.decode[String iso]("MZXWB===")? })

        h.assert_error({() ? =>
            Base32.decode[String iso]("MZXW6YB=")? })

        h.assert_error({() ? =>
            Base32.decode[String iso]("MZXW6YTBOC======")? })

        h.assert_error({() ? =>
            Base32.decode[String iso]("AB======")? })


// From https://commons.apache.org/proper/commons-codec/xref-test/org/apache/commons/codec/binary/Base32Test.html
class iso _TestBase32DecodeImpossibleChunked is UnitTest
    """
    Test Base32 impossible cases chunked.  These should error.
    """
    fun name(): String => "Base32/Decode.Impossible.Chunked"
    fun label(): String => "decode"

    fun apply(h: TestHelper)  =>

        h.assert_error({() ? => 
            Base32.decode[String iso]("M2======\r\n")? })

        h.assert_error({() ? => 
            Base32.decode[String iso]("MZX0====\r\n")? })

        h.assert_error({() ? => 
            Base32.decode[String iso]("MZXW0===\r\n")? })

        h.assert_error({() ? => 
            Base32.decode[String iso]("MZXW6Y2=\r\n")? })

        h.assert_error({() ? => 
            Base32.decode[String iso]("MZXW6YTBO2======\r\n")? })


