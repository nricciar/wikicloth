module WikiCloth
  class ReferencesExtension < Extension

    # <ref>reference content</ref>
    # <ref name="named">reference content</ref>
    # <ref name="named" />
    # <ref group="group_name">reference content</ref>
    #
    element 'ref' do |buffer|
      # find our named reference reference if it exists
      named_ref = buffer.get_attribute_by_name("name")
      ref = @options[:link_handler].find_reference_by_name(named_ref) unless named_ref.nil?

      # reference either not "named" or first time in document
      if ref.nil?
        @options[:link_handler].references << { :name => named_ref, :value => buffer.element_content, :count => 0, :group => buffer.get_attribute_by_name("group") }
        ref = @options[:link_handler].references.last
      end

      ref_id = (named_ref.nil? ? "" : "#{named_ref}_") + "#{@options[:link_handler].reference_index(ref)}-#{ref[:count]}"
      cite_anchor = "#cite_note-" + (named_ref.nil? ? "" : "#{named_ref}_") + @options[:link_handler].reference_index(ref).to_s
      group_label = buffer.get_attribute_by_name("group") ? "#{buffer.get_attribute_by_name("group")} " : ""
      ref_link = "<a href=\"#{cite_anchor}\">#{@options[:link_handler].reference_index(ref)}</a>"
      ref[:count] += 1

      "<sup class=\"reference\" id=\"cite_ref-#{ref_id}\">[#{group_label}#{ref_link}]</sup>"
    end

    # <references />
    # <references group="group_name" />
    #
    element 'references' do |buffer|
      ref_count = 0
      group_match = buffer.get_attribute_by_name("group")
      refs = @options[:link_handler].references.collect { |r|
        next if r[:group] != group_match
        ref_count += 1
        ref_name = (r[:name].nil? ? "" : r[:name].to_slug + "_")
        ret = "<li id=\"cite_note-#{ref_name}#{ref_count}\"><b>"
        1.upto(r[:count]) { |x| ret += "<a href=\"#cite_ref-#{ref_name}#{ref_count}-#{x-1}\">" +
                (r[:count] == 1 ? "^" : (x-1).to_s(26).tr('0-9a-p', 'a-z')) + "</a> " }
        ret += "</b> #{r[:value]}</li>"
      }.to_s
      "<ol>#{refs}</ol>"
    end

  end
end
