require 'xml/mapping'

module XML::Mapping
  def ==(other)
    Marshal.dump(self) == Marshal.dump(other)
  end
end


# forward declarations
class Point; end

class Triangle
  include XML::Mapping

  use_mapping :m1

  text_node :name, "@name"
  object_node :p1, "pt1", :class=>Point
  object_node :p2, "points/point[2]", :class=>Point, :mapping=>:m2, :sub_mapping=>:m1
  object_node :p3, "pt3", :class=>Point
  text_node :color, "color"


  use_mapping :m2

  text_node :color, "@color"
  text_node :name, "name"
  object_node :p1, "points/point[1]", :class=>Point, :sub_mapping=>:m1
  object_node :p2, "pt2", :class=>Point, :mapping=>:m1
  object_node :p3, "points/point[3]", :class=>Point, :sub_mapping=>:m1

  text_node :descr, "description", :default_value=>"default description"

  def initialize(name,color,p1,p2,p3)
    @name,@color,@p1,@p2,@p3 = name,color,p1,p2,p3
  end

  def ==(other)
    name==other.name and color==other.color and
      p1==other.p1 and p2==other.p2 and p3==other.p3
  end
end


class Point
  include XML::Mapping

  use_mapping :m1

  numeric_node :x, "x"
  numeric_node :y, "y"

  def initialize(x,y)
    @x,@y = x,y
  end
end
