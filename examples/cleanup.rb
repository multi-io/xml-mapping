%w{Address Client Company Customer Document Entry Folder Foo Item Order People Person Publication Signature}.each do |cname|
  begin
    Object.send(:remove_const, cname)  # name clash with company_usage...
  rescue
  end
end


%w{company documents_folders order order_signature_enhanced stringarray time_node}.each do |mod|
  $".delete_if{|f| f =~ %r{/#{mod}.rb$} }
end
