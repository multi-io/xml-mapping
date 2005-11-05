module XML
  class XXPath

    class Step
      def self.inherited(subclass)
        (@subclasses||=[]) << subclass
      end

      def self.compile string
        (@subclasses||=[]).each do |sc|
          obj = sc.compile string
          return obj if obj
        end
        raise XXPathError, "can't compile XPath step: #{string}"
      end
    end


    class NameAndAttrStep < Step
      def self.compile string
        /^(.*?)\[@(.*?)='(.*?)'\]$/ === string or return nil
        self.new $1,$2,$3
      end

      def initialize(name,attr_name,attr_value)
        @name,@attr_name,@attr_value = name,attr_name,attr_value
      end

      def matches node
        node.class==REXML::Element and node.name==@name and node.attributes[@attr_name]==@attr_value
      end

      def create_on(node,create_new)
        if create_new
          newnode = node.elements.add(@name)
        else
          newnode = node.elements.select{|elt| elt.name==@name}[0]
          if not(newnode) or newnode.attributes[@attr_name]
            newnode = node.elements.add(@name)
          end
        end
        newnode.attributes[@attr_name]=@attr_value
        newnode
      end
    end


    class NameAndIndexStep < Step
      def self.compile string
        /^(.*?)\[(\d+)\]$/ === string or return nil
        self.new $1,$2.to_i
      end

      def initialize(name,index)
        @name,@index = name,index
      end

      def matches node
        raise XXPathError, "can't use #{@name}[#{@index}] on root node" if node.parent.nil?
        node == node.parent.elements.select{|elt| elt.name==@name}[@index-1]
      end

      def create_on(node,create_new)
        name_matches = node.elements.select{|elt| elt.name==@name}
        if create_new and (name_matches.size >= @index)
          raise XXPathError, "XPath: #{@name}[#{@index}]: create_new and element already exists"
        end
        newnode = name_matches[0]
        (@index-name_matches.size).times do
          newnode = node.elements.add @name
        end
        newnode
      end
    end


    class AttrNameStep < Step
      def self.compile string
        /^@(.*)$/ === string or return nil
        self.new $1
      end

      def initialize(attr_name)
        @attr_name = attr_name
      end

      def matches node
        node.class==XML::XXPath::Accessors::Attribute and node.name==@attr_name
      end

      def create_on(node,create_new)
        if create_new and node.attributes[@attr_name]
          raise XXPathError, "XPath (@#{@attr_name}): create_new and attribute already exists"
        end
        XML::XXPath::Accessors::Attribute.new(node,@attr_name,true)
      end
    end


    class AllElementsStep < Step
      def self.compile string
        '*'==string or return nil
        self.new
      end

      def matches node
        node.class==REXML::Element
      end

      def create_on(node,create_new)
        node = node.elements.add
        node.unspecified = true
        node
      end
    end


    class ThisNodeStep < Step
      def self.compile string
        '.'==string or return nil
        self.new
      end

      def matches node
        true
      end

      def create_on(node,create_new)
        if create_new
          raise XXPathError, "XPath: .: create_new and attribute already exists"
        end
        node
      end
    end


    class NameStep < Step
      def self.compile string
        self.new string
      end

      def initialize(name)
        @name = name
      end

      def matches node
        node.class==REXML::Element and node.name==@name
      end

      def create_on(node,create_new)
        node.elements.add @name
      end
    end
  end
end
