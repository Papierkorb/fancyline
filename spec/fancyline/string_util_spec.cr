require "../spec_helper"

{% begin %}

# https://github.com/crystal-lang/crystal/pull/5257
# TODO: Remove { % begin/end % } once ^ is fixed.
{% broken_unicode_handling = !Char::Reader.methods.map(&.name.stringify).includes?("byte_at?") %}
private def len(str)
  Fancyline::StringUtil.terminal_size str
end

private def sub(*args)
  Fancyline::StringUtil.terminal_sub(*args)
end

private def dim(*args)
  Fancyline::StringUtil::Dimension.new(*args)
end

describe Fancyline::StringUtil do
  describe ".terminal_size" do
    it "returns 0, 0, 0 for nil" do
      len(nil).should eq dim(0, 0, 0)
    end

    it "returns 1, 0, 0 for ''" do
      len("").should eq dim(1, 0, 0)
    end

    it "returns 1, 1, 1 for 'a'" do
      len("a").should eq dim(1, 1, 1)
    end

    it "returns 2, 0, 0 for '\\n'" do
      len("\n").should eq dim(2, 0, 0)
    end

    it "returns 3, 0, 0 for '\\n\\n'" do
      len("\n\n").should eq dim(3, 0, 0)
    end

    {% unless broken_unicode_handling %}
    it "returns 1, 1, 1 for 'ß'" do
      len("ß").should eq dim(1, 1, 1)
    end
    {% end %}

    it "returns 1, 7, 7 for 'abcdefg'" do
      len("abcdefg").should eq dim(1, 7, 7)
    end

    {% unless broken_unicode_handling %}
    it "returns 1, 3, 3 for 'äöü'" do
      len("äöü").should eq dim(1, 3, 3)
    end
    {% end %}

    it "returns 1, 3, 3 for '\\e[1mfoo\\e[0m'" do
      len("\e[1mfoo\e[0m").should eq dim(1, 3, 3)
    end

    it "returns 2, 2, 3 for '\\e[30;47mfo\\no\\e[0m'" do
      len("\e[30;47mfo\no\e[0m").should eq dim(2, 2, 3)
    end

    it "returns 1, 8, 8 for '\\t'" do
      len("\t").should eq dim(1, 8, 8)
    end

    it "returns 1, 8, 8 for 'abcdefg\\t'" do
      len("abcdefg\t").should eq dim(1, 8, 8)
    end

    it "returns 1, 15, 15 for '\\tabcdefg'" do
      len("\tabcdefg").should eq dim(1, 15, 15)
    end

    it "returns 1, 16, 16 for '\\t\\t'" do
      len("\t\t").should eq dim(1, 16, 16)
    end

    it "returns 1, 16, 16 for '\\tabcdefg\\t'" do
      len("\t\t").should eq dim(1, 16, 16)
    end

    it "returns 1, 24, 24 for '\\t\\t\\t'" do
      len("\t\t\t").should eq dim(1, 24, 24)
    end

    it "returns 2, 0, 0 for '\\n'" do
      len("\n").should eq dim(2, 0, 0)
    end

    it "returns 2, 3, 5 for 'abc\\nde'" do
      len("abc\nde").should eq dim(2, 3, 5)
    end

    it "returns 2, 3, 5 for 'ab\\ncde'" do
      len("ab\ncde").should eq dim(2, 3, 5)
    end

    {% unless broken_unicode_handling %}
    it "returns 2, 3, 4 for 'ß\\ndef'" do
      len("ß\ndef").should eq dim(2, 3, 4)
    end
    {% end %}
  end

  describe ".terminal_sub" do
    it "works for ascii-only strings" do
      sub("foo bar baz", 4, 3).should eq "bar"
      sub("foo bar baz", 0, 100).should eq "foo bar baz"
    end

    it "works for unicode strings" do
      sub("äöü", 0, 1).should eq "ä"
      sub("äöü", 1, 1).should eq "ö"
      sub("äöü", 2, 1).should eq "ü"
      sub("äöü", 0, 2).should eq "äö"
      sub("äöü", 1, 2).should eq "öü"
      sub("äöü", 0, 3).should eq "äöü"
    end

    it "works with leading escape sequence" do
      sub("\e[1mFooBär", 3, 3).should eq "\e[1mBär"
    end

    it "works with trailing escape sequence" do
      sub("FooBär\e[0m", 3, 3).should eq "Bär\e[0m"
    end

    it "works with surrounding escape sequences" do
      sub("\e[1mFooBär\e[0m", 3, 3).should eq "\e[1mBär\e[0m"
    end

    it "works with inner escape sequences" do
      sub("Foo\e[1mBär", 3, 3).should eq "\e[1mBär"
      sub("Foo\e[1mBär", 3, 2).should eq "\e[1mBä"
      sub("Foo\e[1mBär", 3, 1).should eq "\e[1mB"
      sub("Foo\e[1mBär", 2, 2).should eq "o\e[1mB"
    end
  end
end
{% end %}
