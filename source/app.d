module kaksipiippuinen.app;
import std.random, std.math, std.range, std.algorithm, std.array,
    std.stdio, std.process, std.conv, std.typecons, std.container,
    std.variant, std.traits;
import kaksipiippuinen.bird, kaksipiippuinen.shot, kaksipiippuinen.gameObject;
import core.runtime;
import dlib.math.vector : vec3;
import sd = arsd.simpledisplay;

alias InputEvent = Algebraic!(sd.KeyEvent, sd.MouseEvent);

//enum collectLength = 500;
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

class GameBoard : sd.SimpleWindow
{   enum size = vec3(32, 24, 0);
    enum windowParameters = tuple(640, 480, "Kaksipiippuinen");
    enum missPenalty = 10.0;
    int drops;
    float time = 240;
    GameObject[] content;

    public this()
    {   super(windowParameters.expand);
        foreach(i; 0 .. 5){content ~= new Bird;}
    }
    private class Bird : kaksipiippuinen.bird.Bird{
    this(){
        position = vec3(-1, 0.5.uniform(1) * GameBoard.size.y, normalZ);
        velocity = vec3(uniform(7.5, 12.5 + drops * .1), 0, 0);
        if (dice(50, 50)){
        position.x = GameBoard.size.x + 1;
        velocity.x *= -1;
        }
    }

    override void takeDamage(int amount){
        auto originallyAlive = hitPoints >= 0;
        auto originalSpeed = velocity.x;
        super.takeDamage(amount);
        if (originallyAlive){
        //tappo
        if(hitPoints < 0){
            drops++;
            time += originalSpeed.abs;
        }
        //haavakko
        else{}
        }
    }
    override bool outOfArea(){
        if (-Bird.size.x <= position.x && position.x <= GameBoard.size.x + Bird.size.x)
        return false;
        //haavoittunut
        if (hitPoints != normalHitPoints && hitPoints >= 0){
        time = time * .9 - 15;
        }
        return position.x.sgn == velocity.x.sgn;
    }
    }
    auto _hitCanditates()
    {   return  content
        .   map!(a => cast(Bird)a)
        .   filter!(a => a)
        ;
    }

    private class Shot : kaksipiippuinen.shot.Shot!Bird
    {   int kills = 0;
        override bool outOfArea()
        {   return (position.z > 2 * Bird.normalZ)
            .   use!( (a)
                {   if(a)
                    {   writeln("shot out");
                        //Tappamaton laukaus sakottaa,
                        //useamman kerralla tappamalla saa bonuksen
                        time += (kills - 1) * missPenalty;
                    }
                    return a;
                })
            ;
        }

        override void onHit(Bird victim, int damage)
        {   if (!victim.alive) kills--;
            super.onHit(victim, damage);
            if (!victim.alive) kills++;
        }

        override ForwardRange!Bird hitCanditates(){return _hitCanditates.inputRangeObject;}
    }

    void onMouseEvent(sd.MouseEvent what)
    {   if(what.type == sd.MouseEventType.buttonPressed)
        {   if(what.button == sd.MouseButton.left)
            {  writeln("bang!");
                auto shot = new Shot;
                content ~= shot;
                shot.position = vec3(what.x / 20, size.y - what.y / 20, 0);
                shot.velocity = shot.muzzleVel;
            }
        }
    }

    override sd.ScreenPainter draw()
    {   auto painter = super.draw();
        painter.clear;
        painter.outlineColor = sd.Color.black;
        painter.fillColor = sd.Color.black;

        content.each!( (GameObject na){
            if(auto a = cast(Bird)na)
            {
                auto paintPos = (a.position * 20).use!((vec3 b) => sd.Point(b.x.to!int, GameBoard.height - b.y.to!int) );
                paintPos.x -= Bird.size.x / 2;
                paintPos.y -= Bird.size.y / 2;
                painter.drawRectangle(paintPos, Bird.size.x, Bird.size.y);
            }});

        painter.drawText(sd.Point(0, 0), "Tiputuksia: " ~ drops.to!string);
        painter.drawText(sd.Point(0, 30), "Aika: " ~ time.to!int.to!string);
        return painter;
    }
}


void main() {
    auto board = new GameBoard;

    board.eventLoop((delta*1000).to!int,
            delegate () {
                try{
                    board.step;
                    board.draw;
                } catch(Throwable e){
                    e.toString((a){a.writeln;});
                    stdout.flush;
                    Runtime.terminate;
                }
            },
            delegate (sd.KeyEvent event) {},
            delegate (sd.MouseEvent event)
            {   board.onMouseEvent(event);
            }
    );
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

void step(GameBoard board){
    with(board)
    {
    if (dice(97, 3)) board.content ~= board.new Bird;
    content =
        content
        .filter!(a => a.step(delta))
        .array;
    }
    board.time -= delta * (1 + board.drops/100);

}


