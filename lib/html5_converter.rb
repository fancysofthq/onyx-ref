# Asciidoctor backend code is the worst
# of all open-source projects I've seen.
# Still, it is extremely useful.
#

# My changes include:
#
# * Changed `convert_document` to remove `"code"`
# from ASCIIMath's `skipTags` settings.
#
# * Changed `convert_table` so it
# renders link in the table caption.
#

class HTML5Converter < (Asciidoctor::Converter.for 'html5')
  register_for 'html5'

  def convert_document node
    br = %(<br#{slash = @void_element_slash}>)
    unless (asset_uri_scheme = (node.attr 'asset-uri-scheme', 'https')).empty?
      asset_uri_scheme = %(#{asset_uri_scheme}:)
    end
    cdn_base_url = %(#{asset_uri_scheme}//cdnjs.cloudflare.com/ajax/libs)
    linkcss = node.attr? 'linkcss'
    result = ['<!DOCTYPE html>']
    lang_attribute = (node.attr? 'nolang') ? '' : %( lang="#{node.attr 'lang', 'en'}")
    result << %(<html#{@xml_mode ? ' xmlns="http://www.w3.org/1999/xhtml"' : ''}#{lang_attribute}>)
    result << %(<head>
<meta charset="#{node.attr 'encoding', 'UTF-8'}"#{slash}>
<meta http-equiv="X-UA-Compatible" content="IE=edge"#{slash}>
<meta name="viewport" content="width=device-width, initial-scale=1.0"#{slash}>
<meta name="generator" content="Asciidoctor #{node.attr 'asciidoctor-version'}"#{slash}>)
    result << %(<meta name="application-name" content="#{node.attr 'app-name'}"#{slash}>) if node.attr? 'app-name'
    result << %(<meta name="description" content="#{node.attr 'description'}"#{slash}>) if node.attr? 'description'
    result << %(<meta name="keywords" content="#{node.attr 'keywords'}"#{slash}>) if node.attr? 'keywords'
    result << %(<meta name="author" content="#{((authors = node.sub_replacements node.attr 'authors').include? '<') ? (authors.gsub XmlSanitizeRx, '') : authors}"#{slash}>) if node.attr? 'authors'
    result << %(<meta name="copyright" content="#{node.attr 'copyright'}"#{slash}>) if node.attr? 'copyright'
    if node.attr? 'favicon'
      if (icon_href = node.attr 'favicon').empty?
        icon_href = 'favicon.ico'
        icon_type = 'image/x-icon'
      elsif (icon_ext = Helpers.extname icon_href, nil)
        icon_type = icon_ext == '.ico' ? 'image/x-icon' : %(image/#{icon_ext.slice 1, icon_ext.length})
      else
        icon_type = 'image/x-icon'
      end
      result << %(<link rel="icon" type="#{icon_type}" href="#{icon_href}"#{slash}>)
    end
    result << %(<title>#{node.doctitle sanitize: true, use_fallback: true}</title>)

    if Asciidoctor::DEFAULT_STYLESHEET_KEYS.include?(node.attr 'stylesheet')
      if (webfonts = node.attr 'webfonts')
        result << %(<link rel="stylesheet" href="#{asset_uri_scheme}//fonts.googleapis.com/css?family=#{webfonts.empty? ? 'Open+Sans:300,300italic,400,400italic,600,600italic%7CNoto+Serif:400,400italic,700,700italic%7CDroid+Sans+Mono:400,700' : webfonts}"#{slash}>)
      end
      if linkcss
        result << %(<link rel="stylesheet" href="#{node.normalize_web_path DEFAULT_STYLESHEET_NAME, (node.attr 'stylesdir', ''), false}"#{slash}>)
      else
        result << %(<style>
#{Asciidoctor::Stylesheets.instance.primary_stylesheet_data}
</style>)
      end
    elsif node.attr? 'stylesheet'
      if linkcss
        result << %(<link rel="stylesheet" href="#{node.normalize_web_path((node.attr 'stylesheet'), (node.attr 'stylesdir', ''))}"#{slash}>)
      else
        result << %(<style>
#{node.read_asset node.normalize_system_path((node.attr 'stylesheet'), (node.attr 'stylesdir', '')), warn_on_failure: true, label: 'stylesheet'}
</style>)
      end
    end

    if node.attr? 'icons', 'font'
      if node.attr? 'iconfont-remote'
        result << %(<link rel="stylesheet" href="#{node.attr 'iconfont-cdn', %[#{cdn_base_url}/font-awesome/#{Asciidoctor::FONT_AWESOME_VERSION}/css/font-awesome.min.css]}"#{slash}>)
      else
        iconfont_stylesheet = %(#{node.attr 'iconfont-name', 'font-awesome'}.css)
        result << %(<link rel="stylesheet" href="#{node.normalize_web_path iconfont_stylesheet, (node.attr 'stylesdir', ''), false}"#{slash}>)
      end
    end

    if (syntax_hl = node.syntax_highlighter)
      result << (syntax_hl_docinfo_head_idx = result.size)
    end

    unless (docinfo_content = node.docinfo).empty?
      result << docinfo_content
    end

    result << '</head>'
    body_attrs = node.id ? [%(id="#{node.id}")] : []
    if (sectioned = node.sections?) && (node.attr? 'toc-class') && (node.attr? 'toc') && (node.attr? 'toc-placement', 'auto')
      classes = [node.doctype, (node.attr 'toc-class'), %(toc-#{node.attr 'toc-position', 'header'})]
    else
      classes = [node.doctype]
    end
    classes << node.role if node.role?
    body_attrs << %(class="#{classes.join ' '}")
    body_attrs << %(style="max-width: #{node.attr 'max-width'};") if node.attr? 'max-width'
    result << %(<body #{body_attrs.join ' '}>)

    unless (docinfo_content = node.docinfo :header).empty?
      result << docinfo_content
    end

    unless node.noheader
      result << '<div id="header">'
      if node.doctype == 'manpage'
        result << %(<h1>#{node.doctitle} Manual Page</h1>)
        if sectioned && (node.attr? 'toc') && (node.attr? 'toc-placement', 'auto')
          result << %(<div id="toc" class="#{node.attr 'toc-class', 'toc'}">
<div id="toctitle">#{node.attr 'toc-title'}</div>
#{node.converter.convert node, 'outline'}
</div>)
        end
        result << (generate_manname_section node) if node.attr? 'manpurpose'
      else
        if node.header?
          result << %(<h1>#{node.header.title}</h1>) unless node.notitle
          details = []
          idx = 1
          node.authors.each do |author|
            details << %(<span id="author#{idx > 1 ? idx : ''}" class="author">#{node.sub_replacements author.name}</span>#{br})
            details << %(<span id="email#{idx > 1 ? idx : ''}" class="email">#{node.sub_macros author.email}</span>#{br}) if author.email
            idx += 1
          end
          if node.attr? 'revnumber'
            details << %(<span id="revnumber">#{((node.attr 'version-label') || '').downcase} #{node.attr 'revnumber'}#{(node.attr? 'revdate') ? ',' : ''}</span>)
          end
          if node.attr? 'revdate'
            details << %(<span id="revdate">#{node.attr 'revdate'}</span>)
          end
          if node.attr? 'revremark'
            details << %(#{br}<span id="revremark">#{node.attr 'revremark'}</span>)
          end
          unless details.empty?
            result << '<div class="details">'
            result.concat details
            result << '</div>'
          end
        end

        if sectioned && (node.attr? 'toc') && (node.attr? 'toc-placement', 'auto')
          result << %(<div id="toc" class="#{node.attr 'toc-class', 'toc'}">
<div id="toctitle">#{node.attr 'toc-title'}</div>
#{node.converter.convert node, 'outline'}
</div>)
        end
      end
      result << '</div>'
    end

    result << %(<div id="content">
#{node.content}
</div>)

    if node.footnotes? && !(node.attr? 'nofootnotes')
      result << %(<div id="footnotes">
<hr#{slash}>)
      node.footnotes.each do |footnote|
        result << %(<div class="footnote" id="_footnotedef_#{footnote.index}">
<a href="#_footnoteref_#{footnote.index}">#{footnote.index}</a>. #{footnote.text}
</div>)
      end
      result << '</div>'
    end

    unless node.nofooter
      result << '<div id="footer">'
      result << '<div id="footer-text">'
      result << %(#{node.attr 'version-label'} #{node.attr 'revnumber'}#{br}) if node.attr? 'revnumber'
      result << %(#{node.attr 'last-update-label'} #{node.attr 'docdatetime'}) if (node.attr? 'last-update-label') && !(node.attr? 'reproducible')
      result << '</div>'
      result << '</div>'
    end

    # JavaScript (and auxiliary stylesheets) loaded at the end of body for performance reasons
    # See http://www.html5rocks.com/en/tutorials/speed/script-loading/

    if syntax_hl
      if syntax_hl.docinfo? :head
        result[syntax_hl_docinfo_head_idx] = syntax_hl.docinfo :head, node, cdn_base_url: cdn_base_url, linkcss: linkcss, self_closing_tag_slash: slash
      else
        result.delete_at syntax_hl_docinfo_head_idx
      end
      if syntax_hl.docinfo? :footer
        result << (syntax_hl.docinfo :footer, node, cdn_base_url: cdn_base_url, linkcss: linkcss, self_closing_tag_slash: slash)
      end
    end

    if node.attr? 'stem'
      eqnums_val = node.attr 'eqnums', 'none'
      eqnums_val = 'AMS' if eqnums_val.empty?
      eqnums_opt = %( equationNumbers: { autoNumber: "#{eqnums_val}" } )
      # IMPORTANT inspect calls on delimiter arrays are intentional for JavaScript compat (emulates JSON.stringify)
      result << %(<script type="text/x-mathjax-config">
MathJax.Hub.Config({
  messageStyle: "none",
  tex2jax: {
    inlineMath: [#{Asciidoctor::INLINE_MATH_DELIMITERS[:latexmath].inspect}],
    displayMath: [#{Asciidoctor::BLOCK_MATH_DELIMITERS[:latexmath].inspect}],
    ignoreClass: "nostem|nolatexmath"
  },
  asciimath2jax: {
    delimiters: [#{Asciidoctor::BLOCK_MATH_DELIMITERS[:asciimath].inspect}],
    skipTags: ["script", "noscript", "style", "textarea"],
    ignoreClass: "nostem|noasciimath"
  },
  TeX: {#{eqnums_opt}}
})
MathJax.Hub.Register.StartupHook("AsciiMath Jax Ready", function () {
  MathJax.InputJax.AsciiMath.postfilterHooks.Add(function (data, node) {
    if ((node = data.script.parentNode) && (node = node.parentNode) && node.classList.contains("stemblock")) {
      data.math.root.display = "block"
    }
    return data
  })
})
</script>
<script src="#{cdn_base_url}/mathjax/#{Asciidoctor::MATHJAX_VERSION}/MathJax.js?config=TeX-MML-AM_HTMLorMML"></script>)
    end

    unless (docinfo_content = node.docinfo :footer).empty?
      result << docinfo_content
    end

    result << '</body>'
    result << '</html>'
    result.join Asciidoctor::LF
  end

  def convert_table(node)
    result = []
    id_attribute = node.id ? %( id="#{node.id}") : ''
    classes = ['tableblock', %(frame-#{node.attr 'frame', 'all', 'table-frame'}), %(grid-#{node.attr 'grid', 'all', 'table-grid'})]

    if (stripes = node.attr 'stripes', nil, 'table-stripes')
      classes << %(stripes-#{stripes})
    end

    styles = []

    if (autowidth = node.option? 'autowidth') && !(node.attr? 'width')
      classes << 'fit-content'
    elsif (tablewidth = node.attr 'tablepcwidth') == 100
      classes << 'stretch'
    else
      styles << %(width: #{tablewidth}%;)
    end

    classes << (node.attr 'float') if node.attr? 'float'

    if (role = node.role)
      classes << role
    end

    class_attribute = %( class="#{classes.join ' '}")
    style_attribute = styles.empty? ? '' : %( style="#{styles.join ' '}")

    result << %(<table#{id_attribute}#{class_attribute}#{style_attribute}>)

    if node.title?
      result << <<-HTML.chomp
      <caption class="title"><a href="#_table-#{node.number}" id="_table-#{node.number}" class="table-caption-link">#{node.captioned_title}</caption>
      HTML
    end

    if (node.attr 'rowcount') > 0
      slash = @void_element_slash
      result << '<colgroup>'

      if autowidth
        result += (Array.new node.columns.size, %(<col#{slash}>))
      else
        node.columns.each do |col|
          result << ((col.option? 'autowidth') ? %(<col#{slash}>) : %(<col style="width: #{col.attr 'colpcwidth'}%;"#{slash}>))
        end
      end

      result << '</colgroup>'
      node.rows.to_h.each do |tsec, rows|
        next if rows.empty?
        result << %(<t#{tsec}>)
        rows.each do |row|
          result << '<tr>'
          row.each do |cell|
            if tsec == :head
              cell_content = cell.text
            else
              case cell.style
              when :asciidoc
                cell_content = %(<div class="content">#{cell.content}</div>)
              when :literal
                cell_content = %(<div class="literal"><pre>#{cell.text}</pre></div>)
              else
                cell_content = unless (
                  cell_content = cell.content
                ).empty?
                  <<-HTML
                  <p class="tableblock">#{cell_content.join '</p><p class="tableblock">'}</p>
                  HTML
                end
              end
            end

            cell_tag_name = (tsec == :head || cell.style == :header ? 'th' : 'td')
            cell_class_attribute = %( class="tableblock halign-#{cell.attr 'halign'} valign-#{cell.attr 'valign'}")
            cell_colspan_attribute = cell.colspan ? %( colspan="#{cell.colspan}") : ''
            cell_rowspan_attribute = cell.rowspan ? %( rowspan="#{cell.rowspan}") : ''
            cell_style_attribute = (node.document.attr? 'cellbgcolor') ? %( style="background-color: #{node.document.attr 'cellbgcolor'};") : ''
            result << %(<#{cell_tag_name}#{cell_class_attribute}#{cell_colspan_attribute}#{cell_rowspan_attribute}#{cell_style_attribute}>#{cell_content}</#{cell_tag_name}>)
          end
          result << '</tr>'
        end
        result << %(</t#{tsec}>)
      end
    end

    result << '</table>'
    result.join Asciidoctor::LF
  end
end
