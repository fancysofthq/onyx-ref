Asciidoctor::Extensions.register do
  inline_macro do
    named :conum

    process do |parent, target, attrs|
      # TODO validate that this conum is valid
      Asciidoctor::Inline.new(parent, :callout, target.to_i).convert
    end
  end
end
