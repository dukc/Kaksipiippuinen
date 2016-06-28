import std.random, std.math, std.range, std.algorithm, std.array,
	std.stdio, std.process, std.conv, std.typecons, std.container,
	std.variant, std.traits;
import bird, shot, gameObject;
import core.runtime;
import dlib.math.vector : vec3;
static import simpledisplay;
alias sd = simpledisplay;
static import dlib;

alias InputEvent = Algebraic!(sd.KeyEvent, sd.MouseEvent);

enum collectLength = 500;
enum delta = .04f;

auto ref use(alias code, T)(auto ref T a){return code(a);}

struct Functor(alias f){
	Parameters!f[0] state;
	auto opCall(Parameters!f[1 .. $] par){
		return f(state, par);
	}
	this (Parameters!f[0] a){
		state = a;
	}
}

auto cumulative(Range)(Range base)
	if (isInputRange!Range)
{	return Cumulative!(Range, ReturnType!(Range.front))(base);
}
struct Cumulative(Range, Elem)
	if (isInputRange!Range)
{  Range base;
	Elem soFar;
	bool frontCalculated = false;
	static if (isForwardRange!Range)
	{	this(this)
	{	base = base.save;
	}}
	ref front()
	{	if (!frontCalculated)
		{	soFar += base.front;
			frontCalculated = true;
		}
		return soFar;
	}
	void popFront()
	{	front;
		base.popFront;
		frontCalculated = false;
	}
	bool empty()
	{	return base.empty;
	}
	static if (isForwardRange!Range)
	{	auto save() inout
	{	return this;
	}}
}

void generate(C)(C mission, int times){
	static if (is(void == ReturnType!mission)){
		mission
			.repeat(times)
			.each!(a => a());
	} else {
		mission
			.generate
			.take(times);
	}
	return;
}

class GameBoard{
	auto size = sd.Point(32, 24);
	int drops = 0;
	float time = 0;
	GameObject[] content;
	/+auto schelude = make!(RedBlackTree!(Variant, "a.state.time < b.state.time") );
	SList!InputEvent events; +/

	this()
	{	foreach(i; 0 .. 5){content ~= new Bird;}
	}
	private class Bird : bird.Bird
	{  this()
		{	position = vec3(-1, 0.5.uniform(1) * GameBoard.size.y, normalZ);
			velocity = vec3(uniform(7.5, 12.5), 0, normalZ);
			if (dice(50, 50)){
				position.x = GameBoard.size.x + 1;
				velocity.x *= -1;
			}
		}
		override bool outOfArea()
		{	if (-Bird.size.x <= position.x && position.x <= GameBoard.size.x + Bird.size.x)
				return false;
			return position.x.sgn == velocity.x.sgn;
		}
	}

	//En keksi parempaa tapaa saada tyyppiä Shotin (alla) malliargumentille
	auto _hitCanditates()
	{	return	content
		.	map!(a => cast(Bird)a)
		.	filter!(a => a)
		;
	}

	private class Shot : shot.Shot!(typeof(_hitCanditates() ) )
	{	override bool outOfArea()
		{	return (position.z > 2 * Bird.normalZ)
			.	use!( (a)
				{	if(a) {writeln("shot out");}
					return a;
				})
			;
		}

		override typeof(_hitCanditates() ) hitCanditates(){return _hitCanditates;}
	}

	void onMouseEvent(sd.MouseEvent what)
	{	if(what.type == sd.MouseEventType.buttonPressed)
		{	if(what.button == sd.MouseButton.left)
			{  writeln("bang!");
				auto shot = new Shot;
				content ~= shot;
				shot.position = vec3(what.x * 20, what.y * 20, 0);
				shot.velocity = shot.muzzleVel;
			}
		}
	}
}



void main() {
	auto board = new GameBoard;
	auto window = new sd.SimpleWindow(640, 480, "Kaksipiippuinen");

	/+(() => board.serve)
		.generate(5);+/

	window.eventLoop((delta*1000).to!int,
		delegate () {
			try{
				board.step; draw(window, board);
			} catch(Throwable e){
				e.toString((a){a.writeln;});
				stdout.flush;
				Runtime.terminate;
			}
		},
		delegate (sd.KeyEvent event) {},
		delegate (sd.MouseEvent event)
		{board.onMouseEvent(event);}
	);
}

/+struct Shot{
	dlib.Sphere shape;
	alias shape this;
	ref position() @property inout {return shape.center;}
	enum velocity = vec3(0, 0, 200);
}+/

/+auto step(ref Bird obj){
	obj.position += obj.velocity * delta;
	return obj;
}

auto effective(Bird a, in GameBoard where){
	if (-Bird.size.x <= a.position.x && a.position.x <= where.size.x + Bird.size.x)
		return true;
	return a.position.x.sgn != a.velocity.x.sgn;
}+/

auto alive(Bird what){return what.hitPoints > 0;}
unittest{
	auto rabbit = Bird.init;
	assert(rabbit.alive);
	rabbit.hitPoints = 0;
	assert(!rabbit.alive);
	rabbit.hitpoints -= 10;
	assert(!rabbit.alive);
}

/+auto step(ref Shot obj){
	obj.position += obj.velocity * delta;
	return obj;
}

auto effective(in Shot obj, in GameBoard where){
	return obj.position.z < 50;
}+/

void step(ref GameBoard board){
	with(board)
{
	if (dice(97, 3)) board.content ~= board.new Bird;
	content =
		content
		.filter!(a => a.step(delta))
		.array;
	/+shots =
		shots
		.filter!(a => a.effective(board))
		.array;
	shots.each!((ref Shot a){
		a.step;
	});
	board.time += delta;
	schelude[ ]
		.until!(a => a.state.time < board.time)
		.each!"a( )";+/
}}

void draw(sd.SimpleWindow window, GameBoard board){
	auto painter = window.draw();
	painter.clear;
	painter.outlineColor = sd.Color.black;
	painter.fillColor = sd.Color.black;

	board.content.each!( (GameObject na){
		if(auto a = cast(Bird)na)
	{
        auto paintPos = (a.position * 20).use!((vec3 b) => sd.Point(b.x.to!int, window.height - b.y.to!int) );
        paintPos.x -= Bird.size.x / 2;
        paintPos.y -= Bird.size.y / 2;
		painter.drawRectangle(paintPos, Bird.size.x, Bird.size.y);
	}});
}

/+void serve(ref GameBoard where) {
	where.content ~= where.new Bird;
} +/
