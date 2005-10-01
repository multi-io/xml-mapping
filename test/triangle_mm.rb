require 'xml/mapping'

# forward declarations
class Point; end

class Triangle
  include XML::Mapping

  text_node :name, "@name", :mapping=>:m1
  object_node :p1, "pt1", :class=>Point, :mapping=>:m1
  object_node :p2, "pt2", :class=>Point, :mapping=>:m1
  object_node :p3, "pt3", :class=>Point, :mapping=>:m1
  text_node :color, "color", :mapping=>:m1

  text_node :color, "@color", :mapping=>:m2
  text_node :name, "name", :mapping=>:m2
  object_node :p1, "points/point[1]", :class=>Point, :mapping=>:m2
  object_node :p2, "points/point[2]", :class=>Point, :mapping=>:m2
  object_node :p3, "points/point[3]", :class=>Point, :mapping=>:m2

  def initialize(name,color,p1,p2,p3)
    @name,@color,@p1,@p2,@p3 = name,color,p1,p2,p3
  end

  def ==(other)
    color==other.color and
      name==other.name and
      p1==other.p1 and
      p2==other.p2 and
      p3==other.p3
  end
end


class Point
  include XML::Mapping

  numeric_node :x, "x"
  numeric_node :y, "y"

  def initialize(x,y)
    @x,@y = x,y
  end

  def ==(other)
    x==other.x and y==other.y
  end
end
