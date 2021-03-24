use "json" 
use "ponytest"
use "collections"
//use "base32"

actor Main is TestList
  new create(env: Env) => PonyTest(env, this)
  new make() => None

  fun tag tests(test: PonyTest) =>
    test(_TestBase32Encode)
    test(_TestBase32DecodeBasic)
    test(_TestBase32DecodeRfc4648)
    test(_TestBase32DecodeImpossible)
    test(_TestBase32DecodeImpossibleChunked)

class iso _TestBase32Encode is UnitTest
  """
  Test encoding of various values as Base32
  """
  fun name(): String => "Base32/Encode.foobar"
  fun label(): String => "simple"

    fun test_empty(h: TestHelper) =>
        h.assert_eq[String val]("", Base32.encode("") )
 
    fun test_f(h: TestHelper) =>
        h.assert_eq[String val]("MY======", Base32.encode("f") )

    fun test_fo(h: TestHelper) =>
        let expect = "MZXQ===="
        let actual : String val = Base32.encode("fo")
        h.assert_eq[String val](expect, actual)

    fun test_foo(h: TestHelper) =>
        let expect = "MZXW6==="
        let actual : String val = Base32.encode("foo")
        h.assert_eq[String val](expect, actual)

    fun test_foob(h: TestHelper) =>
        let expect = "MZXW6YQ="
        let actual : String val = Base32.encode("foob")
        h.assert_eq[String val](expect, actual)

    fun test_fooba(h: TestHelper) =>
        let expect = "MZXW6YTB"
        let actual : String val = Base32.encode("fooba")
        h.assert_eq[String val](expect, actual)

    fun test_foobar(h: TestHelper) =>
        let expect = "MZXW6YTBOI======"
        let actual : String val = Base32.encode("foobar")
        h.assert_eq[String val](expect, actual)

    fun apply(h: TestHelper)  =>
        h.assert_eq[String val]("", Base32.encode("") )

        test_f(h)
        test_fo(h)
        test_foo(h)
        test_foob(h)
        test_fooba(h)
        test_foobar(h)


class iso _TestBase32DecodeBasic is UnitTest
    """
    Test Base32 decoding of various strings
    """
    fun name(): String => "Base32/Decode.Basic"

    fun apply(h: TestHelper)  =>

        h.assert_no_error({() ? =>
            h.assert_eq[String]("", Base32.decode[String iso]("")?)
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


class iso _TestBase32DecodeRfc4648 is UnitTest
    """
    Test Base32 decoding of various strings
    """
    fun name(): String => "Base32/Decode.Rfc4648"

    fun apply(h: TestHelper)  =>

        h.assert_no_error({() ? =>
            h.assert_eq[String]("", Base32.decode[String iso]("")?)
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


