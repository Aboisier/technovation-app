module ApplicationHelper
  require 'redcarpet/render_strip'

  def strikethrough(should, &block)
    if should
      "<s>#{capture(&block)}</s>".html_safe
    else
      capture(&block).html_safe
    end
  end

  def format_division(division)
    case division.to_sym
    when :hs
      'High School'
    when :ms
      'Middle School'
    when :x
      'Ineligible'
    else
      'Error'
    end
  end

  def format_region(region, division)
    case region.to_sym
    when :us
      "US/Canada"
    when :mexico
      if division.to_sym == :hs
        "Mexico/Central America/South America/Africa"
      else
        "Mexico/Central America/South America/Africa"
      end
    when :africa
      "Africa"
    when :europe
      "Europe/Australia/New Zealand/Asia"
    else
      "Error"
    end
  end

  def doc_path(file)
    File.join('/docs', file).to_s
  end


  def render_markdown(text)
    renderer = Redcarpet::Render::HTML.new(filter_html: true, no_images: true, hard_wrap: true)
    parser = Redcarpet::Markdown.new(renderer, tables: true, fenced_code_blocks: true, strikethrough: true, superscript: true, underline: true, highlight: true)
    parser.render(text).html_safe
  end

  def render_markdown_brief(text)
    renderer = Redcarpet::Render::StripDown.new()
    parser = Redcarpet::Markdown.new(renderer, tables: true, fenced_code_blocks: true, strikethrough: true, superscript: true, underline: true, highlight: true)
    parser.render(text)
  end
end
