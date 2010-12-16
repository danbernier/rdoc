require 'strscan'

##
# Methods for manipulating comment text

module RDoc::Text

  ##
  # Expands tab characters in +text+ to eight spaces

  def expand_tabs text
    expanded = []

    text.each_line do |line|
      line.gsub!(/^(.{8}*?)([^\t\r\n]{0,7})\t/) do
        "#{$1}#{$2}#{' ' * (8 - $2.size)}"
      end until line !~ /\t/

      expanded << line
    end

    expanded.join
  end

  ##
  # Flush +text+ left based on the shortest line

  def flush_left text
    indents = []

    text.each_line do |line|
      indents << (line =~ /[^\s]/ || 9999)
    end

    indent = indents.min

    flush = []

    text.each_line do |line|
      line[/^ {0,#{indent}}/] = ''
      flush << line
    end

    flush.join
  end

  ##
  # Convert a string in markup format into HTML.
  #
  # Requires the including class to implement #formatter

  def markup text
    document = parse text

    document.accept formatter
  end

  ##
  # Strips hashes, expands tabs then flushes +text+ to the left

  def normalize_comment text
    return text if text.empty?

    text = strip_hashes text
    text = expand_tabs text
    text = flush_left text
    strip_newlines text
  end

  ##
  # Normalizes +text+ then builds a RDoc::Markup::Document from it

  def parse text
    return text if RDoc::Markup::Document === text

    text = normalize_comment text

    return RDoc::Markup::Document.new if text =~ /\A\n*\z/

    RDoc::Markup::Parser.parse text
  rescue RDoc::Markup::Parser::Error => e
    $stderr.puts <<-EOF
While parsing markup, RDoc encountered a #{e.class}:

#{e}
\tfrom #{e.backtrace.join "\n\tfrom "}

---8<---
#{text}
---8<---

RDoc #{RDoc::VERSION}

Ruby #{RUBY_VERSION}-p#{RUBY_PATCHLEVEL} #{RUBY_RELEASE_DATE}

Please file a bug report with the above information at:

http://rubyforge.org/tracker/?atid=2472&group_id=627&func=browse

    EOF
    raise
  end

  ##
  # Strips leading # characters from +text+

  def strip_hashes text
    return text if text =~ /^(?>\s*)[^\#]/
    text.gsub(/^\s*(#+)/) { $1.tr '#',' ' }.gsub(/^\s+$/, '')
  end

  ##
  # Strips leading and trailing \n characters from +text+

  def strip_newlines text
    text.gsub(/\A\n*(.*?)\n*\z/m, '\1')
  end

  ##
  # Strips /* */ style comments

  def strip_stars text
    text = text.gsub %r%Document-method:\s+[\w:.#]+%, ''
    text.sub!  %r%/\*+%       do " " * $&.length end
    text.sub!  %r%\*+/%       do " " * $&.length end
    text.gsub! %r%^[ \t]*\*%m do " " * $&.length end
    text.gsub(/^\s+$/, '')
  end

  ##
  # Converts ampersand, dashes, ellipsis, quotes, copyright and registered
  # trademark symbols in +text+ to HTML escaped Unicode.
  #--
  # TODO transcode when the output encoding is not UTF-8

  def to_html text
    html = ''
    s = StringScanner.new text
    insquotes = false
    indquotes = false
    after_word = nil

#p :start => s

    until s.eos? do
      case
      when s.scan(/<tt>.*?<\/tt>/) then # skip contents of tt
        html << s.matched.gsub('\\\\', '\\')
      when s.scan(/<tt>.*?/) then
        warn 'mismatched <tt> tag' # TODO signal file/line
        html << s.matched
      when s.scan(/<[^>]+\/?s*>/) then # skip HTML tags
#p "tag: #{s.matched}"
        html << s.matched
      when s.scan(/\\(\S)/) then # unhandled suppressed crossref
#p "backslashes: #{s.matched}"
        html << s[1]
        after_word = nil
      when s.scan(/\.\.\.(\.?)/) then # ellipsis
#p "ellipses: #{s.matched}"
        html << s[1] << '&#8230;'
        after_word = nil
      when s.scan(/\(c\)/) then # copyright
#p "copyright: #{s.matched}"
        html << '&#169;'
        after_word = nil
      when s.scan(/\(r\)/) then # registered trademark
#p "trademark: #{s.matched}"
        html << '&#174;'
        after_word = nil
      when s.scan(/---/) then # em-dash
#p "em-dash: #{s.matched}"
        html << '&#8212;'
        after_word = nil
      when s.scan(/--/) then # en-dash
#p "en-dash: #{s.matched}"
        html << '&#8211;'
        after_word = nil
      when s.scan(/&quot;|"/) then # double quote
#p "dquotes: #{s.matched}"
        html << (indquotes ? '&#8221;' : '&#8220;')
        indquotes = !indquotes
        after_word = nil
      when s.scan(/``/) then # backtick double quote
#p "dquotes: #{s.matched}"
        html << '&#8220;' # opening
        after_word = nil
      when s.scan(/''/) then # tick double quote
#p "dquotes: #{s.matched}"
        html << '&#8221;' # closing
        after_word = nil
      when s.scan(/'/) then # single quote
#p "squotes: #{s.matched}"
        if insquotes
          html << '&#8217;' # closing
          insquotes = false
        elsif after_word
          # Mary's dog, my parents' house: do not start paired quotes
          html << '&#8217;' # closing
        else
          html << '&#8216;' # opening
          insquotes = true
        end

        after_word = nil
      else # advance to the next potentially significant character
        match = s.scan(/.+?(?=[<\\.("'`&-])/) #"

        if match then
          html << match
          after_word = match =~ /\w$/
        else
          html << s.rest
          break
        end
      end
    end

    html
  end

end

