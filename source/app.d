import std.random, std.math, std.range, std.algorithm, std.array,
	std.stdio, std.process, std.conv, std.typecons, std.container,
	std.variant, std.traits;
import core.runtime;
import dlib.math.vector : vec3;
static import simpledisplay;
alias sd = simpledisplay;
static import dlib;

enum collectLength = 500;
enum delta = .04f;

struct Functor(alias f){
	Parameters!f[0] state;
	auto opCall(Parameters!f[1 .. $] par){
		return f(state, par);
	}
	this (Parameters!f[0] a){
		state = a;
	}
}

void generate(C)(C mission, int times){
	static if (is(void == ReturnType!mission)){
		mission
			.repeat(times)
			.each!("a()");
	} else {
		mission
			.generate
			.take(times);
	}
	return;
}

class GameBoard{
	auto size = sd.Point(640, 480);
	int drops = 0;
	Bird[] birds;
	Shot[] shots;
	auto schelude = make!(RedBlackTree!(Tuple!(float, Variant), "a[0] < b[0]"));
}

void main() {
	auto board = GameBoard.init;
	auto window = new sd.SimpleWindow(640, 480, "Kaksipiippuinen");

	(() => board.serve)
		.generate(5);

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
		delegate (sd.MouseEvent event) {}
	);
}

struct Bird{
	enum size = sd.Point(30, 10);
	enum normalHitPoints = 2;
	enum normalZ = 30;
	
	vec3 position;
	vec3 velocity;
	int _hitPoints = normalHitPoints;

	ref hitPoints()@property {return _hitPoints;}
	auto hitPoints(int val)@property {
        velocity.y = val - normalHitPoints;
		return _hitPoints = val;}
}

struct Shot{
	dlib.Sphere shape;
	alias shape this;
	ref position() @property inout {return shape.center;}
	enum velocity = vec3(0, 0, 200);
}

auto step(ref Bird obj){
	obj.position += obj.velocity * delta;
	return obj;
}

auto effective(Bird a, in GameBoard where){
	if (-Bird.size.x <= a.position.x && a.position.x <= where.size.x + Bird.size.x)
		return true;
	return a.position.x.sgn != a.velocity.x.sgn;
}

auto alive(Bird what){return what.hitPoints > 0;}
unittest{
	auto rabbit = Bird.init;
	assert(rabbit.alive);
	rabbit.hitPoints = 0;
	assert(!rabbit.alive);
	rabbit.hitpoints -= 10;
	assert(!rabbit.alive);
}

auto step(ref Shot obj){
	obj.position += obj.velocity * delta;
	return obj;
}

auto effective(in Shot obj, in GameBoard where){
	return obj.position.z < 50;
}

void step(ref GameBoard board){
	with(board)
{
	if (dice(97, 3)) board.serve;
	birds =
		birds
		.filter!(a => a.effective(board))
		.array;
	birds.each!((ref Bird a){
		a.step;
	});
	shots =
		shots
		.filter!(a => a.effective(board))
		.array;
	shots.each!((ref Shot a){
		a.step;
	});
	
}}

void draw(sd.SimpleWindow window, GameBoard board){
	auto painter = window.draw();
	painter.clear;
	painter.outlineColor = sd.Color.black;
	painter.fillColor = sd.Color.black;
	 
	board.birds.each!( (ref Bird a){
        auto paintPos = sd.Point(a.position.x.to!int, a.position.y.to!int);
        paintPos.x -= Bird.size.x / 2;
        paintPos.y -= Bird.size.y / 2;
		painter.drawRectangle(paintPos, Bird.size.x, Bird.size.y);
		return;
	});
}

void serve(ref GameBoard where) {
	if (where.birds.length >= collectLength)
		where.birds = where.birds.filter!(a => a.effective(where)).array;
	auto newcomer = Bird(vec3(-20, 0.uniform(where.size.y / 2), Bird.normalZ), vec3(uniform(150, 250), 0, Bird.normalZ));
	if (dice(50, 50)){
		newcomer.position.x = where.size.x + 20;
		newcomer.velocity.x *= -1;
	}
	where.birds ~= newcomer;
}
