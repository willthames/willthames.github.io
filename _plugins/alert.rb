module Jekyll

  class AlertBlock < Liquid::Block
    def initialize(tag_name, text, tokens)
      @text = text.rstrip
      @tokens = tokens
      super
    end

    def glyphicon(level)
      results = { 
        'info' => 'info-sign',
        'warning' => 'warning-sign',
        'danger' => 'exclamation-sign',
        'success' => 'ok-sign'
      }  
      "<span class=\"glyphicon glyphicon-#{results[level]}\"></span>"
    end

    def unparagraph(text)
      text.sub(/^<p>/, '').sub(/<\/p>$/, '')
    end

    def render(context)
      site      = context.registers[:site]
      converter = site.getConverterImpl(Jekyll::Converters::Markdown)
      "<div class=\"alert alert-#{@text}\">" + glyphicon(@text) + " " + unparagraph(converter.convert(super)) + "</div>"
    end
  end
end

Liquid::Template.register_tag('alert', Jekyll::AlertBlock)
