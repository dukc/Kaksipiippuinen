import simpledisplay, std.random, std.math, std.range, std.algorithm, std.array, std.stdio;
static import core.stdc.stdlib;
enum collectLength = 10;


	struct Bird{
		Point position;
		int velocity;
		enum normalHitPoints = 2;
		int hitPoints = normalHitPoints;}
	struct GameBoard{
		int width, height;
		Bird[] birds;}
	void serve(ref GameBoard where) {
		if (where.birds.length >= collectLength) collectBirds(where);
		write("new bird. it should become number ", where.birds.length+1, " of them\n");
		assert(where.birds.length < collectLength);
		write("assert passed");
		auto newcomer = Bird(Point(-20, 0.uniform(where.height / 2)), uniform(6, 10));
		if (dice(50, 50)){
			newcomer.position.x = where.width + 20;
			newcomer.velocity *= -1;}
		where.birds ~= newcomer;
	}
	void main() {
		auto board = GameBoard(600, 400);
		auto window = new SimpleWindow(600, 400, "Kaksipiippuinen");

		(() => board.serve).repeat(5).each!"a()";

		window.eventLoop(40,
			delegate () {
				try{
					board.step; draw(window, board);}
				catch(Throwable e){
					write(e.msg);
					core.stdc.stdlib.abort;}
			},
			delegate (KeyEvent event) {},
			delegate (MouseEvent event) {});
	}
void step(ref GameBoard board){
	if(dice(97, 3)) board.serve;
	board.birds.each!(
		(ref Bird a) => a.position.x += a.velocity);
	}
void draw(SimpleWindow window, GameBoard board){
	auto painter = window.draw();
	painter.clear();
	painter.outlineColor = Color.black;
	painter.fillColor = Color.black; 
	board.birds.each!((a){
        auto paintPos = a.position;
        paintPos.x -= 15;
        paintPos.y -= 5;
		painter.drawRectangle(paintPos, 30, 10);
		return;});
}
auto collectBirds(ref GameBoard where)
out(a){
	/+assert(a.birds.length < collectLength);+/}
body{
	auto collected = where.birds.filter!((a){
		if (0 <= a.position.x && a.position.x <= where.width)
			return true;
		return a.position.x != a.velocity;
	}).array;
	where.birds = collected;
	write("collector done");
	return where;	 
}
