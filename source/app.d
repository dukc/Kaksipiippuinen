module kaksipiippuinen.app;
import std.random, std.math, std.range, std.algorithm, std.array,
    std.stdio, std.process, std.conv, std.typecons, std.container,
    std.variant, std.traits;
import kaksipiippuinen.bird, kaksipiippuinen.shot, kaksipiippuinen.gameObject;
import core.runtime;
import dlangui.core.math3d;
import dlangui;

enum delta = .04f;

mixin APP_ENTRY_POINT;

class GameBoard : CanvasWidget
{   import dlangui.core.types : Rect;

    enum size = vec3(32, 24, 0);
    enum missPenalty = 10.0;
    int drops;
    float time = 240;
    GameObject[] content;
    ulong stepTimer;

    static xOf(vec2 pos, Rect transform)
    {   return cast(int)(pos.x / size.x * transform.width) + transform.left;
    }

    static yOf(vec2 pos, Rect transform)
    {   return transform.bottom - cast(int)(pos.y / size.y * transform.height);
    }

    static vecOf(int x, int y, Rect transform)
    {   return vec2
        (   (x - transform.left) * size.x / transform.width,
            -(y - transform.bottom) * size.y / transform.height,
        );
    }

    public void start()
    {   foreach(i; 0 .. 5){content ~= new Bird;}
        stepTimer = setTimer(cast(long)(1000 * delta));
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
                    {   //Tappamaton laukaus sakottaa,
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

    override bool onMouseEvent(from!"dlangui".MouseEvent what)
    {   import dlangui;
        if(what.action == MouseAction.ButtonDown)
        {   if(what.button == MouseButton.Left)
            {   auto shot = new Shot;
                content ~= shot;
                shot.position = vec3(vecOf(what.x, what.y, Rect(0, 0, window.width, window.height)).vec[] ~ [0.0f]);
                shot.velocity = shot.muzzleVel;
                return true;
            }
        }
        
        return false;
    }

    override void doDraw(from!"dlangui".DrawBuf buf, Rect area)
    {   import dlangui;
        //buf.fillRect(area, 0x00FFFFFF);
        buf.fill(/*white*/ 0x00FFFFFF);

        content.each!( (GameObject na){
            if(auto a = cast(Bird)na)
            {
                auto paintPos = vec2(a.position.vec[0 .. 2]) - Bird.size / 2;
                buf.fillRect(Rect
                (   xOf(paintPos, area),
                    yOf(paintPos + Bird.size, area),
                    xOf(paintPos + Bird.size, area),
                    yOf(paintPos, area),
                ), /*black*/ 0X00000000);
            }});

        font.drawText(buf, area.left, area.top, "Tiputuksia: "d ~ drops.to!dstring, 0x00000000);
        font.drawText(buf, area.left, area.top + 30, "Aika: "d ~ time.to!int.to!dstring, 0x00000000);
    }

    override bool onTimer(ulong timerId)
    {   if (timerId == stepTimer)
        {   if (dice(97, 3)) content ~= this.new Bird;
        
            content =
                content
                .filter!(a => a.step(delta))
                .array
                ;
            time -= delta * (1 + drops/100);
            invalidate();

            return true;
        }
        assert(false);
    }
}


extern (C) int UIAppMain(string[] args)
{   import dlangui;
    Window window = Platform.instance.createWindow("Kaksipiippuinen", null, WindowFlag.Resizable | WindowFlag.ExpandSize, 640, 480);
    auto board = new GameBoard();
    window.mainWidget = board;
    window.show;
    board.start;
    return Platform.instance.enterMessageLoop();
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

//////////////////////////////////////////////////////
//utilites from here-on

auto ref use(alias code, T)(auto ref T a){return code(a);}

//Nielsen-Scherkl lookup
template from(string moduleName)
{
    mixin("import from = " ~ moduleName ~ ";");
}

