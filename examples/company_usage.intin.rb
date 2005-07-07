#:invisible:
$:.unshift "../lib"
begin
  Object.send(:remove_const, "Address")  # name clash with order_usage...
rescue
end
require 'company' #<=
#:visible:
c = Company.load_from_file('company.xml') #<=
c.name #<=
c.customers.size #<=
c.customers[1] #<=
c.customers[1].name #<=
c.customers[0].name #<=
c.customers[0].name = 'James Tiberius Kirk' #<=
c.customers << Customer.new('cm','Cookie Monster') #<=
xml2 = c.save_to_xml #<=
#:invisible_retval:
xml2.write($stdout,2) #<=
