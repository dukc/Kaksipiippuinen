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
    float time = -1;
    GameObject[] content;
    ulong stepTimer;
    vec2 mousePos;

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

    public void restart()
    {   drops = 0;
        time = 240;
        content.length = 0;
        stepTimer = setTimer(cast(long)(1000 * delta));
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
    {   if(time < 0) return false;
        mousePos = vecOf(what.x, what.y, Rect(0, 0, window.width, window.height));
        
        if(what.action == MouseAction.ButtonDown)
        {   if(what.button == MouseButton.Left)
            {   auto shot = new Shot;
                content ~= shot;
                shot.position = vec3(mousePos.vec[] ~ [0.0f]);
                shot.velocity = shot.muzzleVel;
            }
        }
        
        invalidate();
        return true;
    }

    override bool onKeyEvent(KeyEvent what)
    {   if(what.keyCode == KeyCode.F2 && time < 0.0f)
        {   restart;
            return true;
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
            
        auto barrels = drawableCache.getImage("Barrels").get;
        buf.drawRescaled
        (
            Rect
            (   xOf(mousePos, area) - area.width / 2,
                yOf(mousePos, area),
                xOf(mousePos, area) + area.width / 2,
                yOf(mousePos, area) + area.height,
            ),
            barrels,
            Rect(0, 0, barrels.width, barrels.height),
        );

        if(true)
        {   bool gameOver = time < 0;
            auto textColor = gameOver? Color.red: Color.black;
            font.drawText(buf, area.left, area.top, "Tiputuksia: "d ~ drops.to!dstring, textColor);
            if(gameOver)
            {   font.drawText(buf, area.left, area.top + 30, "Kiitos pelistä! F2 aloittaaksesi alusta."d, textColor);
            }
            else font.drawText(buf, area.left, area.top + 30, "Aika: "d ~ time.to!int.to!dstring, textColor);
        }
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

            return time >= 0;
        }
        assert(false);
    }
}


extern (C) int UIAppMain(string[] args)
{   import dlangui;
    embeddedResourceList.addResources(embedResourcesFromList!("resources.list")());
    Window window = Platform.instance.createWindow("Kaksipiippuinen", null, WindowFlag.Resizable | WindowFlag.ExpandSize, 640, 480);
    auto board = new GameBoard();
    window.mainWidget = board;
    window.show;
    board.restart;
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

