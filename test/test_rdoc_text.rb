require 'rubygems'
require 'minitest/autorun'
require 'rdoc'
require 'rdoc/text'
require 'rdoc/markup'
require 'rdoc/markup/formatter'

class TestRDocText < MiniTest::Unit::TestCase

  include RDoc::Text

  def test_expand_tabs
    assert_equal("hello\n  dave",
                 expand_tabs("hello\n  dave"), 'spaces')

    assert_equal("hello\n        dave",
                 expand_tabs("hello\n\tdave"), 'tab')

    assert_equal("hello\n        dave",
                 expand_tabs("hello\n \tdave"), '1 space tab')

    assert_equal("hello\n        dave",
                 expand_tabs("hello\n  \tdave"), '2 space tab')

    assert_equal("hello\n        dave",
                 expand_tabs("hello\n   \tdave"), '3 space tab')

    assert_equal("hello\n        dave",
                 expand_tabs("hello\n    \tdave"), '4 space tab')

    assert_equal("hello\n        dave",
                 expand_tabs("hello\n     \tdave"), '5 space tab')

    assert_equal("hello\n        dave",
                 expand_tabs("hello\n      \tdave"), '6 space tab')

    assert_equal("hello\n        dave",
                 expand_tabs("hello\n       \tdave"), '7 space tab')

    assert_equal("hello\n                dave",
                 expand_tabs("hello\n         \tdave"), '8 space tab')

    assert_equal('.               .',
                 expand_tabs(".\t\t."), 'dot tab tab dot')
  end

  def test_flush_left
    text = <<-TEXT

  we don't worry too much.

  The comments associated with
    TEXT

    expected = <<-EXPECTED

we don't worry too much.

The comments associated with
    EXPECTED

    assert_equal expected, flush_left(text)
  end

  def test_markup
    def formatter() RDoc::Markup::ToHtml.new end

    assert_equal "<p>hi</p>", markup('hi').gsub("\n", '')
  end

  def test_normalize_comment
    text = <<-TEXT
##
# we don't worry too much.
#
# The comments associated with
    TEXT

    expected = <<-EXPECTED.rstrip
we don't worry too much.

The comments associated with
    EXPECTED

    assert_equal expected, normalize_comment(text)
  end

  def test_parse
    assert_kind_of RDoc::Markup::Document, parse('hi')
  end

  def test_parse_document
    assert_equal RDoc::Markup::Document.new, parse(RDoc::Markup::Document.new)
  end

  def test_parse_empty
    assert_equal RDoc::Markup::Document.new, parse('')
  end

  def test_parse_empty_newline
    assert_equal RDoc::Markup::Document.new, parse("#\n")
  end

  def test_parse_newline
    assert_equal RDoc::Markup::Document.new, parse("\n")
  end

  def test_strip_hashes
    text = <<-TEXT
##
# we don't worry too much.
#
# The comments associated with
    TEXT

    expected = <<-EXPECTED

  we don't worry too much.

  The comments associated with
    EXPECTED

    assert_equal expected, strip_hashes(text)
  end

  def test_strip_newlines
    assert_equal ' ',  strip_newlines("\n \n")

    assert_equal 'hi', strip_newlines("\n\nhi")

    assert_equal 'hi', strip_newlines(    "hi\n\n")

    assert_equal 'hi', strip_newlines("\n\nhi\n\n")
  end

  def test_strip_stars
    text = <<-TEXT
/*
 * * we don't worry too much.
 *
 * The comments associated with
 */
    TEXT

    expected = <<-EXPECTED

   * we don't worry too much.

   The comments associated with
    EXPECTED

    assert_equal expected, strip_stars(text)
  end

  def test_to_html_apostrophe
    assert_equal '&#8216;a', to_html("'a")
    assert_equal 'a&#8217;', to_html("a'")

    assert_equal '&#8216;a&#8217; &#8216;', to_html("'a' '")
  end

  def test_to_html_backslash
    assert_equal 'S', to_html('\\S')
  end

  def test_to_html_copyright
    assert_equal '&#169;', to_html('(c)')
  end

  def test_to_html_dash
    assert_equal '-',        to_html('-')
    assert_equal '&#8211;',  to_html('--')
    assert_equal '&#8212;',  to_html('---')
    assert_equal '&#8212;-', to_html('----')
  end

  def test_to_html_double_backtick
    assert_equal '&#8220;a',        to_html('``a')
    assert_equal '&#8220;a&#8220;', to_html('``a``')
  end

  def test_to_html_double_quote
    assert_equal '&#8220;a',        to_html('"a')
    assert_equal '&#8220;a&#8221;', to_html('"a"')
  end

  def test_to_html_double_quote_quot
    assert_equal '&#8220;a',        to_html('&quot;a')
    assert_equal '&#8220;a&#8221;', to_html('&quot;a&quot;')
  end

  def test_to_html_double_tick
    assert_equal '&#8221;a',        to_html("''a")
    assert_equal '&#8221;a&#8221;', to_html("''a''")
  end

  def test_to_html_ellipsis
    assert_equal '..',       to_html('..')
    assert_equal '&#8230;',  to_html('...')
    assert_equal '.&#8230;', to_html('....')
  end

  def test_to_html_html_tag
    assert_equal '<a href="http://example">hi&#8217;s</a>',
                 to_html('<a href="http://example">hi\'s</a>')
  end

  def test_to_html_registered_trademark
    assert_equal '&#174;', to_html('(r)')
  end

  def test_to_html_tt_tag
    assert_equal '<tt>hi\'s</tt>',   to_html('<tt>hi\'s</tt>')
    assert_equal '<tt>hi\\\'s</tt>', to_html('<tt>hi\\\\\'s</tt>')
  end

  def test_to_html_tt_tag_mismatch
    assert_output nil, "mismatched <tt> tag\n" do
      assert_equal '<tt>hi', to_html('<tt>hi')
    end
  end

end

