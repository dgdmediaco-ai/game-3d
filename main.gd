extends Node3D
var player:Node3D
var camera:Camera3D
var roads:Array[Node3D]=[]
var traffic:Array[Node3D]=[]
var coins:Array[Node3D]=[]
var target_x:=0.0
var speed:=18.0
var distance:=0.0
var score:=0
var coin_count:=0
var spawn:=0.0
var coin_spawn:=0.0
var over:=false
var loaded:=false
var load_value:=0.0
var rng=RandomNumberGenerator.new()
const LANES=[-3.2,0.0,3.2]
const SEG=40.0

func _ready():
 rng.randomize(); make_world(); make_player(); make_camera(); make_ui()

func material(c:Color, r:=0.7):
 var m=StandardMaterial3D.new(); m.albedo_color=c; m.roughness=r; return m
func box(s:Vector3,m):
 var n=MeshInstance3D.new(); var b=BoxMesh.new(); b.size=s; n.mesh=b; n.material_override=m; return n
func cyl(r:float,h:float,m):
 var n=MeshInstance3D.new(); var c=CylinderMesh.new(); c.top_radius=r;c.bottom_radius=r;c.height=h;c.radial_segments=14;n.mesh=c;n.material_override=m;return n

func make_world():
 var env=WorldEnvironment.new();var e=Environment.new();e.background_mode=Environment.BG_COLOR;e.background_color=Color("#10243a");e.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;e.ambient_light_color=Color("#8bb7ff");e.ambient_light_energy=0.7;env.environment=e;add_child(env)
 var sun=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-55,-25,0);sun.light_energy=1.2;add_child(sun)
 var ground=box(Vector3(90,.2,320),material(Color("#245c32")));ground.position=Vector3(0,-.25,-120);add_child(ground)
 for i in 8:
  var seg=Node3D.new();seg.position.z=-i*SEG;add_child(seg);roads.append(seg)
  seg.add_child(box(Vector3(12,.18,SEG),material(Color("#30343a"))))
  for x in [-2.0,2.0]:
   var line=box(Vector3(.12,.03,SEG),material(Color.WHITE));line.position=Vector3(x,.11,0);seg.add_child(line)
  for side in [-1,1]:
   var curb=box(Vector3(.35,.28,SEG),material(Color("#c9c9c9")));curb.position=Vector3(side*6.25,.08,0);seg.add_child(curb)
   for j in 3:
    var trunk=cyl(.16,1.5,material(Color("#6b4226")));trunk.position=Vector3(side*11,0.75,-10+j*12);seg.add_child(trunk)
    var crown=cyl(.8,1.7,material(Color("#18783b")));crown.position=Vector3(side*11,2,-10+j*12);seg.add_child(crown)

func make_player():
 player=Node3D.new();player.position=Vector3(0,.8,7);add_child(player)
 var body=box(Vector3(2.2,.65,4.1),material(Color("#e72b31"),.25));body.position.y=.45;player.add_child(body)
 var cabin=box(Vector3(1.65,.55,1.9),material(Color("#081a2b"),.15));cabin.position=Vector3(0,.92,-.25);player.add_child(cabin)
 for x in [-.95,.95]:
  for z in [-1.25,1.25]:
   var w=cyl(.38,.22,material(Color("#09090b")));w.rotation_degrees.z=90;w.position=Vector3(x,.12,z);player.add_child(w)

func make_camera():
 camera=Camera3D.new();camera.position=Vector3(0,5.3,12.5);camera.rotation_degrees=Vector3(-12,0,0);add_child(camera);camera.current=true

func label(text,pos,size):
 var l=Label.new();l.text=text;l.position=pos;l.size=Vector2(700,60);l.add_theme_font_size_override("font_size",size);l.add_theme_color_override("font_color",Color.WHITE);return l
var score_l;var coin_l;var speed_l;var loading;var bar;var game_over_ui
func make_ui():
 var layer=CanvasLayer.new();add_child(layer)
 loading=ColorRect.new();loading.color=Color("#07101c");loading.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);layer.add_child(loading)
 var title=label("3D RUSH",Vector2(0,180),58);title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;title.add_theme_color_override("font_color",Color("#ff3b30"));loading.add_child(title)
 var dev=label("Asif develops",Vector2(0,285),28);dev.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;loading.add_child(dev)
 bar=ProgressBar.new();bar.position=Vector2(100,390);bar.size=Vector2(520,35);loading.add_child(bar)
 var lt=label("LOADING...",Vector2(0,440),20);lt.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;loading.add_child(lt)
 score_l=label("SCORE  0",Vector2(28,30),28);layer.add_child(score_l)
 coin_l=label("COINS  0",Vector2(28,70),24);layer.add_child(coin_l)
 speed_l=label("SPEED  0",Vector2(28,108),22);layer.add_child(speed_l)
 var hint=label("DRAG LEFT / RIGHT TO STEER",Vector2(0,1150),20);hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;hint.size.x=720;layer.add_child(hint)
 game_over_ui=ColorRect.new();game_over_ui.color=Color(0,0,0,.72);game_over_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);game_over_ui.visible=false;layer.add_child(game_over_ui)
 var over_l=label("GAME OVER",Vector2(0,360),54);over_l.name="Over";over_l.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;over_l.add_theme_color_override("font_color",Color("#ff3b30"));game_over_ui.add_child(over_l)
 var b=Button.new();b.text="RESTART";b.position=Vector2(245,520);b.size=Vector2(230,75);b.add_theme_font_size_override("font_size",28);b.pressed.connect(restart);game_over_ui.add_child(b)

func _process(d):
 if !loaded:
  load_value=min(100.0,load_value+d*60);bar.value=load_value
  if load_value>=100: loaded=true;await get_tree().create_timer(.3).timeout;loading.visible=false
  return
 if over:return
 speed=min(42.0,speed+d*.35);distance+=speed*d;score=int(distance*4)+coin_count*50
 player.position.x=lerp(player.position.x,target_x,min(1.0,d*10));player.rotation.z=lerp(player.rotation.z,(target_x-player.position.x)*-.05,d*7)
 for r in roads:
  r.position.z+=speed*d
  if r.position.z>40:r.position.z-=SEG*roads.size()
 spawn-=d;coin_spawn-=d
 if spawn<=0:_spawn_car();spawn=max(.42,1.15-speed*.012)
 if coin_spawn<=0:_spawn_coins();coin_spawn=1.8
 for car in traffic.duplicate():
  car.position.z+=speed*d
  if car.position.z>25:traffic.erase(car);car.queue_free()
  elif abs(car.position.x-player.position.x)<1.65 and abs(car.position.z-7)<2.2:game_over()
 for c in coins.duplicate():
  c.position.z+=speed*d;c.rotate_y(d*6)
  if c.position.z>25:coins.erase(c);c.queue_free()
  elif abs(c.position.x-player.position.x)<1.4 and abs(c.position.z-7)<1.7:coin_count+=1;coins.erase(c);c.queue_free()
 score_l.text="SCORE  "+str(score);coin_l.text="COINS  "+str(coin_count);speed_l.text="SPEED  "+str(int(speed*6))+" KM/H"

func _spawn_car():
 var car=Node3D.new();car.position=Vector3(LANES[rng.randi_range(0,2)],.8,-105);add_child(car);traffic.append(car)
 var cols=[Color("#2f78d0"),Color("#f2c94c"),Color("#eeeeee"),Color("#9b59b6")]
 var body=box(Vector3(2.2,.65,4),material(cols[rng.randi_range(0,3)],.3));body.position.y=.45;car.add_child(body)
 var cab=box(Vector3(1.65,.55,1.8),material(Color("#142331"),.2));cab.position=Vector3(0,.92,-.2);car.add_child(cab)
func _spawn_coins():
 var x=LANES[rng.randi_range(0,2)]
 for i in 3:
  var c=cyl(.45,.12,material(Color("#ffd43b"),.25));c.rotation_degrees.x=90;c.position=Vector3(x,1.15,-85-i*4);add_child(c);coins.append(c)
func _input(e):
 if !loaded or over:return
 if e is InputEventScreenTouch and e.pressed:set_target(e.position.x)
 elif e is InputEventScreenDrag:set_target(e.position.x)
 elif e is InputEventMouseButton and e.button_index==MOUSE_BUTTON_LEFT and e.pressed:set_target(e.position.x)
 elif e is InputEventMouseMotion and e.button_mask&MOUSE_BUTTON_MASK_LEFT:set_target(e.position.x)
func set_target(x):target_x=lerp(-3.2,3.2,clamp(x/720.0,0.0,1.0))
func game_over():
 over=true;game_over_ui.visible=true;game_over_ui.get_node("Over").text="GAME OVER\nSCORE  "+str(score)+"\nCOINS  "+str(coin_count)
func restart():
 for c in traffic:c.queue_free()
 for c in coins:c.queue_free()
 traffic.clear();coins.clear();target_x=0;player.position.x=0;speed=18;distance=0;score=0;coin_count=0;over=false;game_over_ui.visible=false
