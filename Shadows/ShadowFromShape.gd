extends CollisionShape2D
# Create a directional shadow from a polygon
# Expects the shadow's vector to be assigned externally

enum SHAPES {NONE, CIRCLE, RECTANGLE, CAPSULE, POLYGON}
const SHADOW_RATIO = 1.0/2.0 #Ratio of height of the object vs length of the shadow cast
const SHADOW_MAX_ALPHA = 0.35
const SQUARE_POLY = PoolVector2Array([Vector2(-1,-1), Vector2(-1,1), Vector2(1,1), Vector2(1,-1)])

export var shadow_color : Color = Color(0, 0, 0, 0.25)
export var shadow_offset : float = 0.0 
export var fill_shape : bool = false
export var object_height : float = 76.0 #px
export var add_top_shadow : bool = false

var _shape_type : int = SHAPES.NONE
var _shadow_vector : Vector2
var _shadow_end_color : Color = Color(0, 0, 0, 0)
var _top_shadow_color : Color = Color(0, 0, 0, 0)

func _ready():
	_shadow_end_color = shadow_color
	_shadow_end_color.a = 0.0
	#Make a top shadow color that will cancel out some color in the base shadow
	_top_shadow_color = Color.from_hsv(fposmod(shadow_color.h + 0.5, 1.0), shadow_color.s, 0.6*shadow_color.v,max(SHADOW_MAX_ALPHA - shadow_color.a, 0.1))
	if !_shadow_vector:
		#Make an example shadow vector for testing
		_shadow_vector = Vector2(0, object_height*SHADOW_RATIO).rotated(-self.rotation + PI/16.0)
	if shape is CircleShape2D:
		_shape_type = SHAPES.CIRCLE
	elif shape is RectangleShape2D:
		_shape_type = SHAPES.RECTANGLE
		
	elif shape is CapsuleShape2D:
		_shape_type = SHAPES.CAPSULE
	elif shape is ConvexPolygonShape2D:
		_shape_type = SHAPES.POLYGON
	else:
		_shape_type = SHAPES.NONE
		assert(false, "Warning: Unable to create shadow from unknown shape!")
	update()

#func _process(_delta):
#	#For testing
#	if Input.is_mouse_button_pressed(BUTTON_LEFT):
#		_shadow_vector = global_position - get_global_mouse_position()
#		#Compensate for any rotation
#		_shadow_vector = _shadow_vector.rotated(-self.rotation) / 2.0
#		update()

func _draw():
	match _shape_type:
		SHAPES.RECTANGLE:
			var shadow_dir : Vector2 = _shadow_vector.normalized()
			var _vertices : PoolVector2Array = []
			for ind in SQUARE_POLY:
				_vertices.append(shape.extents*ind + shadow_offset*shadow_dir)
			_draw_from_poly(_vertices)
			#merge_polygons_2d 
			if fill_shape:
				draw_polygon(_vertices, PoolColorArray([shadow_color]))
				if add_top_shadow:
					draw_polygon(_vertices, PoolColorArray([_top_shadow_color]))
		SHAPES.CIRCLE:
			var _vertices : PoolVector2Array
			var _colors : PoolColorArray 
			var base_angle : float = _shadow_vector.angle()
			var shadow_color_mid : Color = shadow_color
			var shadow_dir : Vector2 = _shadow_vector.normalized()
			shadow_color_mid.a = lerp(shadow_color.a, _shadow_end_color.a, _shadow_vector.length() / (_shadow_vector.length() + shape.radius))
			#Draw the square base of the shadow
			_vertices = PoolVector2Array([shape.radius*shadow_dir.rotated(PI/2.0) + shadow_offset*shadow_dir,
				shape.radius*shadow_dir.rotated(-PI/2.0) + shadow_offset*shadow_dir, 
				shape.radius*shadow_dir.rotated(-PI/2.0) + _shadow_vector + shadow_offset*shadow_dir, 
				shape.radius*shadow_dir.rotated(PI/2.0) + _shadow_vector + shadow_offset*shadow_dir])
			draw_polygon(_vertices, PoolColorArray([shadow_color, shadow_color, shadow_color_mid, shadow_color_mid]))
			#Draw the half circle tip of the shadow
			_vertices = []
			var vert_count : int = 64
			for i in range(vert_count):
				var angle : float = PI*i/(vert_count-1) + base_angle - PI/2.0
				_vertices.append( shape.radius * Vector2(cos(angle), sin(angle)) + _shadow_vector + shadow_offset*shadow_dir)
				var lerp_color : Color = shadow_color
				lerp_color.a = lerp(shadow_color_mid.a,_shadow_end_color.a, abs(sin(PI*i/(vert_count-1))) )
				_colors.append( lerp_color )
			draw_polygon(_vertices, _colors)
			if fill_shape:
				_vertices = []
				for i in range(vert_count):
					var angle : float = PI*i/(vert_count-1) + base_angle + PI/2.0
					_vertices.append( shape.radius * Vector2(cos(angle), sin(angle)) + shadow_offset*shadow_dir)
				draw_polygon(_vertices, PoolColorArray([shadow_color]))
				if add_top_shadow:
					_vertices = []
					for i in range(vert_count):
						var angle : float = PI*i/(vert_count-1) + base_angle - PI/2.0
						_vertices.append( shape.radius * Vector2(cos(angle), sin(angle)) + shadow_offset*shadow_dir)
					draw_polygon(_vertices, PoolColorArray([_top_shadow_color]))
					_vertices = []
					for i in range(vert_count):
						var angle : float = PI*i/(vert_count-1) + base_angle + PI/2.0
						_vertices.append( shape.radius * Vector2(cos(angle), sin(angle)) + shadow_offset*shadow_dir)
					draw_polygon(_vertices, PoolColorArray([_top_shadow_color]))
		SHAPES.CAPSULE:
			var _vertices : PoolVector2Array = []
			var _colors : PoolColorArray 
			var base_angle : float = _shadow_vector.angle()
			var shadow_color_mid : Color = shadow_color
			var shadow_dir : Vector2 = _shadow_vector.normalized()
			shadow_color_mid.a = lerp(shadow_color.a, _shadow_end_color.a, _shadow_vector.length() / (_shadow_vector.length() + shape.radius))
			#Draw the half circle tip of the shadow
			var circle_radius : float = shape.height/2 + shape.radius
			var circle_y_scale : float = shape.radius/circle_radius
			var vert_count : int = 64
			for i in range(vert_count):
				var angle : float = PI*i/(vert_count-1) + base_angle - PI/2.0
				_vertices.append( circle_radius * Vector2(cos(angle), sin(angle)) + _shadow_vector + shadow_offset*shadow_dir)
				var lerp_color : Color = shadow_color
				lerp_color.a = lerp(shadow_color_mid.a,_shadow_end_color.a, abs(sin(PI*i/(vert_count-1))) )
				_colors.append( lerp_color )
			for i in range(_vertices.size()):
				_vertices[i].x = circle_y_scale*_vertices[i].x
			draw_polygon(_vertices, _colors)
			#Draw the square base of the shadow
			_vertices = []
			_vertices = PoolVector2Array([circle_radius*shadow_dir.rotated(PI/2.0) + shadow_offset*shadow_dir,
				circle_radius*shadow_dir.rotated(-PI/2.0) + shadow_offset*shadow_dir, 
				circle_radius*shadow_dir.rotated(-PI/2.0) + _shadow_vector + shadow_offset*shadow_dir, 
				circle_radius*shadow_dir.rotated(PI/2.0) + _shadow_vector + shadow_offset*shadow_dir])
			for i in range(_vertices.size()):
				_vertices[i].x = circle_y_scale*_vertices[i].x
			draw_polygon(_vertices, PoolColorArray([shadow_color, shadow_color, shadow_color_mid, shadow_color_mid]))
			#Draw the base shape
			if fill_shape:
				_vertices = []
				for i in range(vert_count):
					var angle : float = PI*i/(vert_count-1) + base_angle + PI/2.0
					_vertices.append( circle_radius * Vector2(cos(angle), sin(angle)) + shadow_offset*shadow_dir)
				for i in range(_vertices.size()):
					_vertices[i].x = circle_y_scale*_vertices[i].x
				draw_polygon(_vertices, PoolColorArray([shadow_color]))
				if add_top_shadow:
					_vertices = []
					for i in range(vert_count):
						var angle : float = PI*i/(vert_count-1) + PI/2.0
						_vertices.append( circle_radius * Vector2(cos(angle), sin(angle)))
					for i in range(_vertices.size()):
						_vertices[i].x = circle_y_scale*_vertices[i].x
					draw_polygon(_vertices, PoolColorArray([_top_shadow_color]))
					_vertices = []
					for i in range(vert_count):
						var angle : float = PI*i/(vert_count-1) - PI/2.0
						_vertices.append( circle_radius * Vector2(cos(angle), sin(angle)))
					for i in range(_vertices.size()):
						_vertices[i].x = circle_y_scale*_vertices[i].x
					draw_polygon(_vertices, PoolColorArray([_top_shadow_color]))
		SHAPES.POLYGON:
			var _vertices : PoolVector2Array = shape.points
			var shadow_offset_vector : Vector2 = shadow_offset * _shadow_vector.normalized()
			for i in range(_vertices.size()):
				_vertices[i] += shadow_offset_vector
			var num_of_vertices = _vertices.size()
			for vertice_ind in range(num_of_vertices):
				var vertice = _vertices[vertice_ind]
				var next_vertice = _vertices[(vertice_ind + 1) % num_of_vertices]
				var normal = (next_vertice - vertice).normalized().rotated(PI / 2.0)
				if _shadow_vector.dot(normal) > 0:
					draw_polygon(PoolVector2Array([vertice, vertice + _shadow_vector, next_vertice]), PoolColorArray([shadow_color, _shadow_end_color, shadow_color]))
					draw_polygon(PoolVector2Array([next_vertice, next_vertice + _shadow_vector, vertice + _shadow_vector]), PoolColorArray([shadow_color, _shadow_end_color, _shadow_end_color]))
			if fill_shape:
				draw_polygon(_vertices, PoolColorArray([shadow_color]))
				if add_top_shadow:
					draw_polygon(_vertices, PoolColorArray([_top_shadow_color]))

func _draw_from_poly(vertices : PoolVector2Array) -> void:
	var num_of_vertices : int = vertices.size()
	if num_of_vertices < 3:
		return
	for vertice_ind in range(num_of_vertices):
		var vertice : Vector2 = vertices[vertice_ind]
		var next_vertice : Vector2= vertices[(vertice_ind + 1) % num_of_vertices]
		var normal : Vector2 = (next_vertice - vertice).normalized().rotated(PI / 2.0)
		if _shadow_vector.dot(normal) > 0:
			draw_polygon(PoolVector2Array([vertice, vertice + _shadow_vector, next_vertice]), PoolColorArray([shadow_color, _shadow_end_color, shadow_color]))
			draw_polygon(PoolVector2Array([next_vertice, next_vertice + _shadow_vector, vertice + _shadow_vector]), PoolColorArray([shadow_color, _shadow_end_color, _shadow_end_color]))

func set_shadow_vector(shadow_vector : Vector2) -> void:
	#Set the shadow length and direction
	_shadow_vector = shadow_vector
	update()
